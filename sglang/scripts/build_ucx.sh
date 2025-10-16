#!/bin/bash
apt-get install -y flex
git clone https://github.com/openucx/ucx.git -b v1.18.1
cd ucx 
./autogen.sh
./configure --with-rocm=/opt/rocm --enable-mt --prefix=/opt/ucx 
make -j 
make install
echo 'export PATH=/opt/ucx/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/opt/ucx/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
cd ..
