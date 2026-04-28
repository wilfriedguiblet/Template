/*
 * modules/stage_two.nf
 * Stage 2: Brief description of what this stage does.
 */

process STAGE_TWO {
    tag "${meta.prefix}"
    label 'process_medium'

    publishDir "${params.outdir}/${meta.prefix}/stage_two", mode: 'copy'

    input:
    tuple val(meta), path(stage_one_output)
    path  sampleinfo

    output:
    tuple val(meta), path("*_results.csv"),  emit: results
    tuple val(meta), path("*.png"),          emit: plots, optional: true

    script:
    def prefix = meta.prefix
    """
    python3 ${projectDir}/bin/stage_two.py \\
        --input       ${stage_one_output} \\
        --sampleinfo  ${sampleinfo} \\
        --outdir      . \\
        --prefix      ${prefix}
    """

    stub:
    """
    touch ${meta.prefix}_results.csv
    """
}
