#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=resolve_rocm_root.sh
source "${SCRIPT_DIR}/resolve_rocm_root.sh"
ROCM_ROOT="$(resolve_rocm_root)" || exit 1
echo "Using ROCm root: ${ROCM_ROOT}"

apt-get install -y flex
git clone https://github.com/openucx/ucx.git -b v1.18.1
cd ucx 
./autogen.sh
./configure --with-rocm="${ROCM_ROOT}" --enable-mt --prefix=/opt/ucx
make -j 
make install
echo 'export PATH=/opt/ucx/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/opt/ucx/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
cd ..
