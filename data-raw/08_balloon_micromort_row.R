# data-raw/08_balloon_micromort_row.R
# Hot-air ballooning micromorts (issue #222).
#
# Derives the ballooning rate from the committed source files and writes it
# into data-raw/sources/acute_risks_base.csv and risk_sources.csv:
#   numerator:   data-raw/sources/ntsb_balloon_events.csv
#                (made by 07_ntsb_balloon_extract.sh from the NTSB database)
#   denominator: data-raw/sources/faa_lta_hours.csv
#                (made by 06_faa_ga_survey_download.sh from the FAA survey)
#
# No number in this script is typed in by hand. Re-running it is idempotent:
# any earlier ballooning rows are replaced. After running, regenerate the
# parquet files with the targets pipeline:
#   targets::tar_make(c(export_acute, export_sources))
#
# usage: Rscript data-raw/08_balloon_micromort_row.R [REPO_ROOT]

args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args) >= 1L) args[[1]] else "."
pkgload::load_all(root, quiet = TRUE)

src <- function(...) file.path(root, "data-raw", "sources", ...)

# ── Numerator and denominator ───────────────────────────────────────────────
events <- read_ntsb_balloon_events(src("ntsb_balloon_events.csv"))
hours <- utils::read.csv(src("faa_lta_hours.csv"), stringsAsFactors = FALSE)

res <- compute_balloon_risk(events, hours)
print(res$by_year)
print(res$summary)

# ── Provenance ──────────────────────────────────────────────────────────────
ntsb_prov <- utils::read.csv(src("ntsb_balloon_events_provenance.csv"), stringsAsFactors = FALSE)
last_accessed <- max(as.Date(c(ntsb_prov$last_accessed, hours$last_accessed)))

ntsb_url <- "https://data.ntsb.gov/avdata"
faa_url <- "https://www.faa.gov/data_research/aviation_data_statistics/general_aviation"
source_id <- "ntsb_faa_balloon"

row <- balloon_acute_row(res$summary, ntsb_url, source_id, last_accessed)

s <- res$summary
ga_only_years <- hours$year[hours$basis == "general_aviation_only"]
description <- sprintf(
  paste0(
    "NTSB aviation accident database (balloon accidents in the USA, %d-%d: %d pilot deaths) ",
    "divided by FAA General Aviation and Part 135 Activity Survey lighter-than-air hours (%s hours; %s). ",
    "Pilot deaths per aircraft hour; one pilot per balloon. 95%% interval %.1f-%.1f micromorts per hour. ",
    "Survey hours cover all lighter-than-air craft; years %s count general-aviation hours only"
  ),
  s$year_from, s$year_to, s$pilot_deaths,
  format(round(s$lta_hours), big.mark = ",", trim = TRUE), faa_url,
  s$ci_low, s$ci_high,
  if (length(ga_only_years) > 0L) paste(range(ga_only_years), collapse = "-") else "none"
)
source_row <- data.frame(
  citation = "NTSB aviation accident database + FAA GA and Part 135 Activity Survey",
  primary_url = ntsb_url,
  type = "Government",
  description = description,
  source_id = source_id,
  data_types = "acute",
  last_accessed = as.character(last_accessed),
  stringsAsFactors = FALSE
)

# ── Write: drop earlier balloon lines, append the new ones (existing lines are
#    left byte-for-byte untouched) ─────────────────────────────────────────────
replace_lines <- function(path, key_pattern, new_df) {
  lines <- readLines(path, warn = FALSE)
  lines <- lines[!grepl(key_pattern, lines)]
  new_lines <- readr::format_csv(new_df, col_names = FALSE)
  new_lines <- strsplit(sub("\n$", "", new_lines), "\n", fixed = TRUE)[[1]]
  writeLines(c(lines, new_lines), path)
}
replace_lines(src("acute_risks_base.csv"), "^\"?Hot-air ballooning", row)
replace_lines(src("risk_sources.csv"), paste0(",", source_id, ","), source_row)

cli::cli_alert_success(
  "Wrote ballooning row: {row$micromorts} micromorts per flight hour ({s$pilot_deaths} pilot deaths / {round(s$lta_hours)} hours)"
)
