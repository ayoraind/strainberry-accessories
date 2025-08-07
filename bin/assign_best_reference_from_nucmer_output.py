#!/usr/bin/env python3

"""
Assigns each query contig to its best-matching reference based on alignment identity and coverage.

This script expects one or more .coords-like files (tab-separated) and outputs a filtered table
showing the best alignment(s) per query.

Reference: Adapted from strainberry's assembly_stats.py and floria_analysis_workflow's assemblies_stats_analyse_nucmer.py.
"""

import os
import pandas as pd
import argparse

from pybedtools import BedTool

def load_qcoords(fname):
    names = ['R_BEG', 'R_END', 'Q_BEG', 'Q_END', 'R_HITLEN', 'Q_HITLEN', 
             '%IDY', 'R_LEN', 'Q_LEN', 'R_COV', 'Q_COV', 'R_NAME', 'Q_NAME']
    
    df = pd.read_csv(fname, sep='\t', names=names)
    df['fidx'] = os.path.basename(fname).split('.')[0]
    return df

def get_coverage_bedtool(df):
    if len(df) > 1:
        bt = BedTool.from_dataframe(df[['Q_NAME', 'Q_MIN', 'Q_MAX']].sort_values('Q_MIN'))
        return bt.merge().total_coverage()
    else:
        return (df['Q_MAX'] - df['Q_MIN']).sum()

# def get_coverage_portion(df):
#     if len(df) > 1:
#         intervals = [portion.closed(*row) for row in zip(df['Q_MIN'], df['Q_MAX'])]
#         merge = portion.Interval(*intervals)
#         return sum(i.upper - i.lower for i in merge)
#     else:
#         return (df['Q_MAX'] - df['Q_MIN']).sum()

def extract_sim(df):
    df['Q_MIN'] = df[['Q_BEG', 'Q_END']].min(axis=1) - 1
    df['Q_MAX'] = df[['Q_BEG', 'Q_END']].max(axis=1)
    df['weight'] = df['R_HITLEN'] + df['Q_HITLEN']

    keys = ['Q_NAME', 'fidx']
    func = get_coverage_bedtool    
    cov = df.groupby(keys).apply(func).rename('aligned_bases').reset_index()

    df['widy'] = df['%IDY'] * df['weight']
    avgIdy = (df.groupby(keys)['widy'].sum() / df.groupby(keys)['weight'].sum()).rename('avg_idy').reset_index()

    qlen = df.groupby('Q_NAME')['Q_LEN'].nunique()
    assert qlen[qlen != 1].empty, "Q_LEN is not consistent for some queries"
    qlen = df.drop_duplicates('Q_NAME').set_index('Q_NAME')['Q_LEN'].to_dict()

    sdf = avgIdy.merge(cov, how='outer')
    sdf['size_query'] = sdf['Q_NAME'].map(qlen)
    sdf['prc_query'] = (100 * sdf['aligned_bases']) / sdf['size_query']

    return sdf

def filter_best(df):
    sdf = extract_sim(df)
    sdf = sdf[sdf['prc_query'] > 50]  # Minimum 50% coverage
    sdf['score'] = sdf['avg_idy'] * sdf['aligned_bases']
    sdf['best'] = sdf.groupby('Q_NAME')['score'].transform(max) == sdf['score']
    return sdf

def main(input_files, output_file):
    all_data = pd.concat([load_qcoords(fname) for fname in sorted(input_files)])
    best_df = filter_best(all_data)
    best_df.to_csv(output_file, sep='\t', index=False)
    print(f"✅ Results saved to: {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Assign best references to query contigs based on alignment stats.")
    parser.add_argument("input", nargs='+', help="Input .coords-like tab-separated file(s)")
    parser.add_argument("-o", "--output", required=True, help="Output .tsv file")
    args = parser.parse_args()

    main(args.input, args.output)
