#!/usr/bin/env python3
"""Write checksums for a task's output files and capture runtime versions."""

import argparse
import csv
import hashlib
import platform
import sys
from pathlib import Path


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stage", required=True)
    parser.add_argument("--cohort", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--versions", required=True, type=Path)
    parser.add_argument("--output-prefix", required=True)
    parser.add_argument("--inputs", nargs="*", type=Path, default=[])
    parser.add_argument("--outputs", nargs="+", type=Path, required=True)
    args = parser.parse_args()

    with args.output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["stage", "cohort", "kind", "path", "bytes", "sha256"],
        )
        writer.writeheader()
        for kind, paths in (("input", args.inputs), ("output", args.outputs)):
            for path in sorted(paths, key=str):
                relative_path = (
                    f"{args.cohort}/{kind}/{path.name}"
                    if kind == "input"
                    else f"{args.output_prefix}/{path.name}"
                )
                writer.writerow({
                    "stage": args.stage,
                    "cohort": args.cohort,
                    "kind": kind,
                    "path": relative_path,
                    "bytes": path.stat().st_size,
                    "sha256": sha256(path),
                })

    try:
        import pandas
        pandas_version = pandas.__version__
    except ImportError:
        pandas_version = "not installed"
    args.versions.write_text(
        f"{args.stage}:\n"
        f"  python: {sys.version.split()[0]}\n"
        f"  pandas: {pandas_version}\n"
        f"  platform: {platform.platform()}\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
