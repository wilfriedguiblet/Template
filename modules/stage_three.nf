/*
 * modules/stage_three.nf
 * Stage 3: Brief description of what this stage does.
 */

process STAGE_THREE {
    tag "${meta.prefix}"
    label 'process_low'

    publishDir "${params.outdir}/${meta.prefix}/stage_three", mode: 'copy'

    input:
    tuple val(meta), path(stage_two_output)
    path  sampleinfo

    output:
    tuple val(meta), path("*_final.csv"), emit: results

    script:
    def prefix = meta.prefix
    """
    python3 ${projectDir}/bin/stage_three.py \\
        --input       ${stage_two_output} \\
        --sampleinfo  ${sampleinfo} \\
        --outdir      . \\
        --prefix      ${prefix}
    """

    stub:
    """
    touch ${meta.prefix}_final.csv
    """
}
