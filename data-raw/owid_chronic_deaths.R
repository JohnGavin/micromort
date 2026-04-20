## data-raw/owid_chronic_deaths.R
##
## Downloads and filters OWID/GBD cause-of-death data to a small bundled CSV.
##
## Source: IHME Global Burden of Disease 2024-05-20 release, via Our World in
## Data catalog:
## https://catalog.ourworldindata.org/garden/ihme_gbd/2024-05-20/gbd_cause/gbd_cause_deaths.csv
##
## The full dataset is large (>500 MB). This script filters to:
##   - 7 chronic disease causes
##   - ~20 countries (top by population + all OECD)
##   - Most recent year available
## and saves the result to inst/extdata/owid_chronic_deaths.csv (<50 KB).
##
## Run manually when refreshing the bundled snapshot:
##   Rscript data-raw/owid_chronic_deaths.R

library(dplyr)
library(readr)

OWID_URL <- paste0(
  "https://catalog.ourworldindata.org/garden/ihme_gbd/",
  "2024-05-20/gbd_cause/gbd_cause_deaths.csv"
)

# Causes of interest (GBD cause labels may vary; adjust to match actual data)
CHRONIC_CAUSES <- c(
  "Cardiovascular diseases",
  "Neoplasms",
  "Chronic respiratory diseases",
  "Diabetes mellitus",
  "Chronic kidney disease",
  "Chronic liver disease",
  "Digestive diseases"
)

# ISO-3 codes: top 20 by population + OECD countries
COUNTRIES_ISO3 <- c(
  # Top 20 by population (approx 2024)
  "CHN", "IND", "USA", "IDN", "PAK", "BRA", "NGA", "BGD", "RUS", "ETH",
  "MEX", "JPN", "PHL", "COD", "EGY", "VNM", "TZA", "IRN", "TUR", "DEU",
  # Additional OECD (not already in top 20)
  "GBR", "FRA", "ITA", "ESP", "KOR", "NLD", "SWE", "POL", "CAN", "AUS",
  "CHE", "BEL", "AUT", "NZL", "NOR", "DNK", "FIN", "IRL", "PRT", "GRC",
  "CZE", "HUN", "SVK", "LUX", "SVN", "EST", "LVA", "LTU", "ISL", "CHL",
  "ISR", "COL", "CRI", "ARG"
)

message("Attempting to download OWID GBD cause data from:\n  ", OWID_URL)
message("Note: This file is large (>500 MB). Download may take several minutes.")

raw <- tryCatch(
  readr::read_csv(OWID_URL, show_col_types = FALSE),
  error = function(e) {
    message(
      "Download failed: ", conditionMessage(e), "\n",
      "Using existing inst/extdata/owid_chronic_deaths.csv instead."
    )
    NULL
  }
)

if (!is.null(raw)) {
  # Identify the relevant columns — OWID column names vary by dataset edition
  # Expected: country, code (ISO-3), cause, year, deaths_per_100k (or similar)
  # Adjust column selection to match actual schema
  filtered <- raw |>
    dplyr::filter(
      .data$code %in% COUNTRIES_ISO3,
      .data$cause %in% CHRONIC_CAUSES
    ) |>
    dplyr::group_by(.data$code) |>
    dplyr::filter(.data$year == max(.data$year)) |>
    dplyr::ungroup() |>
    dplyr::select(
      country  = .data$entity,
      iso3     = .data$code,
      cause    = .data$cause,
      year     = .data$year,
      deaths_per_100k = .data$deaths_per_100k
    )

  out_path <- here::here("inst", "extdata", "owid_chronic_deaths.csv")
  readr::write_csv(filtered, out_path)
  message("Saved ", nrow(filtered), " rows to ", out_path)
} else {
  message("Skipped — using existing bundled CSV.")
}
