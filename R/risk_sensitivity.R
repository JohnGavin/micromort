#' Sensitivity Analysis for Activity Risk Estimates
#'
#' Computes how activity micromort rankings shift when the base estimate is
#' varied by ±`pct`%. Useful for communicating uncertainty around point
#' estimates derived from sparse epidemiological data.
#'
#' Activities are sourced from [common_risks()]. The `rank_change` column
#' reports the absolute number of ranking positions an activity moves between
#' its low and high estimate when all activities are re-ranked.
#'
#' @param activity Character scalar — activity name matching a row in
#'   [common_risks()]. Pass `NULL` (default) to return sensitivity for all
#'   activities.
#' @param pct Numeric scalar — percentage variation applied symmetrically
#'   around the base estimate. Default `20` (i.e., ±20%). Must be in (0, 100).
#' @return A tibble with columns:
#' \describe{
#'   \item{activity}{Activity name}
#'   \item{micromorts_base}{Base micromort estimate from [common_risks()]}
#'   \item{micromorts_low}{Low estimate: `base * (1 - pct/100)`}
#'   \item{micromorts_high}{High estimate: `base * (1 + pct/100)`}
#'   \item{rank_base}{Rank of the activity at the base estimate (1 = highest risk)}
#'   \item{rank_change}{Absolute rank positions shifted between low and high estimates}
#' }
#' @family analysis
#' @seealso [common_risks()], [daily_hazard_rate()]
#' @export
#' @examples
#' # Sensitivity for a single activity
#' risk_sensitivity("Skydiving (US)")
#'
#' # Sensitivity for all activities at ±10%
#' risk_sensitivity(pct = 10)
#'
#' # Activities with the largest rank uncertainty
#' risk_sensitivity() |> dplyr::arrange(dplyr::desc(rank_change))
risk_sensitivity <- function(activity = NULL, pct = 20) {
  checkmate::assert_number(pct, lower = 0, upper = 100, finite = TRUE)
  if (pct <= 0 || pct >= 100) {
    cli::cli_abort(c(
      "{.arg pct} must be strictly between 0 and 100.",
      "x" = "Got {.val {pct}}."
    ))
  }
  if (!is.null(activity)) {
    checkmate::assert_character(activity, min.len = 1, any.missing = FALSE)
  }

  mult <- pct / 100

  # Pull all activities from common_risks() as the source of truth
  all_risks <- common_risks()

  # Validate the requested activity names before proceeding
  if (!is.null(activity)) {
    missing_acts <- setdiff(activity, all_risks$activity)
    if (length(missing_acts) > 0) {
      cli::cli_abort(c(
        "Activity not found in {.fn common_risks}:",
        "x" = "{.val {missing_acts}}",
        "i" = "Use {.fn common_risks} to see available activity names."
      ))
    }
  }

  # Per-activity perturbation ranks: for each activity i, only x[i] is
  # scaled by (1 +/- mult); all others stay at baseline. Re-ranking gives
  # where i would sit if its estimate were at the low or high bound.
  # (Uniform scaling preserves relative order => rank_change = 0 always.)
  x <- all_risks[["micromorts"]]
  n <- length(x)
  rank_base    <- rank(-x, ties.method = "min")
  rank_at_low  <- vapply(seq_len(n), function(i) {
    v <- x; v[i] <- x[i] * (1 - mult)
    rank(-v, ties.method = "min")[i]
  }, integer(1L))
  rank_at_high <- vapply(seq_len(n), function(i) {
    v <- x; v[i] <- x[i] * (1 + mult)
    rank(-v, ties.method = "min")[i]
  }, integer(1L))

  all_risks <- tibble::tibble(
    activity        = all_risks[["activity"]],
    micromorts_base = x,
    micromorts_low  = x * (1 - mult),
    micromorts_high = x * (1 + mult),
    rank_base       = rank_base,
    rank_change     = abs(rank_at_high - rank_at_low)
  )

  # Filter to requested activity if supplied.
  # Capture the parameter into a local to avoid dplyr masking it with the
  # column of the same name inside filter().
  activity_filter <- activity
  if (!is.null(activity_filter)) {
    all_risks <- all_risks |>
      dplyr::filter(.data$activity %in% .env$activity_filter)
  }

  all_risks
}
