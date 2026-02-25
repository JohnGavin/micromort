#' Data Acquisition Plan
#'
#' Tracks source CSV files and parses them into normalized tibbles.
#'
#' @return List of targets for data acquisition
plan_data_acquisition <- list(
  # Track source files
  targets::tar_target(
    src_acute_base,
    "data-raw/sources/acute_risks_base.csv",
    format = "file"
  ),

  targets::tar_target(
    src_chronic_base,
    "data-raw/sources/chronic_risks_base.csv",
    format = "file"
  ),

  targets::tar_target(
    src_covid_vaccine,
    "data-raw/sources/covid_vaccine_rr.csv",
    format = "file"
  ),

  targets::tar_target(
    src_demographic,
    "data-raw/sources/demographic_factors.csv",
    format = "file"
  ),

  targets::tar_target(
    src_risk_sources,
    "data-raw/sources/risk_sources.csv",
    format = "file"
  ),

  # Parse source files
  targets::tar_target(
    parsed_acute_base,
    {
      data <- readr::read_csv(src_acute_base, show_col_types = FALSE)

      # Add computed columns
      data$period_normalized <- dplyr::case_when(
        grepl("event|jump|climb|dive|flight|ascent", data$period, ignore.case = TRUE) ~ "event",
        grepl("per day", data$period, ignore.case = TRUE) ~ "day",
        grepl("per week", data$period, ignore.case = TRUE) ~ "week",
        grepl("per month|weeks", data$period, ignore.case = TRUE) ~ "month",
        grepl("per year", data$period, ignore.case = TRUE) ~ "year",
        TRUE ~ "event"
      )

      data$activity_normalized <- tolower(gsub("\\s*\\([^)]*\\)\\s*", "", data$activity))
      data$record_id <- paste0(data$source_id, "_", seq_len(nrow(data)))

      data
    }
  ),

  targets::tar_target(
    parsed_chronic_base,
    {
      data <- readr::read_csv(src_chronic_base, show_col_types = FALSE)
      data$factor_normalized <- tolower(gsub("\\s*\\([^)]*\\)\\s*", "", data$factor))
      data$record_id <- paste0(data$source_id, "_", seq_len(nrow(data)))
      data
    }
  ),

  targets::tar_target(
    parsed_covid,
    {
      readr::read_csv(src_covid_vaccine, show_col_types = FALSE)
    }
  ),

  targets::tar_target(
    parsed_demographic,
    {
      readr::read_csv(src_demographic, show_col_types = FALSE)
    }
  ),

  targets::tar_target(
    parsed_sources,
    {
      readr::read_csv(src_risk_sources, show_col_types = FALSE)
    }
  )
)
