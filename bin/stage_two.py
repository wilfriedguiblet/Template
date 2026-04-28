#!/usr/bin/env python3
"""
stage_two.py — Stage 2 analysis script.

Replace this with your actual analysis code.
"""

import argparse
import os

import pandas as pd


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--input", required=True,
                   help="Output from stage 1")
    p.add_argument("--sampleinfo", required=True,
                   help="Sample metadata CSV")
    p.add_argument("--outdir", default=".")
    p.add_argument("--prefix", default="study")
    return p.parse_args()


def main():
    args = parse_args()
    os.makedirs(args.outdir, exist_ok=True)

    print("[1] Loading stage 1 output …")
    data = pd.read_csv(args.input)
    info = pd.read_csv(args.sampleinfo, index_col=0)

    print("[2] Running analysis …")
    # TODO: Replace with your analysis
    results = data.copy()

    out_path = os.path.join(args.outdir, f"{args.prefix}_results.csv")
    results.to_csv(out_path, index=False)
    print(f"    → {out_path}")
    print("    Done.")


if __name__ == "__main__":
    main()
