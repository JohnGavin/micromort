#' @name loaders
#' @title Parquet Dataset Loaders
#' @description Functions to load micromort/microlife datasets from parquet files.

#' Load Acute Risks Dataset
#'
#' @param path Optional path to parquet file. Defaults to inst/extdata/acute_risks.parquet
#' @return A tibble with acute risk data
#' @export
load_acute_risks <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file("extdata", "acute_risks.parquet", package = "micromort")
    if (path == "") {
      path <- "inst/extdata/acute_risks.parquet"
    }
  }

  if (!file.exists(path)) {
    cli::cli_abort(c(
      "x" = "Acute risks parquet file not found",
      "i" = "Path: {path}",
      "i" = "Run tar_make() to generate the dataset"
    ))
  }

  arrow::read_parquet(path)
}

#' Load Chronic Risks Dataset
#'
#' @param path Optional path to parquet file. Defaults to inst/extdata/chronic_risks.parquet
#' @return A tibble with chronic risk data
#' @export
load_chronic_risks <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file("extdata", "chronic_risks.parquet", package = "micromort")
    if (path == "") {
      path <- "inst/extdata/chronic_risks.parquet"
    }
  }

  if (!file.exists(path)) {
    cli::cli_abort(c(
      "x" = "Chronic risks parquet file not found",
      "i" = "Path: {path}",
      "i" = "Run tar_make() to generate the dataset"
    ))
  }

  arrow::read_parquet(path)
}

#' Load Risk Sources Registry
#'
#' @param path Optional path to parquet file. Defaults to inst/extdata/risk_sources.parquet
#' @return A tibble with source metadata
#' @export
load_sources <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file("extdata", "risk_sources.parquet", package = "micromort")
    if (path == "") {
      path <- "inst/extdata/risk_sources.parquet"
    }
  }

  if (!file.exists(path)) {
    cli::cli_abort(c(
      "x" = "Risk sources parquet file not found",
      "i" = "Path: {path}",
      "i" = "Run tar_make() to generate the dataset"
    ))
  }

  arrow::read_parquet(path)
}
