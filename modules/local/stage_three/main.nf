process STAGE_THREE {
    tag "${meta.prefix}"
    label 'process_low'
    publishDir path: { "${params.outdir}/${meta.prefix}/stage_three" }, mode: 'copy'

    input:
    tuple val(meta), path(stage_two_output), path(sampleinfo)
    path script_file
    path checksum_script

    output:
    tuple val(meta), path("*_final.csv"), emit: results
    path '*_checksums.csv', emit: checksums
    path '*_versions.yml', emit: versions

    script:
    def prefix = meta.prefix
    """
    python3 "${script_file}" \\
        --input "${stage_two_output}" \\
        --sampleinfo "${sampleinfo}" \\
        --outdir . \\
        --prefix ${prefix}
    python3 "${checksum_script}" --stage stage_three --cohort "${prefix}" \\
        --output ${prefix}_stage_three_checksums.csv \\
        --versions ${prefix}_stage_three_versions.yml \\
        --output-prefix "${prefix}/stage_three" \\
        --inputs "${stage_two_output}" "${sampleinfo}" \\
        --outputs ${prefix}_final.csv
    """

    stub:
    """
    printf 'sample,value\\nexample,0\\n' > ${meta.prefix}_final.csv
    printf 'stage,cohort,kind,path,bytes,sha256\\n' > ${meta.prefix}_stage_three_checksums.csv
    printf 'stage_three: stub\\n' > ${meta.prefix}_stage_three_versions.yml
    """
}