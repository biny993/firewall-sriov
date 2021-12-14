#!/bin/bash

#update root ca (wr lab only)
# apt-get update

# echo 'Updte CA Cert'
# mkdir -p /usr/local/share/ca-certificates/extra
# cp /opt/rootCA.crt /usr/local/share/ca-certificates/extra/
# update-ca-certificates
# apt install -y libnss3-tools
# cp /opt/ImportScript /root
# chmod a+x /root/ImportScript
# /root/ImportScript

apt-get update
apt-get install -y sudo curl net-tools iproute2 wget inetutils-ping vim

#curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | sudo bash

apt-get install -y gnupg
curl -k -L https://packagecloud.io/fdio/1901/gpgkey | sudo apt-key add -

cat <<EOF > /etc/apt/sources.list.d/fdio_1901.list
deb https://packagecloud.io/fdio/1901/ubuntu/ bionic main
deb-src https://packagecloud.io/fdio/1901/ubuntu/ bionic main
EOF

apt-get update

#export VPP_VER=19.01.2-release
export VPP_VER=19.01.3-rc0~9-gbef25c30a~b79
apt-get install -y vpp=$VPP_VER vpp-lib=$VPP_VER
apt-get install -y vpp-plugins=$VPP_VER

if [ -e /run/vpp/cli-vpp1.sock ]; then
    rm /run/vpp/cli-vpp1.sock
fi

apt-get install -y python3

python3 /opt/vpgstarter.py

# #	root@vpktgen:/# taskset -p --cpu-list 1
# #	pid 1's current affinity list: 1,2,29

# corelist=`taskset -p -c 1 |cut -d : -f 2 | sed 's/^ *//' | sed 's/ *$//'`
# #extract master core
# mastercoreidx=`echo $corelist | cut -d , -f 1`
# #extract worker cores
# workercorelist=`echo $corelist | sed -E 's/^[0-9]*,//'`

# echo 'start... vpp'
# vpp unix {cli-listen /run/vpp/cli-vpp1.sock} api-segment { prefix vpp1 } \
#     cpu { main-core $mastercoreidx  corelist-workers $workercorelist }

# echo 'wait vpp be up ...'
# while [ ! -e /run/vpp/cli-vpp1.sock ]; do
#     sleep 1;
# done

# echo 'configure vpp ...'

# ifconfig veth11 0.0.0.0
# ifconfig veth11 down

# HWADDR1=$(ifconfig veth11 |grep ether | tr -s ' ' | cut -d' ' -f 3)

# vppctl -s /run/vpp/cli-vpp1.sock show ver
# vppctl -s /run/vpp/cli-vpp1.sock show threads

# vppctl -s /run/vpp/cli-vpp1.sock create host-interface name veth11 hw-addr $HWADDR1

# vppctl -s /run/vpp/cli-vpp1.sock set int state host-veth11 up

# vppctl -s /run/vpp/cli-vpp1.sock show int
# vppctl -s /run/vpp/cli-vpp1.sock show hardware

# vppctl -s /run/vpp/cli-vpp1.sock set int ip address host-veth11 10.10.1.2/24

# vppctl -s /run/vpp/cli-vpp1.sock show int addr

# vppctl -s /run/vpp/cli-vpp1.sock ip route add 10.10.2.0/24  via 10.10.1.1

# vppctl -s /run/vpp/cli-vpp1.sock show ip fib

# #vppctl -s /run/vpp/cli-vpp1.sock trace add af-packet-input 10

echo "provision streams"
### pktgen config
vppctl -s /run/vpp/cli-vpp1.sock loop create
vppctl -s /run/vpp/cli-vpp1.sock set int ip address loop0 11.22.33.1/24
vppctl -s /run/vpp/cli-vpp1.sock set int state loop0 up

cd /opt

mkdir /home/root
cat <<EOF> /home/root/stream_fw_udp1_loop0
packet-generator new {
	  name fw_udp1
	  rate 10
	  node ip4-input
	  size 64-64
	  no-recycle
      interface loop0
	  data {
		UDP: 10.10.1.2 -> 10.10.2.2
		UDP: 15320 -> 8080
		length 128 checksum 0 incrementing 1
	  }
	}
EOF

vppctl -s /run/vpp/cli-vpp1.sock  exec /home/root/stream_fw_udp1_loop0

#vppctl -s /run/vpp/cli-vpp1.sock show packet-generator

#vppctl -s /run/vpp/cli-vpp1.sock trace add pg-input 10

vppctl -s /run/vpp/cli-vpp1.sock packet-generator enable

vppctl -s /run/vpp/cli-vpp1.sock show packet-generator

vppctl -s /run/vpp/cli-vpp1.sock show int

#vppctl -s /run/vpp/cli-vpp1.sock packet-generator disable

#vppctl -s /run/vpp/cli-vpp1.sock packet-generator delete fw_udp1

echo "done"
sleep infinity