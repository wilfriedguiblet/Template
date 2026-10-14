/*
 * modules/stage_one.nf
 * Stage 1: Brief description of what this stage does.
 */

process STAGE_ONE {
    tag "${meta.prefix}"
    label 'process_low'

    publishDir "${params.outdir}/stage_one", mode: 'copy'

    input:
    tuple val(meta), path(expression), path(sampleinfo), path(script_file)

    output:
    tuple val(meta), path("*_output.csv"), path(sampleinfo), emit: results
    path 'stage_one_versions.yml', emit: versions

    script:
    def prefix = meta.prefix
    """
    python3 "${script_file}" \\
        --expression  "${expression}" \\
        --sampleinfo  "${sampleinfo}" \\
        --outdir      . \\
        --prefix      ${prefix}
    cat <<-END_VERSIONS > stage_one_versions.yml
    "${task.process}":
        python: \$(python3 --version 2>&1)
        pandas: \$(python3 -c 'import pandas; print(pandas.__version__)')
    END_VERSIONS
    """

    stub:
    """
    printf 'sample,value\\nexample,0\\n' > ${meta.prefix}_output.csv
    cat <<-END_VERSIONS > stage_one_versions.yml
    "${task.process}":
        python: stub
        pandas: stub
    END_VERSIONS
    """

}
