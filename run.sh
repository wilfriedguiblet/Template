#!/bin/bash
#SBATCH --job-name    pipeline
#SBATCH --ntasks      1
#SBATCH --cpus-per-task 4
#SBATCH --partition   norm
#SBATCH --time        24:00:00
#SBATCH --mem         16g

# ── Load required modules ─────────────────────────────────────────────────────
module load nextflow python

# ── Run the pipeline ──────────────────────────────────────────────────────────
# Edit the params file and profile to match your setup.
# Add -resume to skip completed tasks after a failure.

nextflow run main.nf -params-file params.yaml -profile slurm

# ── Examples ──────────────────────────────────────────────────────────────────
# Run a single stage:
#   nextflow run main.nf -params-file params.yaml -profile slurm --step stage_two
#
# Resume after failure:
#   nextflow run main.nf -params-file params.yaml -profile slurm -resume
#
# Use a different dataset:
#   nextflow run main.nf -params-file params_dataset2.yaml -profile slurm
