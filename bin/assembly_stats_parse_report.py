#!/usr/bin/env python3

import os
import argparse
import pandas as pd
import numpy as np
from Bio import SeqIO

def parse_dnadiff_report(fname):
    res = {}
    with open(fname) as f:
        for line in f:
            line = line.strip().split()
            if line and line[0] not in res:
                res[line[0]] = line
    return res

def dnadiff_dup_bases(fname):
    count = 0
    with open(fname) as f:
        for line in f:
            line = line.strip().split('\t')
            if line[1] == 'DUP':
                count += int(line[4])
    return count

def fasta_n50(fname, gsize=0):
    fdata = SeqIO.parse(fname, 'fasta')
    lengths = sorted((len(record.seq) for record in fdata), reverse=True)
    total_len = sum(lengths)
    mid = gsize or total_len
    mid /= 2

    cumsum = 0
    for length in lengths:
        cumsum += length
        if cumsum > mid:
            return length
    return None

def fill_empty(ref_id, refpath):
    result = {
        'refid': ref_id,
        'refpath': refpath,
        'refbname': os.path.splitext(os.path.basename(refpath))[0],
        'seq_num': 0,
        'ref_size': np.nan,
        'asm_size': np.nan,
        'n50': np.nan,
        'unaligned_ref_bases': np.nan,
        'unaligned_ref': 100.0,
        'unaligned_asm_bases': np.nan,
        'unaligned_asm': 100.0,
        'ani': 0.0,
        'aligned_ref_bases': 0,
        'aligned_asm_bases': 0,
        'dup_ratio': np.nan,
        'dup_bases': np.nan,
        'cmp_bases': np.nan,
        'snps': np.nan,
        'inversions': np.nan,
        'relocations': np.nan,
        'transloc': np.nan,
    }
    return result

def parse_mummer_outputs(report_path, reflist):
    ref_id = os.path.basename(report_path).split('.')[1]
    refpath = reflist[ref_id]
    asm_id = os.path.basename(report_path).split('.')[0]

    if not refpath:
        print(f"DEBUG: Couldn't find ref_id '{ref_id} in reference list")
        print(f"Available ref_ids: {list(reflist.keys)}")
        raise ValueError(f"No reference path found for ID: {ref_id}")

    result = {
        'asm_name': asm_id,
        'refid': ref_id,
        'refpath': refpath,
    }

    if os.stat(report_path).st_size == 0:
        return fill_empty(ref_id, refpath)

    prefix = report_path[:-7]  # remove ".report"
    report = parse_dnadiff_report(prefix + '.report')

    result['seq_num'] = int(report['TotalSeqs'][2])
    result['ref_size'] = int(report['TotalBases'][1])
    result['asm_size'] = int(report['TotalBases'][2])
    result['n50'] = fasta_n50(prefix + '.fasta', result['ref_size'])

    result['unaligned_ref_bases'] = int(report['UnalignedBases'][1].split('(')[0])
    result['unaligned_ref'] = 100.0 * result['unaligned_ref_bases'] / result['ref_size']
    result['unaligned_asm_bases'] = int(report['UnalignedBases'][2].split('(')[0])
    result['unaligned_asm'] = 100.0 * result['unaligned_asm_bases'] / result['asm_size']

    result['ani'] = float(report['AvgIdentity'][1])
    result['aligned_ref_bases'] = int(report['AlignedBases'][1].split('(')[0])
    result['aligned_asm_bases'] = int(report['AlignedBases'][2].split('(')[0])
    result['dup_ratio'] = result['aligned_asm_bases'] / result['aligned_ref_bases']

    result['dup_bases'] = dnadiff_dup_bases(prefix + '.qdiff')
    result['cmp_bases'] = dnadiff_dup_bases(prefix + '.rdiff')

    result['snps'] = int(report['TotalSNPs'][1])
    result['inversions'] = int(report['Inversions'][2])
    result['relocations'] = int(report['Relocations'][2])
    result['transloc'] = int(report['Translocations'][2])

    return result

def load_reflist(file_path):
    reflist = {}
    with open(file_path) as f:
        for line in f:
            if not line.strip():
                continue
            parts = line.strip().split(',')
            if len(parts) != 2:
                raise ValueError(f"Invalid line in reflist: {line}")
            ref_id, ref_path = parts
            reflist[ref_id] = ref_path
    return reflist

def main(report_paths, reflist_path, outfile):
    reflist = load_reflist(reflist_path)

    results = []
    for report in report_paths:
        try:
            res = parse_mummer_outputs(report, reflist)
            results.append(res)
        except Exception as e:
            print(f"❌ Error processing {report}: {e}")

    df = pd.DataFrame(results)
    df.to_csv(outfile, sep='\t', index=False)
    print(f"✅ Summary written to {outfile}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Summarize MUMmer dnadiff results.")
    parser.add_argument("--reports", nargs="+", help="List of .report files")
    parser.add_argument("-r", "--reflist", required=True,
                        help="CSV file with reference ID,path (e.g. 12345,/path/to/12345.fasta)")
    parser.add_argument("-o", "--outfile", required=True, help="Output TSV file")

    args = parser.parse_args()
    main(args.reports, args.reflist, args.outfile)
