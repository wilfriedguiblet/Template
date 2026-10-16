# Getting Started

This project keeps a direct Nextflow interface. There is no installable Python package or pipeline CLI.

## Layout

```text
assets/                 Example samplesheet and tiny input files
bin/                    Analysis and checksum scripts
conf/                   Base, module, container, SLURM, and test configuration
docs/                   User documentation
modules/local/          Individual Nextflow processes
subworkflows/local/     Stage orchestration
tests/                  Lightweight smoke test
main.nf                 Nextflow entry point
nextflow.config         Parameters and configuration includes
```

## Run

From the repository root:

```bash
nextflow lint main.nf
nextflow run main.nf -params-file params.yaml -profile test -stub
```

Run the smoke test with `bash tests/smoke.sh`. For a real local run, install the Python requirement and omit `-stub`:

```bash
python3 -m pip install -r requirements.txt
nextflow run main.nf -params-file params.yaml --outdir results/run_20261016_a
```

On SLURM, choose a fresh output directory for each independent run:

```bash
sbatch run.sh params.yaml slurm --outdir results/run_20261016_a
```

Reuse the same params and output directory when resuming with `-resume`.

## Inputs

`assets/samplesheet.csv` is a runnable example. Required fields are `cohort`, `expression`, and `sampleinfo`. Input paths are relative to the launch directory or absolute. `prefix` defaults to `cohort` and must be unique within one samplesheet. Other fields are passed through in the metadata map; `covariates` and fields ending in `_values` are split on `|`.

For a new dataset, copy `params.yaml`, point it to a samplesheet, and set a unique `outdir`. Keep stage-specific Python code in `bin/`, process definitions in `modules/local/`, and stage connections in `subworkflows/local/`.

## Profiles and Outputs

No profile runs locally. `-profile slurm` submits tasks to SLURM; combine with `docker` or `singularity` to run in the configured Python image. `-profile test` uses reduced resources for smoke runs.

Each run writes cohort-scoped stage outputs and checksum/version sidecars under `outdir/{cohort}/`. Nextflow reports and traces go under `outdir/pipeline_info/`. The aggregate SHA-256 manifest is optional (`run_manifest: true`); the small per-stage sidecars are always generated.

Use a separate `outdir` for simultaneous runs to avoid published-output and report collisions. Nextflow's `-resume` reuses completed work when the same run configuration is repeated.