#!/bin/bash
apt update && apt install -y zip unzip openssh-server
apt -y install gcc make libtool autoconf  librdmacm-dev rdmacm-utils infiniband-diags ibverbs-utils perftest ethtool  libibverbs-dev rdma-core strace
cd /sgl-workspace
pip install mooncake-transfer-engine
