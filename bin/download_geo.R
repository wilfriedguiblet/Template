#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
    stop("Usage: download_geo.R ACCESSION PLATFORM OUTPUT_PREFIX")
}
accession <- args[[1L]]
requested_platform <- args[[2L]]
prefix <- args[[3L]]
if (!requireNamespace("GEOquery", quietly = TRUE)) {
    stop("GEOquery is required for geo_accession samplesheet rows")
}

geo <- GEOquery::getGEO(accession, GSEMatrix = TRUE, getGPL = FALSE)
sets <- if (methods::is(geo, "ExpressionSet")) list(geo) else geo
if (length(sets) > 1L) {
    platforms <- vapply(sets, Biobase::annotation, character(1))
    if (!nzchar(requested_platform)) {
        stop("GEO series has multiple platforms; set geo_platform to one of: ",
             paste(platforms, collapse = ", "))
    }
    selected <- which(platforms == requested_platform)
    if (length(selected) != 1L) {
        stop("geo_platform not found; available platforms: ", paste(platforms, collapse = ", "))
    }
    eset <- sets[[selected]]
} else {
    eset <- sets[[1L]]
    platform <- Biobase::annotation(eset)
    if (nzchar(requested_platform) && requested_platform != platform) {
        stop("Requested platform ", requested_platform, " but GEO returned ", platform)
    }
}

expression <- Biobase::exprs(eset)
metadata <- Biobase::pData(eset)
metadata <- data.frame(Sample_ID = rownames(metadata), metadata, check.names = FALSE)
write.table(expression, paste0(prefix, "_geo_expression.tsv"), sep = "\t",
            quote = FALSE, col.names = NA)
write.csv(metadata, paste0(prefix, "_geo_sampleinfo.csv"), row.names = FALSE,
          na = "")
cat("GEOquery:", as.character(utils::packageVersion("GEOquery")), "\n")
cat("Biobase:", as.character(utils::packageVersion("Biobase")), "\n")
