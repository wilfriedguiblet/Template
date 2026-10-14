# Nextflow Pipeline Template

A reusable three-stage DSL2 template for cohort-based analyses. Inputs are declared in a samplesheet, stage metadata travels with each sample, and optional run manifests checksum the declared inputs and final outputs.

## Contents

- [Workflow](#workflow)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Samplesheet](#samplesheet)
- [Parameters](#parameters)
- [Stages and outputs](#stages-and-outputs)
- [Execution profiles](#execution-profiles)
- [Provenance and resume](#provenance-and-resume)
- [Troubleshooting](#troubleshooting)

## Workflow

```text
samplesheet ──► optional GEO download ──► STAGE_ONE ──► STAGE_TWO ──► STAGE_THREE
                     │                       │              │              │
                     └───────────────────────┴──────────────┴──► manifest + reports
```

Each row is one cohort or independent analysis unit. Its metadata map is passed through each stage, so fields such as `age_col`, `covariates`, `subset_values`, and project-specific labels remain attached to outputs. The example Python scripts are placeholders; replace their analysis logic and declared output contracts for a real project.

## Requirements

- Nextflow 26.04 or newer, with Java 17 or newer.
- Python 3.10 and the packages in `requirements.txt` for local execution.
- Optional: Docker or Apptainer/Singularity for containers; SLURM for cluster execution.
- Optional GEO input: R 4.3 with Bioconductor `GEOquery` and `Biobase`, or the configured GEO container.

Build the pinned Python image for containerized Python stages:

```bash
docker build -t pipeline-template:1.0.0 .
```

The GEO process uses the separately pinned Bioconductor image configured as `geo_container`.

## Quick Start

The repository includes a small synthetic matrix and metadata file. Run from the repository root:

```bash
nextflow lint main.nf
nextflow run main.nf -params-file params.yaml -profile test -stub
# Optional GEO-branch test; uses a fake accession and does not access the network.
nextflow run main.nf -params-file params.yaml --samplesheet samplesheet.geo-stub.csv --outdir /tmp/geo-stub -profile test -stub
```

For a real local run, install the Python requirements and omit `-stub`:

```bash
python3 -m pip install -r requirements.txt
nextflow run main.nf -params-file params.yaml
```

To run on SLURM:

```bash
sbatch run.sh params.yaml slurm
```

The launcher accepts a params path, profile, then any additional Nextflow arguments. For example:

```bash
sbatch run.sh params.yaml slurm --step stage_two -resume
```

When submitting from a SLURM spool directory, `run.sh` resolves the repository from its own path or `SLURM_SUBMIT_DIR`; set `TEMPLATE_DIR` if neither identifies the checkout.

## Samplesheet

The default `samplesheet.csv` is:

```csv
cohort,prefix,expression,sampleinfo,geo_accession,geo_platform,age_col,covariates,subset_column,subset_values
example,example,examples/counts.tsv,examples/metadata.csv,,,,,,
```

Required columns are `cohort` and either both `expression`/`sampleinfo` or `geo_accession`. `prefix` is optional and defaults to `cohort`; it must be unique and contain only letters, digits, dots, underscores, or hyphens. Local file paths are relative to the launch directory or absolute.

| Column | Meaning |
|---|---|
| `cohort` | Required row identifier, also used in validation errors. |
| `prefix` | Optional output-name prefix; defaults to `cohort`. |
| `expression` | Local expression/count matrix, genes by samples. |
| `sampleinfo` | Local CSV metadata with sample IDs in the first column. |
| `geo_accession` | Optional GEO series accession. Used only when both local paths are blank. |
| `geo_platform` | Optional GPL ID for a multi-platform GEO series; required when a series has multiple platforms. |
| `age_col`, `covariates`, `subset_column`, `subset_values` | Optional metadata fields retained in the per-row metadata map. |

`covariates` and fields ending in `_values` are split on `|` into lists. For example, `age|sex` becomes `['age', 'sex']`. Add additional columns freely; they are carried through as metadata.

The GEO adapter downloads the normalized expression matrix and phenotype table available as a GEO Series Matrix. It does not download raw FASTQ files or perform raw-read processing. Choose `geo_platform` when GEO returns more than one platform. Review GEO processing and licensing terms before using downloaded data.

## Parameters

`params.yaml` is the default run configuration. Make a separate params file for each dataset or execution site.

| Parameter | Default | Purpose |
|---|---|---|
| `samplesheet` | `samplesheet.csv` | Cohort/sample input table. |
| `outdir` | `results` | Published analysis results and run reports. |
| `step` | `all` | `all`, one stage, or a comma-separated stage list. |
| `run_manifest` | `true` | Write input/output checksums and run metadata. |
| `load_modules` | `false` | Load `R/4.3` and `python/3.10` in cluster tasks. |
| `container` | `pipeline-template:1.0.0` | Python-stage image used by Docker/Apptainer profiles. |
| `geo_container` | Bioconductor 3.18 image | Image for the optional GEO adapter. |
| `max_memory`, `max_cpus`, `max_time` | `256 GB`, `64`, `72 h` | Hard resource ceilings. |
| `slurm_account`, `slurm_partition` | `null`, `norm` | Optional SLURM account and partition. |

Boolean parameters accept true/false values and are validated before execution. The `step` parameter is also validated before stages are scheduled.

## Stages and Outputs

`--step` selects stages to execute. If an upstream stage is omitted, its published output must already exist. For example, `--step stage_two` reads `results/stage_one/{prefix}_output.csv`; it does not silently rerun stage one. Stage two also requires the sample metadata path from the samplesheet.

```text
results/
├── stage_one/{prefix}_output.csv
├── stage_two/{prefix}_results.csv
├── stage_three/{prefix}_final.csv
├── geo_download/                       # only for GEO rows
└── pipeline_info/
    ├── execution_report.html
    ├── execution_timeline.html
    ├── execution_trace.tsv
    ├── pipeline_dag.dot
    ├── run_manifest.json
    ├── input_checksums.csv
    ├── output_checksums.csv
    └── software_versions.txt
```

Each executed stage also publishes a `*_versions.yml` or `*_versions.txt` file alongside its outputs. The manifest includes task version reports, SHA-256 checksums, the selected parameters, input files, and final result files.

## Execution Profiles

| Profile | Behavior |
|---|---|
| `local` / `standard` | Run on the current machine without containers. |
| `slurm` | Submit tasks to the configured SLURM partition. |
| `docker` | Run Python stages in `container`; GEO uses `geo_container`. |
| `singularity` | Run with Apptainer/Singularity and automatically mounted paths. |
| `test` | Apply small resource requests for smoke tests. |

Profiles can be combined, such as `-profile slurm,docker`. Set `load_modules: true` when cluster tasks need the configured R/Python environment modules. Adapt module names, queue, account, and resource ceilings in `nextflow.config` to the target cluster.

## Provenance and Resume

Each analysis process takes its Python script as an explicit Nextflow `path` input. Editing a script therefore changes the task hash and invalidates the affected cached task on the next `-resume` run. Keep all additional scripts, configuration files, and reference inputs that affect a process as declared inputs for the same reason.

The final manifest checksums the samplesheet, local data files, pipeline scripts/configuration, GEO-derived files when used, and final stage results. Use immutable container tags or digests for reproducible runs; rebuilding a mutable image tag can otherwise change the runtime without changing the params file.

## Troubleshooting

| Symptom | Check |
|---|---|
| Missing file before a stage | Confirm paths in the samplesheet are relative to the launch directory or absolute. |
| Stage two/three cannot find an upstream file | Run the omitted upstream stage first, or correct `outdir` and the cohort prefix. |
| GEO returns multiple platforms | Set `geo_platform` to one of the reported GPL identifiers. |
| Exit 137 or another retryable resource failure | Raise the relevant label request and/or `max_memory`, `max_cpus`, or `max_time`. |
| Task unexpectedly resumes cached output | Ensure scripts and other behavior-changing files are declared as process `path` inputs. |

Inspect `.nextflow.log`, the execution trace, or a task's `.command.log` under `work/`. After correcting a failure, rerun with `-resume`.

## License

This project is licensed under the MIT License; see [LICENSE](LICENSE).