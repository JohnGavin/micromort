# data-raw/06_faa_lta_hours_extract.R
# Called by 06_faa_ga_survey_download.sh.
# usage: Rscript 06_faa_lta_hours_extract.R ROOT WORKDIR ACCESS_DATE OUT_CSV
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L) {
  cli::cli_abort(c("x" = "Expected 4 arguments: ROOT WORKDIR ACCESS_DATE OUT_CSV."))
}
root <- args[[1]]
work <- args[[2]]
pkgload::load_all(root, quiet = TRUE)

map <- utils::read.csv(
  file.path(root, "data-raw", "sources", "faa_ga_survey_urls.csv"),
  stringsAsFactors = FALSE
)
out <- do.call(rbind, lapply(seq_len(nrow(map)), function(i) {
  f <- file.path(work, map$file[i])
  res <- read_faa_lta_hours(f, map$year[i])
  res$url <- map$url[i]
  res$sha256 <- digest::digest(f, algo = "sha256", file = TRUE)
  res$last_accessed <- args[[3]]
  res[, c("year", "lta_hours", "basis", "file", "url", "sha256", "last_accessed")]
}))
utils::write.csv(out, args[[4]], row.names = FALSE)
cli::cli_alert_success("Wrote lighter-than-air hours for {nrow(out)} years to {.file {args[[4]]}}")
