#' @name schemas
#' @title Schema Validation Functions
#' @description Validates data against expected schemas for acute/chronic risks.

#' Required columns for acute risks
ACUTE_SCHEMA <- c(
  "activity", "micromorts", "microlives", "category", "period",
  "source_url", "source_id", "confidence", "year", "geography",
  "age_group", "last_accessed"
)

#' Required columns for chronic risks
CHRONIC_SCHEMA <- c(
  "factor", "microlives_per_day", "category", "direction",
  "description", "annual_effect_days", "source_url", "source_id",
  "confidence", "last_accessed"
)

#' Required columns for source registry
SOURCES_SCHEMA <- c(
  "source_id", "citation", "primary_url", "type", "description",
  "data_types", "last_accessed"
)

#' Validate Acute Risks Schema
#'
#' @param data A tibble to validate
#' @return TRUE if valid, otherwise throws error
#' @export
validate_acute_schema <- function(data) {
  missing <- setdiff(ACUTE_SCHEMA, names(data))

  if (length(missing) > 0) {
    cli::cli_abort(c(
      "x" = "Acute risks data missing required columns",
      "i" = "Missing: {paste(missing, collapse = ', ')}"
    ))
  }

  # Type checks
  if (!is.numeric(data$micromorts)) {
    cli::cli_abort("micromorts must be numeric")
  }
  if (!is.numeric(data$microlives)) {
    cli::cli_abort("microlives must be numeric")
  }
  if (!all(data$confidence %in% c("high", "medium", "low"))) {
    cli::cli_abort("confidence must be one of: high, medium, low")
  }

  cli::cli_alert_success("Acute risks schema validated ({nrow(data)} records)")
  TRUE
}

#' Validate Chronic Risks Schema
#'
#' @param data A tibble to validate
#' @return TRUE if valid, otherwise throws error
#' @export
validate_chronic_schema <- function(data) {
  missing <- setdiff(CHRONIC_SCHEMA, names(data))

  if (length(missing) > 0) {
    cli::cli_abort(c(
      "x" = "Chronic risks data missing required columns",
      "i" = "Missing: {paste(missing, collapse = ', ')}"
    ))
  }

  # Type checks
  if (!is.numeric(data$microlives_per_day)) {
    cli::cli_abort("microlives_per_day must be numeric")
  }
  if (!all(data$direction %in% c("gain", "loss"))) {
    cli::cli_abort("direction must be one of: gain, loss")
  }
  if (!all(data$confidence %in% c("high", "medium", "low"))) {
    cli::cli_abort("confidence must be one of: high, medium, low")
  }

  cli::cli_alert_success("Chronic risks schema validated ({nrow(data)} records)")
  TRUE
}

#' Validate Sources Schema
#'
#' @param data A tibble to validate
#' @return TRUE if valid, otherwise throws error
#' @export
validate_sources_schema <- function(data) {
  missing <- setdiff(SOURCES_SCHEMA, names(data))

  if (length(missing) > 0) {
    cli::cli_abort(c(
      "x" = "Sources data missing required columns",
      "i" = "Missing: {paste(missing, collapse = ', ')}"
    ))
  }

  # Check for duplicate source_ids
  if (any(duplicated(data$source_id))) {
    dups <- data$source_id[duplicated(data$source_id)]
    cli::cli_abort(c(
      "x" = "Duplicate source_ids found",
      "i" = "Duplicates: {paste(unique(dups), collapse = ', ')}"
    ))
  }

  cli::cli_alert_success("Sources schema validated ({nrow(data)} sources)")
  TRUE
}
