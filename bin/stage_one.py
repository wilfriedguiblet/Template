#!/usr/bin/env python3
"""
stage_one.py — Stage 1 analysis script.

Replace this with your actual analysis code.
"""

import argparse
import os

import pandas as pd


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--expression", required=True,
                   help="Count matrix (genes × samples)")
    p.add_argument("--sampleinfo", required=True,
                   help="Sample metadata CSV")
    p.add_argument("--outdir", default=".")
    p.add_argument("--prefix", default="study")
    return p.parse_args()


def main():
    args = parse_args()
    os.makedirs(args.outdir, exist_ok=True)

    # ── Load data ─────────────────────────────────────────────────────────────
    print("[1] Loading expression matrix …")
    expr = pd.read_csv(args.expression, sep=None, index_col=0, engine="python")
    print(f"    {expr.shape[0]} genes × {expr.shape[1]} samples")

    info = pd.read_csv(args.sampleinfo, index_col=0)
    common = sorted(set(expr.columns) & set(info.index))
    expr = expr[common]
    print(f"    {len(common)} samples after intersecting with sampleinfo")

    # ── Analysis ──────────────────────────────────────────────────────────────
    print("[2] Running analysis …")
    # TODO: Replace with your analysis
    results = pd.DataFrame({"sample": common, "value": range(len(common))})

    # ── Save ──────────────────────────────────────────────────────────────────
    out_path = os.path.join(args.outdir, f"{args.prefix}_output.csv")
    results.to_csv(out_path, index=False)
    print(f"    → {out_path}")
    print("    Done.")


if __name__ == "__main__":
    main()
