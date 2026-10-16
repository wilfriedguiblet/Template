#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nextflow-template-smoke.XXXXXX")"
trap 'rm -rf "${OUTPUT_DIR}"' EXIT

cd "${ROOT_DIR}"
nextflow lint main.nf
nextflow run main.nf -params-file params.yaml \
    --outdir "${OUTPUT_DIR}" -profile test -stub

test -s "${OUTPUT_DIR}/example/stage_three/example_final.csv"
test -s "${OUTPUT_DIR}/example/stage_three/example_stage_three_checksums.csv"