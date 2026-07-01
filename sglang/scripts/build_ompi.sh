#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=resolve_rocm_root.sh
source "${SCRIPT_DIR}/resolve_rocm_root.sh"
ROCM_ROOT="$(resolve_rocm_root)" || exit 1
echo "Using ROCm root: ${ROCM_ROOT}"

git clone --recursive https://github.com/open-mpi/ompi.git -b v5.0.x
cd ompi 
./autogen.pl
./configure --prefix=/opt/ompi --with-rocm="${ROCM_ROOT}" --with-ucx=/opt/ucx
make -j 32
make install
echo 'export PATH=/opt/ompi/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/opt/ompi/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
cd ..
