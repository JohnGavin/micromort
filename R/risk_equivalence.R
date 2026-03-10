#' Risk Equivalence Table
#'
#' Compares a reference activity to all other activities by computing the
#' ratio of micromorts. "How many X-rays equal one skydive?"
#'
#' @param reference Character. Activity name to use as the reference
#'   (denominator). Must match an `activity` value in `risks`.
#' @param risks A tibble with at least `activity` and `micromorts` columns.
#'   Defaults to [common_risks()].
#' @param min_ratio Numeric. Minimum ratio to include (default 0.01).
#' @param max_ratio Numeric. Maximum ratio to include (default `Inf`).
#' @return A tibble with columns: `activity`, `micromorts`, `reference`,
#'   `reference_micromorts`, `ratio`, `equivalence`.
#' @export
#' @seealso [risk_exchange_matrix()]
#' @examples
#' risk_equivalence("Chest X-ray (radiation per scan)")
#' risk_equivalence("Skydiving (US)")
risk_equivalence <- function(reference, risks = NULL, min_ratio = 0.01,
                             max_ratio = Inf) {
  if (is.null(risks)) risks <- common_risks()

  if (!reference %in% risks$activity) {
    cli::cli_abort(c(
      "x" = "Reference activity not found: {.val {reference}}",
      "i" = "Use {.code common_risks()$activity} to see available activities."
    ))
  }

  ref_mm <- risks$micromorts[risks$activity == reference]

  if (ref_mm == 0) {
    cli::cli_abort(c(
      "x" = "Reference activity has 0 micromorts; cannot compute ratios."
    ))
  }

  risks |>
    dplyr::filter(activity != reference) |>
    dplyr::mutate(
      reference = reference,
      reference_micromorts = ref_mm,
      ratio = round(micromorts / ref_mm, 2),
      equivalence = paste0(
        "1 ", activity, " = ",
        format(round(micromorts / ref_mm, 1), scientific = FALSE), " ", reference
      )
    ) |>
    dplyr::filter(ratio >= min_ratio, ratio <= max_ratio) |>
    dplyr::arrange(dplyr::desc(ratio)) |>
    dplyr::select(activity, micromorts, reference, reference_micromorts,
                  ratio, equivalence)
}


#' Risk Exchange Matrix
#'
#' Creates a cross-comparison matrix showing how many of activity B equal
#' one of activity A, for a selected set of activities.
#'
#' @param activities Character vector of activity names to include.
#'   Defaults to a curated set of 10 diverse activities.
#' @param risks A tibble with at least `activity` and `micromorts` columns.
#'   Defaults to [common_risks()].
#' @return A tibble where rows are activities and columns are exchange rates.
#'   Cell (i, j) = "how many of activity j equal one of activity i".
#' @export
#' @seealso [risk_equivalence()]
#' @examples
#' risk_exchange_matrix()
risk_exchange_matrix <- function(activities = NULL, risks = NULL) {
  if (is.null(risks)) risks <- common_risks()

  if (is.null(activities)) {
    # Default curated set covering a range of risk levels
    activities <- c(
      "Chest X-ray (radiation per scan)",
      "Cup of coffee",
      "Crossing a road",
      "Driving (230 miles)",
      "Flying (8h long-haul)",
      "Skiing",
      "Scuba diving, trained",
      "Running a marathon",
      "Skydiving (US)",
      "General anesthesia (emergency)"
    )
  }

  available <- risks$activity
  missing <- setdiff(activities, available)
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "x" = "Activities not found: {.val {missing}}",
      "i" = "Use {.code common_risks()$activity} to see available activities."
    ))
  }

  subset <- risks |>
    dplyr::filter(activity %in% activities) |>
    dplyr::select(activity, micromorts) |>
    dplyr::distinct()

  # Guard against zero-micromort activities producing Inf/NaN
  zero_acts <- subset$activity[subset$micromorts == 0]
  if (length(zero_acts) > 0) {
    cli::cli_abort(c(
      "x" = "Cannot compute exchange rates for zero-micromort activities: {.val {zero_acts}}",
      "i" = "Remove zero-risk activities or use {.fn risk_equivalence} instead."
    ))
  }

  # Build matrix: row i, col j = micromorts_i / micromorts_j
  mm <- subset$micromorts
  names(mm) <- subset$activity
  n <- length(mm)

  mat <- matrix(NA_real_, nrow = n, ncol = n)
  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      mat[i, j] <- round(mm[i] / mm[j], 1)
    }
  }

  result <- tibble::as_tibble(as.data.frame(mat))
  names(result) <- names(mm)
  result <- dplyr::bind_cols(tibble::tibble(activity = names(mm)), result)

  result
}
