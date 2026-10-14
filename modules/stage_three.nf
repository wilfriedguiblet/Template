/*
 * modules/stage_three.nf
 * Stage 3: Brief description of what this stage does.
 */

process STAGE_THREE {
    tag "${meta.prefix}"
    label 'process_low'

    publishDir "${params.outdir}/stage_three", mode: 'copy'

    input:
    tuple val(meta), path(stage_two_output), path(sampleinfo), path(script_file)

    output:
    tuple val(meta), path("*_final.csv"), emit: results
    path 'stage_three_versions.yml', emit: versions

    script:
    def prefix = meta.prefix
    """
    python3 "${script_file}" \\
        --input       "${stage_two_output}" \\
        --sampleinfo  "${sampleinfo}" \\
        --outdir      . \\
        --prefix      ${prefix}
    cat <<-END_VERSIONS > stage_three_versions.yml
    "${task.process}":
        python: \$(python3 --version 2>&1)
        pandas: \$(python3 -c 'import pandas; print(pandas.__version__)')
    END_VERSIONS
    """

    stub:
    """
    printf 'sample,value\\nexample,0\\n' > ${meta.prefix}_final.csv
    cat <<-END_VERSIONS > stage_three_versions.yml
    "${task.process}":
        python: stub
        pandas: stub
    END_VERSIONS
    """
}
