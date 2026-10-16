#!/usr/bin/env python3
"""Write checksums and execution metadata for a completed pipeline run."""

import argparse
import base64
import csv
import hashlib
import json
import platform
import sys
from datetime import datetime, timezone
from pathlib import Path


def decode_json(value):
    return json.loads(base64.b64decode(value).decode("utf-8"))


def checksum(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return {"path": str(path.resolve()), "bytes": path.stat().st_size, "sha256": digest.hexdigest()}


def write_checksums(path, files):
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["stage", "cohort", "kind", "path", "bytes", "sha256"],
            extrasaction="ignore",
        )
        writer.writeheader()
        writer.writerows(files)


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--samplesheet", required=True, type=Path)
    parser.add_argument("--checksum-files", nargs="+", required=True, type=Path)
    parser.add_argument("--version-files", nargs="+", required=True, type=Path)
    parser.add_argument("--source-files", nargs="+", required=True, type=Path)
    parser.add_argument("--parameters-base64", required=True)
    parser.add_argument("--outdir", type=Path, default=Path("."))
    return parser.parse_args()


def main():
    args = parse_args()
    args.outdir.mkdir(parents=True, exist_ok=True)
    required_paths = [args.samplesheet, *args.checksum_files, *args.version_files, *args.source_files]
    missing = sorted(str(path) for path in required_paths if not path.is_file())
    if missing:
        raise FileNotFoundError("Provenance inputs are missing: " + ", ".join(missing))

    input_checksums = []
    output_checksums = []
    for path in args.checksum_files:
        with path.open(newline="", encoding="utf-8") as handle:
            for row in csv.DictReader(handle):
                target = input_checksums if row["kind"] == "input" else output_checksums
                target.append(row)
    input_checksums.extend(
        checksum(path) for path in [args.samplesheet, *args.source_files]
    )
    input_checksums.sort(key=lambda row: row["path"])
    output_checksums.sort(key=lambda row: row["path"])
    version_records = {
        path.as_posix(): path.read_text(encoding="utf-8")
        for path in sorted(args.version_files, key=str)
    }
    write_checksums(args.outdir / "input_checksums.csv", input_checksums)
    write_checksums(args.outdir / "output_checksums.csv", output_checksums)

    try:
        import pandas

        pandas_version = pandas.__version__
    except ImportError:
        pandas_version = "not installed in manifest task"

    manifest = {
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "parameters": decode_json(args.parameters_base64),
        "inputs": input_checksums,
        "outputs": output_checksums,
        "task_versions": version_records,
        "software": {
            "python": sys.version.split()[0],
            "pandas": pandas_version,
            "platform": platform.platform(),
        },
    }
    (args.outdir / "run_manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    (args.outdir / "software_versions.txt").write_text(
        "".join(version_records.values())
        + f"Python: {sys.version.split()[0]}\nPandas: {pandas_version}\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
