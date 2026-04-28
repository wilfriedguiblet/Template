/*
 * modules/stage_one.nf
 * Stage 1: Brief description of what this stage does.
 */

process STAGE_ONE {
    tag "${meta.prefix}"
    label 'process_low'

    publishDir "${params.outdir}/${meta.prefix}/stage_one", mode: 'copy'

    input:
    tuple val(meta), path(expression)
    path  sampleinfo

    output:
    tuple val(meta), path("*_output.csv"), emit: results

    script:
    def prefix = meta.prefix
    """
    python3 ${projectDir}/bin/stage_one.py \\
        --expression  ${expression} \\
        --sampleinfo  ${sampleinfo} \\
        --outdir      . \\
        --prefix      ${prefix}
    """

    stub:
    """
    touch ${meta.prefix}_output.csv
    """
}
