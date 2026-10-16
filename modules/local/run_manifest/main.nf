process BUILD_RUN_MANIFEST {
    tag 'run_manifest'
    label 'process_low'
    publishDir "${params.outdir}/pipeline_info", mode: 'copy'

    input:
    path samplesheet
    path checksum_files, stageAs: 'checksums/*'
    path version_files, stageAs: 'versions/*'
    path source_files, stageAs: 'source??/*'
    path script_file
    val parameters_base64

    output:
    path 'run_manifest.json', emit: manifest
    path 'input_checksums.csv', emit: input_checksums
    path 'output_checksums.csv', emit: output_checksums
    path 'software_versions.txt', emit: software_versions

    script:
    def checksumArgs = checksum_files.collect { item -> "\"${item}\"" }.join(' ')
    def versionArgs = version_files.collect { item -> "\"${item}\"" }.join(' ')
    def sourceArgs = source_files.collect { item -> "\"${item}\"" }.join(' ')
    """
    python3 "${script_file}" \\
        --samplesheet "${samplesheet}" \\
        --checksum-files ${checksumArgs} \\
        --version-files ${versionArgs} \\
        --source-files ${sourceArgs} \\
        --parameters-base64 ${parameters_base64} \\
        --outdir .
    """

    stub:
    """
    printf '{"stub": true}\\n' > run_manifest.json
    printf 'path,bytes,sha256\\n' > input_checksums.csv
    printf 'path,bytes,sha256\\n' > output_checksums.csv
    printf 'python: stub\\n' > software_versions.txt
    """
}