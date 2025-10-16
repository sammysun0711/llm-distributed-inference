# Setup Environment LLM distributed inference on 2 GPU nodes

Scripts and tools to setup SGLang PD disaggregation in docker container, need to setup in both 2 nodes.
Reference: 
- [LLM distributed inference and PD disaggregation on AMD Instinct GPUs](https://rocm.docs.amd.com/projects/ai-developer-hub/en/latest/notebooks/inference/SGlang_PD_Disagg_On_AMD_GPU.html)
- [Unleashing AMD Instinct™ MI300X GPUs for LLM Serving: Disaggregating Prefill & Decode with SGLang](https://rocm.blogs.amd.com/software-tools-optimization/disaggregation/README.html)

1. Launch docker container
```bash
podman run --name rocm-sgl-dev-v0.5.2-rocm700-mi30x-20250915-rc-gpu4 -it --rm --device=/dev/dri --device=/dev/kfd --device=/dev/infiniband --device=/dev/infiniband/rdma_cm --privileged  --network=host --ipc=host --cap-add=SYS_ADMIN --cap-add=SYS_PTRACE   --security-opt seccomp=unconfined  --group-add keep-groups -v $HOME:/workdir --workdir /workdir docker://rocm/sgl-dev:v0.5.2-rocm700-mi30x-20250915-rc bash
```

2. Install etcd for cluster metadata storage
```bash
./scripts/install_etcd.sh
```

3. Install Mooncake for KV cache transfer between nodes
```bash
./scripts/install_nic_rdma_driver.sh
```

4. Install the NIC RDMA driver (Broadcom Thor2/BCM‑57608)
```bash
./scripts/install_nic_rdma_driver.sh
```

5. Build and install the ROCm-aware UCX library
```bash
source ./scripts/build_ucx.sh
```

6. Build and install the ROCm-Aware Open MPI library
```bash
source ./scripts/build_ompi.sh
```

7. Setup SSH for docker container on multi GPU node
Setup ssh connection for docker container on current node (gpu-4) to remote node (gpu-11)
```bash
./scripts/setup_docker_passwdless_ssh.sh gpu-11
```
Please note: need to manually copy public key to /root/.ssh/authorized_keys on remote GPU node.

8. Build and run RCCL test on 2 GPU nodes
```bash
git clone https://github.com/ROCm/rccl-tests
cd rccl-tests
./install.sh --mpi --rocm_home /opt/rocm --rccl_home /opt/rocm --mpi_home /opt/ompi/ --hip_compiler /opt/rocm/bin/amdclang++
cd ..
TORCH_NCCL_HIGH_PRIORITY=1  RCCL_MSCCL_ENABLE=0  mpirun -np 16  --map-by ppr:8:node  --hostfile mpi_hosts  --allow-run-as-root  --mca pml ucx  --mca btl ^openib  -x NCCL_SOCKET_IFNAME=enp49s0f1np1  -x NCCL_DEBUG=VERSION  -x NCCL_IB_HCA=bnxt_re0,bnxt_re1,bnxt_re2,bnxt_re3,bnxt_re4,bnxt_re5,bnxt_re6,bnxt_re7,bnxt_re8  -x NCCL_IB_GID_INDEX=3  /workdir/rccl-tests/build/all_reduce_perf -b 1k -e 2G -f 2 -g 1
```

9. Run Mooncake Transfer Engine Bench
9.1. Build Mooncake Transfer Engine Bench 
```bash 
git clone https://github.com/kvcache-ai/Mooncake.git
cd Mooncake.git && git submodule update --init --recursive
mkdir build && cd build 
GO111MODULE=on cmake -DWITH_STORE=OFF -DUSE_ETCD=ON ..  && make -j8
```

9.2. Start ETCD server
```bash
MC_GID_INDEX=3 etcd --listen-client-urls http://10.2.96.23:2379 --advertise-client-urls http://10.2.96.23:2379 & 
```

9.3. Launch server
```bash
MC_GID_INDEX=3 ./mooncake-transfer-engine/example/transfer_engine_bench --mode=target --metadata_server=10.2.96.23:2379 --local_server_name=10.2.96.23:22222 --protocol=rdma --device_name=bnxt_re0 & 
```

9.4. Launch client
```bash 
MC_TE_METRIC=1 MC_GID_INDEX=3 ./mooncake-transfer-engine/example/transfer_engine_bench --metadata_server=10.2.96.23:2379 --local_server_name=10.2.96.23:33333 --segment_id=10.2.96.23:22222 --protocol=rdma --device_name=bnxt_re0 --block_size=16384 --duration 60
```
