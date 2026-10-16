#!/usr/bin/env bash
#SBATCH --job-name=pipeline
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --partition=norm
#SBATCH --time=24:00:00
#SBATCH --mem=16g

set -euo pipefail

resolve_pipeline_dir() {
    local candidate
    for candidate in \
        "${TEMPLATE_DIR:-}" \
        "$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" \
        "${SLURM_SUBMIT_DIR:-}" \
        "$(pwd)"
    do
        if [[ -n "${candidate}" && -f "${candidate}/main.nf" ]]; then
            printf '%s\n' "${candidate}"
            return 0
        fi
    done
    echo "ERROR: cannot locate main.nf; submit from the project directory or set TEMPLATE_DIR" >&2
    return 1
}

SCRIPT_DIR="$(resolve_pipeline_dir)"
PARAMS_INPUT="${1:-${SCRIPT_DIR}/params.yaml}"
PROFILE="${2:-slurm}"
if [[ $# -gt 0 ]]; then shift; fi
if [[ $# -gt 0 ]]; then shift; fi

PARAMS="$(cd "$(dirname "${PARAMS_INPUT}")" && pwd)/$(basename "${PARAMS_INPUT}")"
[[ -f "${PARAMS}" ]] || { echo "ERROR: params file not found: ${PARAMS}" >&2; exit 1; }

if command -v module >/dev/null 2>&1; then
    module load nextflow/26.04
fi
command -v nextflow >/dev/null || { echo "ERROR: nextflow is not available" >&2; exit 1; }
nextflow lint "${SCRIPT_DIR}/main.nf"
cd "${SCRIPT_DIR}"
nextflow run main.nf -params-file "${PARAMS}" -profile "${PROFILE}" "$@" -resume