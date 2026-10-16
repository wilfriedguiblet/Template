# Nextflow Pipeline Template

A lightweight Nextflow DSL2 starting point for cohort-based analyses. A samplesheet defines the cohorts and their inputs; a local subworkflow runs three dependent stages for each cohort. Run it directly with Nextflow.

## Repository Layout

```text
assets/                 Example samplesheet and input files
bin/                    Analysis and checksum scripts
conf/                   Resource, profile, and runtime configuration
docs/                   User guide
modules/local/          Stage and manifest processes
subworkflows/local/     Stage orchestration
tests/                  Smoke test
main.nf                 Pipeline entry point
nextflow.config         Parameters and configuration includes
params.yaml             Example run parameters
```

## Quick Start

Requirements: Nextflow 26.04 or newer, Java 17 or newer, and Python 3.10 with the packages in `requirements.txt` for a real local run.

Run a syntax check and stub smoke test from the repository root:

```bash
bash tests/smoke.sh
```

For a real run, install the Python requirement and launch the workflow:

```bash
python3 -m pip install -r requirements.txt
nextflow run main.nf -params-file params.yaml
```

To run on SLURM, use the launcher and select a fresh output directory:

```bash
sbatch run.sh params.yaml slurm --outdir results/run_20261016_a
```

Reuse the same parameters and output directory with `-resume` to continue a run. Use a distinct output directory for each independent or concurrent run.

## Inputs and Parameters

The default `params.yaml` points to `assets/samplesheet.csv`. Each row describes one cohort. Required columns are `cohort`, `expression`, and `sampleinfo`; `prefix` is optional and defaults to the cohort name. Prefixes must be unique within the samplesheet. Additional columns are carried through as metadata, and `covariates` or fields ending in `_values` are split on `|`.

Copy `params.yaml` for a dataset or execution site, then set `samplesheet` and `outdir`. The samplesheet paths are relative to the launch directory or may be absolute. The example file paths are relative to the repository root.

## Workflow and Outputs

Each cohort passes through `STAGE_ONE`, `STAGE_TWO`, and `STAGE_THREE`. The root workflow validates inputs and connects the local analysis subworkflow. Analysis scripts are explicit process inputs so changes invalidate the appropriate cached tasks.

```text
{outdir}/
├── {cohort}/
│   ├── stage_one/
│   ├── stage_two/
│   └── stage_three/
└── pipeline_info/
```

Stages publish their results, checksum sidecars, and software-version sidecars within their cohort directories. Nextflow writes the report, timeline, trace, and DAG under `pipeline_info/`. Set `run_manifest: true` to combine task sidecars with checksums for the samplesheet and pipeline source/configuration files.

## Execution Profiles

Without a profile, tasks run locally. Use `-profile slurm` for SLURM, and combine it with `docker` or `singularity` for container execution. The `test` profile uses reduced resource requests for smoke tests. Adjust resources and cluster settings under `conf/` for your environment.

See [docs/getting-started.md](docs/getting-started.md) for more detail on the samplesheet, configuration, and run behavior.

## License

MIT; see [LICENSE](LICENSE).
