process STAGE_ONE {
    tag "${meta.prefix}"
    label 'process_low'
    publishDir path: { "${params.outdir}/${meta.prefix}/stage_one" }, mode: 'copy'

    input:
    tuple val(meta), path(expression), path(sampleinfo)
    path script_file
    path checksum_script

    output:
    tuple val(meta), path("*_output.csv"), path(sampleinfo), emit: results
    path '*_checksums.csv', emit: checksums
    path '*_versions.yml', emit: versions

    script:
    def prefix = meta.prefix
    """
    python3 "${script_file}" \\
        --expression "${expression}" \\
        --sampleinfo "${sampleinfo}" \\
        --outdir . \\
        --prefix ${prefix}
    python3 "${checksum_script}" --stage stage_one --cohort "${prefix}" \\
        --output ${prefix}_stage_one_checksums.csv \\
        --versions ${prefix}_stage_one_versions.yml \\
        --output-prefix "${prefix}/stage_one" \\
        --inputs "${expression}" "${sampleinfo}" \\
        --outputs ${prefix}_output.csv
    """

    stub:
    """
    printf 'sample,value\\nexample,0\\n' > ${meta.prefix}_output.csv
    printf 'stage,cohort,kind,path,bytes,sha256\\n' > ${meta.prefix}_stage_one_checksums.csv
    printf 'stage_one: stub\\n' > ${meta.prefix}_stage_one_versions.yml
    """
}