#!/bin/bash

# Configuration
#MC_GID_INDEX=3 etcd --listen-client-urls http://10.2.96.23:2379 --advertise-client-urls http://10.2.96.23:2379

#MC_GID_INDEX=3 ./mooncake-transfer-engine/example/transfer_engine_bench --mode=target --metadata_server=10.2.96.23:2379 --local_server_name=10.2.96.23:22222 --protocol=rdma --device_name=bnxt_re0

#MC_TE_METRIC=1 MC_GID_INDEX=3 ./mooncake-transfer-engine/example/transfer_engine_bench --metadata_server=10.2.96.23:2379 --local_server_name=10.2.96.23:33333 --segment_id=10.2.96.23:22222 --protocol=rdma --device_name=bnxt_re0 --block_size=20480 --duration 60

MC_TE_METRIC=1 
MC_GID_INDEX=3
METADATA_SERVER="10.2.96.23:2379"
SEGMENT_ID="10.2.96.23:22222"
LOCAL_SERVER_NAME="10.2.96.23:33333"
PROTO="rdma"
OUTDIR="/workdir/mooncake_te_rdma"
DEVICE_NAME="bnxt_re0"
#DEVICE_NAME="bnxt_re1,bnxt_re3,bnxt_re2,bnxt_re0,bnxt_re5,bnxt_re0,bnxt_re7,bnxt_re4"

# Make sure output dir exists
mkdir -p "$OUTDIR"

# Start & end sizes (bytes)
START_SIZE=1024          # 1 KB
END_SIZE=524288          # 1 MB
DURATION=60

# Current size
size=$START_SIZE

# Loop: double size each run
while [ $size -le $END_SIZE ]; do
    echo "===================================================="
    echo " Running benchmark with block_size = $size bytes "
    echo "===================================================="

    # Run with metrics enabled, save log
    MC_TE_METRIC=1 MC_GID_INDEX=3 /workdir/Mooncake/build/mooncake-transfer-engine/example/transfer_engine_bench \
        --metadata_server="$METADATA_SERVER" \
        --segment_id="$SEGMENT_ID" \
        --local_server_name="$LOCAL_SERVER_NAME" \
        --protocol="$PROTO" \
        --device_name="$DEVICE_NAME" \
        --block_size="$size" \
        --duration="$DURATION" \
        2>&1 | tee "$OUTDIR/block_size_${size}.log"

    # Double the block size
    size=$(( size * 2 ))
done

echo "All tests completed. Logs are in: $OUTDIR"
