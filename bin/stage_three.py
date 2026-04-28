#!/usr/bin/env python3
"""
stage_three.py — Stage 3 analysis script.

Replace this with your actual analysis code.
"""

import argparse
import os

import pandas as pd


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--input", required=True,
                   help="Output from stage 2")
    p.add_argument("--sampleinfo", required=True,
                   help="Sample metadata CSV")
    p.add_argument("--outdir", default=".")
    p.add_argument("--prefix", default="study")
    return p.parse_args()


def main():
    args = parse_args()
    os.makedirs(args.outdir, exist_ok=True)

    print("[1] Loading stage 2 output …")
    data = pd.read_csv(args.input)
    info = pd.read_csv(args.sampleinfo, index_col=0)

    print("[2] Running final analysis …")
    # TODO: Replace with your analysis
    results = data.copy()

    out_path = os.path.join(args.outdir, f"{args.prefix}_final.csv")
    results.to_csv(out_path, index=False)
    print(f"    → {out_path}")
    print("    Done.")


if __name__ == "__main__":
    main()
