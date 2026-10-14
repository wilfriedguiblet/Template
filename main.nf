#!/usr/bin/env nextflow

/*
 * Pipeline Name
 * Three-stage analysis template driven by a per-dataset samplesheet.
 *
 * Run with: nextflow run main.nf -params-file params.yaml
 */

include { STAGE_ONE } from './modules/stage_one'
include { STAGE_TWO } from './modules/stage_two'
include { STAGE_THREE } from './modules/stage_three'
include { DOWNLOAD_GEO } from './modules/download_geo'
include { BUILD_RUN_MANIFEST } from './modules/run_manifest'

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
    def stepRaw = (params.step ?: 'all').toString().toLowerCase().trim()
    def steps = stepRaw.tokenize(',').collect { step -> step.trim() }
    def validSteps = ['all', 'stage_one', 'stage_two', 'stage_three']
    if (!steps || steps.any { step -> !(step in validSteps) }) {
        error "Invalid --step '${stepRaw}'. Use ${validSteps.join(', ')} or a comma-separated list."
    }
    def runAll = 'all' in steps
    def runOne = runAll || 'stage_one' in steps
    def runTwo = runAll || 'stage_two' in steps
    def runThree = runAll || 'stage_three' in steps
    def writeManifest = boolParam(params.run_manifest, 'run_manifest')

    if (!params.samplesheet) error "Required parameter '--samplesheet' is missing"
    def samplesheet = requiredFile(params.samplesheet, 'samplesheet')
    def seenPrefixes = new HashSet()

    ch_samples = channel.fromPath(samplesheet)
        .splitCsv(header: true)
        .ifEmpty { error "Samplesheet has a header but no data rows: ${samplesheet}" }
        .map { row ->
            def cohort = row.cohort?.toString()?.trim()
            def prefix = row.prefix?.toString()?.trim() ?: cohort
            def sampleinfoPath = row.sampleinfo?.toString()?.trim()
            def expressionPath = row.expression?.toString()?.trim()
            def accession = row.geo_accession?.toString()?.trim()
            def platform = row.geo_platform?.toString()?.trim() ?: ''
            if (!cohort) error 'Samplesheet row is missing required field cohort'
            if (!prefix || !(prefix ==~ /[A-Za-z0-9][A-Za-z0-9._-]*/)) {
                error "Invalid output prefix '${prefix}' for cohort '${cohort}'"
            }
            if (!seenPrefixes.add(prefix)) error "Samplesheet output prefix must be unique: '${prefix}'"
            def hasExpression = expressionPath && expressionPath.trim()
            def hasSampleinfo = sampleinfoPath && sampleinfoPath.trim()
            if (hasExpression != hasSampleinfo) {
                error "Samplesheet cohort '${cohort}' must provide both expression and sampleinfo, or neither"
            }
            if (!hasExpression && !accession) {
                error "Samplesheet cohort '${cohort}' needs local files or geo_accession"
            }
            if (!runOne && !hasExpression) {
                error "Cohort '${cohort}' needs local expression and sampleinfo when stage_one is skipped"
            }
            if (hasExpression) {
                requiredFile(expressionPath, "${cohort}.expression")
                requiredFile(sampleinfoPath, "${cohort}.sampleinfo")
            }
            def meta = row.findAll { key, _value -> !(key in ['expression', 'sampleinfo']) }
            meta.prefix = prefix
            ['covariates'].plus(meta.keySet().findAll { key -> key.toString().endsWith('_values') })
                .unique().each { field ->
                    def value = meta[field]?.toString()?.trim()
                    if (value) meta[field] = value.split(/\|/).collect { item -> item.trim() }
                }
            tuple(meta, expressionPath, sampleinfoPath, accession, platform)
        }

    log.info "Selected stages: ${steps.join(', ')}; samplesheet: ${samplesheet}"

    ch_stage_one_out = channel.empty()
    ch_version_files = channel.empty()
    if (runOne) {
        ch_local_samples = ch_samples
            .filter { _meta, expressionPath, _sampleinfoPath, _accession, _platform -> expressionPath }
            .map { meta, expressionPath, sampleinfoPath, _accession, _platform ->
                tuple(meta, file(expressionPath), file(sampleinfoPath))
            }
        ch_geo_inputs = ch_samples
            .filter { _meta, expressionPath, _sampleinfoPath, accession, _platform -> !expressionPath && accession }
            .map { meta, _expressionPath, _sampleinfoPath, accession, platform ->
                tuple(meta, accession, platform, file("${projectDir}/bin/download_geo.R"))
            }
        DOWNLOAD_GEO(ch_geo_inputs)
        ch_stage_one_inputs = ch_local_samples.mix(DOWNLOAD_GEO.out.dataset).map {
            meta, expression, sampleinfo ->
            tuple(meta, expression, sampleinfo, file("${projectDir}/bin/stage_one.py"))
        }
        STAGE_ONE(ch_stage_one_inputs)
        ch_stage_one_out = STAGE_ONE.out.results
        ch_version_files = STAGE_ONE.out.versions.mix(DOWNLOAD_GEO.out.versions)
    } else if (runTwo || runThree) {
        ch_stage_one_out = ch_samples.map { meta, _expressionPath, sampleinfoPath, _accession, _platform ->
            def sampleinfo = requiredFile(sampleinfoPath, "${meta.prefix}.sampleinfo")
            def previous = requiredFile(
                "${params.outdir}/stage_one/${meta.prefix}_output.csv",
                "${meta.prefix} stage_one output"
            )
            tuple(meta, previous, sampleinfo)
        }
    }

    ch_stage_two_out = channel.empty()
    if (runTwo) {
        ch_stage_two_inputs = ch_stage_one_out.map { meta, stageOneOutput, sampleinfo ->
            tuple(meta, stageOneOutput, sampleinfo, file("${projectDir}/bin/stage_two.py"))
        }
        STAGE_TWO(ch_stage_two_inputs)
        ch_stage_two_out = STAGE_TWO.out.results
        ch_version_files = ch_version_files.mix(STAGE_TWO.out.versions)
    } else if (runThree) {
        ch_stage_two_out = ch_samples.map { meta, _expressionPath, sampleinfoPath, _accession, _platform ->
            def sampleinfo = requiredFile(sampleinfoPath, "${meta.prefix}.sampleinfo")
            def previous = requiredFile(
                "${params.outdir}/stage_two/${meta.prefix}_results.csv",
                "${meta.prefix} stage_two output"
            )
            tuple(meta, previous, sampleinfo)
        }
    }

    ch_final_results = channel.empty()
    if (runThree) {
        ch_stage_three_inputs = ch_stage_two_out.map { meta, stageTwoOutput, sampleinfo ->
            tuple(meta, stageTwoOutput, sampleinfo, file("${projectDir}/bin/stage_three.py"))
        }
        STAGE_THREE(ch_stage_three_inputs)
        ch_final_results = STAGE_THREE.out.results.map { meta, result -> tuple(meta, result) }
        ch_version_files = ch_version_files.mix(STAGE_THREE.out.versions)
    } else if (runTwo) {
        ch_final_results = STAGE_TWO.out.results.map { meta, result, _sampleinfo -> tuple(meta, result) }
    } else {
        ch_final_results = STAGE_ONE.out.results.map { meta, result, _sampleinfo -> tuple(meta, result) }
    }

    if (writeManifest) {
        def sourceFiles = [
            'main.nf', 'nextflow.config', 'params.yaml',
            'modules/stage_one.nf', 'modules/stage_two.nf', 'modules/stage_three.nf',
            'modules/download_geo.nf', 'modules/run_manifest.nf', 'bin/stage_one.py',
            'bin/stage_two.py', 'bin/stage_three.py', 'bin/download_geo.R',
            'bin/build_run_manifest.py', 'Dockerfile', 'requirements.txt'
        ].collect { relativePath -> file("${projectDir}/${relativePath}").toString() }
        ch_input_path_entries = ch_samples.flatMap { _meta, expressionPath, sampleinfoPath, _accession, _platform ->
            def declared = []
            if (expressionPath) declared << file(expressionPath).toString()
            if (sampleinfoPath) declared << file(sampleinfoPath).toString()
            declared
        }
        if (runOne) {
            ch_input_path_entries = ch_input_path_entries.mix(
                DOWNLOAD_GEO.out.dataset.flatMap { _meta, expression, sampleinfo ->
                    [expression.toString(), sampleinfo.toString()]
                }
            )
        }
        ch_input_paths = ch_input_path_entries.collect().map { inputPaths ->
            inputPaths.unique() + sourceFiles + [samplesheet.toString()]
        }
        ch_manifest_parameters = channel.value(
            java.util.Base64.encoder.encodeToString(
                groovy.json.JsonOutput.toJson([
                    step: steps,
                    outdir: params.outdir,
                    run_manifest: writeManifest,
                    nextflow_version: workflow.nextflow.version.toString(),
                    container: params.container,
                    geo_container: params.geo_container,
                    max_memory: params.max_memory,
                    max_cpus: params.max_cpus,
                    max_time: params.max_time
                ]).getBytes('UTF-8')
            )
        )
        BUILD_RUN_MANIFEST(
            channel.value(samplesheet),
            ch_final_results.map { _meta, result -> result }.collect(),
            ch_version_files.collect(),
            file("${projectDir}/bin/build_run_manifest.py"),
            ch_input_paths.map { inputPaths ->
                java.util.Base64.encoder.encodeToString(
                    groovy.json.JsonOutput.toJson(inputPaths.unique()).getBytes('UTF-8')
                )
            },
            ch_manifest_parameters
        )
    }

    onComplete:
        def status = workflow.success ? 'SUCCESS' : 'FAILED'
        log.info "Pipeline ${status}; duration ${workflow.duration}; exit ${workflow.exitStatus}"

    onError:
        log.error "Pipeline failed: ${workflow.errorReport}"
}