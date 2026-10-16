process STAGE_TWO {
    tag "${meta.prefix}"
    label 'process_medium'
    publishDir path: { "${params.outdir}/${meta.prefix}/stage_two" }, mode: 'copy'

    input:
    tuple val(meta), path(stage_one_output), path(sampleinfo)
    path script_file
    path checksum_script

    output:
    tuple val(meta), path("*_results.csv"), path(sampleinfo), emit: results
    tuple val(meta), path("*.png"), emit: plots, optional: true
    path '*_checksums.csv', emit: checksums
    path '*_versions.yml', emit: versions

    script:
    def prefix = meta.prefix
    """
    python3 "${script_file}" \\
        --input "${stage_one_output}" \\
        --sampleinfo "${sampleinfo}" \\
        --outdir . \\
        --prefix ${prefix}
    python3 "${checksum_script}" --stage stage_two --cohort "${prefix}" \\
        --output ${prefix}_stage_two_checksums.csv \\
        --versions ${prefix}_stage_two_versions.yml \\
        --output-prefix "${prefix}/stage_two" \\
        --inputs "${stage_one_output}" "${sampleinfo}" \\
        --outputs ${prefix}_results.csv
    """

    stub:
    """
    printf 'sample,value\\nexample,0\\n' > ${meta.prefix}_results.csv
    printf 'stage,cohort,kind,path,bytes,sha256\\n' > ${meta.prefix}_stage_two_checksums.csv
    printf 'stage_two: stub\\n' > ${meta.prefix}_stage_two_versions.yml
    """
}