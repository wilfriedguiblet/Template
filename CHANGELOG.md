# Changelog

All notable changes to this pipeline will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- Samplesheet-driven cohort inputs with metadata propagation and optional GEO Series Matrix download
- SHA-256 input/output checksums, run manifest, and task software-version reports
- Pinned Python and GEO container defaults, SLURM module loading, resource caps, retries, and test profile
- Strict-parser DSL2 workflow callbacks and updated Nextflow launch script
- Synthetic example data and a runnable stub smoke test

### Changed
- Stage selection now requires published upstream outputs when earlier stages are skipped
- Output publication uses stage-level directories with cohort-specific filenames
- README documents samplesheet fields, GEO limitations, provenance, profiles, and resume behavior
