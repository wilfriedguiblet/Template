# Nextflow Pipeline Template

A lightweight, direct-Nextflow template for cohort-based analysis. It follows the CCBR directory conventions for configuration, local modules, subworkflows, assets, tests, and documentation without the Python CLI/package layer.

## Quick Start

```bash
bash tests/smoke.sh
```

Run a real analysis with `nextflow run main.nf -params-file params.yaml`. Choose a unique `outdir` for each independent or concurrent run; reuse it with `-resume` to continue the same run.

See [docs/getting-started.md](docs/getting-started.md) for the directory map, samplesheet format, profiles, outputs, and testing details.

## License

MIT; see [LICENSE](LICENSE).