#' Normalization Plan
#'
#' Merges and normalizes data from multiple sources into unified schemas.
#'
#' @return List of targets for data normalization
plan_normalization <- list(
  # Merge acute risks
  targets::tar_target(
    acute_risks_merged,
    {
      # Select and reorder columns to match schema
      acute_cols <- c(
        "record_id", "activity", "activity_normalized", "micromorts",
        "microlives", "category", "period", "period_normalized",
        "age_group", "geography", "year", "source_id", "source_url",
        "confidence", "last_accessed"
      )

      data <- parsed_acute_base

      # Ensure all columns exist
      for (col in acute_cols) {
        if (!col %in% names(data)) {
          data[[col]] <- NA
        }
      }

      data <- data[, acute_cols]
      data <- data[order(-data$micromorts), ]
      rownames(data) <- NULL

      cli::cli_alert_success("Merged {nrow(data)} acute risks")
      data
    }
  ),

  # Merge chronic risks
  targets::tar_target(
    chronic_risks_merged,
    {
      chronic_cols <- c(
        "record_id", "factor", "factor_normalized", "microlives_per_day",
        "direction", "category", "description", "annual_effect_days",
        "source_id", "source_url", "confidence", "last_accessed"
      )

      data <- parsed_chronic_base

      for (col in chronic_cols) {
        if (!col %in% names(data)) {
          data[[col]] <- NA
        }
      }

      data <- data[, chronic_cols]
      data <- data[order(-abs(data$microlives_per_day)), ]
      rownames(data) <- NULL

      cli::cli_alert_success("Merged {nrow(data)} chronic risks")
      data
    }
  ),

  # Source registry
  targets::tar_target(
    risk_sources_merged,
    {
      source_cols <- c(
        "source_id", "citation", "primary_url", "type",
        "description", "data_types", "last_accessed"
      )

      data <- parsed_sources

      for (col in source_cols) {
        if (!col %in% names(data)) {
          data[[col]] <- NA
        }
      }

      data <- data[, source_cols]

      # Validate no duplicate source_ids
      if (any(duplicated(data$source_id))) {
        dups <- data$source_id[duplicated(data$source_id)]
        cli::cli_warn("Duplicate source_ids: {paste(unique(dups), collapse = ', ')}")
      }

      cli::cli_alert_success("Compiled {nrow(data)} sources")
      data
    }
  )
)
