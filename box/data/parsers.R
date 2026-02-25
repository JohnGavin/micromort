#' @name parsers
#' @title Source Data Parsers
#' @description Functions to parse and normalize source data files.

#' Parse Acute Risks CSV
#'
#' Reads and validates acute risks data from CSV.
#'
#' @param path Path to CSV file
#' @return A tibble with normalized acute risk data
#' @export
parse_acute_csv <- function(path) {
  data <- readr::read_csv(path, show_col_types = FALSE)

  # Normalize column names
  names(data) <- tolower(names(data))

  # Ensure required columns exist
  required <- c("activity", "micromorts", "category", "period", "source_url")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    cli::cli_abort("Missing required columns: {paste(missing, collapse = ', ')}")
  }

  # Add computed columns if missing
  if (!"microlives" %in% names(data)) {
    data$microlives <- round(data$micromorts * 0.7, 1)
  }
  if (!"source_id" %in% names(data)) {
    data$source_id <- "unknown"
  }
  if (!"confidence" %in% names(data)) {
    data$confidence <- "medium"
  }
  if (!"year" %in% names(data)) {
    data$year <- as.integer(format(Sys.Date(), "%Y"))
  }
  if (!"geography" %in% names(data)) {
    data$geography <- "global"
  }
  if (!"age_group" %in% names(data)) {
    data$age_group <- "all"
  }
  if (!"last_accessed" %in% names(data)) {
    data$last_accessed <- Sys.Date()
  }

  # Normalize period values
  data$period_normalized <- normalize_period(data$period)

  # Create activity_normalized for grouping
  data$activity_normalized <- normalize_activity(data$activity)

  # Create record_id
  data$record_id <- paste0(data$source_id, "_", digest::digest(data$activity, algo = "xxhash32"))

  data
}

#' Parse Chronic Risks CSV
#'
#' Reads and validates chronic risks data from CSV.
#'
#' @param path Path to CSV file
#' @return A tibble with normalized chronic risk data
#' @export
parse_chronic_csv <- function(path) {
  data <- readr::read_csv(path, show_col_types = FALSE)
  names(data) <- tolower(names(data))

  required <- c("factor", "microlives_per_day", "category", "direction")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    cli::cli_abort("Missing required columns: {paste(missing, collapse = ', ')}")
  }

  # Add computed columns if missing
  if (!"annual_effect_days" %in% names(data)) {
    data$annual_effect_days <- round(data$microlives_per_day * 365 * 30 / (24 * 60), 1)
  }
  if (!"source_id" %in% names(data)) {
    data$source_id <- "unknown"
  }
  if (!"confidence" %in% names(data)) {
    data$confidence <- "medium"
  }
  if (!"last_accessed" %in% names(data)) {
    data$last_accessed <- Sys.Date()
  }

  # Normalize factor names
  data$factor_normalized <- normalize_factor(data$factor)

  # Create record_id
  data$record_id <- paste0(data$source_id, "_", digest::digest(data$factor, algo = "xxhash32"))

  data
}

#' Normalize Period Strings
#'
#' @param period Vector of period strings
#' @return Normalized period strings
normalize_period <- function(period) {
  dplyr::case_when(
    grepl("event|jump|climb|dive|flight", period, ignore.case = TRUE) ~ "event",
    grepl("day|daily", period, ignore.case = TRUE) ~ "day",
    grepl("week", period, ignore.case = TRUE) ~ "week",
    grepl("month", period, ignore.case = TRUE) ~ "month",
    grepl("year|annual", period, ignore.case = TRUE) ~ "year",
    grepl("lifetime", period, ignore.case = TRUE) ~ "lifetime",
    TRUE ~ "event"
  )
}

#' Normalize Activity Names
#'
#' Creates standardized activity names for grouping similar activities.
#'
#' @param activity Vector of activity strings
#' @return Normalized activity names
normalize_activity <- function(activity) {
  # Remove parenthetical details, lowercase, trim whitespace
  normalized <- tolower(activity)
  normalized <- gsub("\\s*\\([^)]*\\)\\s*", "", normalized)
  normalized <- trimws(normalized)
  normalized
}

#' Normalize Factor Names
#'
#' Creates standardized factor names for grouping similar factors.
#'
#' @param factor Vector of factor strings
#' @return Normalized factor names
normalize_factor <- function(factor) {
  normalized <- tolower(factor)
  normalized <- gsub("\\s*\\([^)]*\\)\\s*", "", normalized)
  normalized <- trimws(normalized)
  normalized
}

#' Merge Acute Risk Datasets
#'
#' Combines multiple acute risk datasets, keeping all records.
#'
#' @param datasets List of tibbles to merge
#' @return A single merged tibble
#' @export
merge_acute_risks <- function(datasets) {
  merged <- dplyr::bind_rows(datasets)

  # Sort by micromorts descending
  merged <- merged[order(-merged$micromorts), ]

  # Reset row numbers
  rownames(merged) <- NULL

  merged
}

#' Merge Chronic Risk Datasets
#'
#' Combines multiple chronic risk datasets, keeping all records.
#'
#' @param datasets List of tibbles to merge
#' @return A single merged tibble
#' @export
merge_chronic_risks <- function(datasets) {
  merged <- dplyr::bind_rows(datasets)

  # Sort by absolute effect descending
  merged <- merged[order(-abs(merged$microlives_per_day)), ]

  rownames(merged) <- NULL
  merged
}
