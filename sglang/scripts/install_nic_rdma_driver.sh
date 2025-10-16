#!/bin/bash

echo -e "\n\n============Installing required pkgs============\n\n"
apt -y install libelf-dev

wget https://docs.broadcom.com/docs-and-downloads/ethernet-network-adapters/NXE/Thor2/GCA2/bcm5760x_231.2.63.0a.zip
unzip -o bcm5760x_231.2.63.0a.zip
cd bcm5760x_231.2.63.0a/drivers_linux/bnxt_rocelib/

tar --no-same-owner -xvzf libbnxt_re-231.0.162.0.tar.gz
cd libbnxt_re-231.0.162.0

echo -e "\n\n============Compiling RoCE Lib now============\n\n"
sh autogen.sh
./configure
make
find /usr/lib64/  /usr/lib -name "libbnxt_re-rdmav*.so"  -exec mv {} {}.inbox \;
make install all
sh -c "echo /usr/local/lib >> /etc/ld.so.conf"
ldconfig
cp -f bnxt_re.driver /etc/libibverbs.d/
find . -name "*.so" -exec md5sum {} \;
BUILT_MD5SUM=$(find . -name "libbnxt_re-rdmav*.so" -exec md5sum {} \; |  cut -d " " -f 1)
echo -e "\n\nmd5sum of the built libbnxt_re is $BUILT_MD5SUM"
