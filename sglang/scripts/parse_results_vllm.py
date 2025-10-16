#!/usr/bin/env python3
import json
import os
import argparse
import pandas as pd

def main():
    parser = argparse.ArgumentParser(description="Extract benchmark metrics from JSON files in a directory")
    parser.add_argument("--input_dir", required=True, help="Directory with JSON files")
    parser.add_argument("--output_file", required=True, help="Path to save Excel or CSV file")
    args = parser.parse_args()

    records = []

    for filename in os.listdir(args.input_dir):
        if filename.lower().endswith(".json"):
            file_path = os.path.join(args.input_dir, filename)
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
            except Exception as e:
                print(f"❌ Skipping {filename}: {e}")
                continue

            record = {
                "File": filename,
                "Max concurrency": data.get("max_concurrency"),
                "Request rate": data.get("request_rate"),
                "Concurrency": data.get("concurrency"),
                "Request throughput (req/s)": data.get("request_throughput"),
                "Mean TTFT (ms)": data.get("mean_ttft_ms"),
                "Mean TPOT (ms)": data.get("mean_tpot_ms"),
                "Mean ITL (ms/token)": data.get("mean_itl_ms"),
                "Mean E2E latency (s)": (data.get("mean_e2e_latency_ms") or 0) / 1000.0 if "mean_e2e_latency_ms" in data else None,
                "Output token throughput (tok/s)": data.get("output_throughput"),
                "Total token throughput (tok/s)": data.get("total_token_throughput"),
                "Median TTFT (ms)": data.get("median_ttft_ms"),
                "Median TPOT (ms)": data.get("median_tpot_ms"),
                "Median ITL (ms/token)": data.get("median_itl_ms"),
                "Median E2E latency (s)": (data.get("median_e2e_latency_ms") or 0) / 1000.0 if "median_e2e_latency_ms" in data else None,
                "P95 TTFT (ms)": data.get("p95_ttft_ms"),
                "P95 TPOT (ms/token)": data.get("p95_tpot_ms"),
                "P95 ITL (ms/token)": data.get("p95_itl_ms"),
                "P99 TTFT (ms)": data.get("p99_ttft_ms"),
                "P99 TPOT (ms/token)": data.get("p99_tpot_ms"),
                "P99 ITL (ms/token)": data.get("p99_itl_ms"),
                # Goodput from JSON
                "Request goodput (req/s)": data.get("request_goodput")
            }
            records.append(record)

    df = pd.DataFrame(records)

    column_order = [
        "File",
        "Max concurrency",
        "Request rate",
        "Concurrency",
        "Request throughput (req/s)",
        "Request goodput (req/s)",
        "Mean TTFT (ms)",
        "Mean TPOT (ms)",
        "Mean ITL (ms/token)",
        "Mean E2E latency (s)",
        "Output token throughput (tok/s)",
        "Total token throughput (tok/s)",
        "Median TTFT (ms)",
        "Median TPOT (ms)",
        "Median ITL (ms/token)",
        "Median E2E latency (s)",
        "P95 TTFT (ms)",
        "P95 TPOT (ms/token)",
        "P95 ITL (ms/token)",
        "P99 TTFT (ms)",
        "P99 TPOT (ms/token)",
        "P99 ITL (ms/token)"
    ]
    for col in column_order:
        if col not in df.columns:
            df[col] = None

    df = df[column_order]

    if args.output_file.lower().endswith(".xlsx"):
        df.to_excel(args.output_file, index=False)
    else:
        df.to_csv(args.output_file, index=False)

    print(f"✅ Extracted {len(records)} records from {args.input_dir} -> {args.output_file}")

if __name__ == "__main__":
    main()
