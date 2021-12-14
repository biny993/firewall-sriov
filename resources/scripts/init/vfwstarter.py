#!/usr/bin/python

import os
import subprocess
from time import sleep
import time

def start_vpp(master_core, worker_cores):
    print("start vpp, master %s, worker_cores: %s" % (master_core,worker_cores))
    subprocess.check_call(
        "vpp unix {cli-listen /run/vpp/cli-vpp2.sock} api-segment { prefix vpp2 } \
            cpu { main-core %s  corelist-workers %s }" % (master_core, worker_cores), 
            shell=True)
    while not os.path.exists("/run/vpp/cli-vpp2.sock"):
        print("waiting for vpp up ...")
        time.sleep(1)
        pass
    print("configure vpp ...")

    subprocess.check_call("ifconfig veth12 0.0.0.0", shell=True)
    subprocess.check_call("ifconfig veth12 down", shell=True)
    subprocess.check_call("ifconfig veth21 0.0.0.0", shell=True)
    subprocess.check_call("ifconfig veth21 down", shell=True)

    status1, HWADDR1= subprocess.getstatusoutput("ifconfig veth12 |grep ether | tr -s ' ' | cut -d' ' -f 3")
    status2, HWADDR2= subprocess.getstatusoutput("ifconfig veth21 |grep ether | tr -s ' ' | cut -d' ' -f 3")
    if status1 != 0 or status2 != 0:
        print("Failed to get HW Addr")
        exit(-1)
    subprocess.check_call("vppctl -s /run/vpp/cli-vpp2.sock show ver", shell=True)
    subprocess.check_call("vppctl -s /run/vpp/cli-vpp2.sock show threads", shell=True)
    subprocess.check_call("vppctl -s /run/vpp/cli-vpp2.sock create host-interface name veth12 hw-addr %s"%HWADDR1, shell=True)
    subprocess.check_call("vppctl -s /run/vpp/cli-vpp2.sock set int state host-veth12 up", shell=True)
    subprocess.check_call("vppctl -s /run/vpp/cli-vpp2.sock set int ip address host-veth12 10.10.1.1/24", shell=True)
    subprocess.check_call("vppctl -s /run/vpp/cli-vpp2.sock create host-interface name veth21 hw-addr %s"%HWADDR2, shell=True)
    subprocess.check_call("vppctl -s /run/vpp/cli-vpp2.sock set int state host-veth21 up", shell=True)
    subprocess.check_call("vppctl -s /run/vpp/cli-vpp2.sock set int ip address host-veth21 10.10.2.1/24", shell=True)
    subprocess.check_call("vppctl -s /run/vpp/cli-vpp2.sock show hardware", shell=True)
    subprocess.check_call("vppctl -s /run/vpp/cli-vpp2.sock show int", shell=True)
    subprocess.check_call("vppctl -s /run/vpp/cli-vpp2.sock show int addr", shell=True)
    subprocess.check_call("vppctl -s /run/vpp/cli-vpp2.sock show ip fib", shell=True)

def extract_master_worker_cores():
    status, coreliststr = subprocess.getstatusoutput(
        "taskset -p -c 1 |cut -d : -f 2 | sed 's/^ *//' | sed 's/ *$//'")
    print("coreliststr: %s" % coreliststr)
    corelist = cpu_list_decoder(coreliststr)
    master_core = corelist[0] if len(corelist) > 0 else -1
    worker_cores = corelist[1:] if len(corelist) > 1 else []
    return master_core, worker_cores

def cpu_list_decoder(cpuliststr):
    print("cpu list:"+cpuliststr)
    result = []
    if cpuliststr == "":
        return []
    # split by ,
    toplist = cpuliststr.split(',')
    for ele in toplist:
        if '-' not in ele:
            result.append(int(ele))
            continue

        secondlist = ele.split('-')
        start = int(secondlist[0])
        end = int(secondlist[1])
        while start <= end:
            result.append(start)
            start += 1
    print("decoded: "+ str(result))
    return result

master_core, worker_cores = extract_master_worker_cores()
start_vpp(master_core, worker_cores)

# if __name__ == "__main__":
#     print ('This is main of module "cpu-list-decoder.py"')
#     cpu_list_decoder("3-5")
#     cpu_list_decoder("2,5-9")
#     cpu_list_decoder("2-4,4-8,11")
