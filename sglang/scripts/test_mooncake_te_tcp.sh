#!/bin/bash

# Configuration
METADATA_SERVER="etcd://10.2.96.23:2379"
SEGMENT_ID="10.2.96.23:12345"
LOCAL_SERVER_NAME="10.2.96.29:12345"
PROTO="tcp"
OUTDIR="/workdir/mooncake_te_tcp"

# Make sure output dir exists
mkdir -p "$OUTDIR"

# Start & end sizes (bytes)
START_SIZE=1024          # 1 KB
END_SIZE=524288          # 1 MB

# Current size
size=$START_SIZE

# Loop: double size each run
while [ $size -le $END_SIZE ]; do
    echo "===================================================="
    echo " Running benchmark with block_size = $size bytes "
    echo "===================================================="

    # Run with metrics enabled, save log
    MC_TE_METRIC=1 /workdir/Mooncake/build/mooncake-transfer-engine/example/transfer_engine_bench \
        --metadata_server="$METADATA_SERVER" \
        --segment_id="$SEGMENT_ID" \
        --local_server_name="$LOCAL_SERVER_NAME" \
        --protocol="$PROTO" \
        --block_size="$size" \
        2>&1 | tee "$OUTDIR/block_size_${size}.log"

    # Double the block size
    size=$(( size * 2 ))
done

echo "All tests completed. Logs are in: $OUTDIR"
