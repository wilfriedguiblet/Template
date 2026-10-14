process BUILD_RUN_MANIFEST {
    tag 'run_manifest'
    label 'process_low'
    publishDir "${params.outdir}/pipeline_info", mode: 'copy'

    input:
    path samplesheet
    path result_files
    path version_files
    path script_file
    val input_paths_base64
    val parameters_base64

    output:
    path 'run_manifest.json', emit: manifest
    path 'input_checksums.csv', emit: input_checksums
    path 'output_checksums.csv', emit: output_checksums
    path 'software_versions.txt', emit: software_versions

    script:
    def resultArgs = result_files.collect { result -> "\"${result}\"" }.join(' ')
    """
    python3 "${script_file}" \\
        --samplesheet "${samplesheet}" \\
        --input-paths-base64 ${input_paths_base64} \\
        --result-files ${resultArgs} \\
        --version-files ${version_files.join(' ')} \\
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
