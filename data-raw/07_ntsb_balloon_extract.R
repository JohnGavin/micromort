# data-raw/07_ntsb_balloon_extract.R
# Called by 07_ntsb_balloon_extract.sh.
# usage: Rscript 07_ntsb_balloon_extract.R ROOT AIRCRAFT_CSV EVENTS_CSV INJURY_CSV OUT_CSV
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 5L) {
  cli::cli_abort(c("x" = "Expected 5 arguments: ROOT AIRCRAFT_CSV EVENTS_CSV INJURY_CSV OUT_CSV."))
}
pkgload::load_all(args[[1]], quiet = TRUE)

ev <- extract_ntsb_balloon_events(args[[2]], args[[3]], args[[4]])
utils::write.csv(ev, args[[5]], row.names = FALSE, na = "")
cli::cli_alert_success("Wrote {nrow(ev)} balloon aircraft records to {.file {args[[5]]}}")
