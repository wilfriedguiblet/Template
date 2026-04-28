# Pipeline Name

> One-sentence summary of what this pipeline does.

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A523.10-brightgreen.svg)](https://www.nextflow.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Table of contents

- [Overview](#overview)
- [Pipeline diagram](#pipeline-diagram)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Parameters](#parameters)
- [Input file formats](#input-file-formats)
- [Outputs](#outputs)
- [Execution profiles](#execution-profiles)
- [Dataset configuration examples](#dataset-configuration-examples)
- [Troubleshooting](#troubleshooting)
- [Citation](#citation)

---

## Overview

<!-- Describe the biological question and computational approach in 2-3 paragraphs.
     Keep it accessible to wet-lab scientists who may not know Nextflow. -->

This pipeline performs …

### Stages

| # | Stage | Description |
|---|-------|-------------|
| 1 | `STAGE_ONE` | Brief description of what this stage does |
| 2 | `STAGE_TWO` | Brief description |
| 3 | `STAGE_THREE` | Brief description |

---

## Pipeline diagram

```
 Input A ───────┐
 Input B ───────┼──► 1. STAGE_ONE ──► intermediate outputs
 Metadata ──────┘         │
                          ▼
                    2. STAGE_TWO ──► more outputs
                          │
                          ▼
                    3. STAGE_THREE ──► final results
```

---

## Requirements

### Software

| Tool | Version | Purpose |
|------|---------|---------|
| [Nextflow](https://www.nextflow.io/) | ≥ 23.10 | Workflow engine |
| [Python](https://www.python.org/) | ≥ 3.9 | Analysis scripts |
| Java | ≥ 11 | Required by Nextflow |

### Python packages

```
numpy pandas scipy scikit-learn matplotlib seaborn
```

Install with:
```bash
pip install numpy pandas scipy scikit-learn matplotlib seaborn
```

### Optional

- **Singularity** or **Docker** for containerized execution
- **SLURM** for HPC cluster submission

---

## Quick start

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_ORG/YOUR_REPO.git
cd YOUR_REPO
```

### 2. Edit `params.yaml`

Point the input parameters at your data files. See
[Parameters](#parameters) and [Dataset configuration examples](#dataset-configuration-examples).

```yaml
expression:  "/path/to/your/counts.tsv"
sampleinfo:  "/path/to/your/metadata.csv"
prefix:      "my_study"
outdir:      "results"
```

### 3. Run

```bash
# Local execution
nextflow run main.nf -params-file params.yaml

# SLURM cluster
nextflow run main.nf -params-file params.yaml -profile slurm

# Dry-run (no analysis scripts executed)
nextflow run main.nf -params-file params.yaml -stub
```

### 4. Resume after failure

Nextflow caches completed tasks. If a step fails, fix the issue and re-run
with `-resume` — only the failed and downstream tasks will re-execute:

```bash
nextflow run main.nf -params-file params.yaml -resume
```

### 5. Run a single stage

Use `--step` to run only one part of the pipeline. Upstream outputs are read
from disk if available, or auto-enabled if missing:

```bash
# Run only stage 2
nextflow run main.nf -params-file params.yaml --step stage_two

# Run stages 2 and 3 together
nextflow run main.nf -params-file params.yaml --step stage_two,stage_three
```

---

## Parameters

### Required inputs

| Parameter | Description |
|-----------|-------------|
| `expression` | Raw counts matrix — genes × samples (TSV or CSV, auto-detected) |
| `sampleinfo` | Sample metadata CSV with columns: `Sample_ID`, `AGE`, plus grouping columns |
| `prefix` | Study name used as filename prefix for all outputs |

### Optional inputs

| Parameter | Default | Description |
|-----------|---------|-------------|
| `outdir` | `"results"` | Root output directory |
| `step` | `"all"` | Which stage(s) to run. Comma-separated list |

<!-- Add your pipeline-specific parameters here. Group them logically. -->

### Stage 1 parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `param_a` | `10` | Description of param_a |
| `param_b` | `0.5` | Description of param_b |

### Resource limits

| Parameter | Default | Description |
|-----------|---------|-------------|
| `max_memory` | `"256.GB"` | Hard cap on memory per process |
| `max_cpus` | `64` | Hard cap on CPUs per process |
| `max_time` | `"72.h"` | Hard cap on wall time per process |

---

## Input file formats

### Expression matrix

Tab-separated (`.tsv`) or comma-separated (`.csv`). Genes as rows, samples as
columns. The first column is the gene identifier (symbols or Ensembl IDs). The
pipeline auto-detects orientation and delimiter.

```
gene       sample_1   sample_2   sample_3
BRCA1      152        87         203
TP53       1041       998        1105
...
```

### Sample metadata

CSV with `Sample_ID` as the first column. Must include all samples present in
the expression matrix. Additional columns (e.g. `AGE`, `tissue`, `disease`,
`sex`) are used for grouping, visualization, and modeling.

```csv
Sample_ID,AGE,tissue,disease,sex
sample_1,45,Liver,Healthy,male
sample_2,62,Brain,Tumor,female
sample_3,38,Liver,Healthy,female
```

> **Important:** `Sample_ID` values must match the column headers in the
> expression matrix exactly (case-sensitive).

---

## Outputs

```
results/{prefix}/
├── stage_one/
│   ├── {prefix}_output_a.csv
│   └── {prefix}_output_b.csv
├── stage_two/
│   ├── {prefix}_results.csv
│   └── {prefix}_plot.png
├── stage_three/
│   └── {prefix}_final.csv
└── pipeline_info/
    ├── execution_report_*.html       # Interactive resource usage report
    ├── execution_timeline_*.html     # Task timeline
    ├── execution_trace_*.tsv         # Per-task resource stats
    └── pipeline_dag_*.svg            # Pipeline DAG visualization
```

### Key output files

| File | Description |
|------|-------------|
| `*_output_a.csv` | Description |
| `*_results.csv` | Description |
| `*_plot.png` | Description |

---

## Execution profiles

Run with `-profile <name>` to select an execution environment. Profiles can be
combined with commas (e.g. `-profile slurm,singularity`).

| Profile | Description |
|---------|-------------|
| `local` | Run on the current machine (default) |
| `slurm` | Submit jobs to a SLURM cluster |
| `singularity` | Use Singularity containers |
| `docker` | Use Docker containers |
| `test` | Small resource caps for CI / dry-runs |

### SLURM submission

To submit the Nextflow head process itself as a SLURM job, use the provided
`run.sh`:

```bash
sbatch run.sh
```

Edit `run.sh` to change the params file, profile, or SLURM directives.

---

## Dataset configuration examples

### Example 1: Mouse multi-tissue aging

```yaml
expression:        "/path/to/mouse_counts.tsv"
sampleinfo:        "/path/to/mouse_info.csv"
prefix:            "mouse_aging"
outdir:            "results"

# All samples are healthy — no disease column
group_col:         "tissue"
healthy_label:     "all"
color_by:          "tissue"

# Mouse ages in months
age_col:           "AGE"
```

### Example 2: Human cancer vs healthy

```yaml
expression:        "/path/to/human_counts.tsv"
sampleinfo:        "/path/to/human_info.csv"
prefix:            "cancer_study"
outdir:            "results"

group_col:         "disease"
healthy_label:     "Healthy"
color_by:          "disease"

age_col:           "AGE"
train_label:       "Healthy"     # train models on healthy, predict all
```

> **Tip:** Create one `params_*.yaml` per dataset and switch between them:
> ```bash
> nextflow run main.nf -params-file params_mouse.yaml -profile slurm
> nextflow run main.nf -params-file params_human.yaml -profile slurm
> ```

---

## Troubleshooting

### Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Process killed` (exit 137) | Out of memory | Increase `max_memory` or use `process_high` label |
| `File not found` | Wrong path in params.yaml | Check paths; use absolute paths on clusters |
| `No matching samples` | Sample IDs don't match between expression and sampleinfo | Ensure column headers in expression match `Sample_ID` in sampleinfo |

### Checking logs

```bash
# View the Nextflow log
cat .nextflow.log

# View a specific task's output
cat work/<hash>/<hash>/.command.log

# List failed tasks
nextflow log last -f name,status,exit | grep -v COMPLETED
```

### Resuming

Always use `-resume` after fixing an error. Nextflow will skip completed tasks:

```bash
nextflow run main.nf -params-file params.yaml -resume
```

### Clean up work directory

The `work/` directory can grow large. After a successful run:

```bash
nextflow clean -f       # Remove old cached runs
rm -rf work/            # Remove all cached data (cannot resume after this)
```

---

## Citation

If you use this pipeline, please cite:

> Author et al. (2026). Pipeline Name: brief description.
> *Journal Name*. DOI: [10.xxxx/xxxxx](https://doi.org/10.xxxx/xxxxx)

---

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for
details.
