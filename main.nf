#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Pipeline Name
  Brief description of what this pipeline does.

  Stages
  ------
  1. STAGE_ONE   – description
  2. STAGE_TWO   – description
  3. STAGE_THREE – description

  Usage
  -----
  nextflow run main.nf -params-file params.yaml [-profile slurm]
  nextflow run main.nf -params-file params.yaml --step stage_two -resume
  nextflow run main.nf -params-file params.yaml -stub   # dry-run
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

// ─────────────────────────────────────────────────────────────────────────────
// Import modules
// ─────────────────────────────────────────────────────────────────────────────

include { STAGE_ONE   } from './modules/stage_one'
include { STAGE_TWO   } from './modules/stage_two'
include { STAGE_THREE } from './modules/stage_three'

// ─────────────────────────────────────────────────────────────────────────────
// Parameter validation
// ─────────────────────────────────────────────────────────────────────────────

def validateParams() {

    // Step validation — supports comma-separated list (e.g. "stage_one,stage_two")
    def step_raw = (params.step ?: 'all').toString().toLowerCase().trim()
    def steps    = step_raw.tokenize(',').collect { it.trim() }
    def valid_steps = ['all', 'stage_one', 'stage_two', 'stage_three']
    steps.each { s ->
        if (!(s in valid_steps)) {
            error "Invalid --step '${s}'. Valid values: ${valid_steps.join(', ')}"
        }
    }

    // Required inputs
    if (!params.sampleinfo || !file(params.sampleinfo).exists()) {
        error "Required parameter '--sampleinfo' is missing or file not found: ${params.sampleinfo}"
    }
    if (!params.expression || !file(params.expression).exists()) {
        error "Required parameter '--expression' is missing or file not found: ${params.expression}"
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main workflow
// ─────────────────────────────────────────────────────────────────────────────

workflow {

    validateParams()

    // ── Step-based flow control ──────────────────────────────────────────────
    def step_raw = (params.step ?: 'all').toString().toLowerCase().trim()
    def steps    = step_raw.tokenize(',').collect { it.trim() }
    def run_all  = 'all' in steps

    def run_one   = run_all || 'stage_one' in steps
    def run_two   = run_all || 'stage_two' in steps
    def run_three = run_all || 'stage_three' in steps

    // ── Auto-enable upstream steps when outputs are missing ──────────────────
    def sampleMeta = [prefix: params.prefix]
    def pubBase    = "${params.outdir}/${params.prefix}"

    if (run_two && !run_one) {
        def check = file("${pubBase}/stage_one/${params.prefix}_output.csv")
        if (!check.exists()) {
            log.warn "Auto-enabling stage_one: outputs not found at ${check}"
            run_one = true
        }
    }

    log.info """
    ╔══════════════════════════════════════════════════════════╗
    ║  Pipeline Name — step: ${step_raw}
    ╠══════════════════════════════════════════════════════════╣
    ║  stage_one:   ${run_one   ? 'ON' : 'skip'}
    ║  stage_two:   ${run_two   ? 'ON' : 'skip'}
    ║  stage_three: ${run_three ? 'ON' : 'skip'}
    ╚══════════════════════════════════════════════════════════╝
    """.stripIndent()

    ch_sampleinfo = Channel.value(file(params.sampleinfo))

    // ── Stage 1 ──────────────────────────────────────────────────────────────
    if (run_one) {
        ch_expression = Channel.of(
            tuple(sampleMeta, file(params.expression))
        )

        STAGE_ONE(ch_expression, ch_sampleinfo)
    }

    // Resolve stage 1 outputs (from process or disk)
    if (run_one) {
        ch_stage_one_out = STAGE_ONE.out.results
    } else if (run_two || run_three) {
        ch_stage_one_out = Channel.of(
            tuple(sampleMeta, file("${pubBase}/stage_one/${params.prefix}_output.csv"))
        )
    }

    // ── Stage 2 ──────────────────────────────────────────────────────────────
    if (run_two) {
        STAGE_TWO(ch_stage_one_out, ch_sampleinfo)
    }

    if (run_two) {
        ch_stage_two_out = STAGE_TWO.out.results
    } else if (run_three) {
        ch_stage_two_out = Channel.of(
            tuple(sampleMeta, file("${pubBase}/stage_two/${params.prefix}_results.csv"))
        )
    }

    // ── Stage 3 ──────────────────────────────────────────────────────────────
    if (run_three) {
        STAGE_THREE(ch_stage_two_out, ch_sampleinfo)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Workflow completion handler
// ─────────────────────────────────────────────────────────────────────────────

workflow.onComplete {
    def status = workflow.success ? "SUCCESS" : "FAILED"
    log.info """
    ╔══════════════════════════════════════════════════════════╗
    ║  Pipeline Name — ${status}
    ╠══════════════════════════════════════════════════════════╣
    ║  Duration : ${workflow.duration}
    ║  Outdir   : ${params.outdir}
    ║  Exit code: ${workflow.exitStatus}
    ╚══════════════════════════════════════════════════════════╝
    """.stripIndent()
}

workflow.onError {
    log.error "Pipeline failed at process: ${workflow.errorReport}"
}
