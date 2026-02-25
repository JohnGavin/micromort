#' Logging Plan
#'
#' Captures pipeline execution metadata for reproducibility.
#'
#' @return List of targets for pipeline logging
plan_logging <- list(
  targets::tar_target(
    pipeline_log,
    {
      dir.create("inst/extdata/logs", showWarnings = FALSE, recursive = TRUE)

      log_entry <- list(
        timestamp = Sys.time(),
        r_version = R.version.string,
        targets_version = as.character(utils::packageVersion("targets")),
        arrow_version = as.character(utils::packageVersion("arrow")),
        acute_risks_count = nrow(acute_risks_merged),
        chronic_risks_count = nrow(chronic_risks_merged),
        sources_count = nrow(risk_sources_merged),
        files_exported = c(export_acute, export_chronic, export_sources),
        platform = R.version$platform,
        session_info = utils::sessionInfo()
      )

      log_file <- sprintf(
        "inst/extdata/logs/pipeline_%s.rds",
        format(Sys.time(), "%Y%m%d_%H%M%S")
      )

      saveRDS(log_entry, log_file)
      cli::cli_alert_success("Pipeline log saved to {log_file}")

      # Print summary
      cli::cli_h2("Pipeline Summary")
      cli::cli_alert_info("Acute risks: {log_entry$acute_risks_count}")
      cli::cli_alert_info("Chronic risks: {log_entry$chronic_risks_count}")
      cli::cli_alert_info("Sources: {log_entry$sources_count}")
      cli::cli_alert_info("R version: {log_entry$r_version}")

      log_entry
    }
  )
)
