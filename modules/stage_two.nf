/*
 * modules/stage_two.nf
 * Stage 2: Brief description of what this stage does.
 */

process STAGE_TWO {
    tag "${meta.prefix}"
    label 'process_medium'

    publishDir "${params.outdir}/stage_two", mode: 'copy'

    input:
    tuple val(meta), path(stage_one_output), path(sampleinfo), path(script_file)

    output:
    tuple val(meta), path("*_results.csv"), path(sampleinfo), emit: results
    tuple val(meta), path("*.png"),          emit: plots, optional: true
    path 'stage_two_versions.yml', emit: versions

    script:
    def prefix = meta.prefix
    """
    python3 "${script_file}" \\
        --input       "${stage_one_output}" \\
        --sampleinfo  "${sampleinfo}" \\
        --outdir      . \\
        --prefix      ${prefix}
    cat <<-END_VERSIONS > stage_two_versions.yml
    "${task.process}":
        python: \$(python3 --version 2>&1)
        pandas: \$(python3 -c 'import pandas; print(pandas.__version__)')
    END_VERSIONS
    """

    stub:
    """
    printf 'sample,value\\nexample,0\\n' > ${meta.prefix}_results.csv
    cat <<-END_VERSIONS > stage_two_versions.yml
    "${task.process}":
        python: stub
        pandas: stub
    END_VERSIONS
    """
}
