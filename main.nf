#!/usr/bin/env nextflow

/*
 * Pipeline Name
 * Three-stage samplesheet-driven analysis template.
 */

include { ANALYSIS } from './subworkflows/local/analysis/main'
include { BUILD_RUN_MANIFEST } from './modules/local/run_manifest/main'

// Normalize booleans because CLI and YAML parameter values may arrive as strings.
def boolParam(value, label) {
    if (value instanceof Boolean) return value
    def normalized = value?.toString()?.trim()?.toLowerCase()
    if (!(normalized in ['true', 'false'])) {
        error "Parameter '${label}' must be true or false; received '${value}'"
    }
    normalized == 'true'
}

def requiredFile(value, label) {
    if (!value) error "Required parameter or samplesheet field '${label}' is empty"
    def candidate = file(value)
    if (!candidate.exists()) error "${label} file not found: ${value}"
    candidate
}

workflow {
    main:
    if (!params.samplesheet) error "Required parameter '--samplesheet' is missing"
    def samplesheet = requiredFile(params.samplesheet, 'samplesheet')
    def writeManifest = boolParam(params.run_manifest, 'run_manifest')
    def seenPrefixes = new HashSet()

    // Keep project-specific columns in the metadata map as rows enter the workflow.
    ch_samples = channel.fromPath(samplesheet)
        .splitCsv(header: true)
        .ifEmpty { error "Samplesheet has a header but no data rows: ${samplesheet}" }
        .map { row ->
            def cohort = row.cohort?.toString()?.trim()
            def prefix = row.prefix?.toString()?.trim() ?: cohort
            def expressionPath = row.expression?.toString()?.trim()
            def sampleinfoPath = row.sampleinfo?.toString()?.trim()
            if (!cohort) error 'Samplesheet row is missing required field cohort'
            if (!prefix || !(prefix ==~ /[A-Za-z0-9][A-Za-z0-9._-]*/)) {
                error "Invalid output prefix '${prefix}' for cohort '${cohort}'"
            }
            if (!seenPrefixes.add(prefix)) error "Samplesheet output prefix must be unique: '${prefix}'"
            def metadata = row.findAll { key, _value -> !(key in ['expression', 'sampleinfo']) }
            metadata.prefix = prefix
            // Normalize list-like metadata once so every stage receives the same representation.
            ['covariates'].plus(metadata.keySet().findAll { key -> key.toString().endsWith('_values') })
                .unique().each { field ->
                    def value = metadata[field]?.toString()?.trim()
                    if (value) metadata[field] = value.split(/\|/).collect { item -> item.trim() }
                }
            tuple(metadata,
                requiredFile(expressionPath, "${cohort}.expression"),
                requiredFile(sampleinfoPath, "${cohort}.sampleinfo"))
        }

    log.info """
    ╔══════════════════════════════════════════════════════════════╗
    ║  Pipeline Name — RUN START                                   ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  Samplesheet : ${samplesheet}
    ║  Output      : ${params.outdir}
    ║  Profile     : ${workflow.profile ?: 'local'}
    ║  Stage 1     : STAGE_ONE (per cohort)
    ║  Stage 2     : STAGE_TWO (per cohort; after stage one)
    ║  Stage 3     : STAGE_THREE (per cohort; after stage two)
    ║  Provenance  : ${writeManifest ? 'enabled' : 'disabled'}
    ╚══════════════════════════════════════════════════════════════╝
    """.stripIndent()

    // Explicit script inputs make code edits invalidate the affected cached tasks.
    ch_scripts = [
        file("${projectDir}/bin/stage_one.py"),
        file("${projectDir}/bin/stage_two.py"),
        file("${projectDir}/bin/stage_three.py"),
        file("${projectDir}/bin/checksum_files.py")
    ].collect { script -> channel.value(script) }
    workflow_result = ANALYSIS(
        ch_samples,
        ch_scripts[0],
        ch_scripts[1],
        ch_scripts[2],
        ch_scripts[3]
    )

    // Stage sidecars stay local to each task unless aggregate provenance is requested.
    if (writeManifest) {
        def sourceFiles = [
            'main.nf', 'nextflow.config', 'params.yaml',
            'conf/base.config', 'conf/modules.config', 'conf/slurm.config',
            'conf/containers.config', 'conf/test.config',
            'subworkflows/local/analysis/main.nf',
            'modules/local/stage_one/main.nf', 'modules/local/stage_two/main.nf',
            'modules/local/stage_three/main.nf', 'modules/local/run_manifest/main.nf',
            'bin/stage_one.py', 'bin/stage_two.py',
            'bin/stage_three.py', 'bin/checksum_files.py',
            'Dockerfile', 'requirements.txt'
        ].collect { relativePath -> file("${projectDir}/${relativePath}") }
        def parameters = groovy.json.JsonOutput.toJson([
            outdir: params.outdir,
            nextflow_version: workflow.nextflow.version.toString(),
            container: params.container,
            max_memory: params.max_memory,
            max_cpus: params.max_cpus,
            max_time: params.max_time
        ])
        BUILD_RUN_MANIFEST(
            channel.value(samplesheet),
            workflow_result.checksums.collect(),
            workflow_result.versions.collect(),
            channel.value(sourceFiles),
            file("${projectDir}/bin/build_run_manifest.py"),
            channel.value(java.util.Base64.encoder.encodeToString(parameters.getBytes('UTF-8')))
        )
    }

    onComplete:
        def status = workflow.success ? 'SUCCESS' : 'FAILED'
        log.info """
        ╔══════════════════════════════════════════════════════════════╗
        ║  Pipeline Name — ${status}
        ╠══════════════════════════════════════════════════════════════╣
        ║  Duration : ${workflow.duration}
        ║  Output   : ${params.outdir}
        ║  Exit     : ${workflow.exitStatus}
        ╚══════════════════════════════════════════════════════════════╝
        """.stripIndent()

    onError:
        log.error "Pipeline failed: ${workflow.errorReport}"
}