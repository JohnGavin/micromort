#' Export Plan
#'
#' Exports merged datasets to parquet files in inst/extdata/.
#'
#' @return List of targets for data export
plan_export <- list(
  # Export acute risks
  targets::tar_target(
    export_acute,
    {
      dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
      path <- "inst/extdata/acute_risks.parquet"
      arrow::write_parquet(acute_risks_merged, path, compression = "zstd")
      cli::cli_alert_success("Exported acute risks to {path}")
      path
    },
    format = "file"
  ),

  # Export chronic risks
  targets::tar_target(
    export_chronic,
    {
      dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
      path <- "inst/extdata/chronic_risks.parquet"
      arrow::write_parquet(chronic_risks_merged, path, compression = "zstd")
      cli::cli_alert_success("Exported chronic risks to {path}")
      path
    },
    format = "file"
  ),

  # Export source registry
  targets::tar_target(
    export_sources,
    {
      dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
      path <- "inst/extdata/risk_sources.parquet"
      arrow::write_parquet(risk_sources_merged, path, compression = "zstd")
      cli::cli_alert_success("Exported risk sources to {path}")
      path
    },
    format = "file"
  ),

  # Validation target
  targets::tar_target(
    export_validation,
    {
      # Verify all exports exist and are readable
      files <- c(export_acute, export_chronic, export_sources)

      results <- lapply(files, function(f) {
        data <- arrow::read_parquet(f)
        list(
          file = basename(f),
          rows = nrow(data),
          cols = ncol(data),
          size_kb = round(file.info(f)$size / 1024, 1)
        )
      })

      summary <- dplyr::bind_rows(results)
      cli::cli_alert_success("Validated {nrow(summary)} parquet exports")
      print(summary)
      summary
    }
  )
)
