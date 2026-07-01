# Setup Environment LLM distributed inference on 2 GPU nodes
Scripts and tools for setup environment for SGLang PD disaggregation in docker container, verified on 2 8xMI325X gpu nodes.

### Reference:
- [LLM distributed inference and PD disaggregation on AMD Instinct GPUs](https://rocm.docs.amd.com/projects/ai-developer-hub/en/latest/notebooks/inference/SGlang_PD_Disagg_On_AMD_GPU.html)
- [Unleashing AMD Instinct™ MI300X GPUs for LLM Serving: Disaggregating Prefill & Decode with SGLang](https://rocm.blogs.amd.com/software-tools-optimization/disaggregation/README.html)

### 1. Launch docker container
```bash
podman run --name rocm-sgl-dev-v0.5.2-rocm700-mi30x-20250915-rc-gpu4 -it --rm --device=/dev/dri --device=/dev/kfd --device=/dev/infiniband --device=/dev/infiniband/rdma_cm --privileged  --network=host --ipc=host --cap-add=SYS_ADMIN --cap-add=SYS_PTRACE   --security-opt seccomp=unconfined  --group-add keep-groups -v $HOME:/workdir --workdir /workdir docker://rocm/sgl-dev:v0.5.2-rocm700-mi30x-20250915-rc bash
```

### 2. Install etcd for cluster metadata storage
```bash
./scripts/install_etcd.sh
```

### 3. Install Mooncake for KV cache transfer between nodes
```bash
./scripts/install_mooncake.sh
```

### 4. Install the NIC RDMA driver (Broadcom Thor2/BCM‑57608)
```bash
./scripts/install_nic_rdma_driver.sh
```

### 5. Build and install the ROCm-aware UCX library
```bash
source ./scripts/build_ucx.sh
```

### 6. Build and install the ROCm-Aware Open MPI library
```bash
source ./scripts/build_ompi.sh
```

### 7. Setup SSH for docker container on multi GPU node
Setup ssh connection for docker container on current node (gpu-8) to remote node (gpu-23)
```bash
./scripts/setup_docker_passwdless_ssh.sh gpu-8
```
Please note: need to manually copy public key to /root/.ssh/authorized_keys on remote GPU node.

### 8. Build and run RCCL test on 2 GPU nodes
```bash
ROCM_ROOT="$(./scripts/resolve_rocm_root.sh)"
HIP_COMPILER="${ROCM_ROOT}/bin/hipcc"
git clone https://github.com/ROCm/rccl-tests
cd rccl-tests
./install.sh --mpi --rocm_home "${ROCM_ROOT}" --rccl_home "${ROCM_ROOT}" --mpi_home /opt/ompi/ --hip_compiler "${HIP_COMPILER}"
cd ..
```
# Single node
```bash
TORCH_NCCL_HIGH_PRIORITY=1  RCCL_MSCCL_ENABLE=0 NCCL_DEBUG=version /opt/ompi/bin/mpirun --allow-run-as-root -np 8 /workdir/rccl-tests/build/all_reduce_perf -b 1G -e 16G -f 2 -g 1 -n 10
```

# Multi node
```bash
TORCH_NCCL_HIGH_PRIORITY=1  RCCL_MSCCL_ENABLE=0  /opt/ompi/bin/mpirun  --allow-run-as-root -H gpu-23:8,gpu-8:8 --mca pml ucx --mca btl ^openib -x LD_LIBRARY_PATH -x UCX_IB_GID_INDEX=3 -x NCCL_IB_GID_INDEX=3 -x NCCL_NET_GDR_LEVEL=3 -x NCCL_IB_HCA=bnxt_re0,bnxt_re1,bnxt_re2,bnxt_re3,bnxt_re4,bnxt_re5,bnxt_re6,bnxt_re7,bnxt_re8 -x UCX_NET_DEVICES=bnxt_re0,bnxt_re1,bnxt_re2,bnxt_re3,bnxt_re4,bnxt_re5,bnxt_re6,bnxt_re7,bnxt_re8 -x NCCL_ALGO=Ring -x NCCL_SOCKET_IFNAME=enp49s0f1np1 /workdir/rccl-tests/build/all_reduce_perf -b 1G -e 16G -f 2 -g 1 -n 10
```

### 9. Run Mooncake Transfer Engine Bench with RDMA
Build Mooncake
```bash 
git clone https://github.com/kvcache-ai/Mooncake.git
cd Mooncake.git && git submodule update --init --recursive
mkdir build && cd build 
GO111MODULE=on cmake -DWITH_STORE=OFF -DUSE_ETCD=ON ..  && make -j8
```

Start etcd server
```bash
MC_GID_INDEX=3 etcd --listen-client-urls http://10.2.96.23:2379 --advertise-client-urls http://10.2.96.23:2379 & 
```

Launch server
```bash
MC_GID_INDEX=3 ./mooncake-transfer-engine/example/transfer_engine_bench --mode=target --metadata_server=10.2.96.23:2379 --local_server_name=10.2.96.23:22222 --protocol=rdma --device_name=bnxt_re0 & 
```

Launch client
```bash 
MC_TE_METRIC=1 MC_GID_INDEX=3 ./mooncake-transfer-engine/example/transfer_engine_bench --metadata_server=10.2.96.23:2379 --local_server_name=10.2.96.23:33333 --segment_id=10.2.96.23:22222 --protocol=rdma --device_name=bnxt_re0 --block_size=16384 --duration 60
```
