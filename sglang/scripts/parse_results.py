import json
import pandas as pd
import os
import argparse

def main():
    # -------- ARGPARSE --------
    parser = argparse.ArgumentParser(description="Extract metrics from JSONL files and save to Excel")
    parser.add_argument("--input_dir", required=True, help="Folder containing .jsonl files")
    parser.add_argument("--output_file", required=True, help="Path to save Excel file")
    args = parser.parse_args()

    input_dir = args.input_dir
    output_file = args.output_file

    # -------- PROCESS FILES --------
    records = []

    for filename in os.listdir(input_dir):
        if filename.lower().endswith(".jsonl"):
            file_path = os.path.join(input_dir, filename)
            print(f"Processing {file_path} ...")
            
            with open(file_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue  # skip empty lines
                    try:
                        data = json.loads(line)
                    except json.JSONDecodeError as e:
                        print(f"❌ Error parsing line in {filename}: {e}")
                        continue
                    
                    # Extract metrics
                    record = {
                        "File": filename,
                        "Max concurrency": data.get("max_concurrency"),
                        "Request rate": data.get("request_rate"),
                        "Request throughput (req/s)": data.get("request_throughput"),
                        "Mean TTFT (ms)": data.get("mean_ttft_ms"),
                        "Mean TPOT (ms)": data.get("mean_tpot_ms"),
                        "Mean ITL (ms/token)": data.get("mean_itl_ms"),
                        "Mean E2E latency (s)": data.get("mean_e2el_ms", 0) / 1000.0,
                        "Output token throughput (tok/s)": data.get("output_throughput"),
                        "Total token throughput (tok/s)": (
                            data.get("input_throughput", 0) + data.get("output_throughput", 0)
                        ),
                        "Median TTFT (ms)": data.get("median_ttft_ms"),
                        "Median TPOT (ms)": data.get("median_tpot_ms"),
                        "Median ITL (ms/token)": data.get("median_itl_ms"),
                        "Median E2E latency (s)": data.get("median_e2el_ms", 0) / 1000.0,
                        "P99 TTFT (ms)": data.get("p99_ttft_ms"),
                        "P99 TPOT (ms/token)": data.get("p99_tpot_ms"),
                        "P99 ITL (ms/token)": data.get("p99_itl_ms")
                    }
                    records.append(record)

    # -------- SAVE TO EXCEL --------
    df = pd.DataFrame(records)

    # Sort by 'Max concurrency' ascending
    df.sort_values(by="Max concurrency", ascending=True, inplace=True)

    # Explicit column order
    column_order = [
        "File",
        "Max concurrency",
        "Request rate",
        "Request throughput (req/s)",
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
        "P99 TTFT (ms)",
        "P99 TPOT (ms/token)",
        "P99 ITL (ms/token)"
    ]
    df = df[column_order]

    df.to_excel(output_file, index=False)
    print(f"✅ Saved {len(records)} records from {input_dir} to '{output_file}' sorted by Max concurrency")

if __name__ == "__main__":
    main()
