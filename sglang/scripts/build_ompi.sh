#!/bin/bash

git clone --recursive https://github.com/open-mpi/ompi.git -b v5.0.x
cd ompi 
./autogen.pl
./configure --prefix=/opt/ompi --with-rocm=/opt/rocm --with-ucx=/opt/ucx
make -j 32
make install
echo 'export PATH=/opt/ompi/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/opt/ompi/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
cd ..
