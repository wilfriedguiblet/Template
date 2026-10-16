# Changelog

All notable changes to this pipeline will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- Samplesheet-driven cohort inputs with metadata propagation
- Per-stage SHA-256 checksum/version sidecars and an optional aggregate run manifest
- Pinned Python container, SLURM module loading, resource caps, retries, and test profile
- Strict-parser DSL2 workflow callbacks and updated Nextflow launch script
- Synthetic example data and a runnable stub smoke test
- CCBR-style `conf/`, `assets/`, `modules/local/`, `subworkflows/local/`, `tests/`, and `docs/` layout without CLI packaging

### Changed
- The core workflow is a straight-through DAG; Nextflow `-resume` replaces manual stage selection
- Outputs are cohort-scoped, and independent runs use distinct output directories
- GEO/download adapters are intentionally outside the core workflow
- README documents samplesheet fields, provenance, profiles, resume behavior, and run isolation
