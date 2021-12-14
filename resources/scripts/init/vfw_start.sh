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
apt-get install -y sudo curl net-tools iproute2 inetutils-ping vim
#curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | sudo bash
#curl -k -s https://packagecloud.io/install/repositories/fdio/1901/script.deb.sh | sudo bash

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

if [ -e /run/vpp/cli-vpp2.sock ]; then
    rm /run/vpp/cli-vpp2.sock
fi

apt-get install -y python3

python3 /opt/vfwstarter.py

echo "done"
sleep infinity
