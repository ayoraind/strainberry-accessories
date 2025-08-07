#!/usr/bin/env python3

"""
Automatically extracts the best-matching query contigs for each reference index (fidx)
and writes one FASTA file per reference:
    metagenome_ref_<fidx>.fasta
"""

import pandas as pd
from Bio import SeqIO
import argparse
import os

def extract_all_best_contigs(table, query, outdir):
    df = pd.read_csv(table, sep='\t')

    if 'fidx' not in df.columns or 'best' not in df.columns or 'Q_NAME' not in df.columns:
        raise ValueError("Input table must contain 'fidx', 'best', and 'Q_NAME' columns.")

    df = df[df['best']]  # Keep only best hits
    unique_fidx = df['fidx'].astype(str).unique()

    print(f"🔍 Found {len(unique_fidx)} reference indices (fidx) with best matches.")

    # Index the FASTA file once
    fasta_index = SeqIO.to_dict(SeqIO.parse(query, 'fasta'))

    os.makedirs(outdir, exist_ok=True)

    for fidx in unique_fidx:
        sdf = df[df['fidx'].astype(str) == fidx]
        ids = set(sdf['Q_NAME'].astype(str))

        output_file = os.path.join(outdir, f"assembly.{fidx}.fasta")

        if not ids:
            open(output_file, 'w').close()
            print(f"⚠️  No contigs found for fidx={fidx}. Empty file created.")
            continue

        matching_records = sorted(
            (fasta_index[qid] for qid in ids if qid in fasta_index),
            key=lambda rec: rec.id
        )

        if len(matching_records) != len(ids):
            missing = ids - set(fasta_index)
            raise Exception(
                f"❌ Error: Missing contigs in FASTA for fidx={fidx}: {missing}"
            )

        with open(output_file, 'w') as f:
            SeqIO.write(matching_records, f, 'fasta')
        print(f"✅ {len(matching_records)} contigs written to {output_file}")

def main():
    parser = argparse.ArgumentParser(
        description="Extract best-matching contigs for each reference (fidx) into separate FASTA files."
    )
    parser.add_argument("table", help="TSV table from filter_best script")
    parser.add_argument("query", help="FASTA file with query contigs")
    parser.add_argument("-o", "--outdir", default="output_contigs",
                        help="Output directory (default: output_contigs)")

    args = parser.parse_args()
    extract_all_best_contigs(args.table, args.query, args.outdir)

if __name__ == "__main__":
    main()
