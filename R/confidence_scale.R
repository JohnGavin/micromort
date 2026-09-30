# Confidence-scale helpers for the population leaderboard stats (#132).
#
# The public Google Sheet stores the quiz confidence column as a
# percent-formatted cell ("75%"). The gviz JSON API returns the underlying
# FRACTION (0.75), not 75. The Google Form only accepts 0%, 25%, 50%, 75%
# and 100%, so valid fractions are 0, 0.25, 0.5, 0.75 and 1. Treating that
# fraction as if it were already 0-100 silently mis-scales every
# downstream calibration figure by a factor of 100.

#' Convert a gviz confidence fraction to a 0-100 percentage
#'
#' Multiplies by 100. Any non-`NA` value outside `[0, 1]` becomes `NA` and
#' a `cli::cli_warn()` reports how many were rejected, so a future change of
#' the Sheet's column format (e.g. to already-scaled 0-100 values) is loud
#' rather than silently mis-scaled.
#'
#' @param x Numeric vector of confidence fractions (0-1), possibly with `NA`.
#' @return Numeric vector of the same length, on the 0-100 scale.
#' @noRd
confidence_fraction_to_pct <- function(x) {
  x <- as.numeric(x)
  bad <- !is.na(x) & (x < 0 | x > 1)
  if (any(bad)) {
    n_bad <- sum(bad)
    cli::cli_warn(c(
      "Rejected {n_bad} confidence value{?s} outside the expected 0-1 fraction range.",
      "i" = "The Sheet's confidence column is percent-formatted, so gviz returns fractions (0.75 for 75%).",
      "i" = "Rejected values were set to {.val NA}; check whether the Sheet's column format changed."
    ))
    x[bad] <- NA_real_
  }
  x * 100
}

#' Attempt-level calibration score (squared error, 0-1 scale)
#'
#' Coarse approximation of a Brier score: `((confidence - score) / 100)^2`,
#' with both inputs on the 0-100 scale.
#'
#' @param confidence_pct Numeric vector: mean confidence, 0-100.
#' @param score_pct Numeric vector: quiz score percentage, 0-100.
#' @return Numeric vector of squared errors in `[0, 1]`.
#' @noRd
confidence_calibration_score <- function(confidence_pct, score_pct) {
  ((confidence_pct - score_pct) / 100)^2
}
