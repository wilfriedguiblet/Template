process DOWNLOAD_GEO {
    tag "${meta.prefix}:${accession}"
    label 'process_geo'
    publishDir "${params.outdir}/geo_download", mode: 'copy'

    input:
    tuple val(meta), val(accession), val(platform), path(script_file)

    output:
    tuple val(meta), path("*_geo_expression.tsv"), path("*_geo_sampleinfo.csv"), emit: dataset
    path 'geo_download_versions.txt', emit: versions

    script:
    def prefix = meta.prefix
    """
    Rscript "${script_file}" "${accession}" "${platform}" "${prefix}"
    cat <<-END_VERSIONS > geo_download_versions.txt
    GEOquery: \$(Rscript -e 'cat(as.character(packageVersion("GEOquery")))')
    Biobase: \$(Rscript -e 'cat(as.character(packageVersion("Biobase")))')
    R: \$(Rscript --version 2>&1 | head -n 1)
    END_VERSIONS
    """

    stub:
    """
    printf 'gene\\tsample_1\\nGENE_A\\t1\\n' > ${meta.prefix}_geo_expression.tsv
    printf 'Sample_ID,group\\nsample_1,example\\n' > ${meta.prefix}_geo_sampleinfo.csv
    printf 'GEOquery: stub\\nBiobase: stub\\nR: stub\\n' > geo_download_versions.txt
    """
}