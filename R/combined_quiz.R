# Conversion constant: 1 micromort ≈ 0.7 microlives at age 40
# Rationale: 1 micromort = 30 min × LLE(1e-6) / (30 min per microlife)
# At 40 years old, LLE ≈ 21 minutes, and 21/30 ≈ 0.7
MICROMORT_TO_MICROLIFE <- 0.7


#' Generate cross-domain quiz pairs comparing acute and chronic risks
#'
#' Creates candidate question pairs mixing acute risks from [common_risks()]
#' (micromorts per event) with chronic risks from [chronic_risks()] (microlives
#' per day), converting both to a common microlife scale so they can be
#' directly compared. Each pair pits one acute activity against one chronic
#' lifestyle factor and asks which has a larger total impact over
#' `time_period_days`.
#'
#' The conversion from micromorts to microlives uses the factor
#' `0.7` (1 micromort ≈ 0.7 microlives at age 40). Chronic impact over the
#' time period is `abs(microlives_per_day) × time_period_days`.
#'
#' @param n Integer. Number of pairs to generate. Default `10`.
#' @param time_period_days Numeric. Time period for chronic risk accumulation.
#'   Default `365` (1 year). For chronic risks, the cumulative impact is
#'   `abs(microlives_per_day) × time_period_days`.
#' @param seed Integer or `NULL`. Random seed for reproducibility. Default
#'   `NULL` (random each call).
#' Acute risks with `period_type == "event"` (true one-off events such as one
#' expedition or one base jump) keep their raw micromort value. Acute risks
#' with period type day/hour/month/year represent a repeatable rate of
#' exposure and are projected to `time_period_days` via
#' `micromorts_per_day_raw × time_period_days` before conversion to microlives.
#' `period_type == "period"` rows are split by their `period` string: a plain
#' "N weeks (YEAR)" surveillance-rate phrasing (e.g. "11 weeks (2022)") scales
#' the same as day/hour/month/year, while a "per N weeks"/"per N months"
#' bounded-window phrasing (e.g. "per 8 weeks" for a specific historical
#' interval) keeps its raw micromort value like an event row. The unrounded
#' column (`micromorts_per_day_raw`) is used rather than the display-rounded
#' `micromorts_per_day` to prevent low-rate annual/monthly rows from
#' collapsing to zero after rounding (e.g. 0.003 µm/day rounds to 0.00).
#'
#' @return A tibble with columns:
#'   - `activity_a`, `type_a` ("acute"), `value_a` (raw micromorts as stored),
#'     `unit_a` ("micromorts"), `category_a`, `period_a`,
#'     `period_type_a` (one of "event", "day", "hour", "month", "year",
#'     "period"), `effective_micromorts_a` (raw value for "event" rows and
#'     bounded-window "period" rows; `micromorts_per_day_raw ×
#'     time_period_days` otherwise)
#'   - `factor_b`, `type_b` ("chronic"), `value_b`, `unit_b` ("microlives/day"),
#'     `category_b`, `direction_b`
#'   - `common_unit` ("microlives"), `common_value_a`
#'     (`effective_micromorts_a × 0.7`), `common_value_b`
#'   - `correct_answer` ("a" or "b" — whichever has higher impact in common
#'     unit)
#'   - `ratio` (larger / smaller common value)
#'   - `explanation` describing both values and the conversion
#'
#' @examples
#' pairs <- combined_quiz_pairs(n = 5, seed = 42)
#' pairs[, c("activity_a", "factor_b", "correct_answer", "ratio")]
#'
#' # One year time period (default)
#' pairs_year <- combined_quiz_pairs(n = 10, time_period_days = 365, seed = 1)
#'
#' @export
combined_quiz_pairs <- function(n = 10, time_period_days = 365, seed = NULL) {
  checkmate::assert_int(n, lower = 1L)
  checkmate::assert_number(time_period_days, lower = 1)
  checkmate::assert_int(seed, null.ok = TRUE)

  if (!is.null(seed)) set.seed(seed)

  # ---- Acute risks ----
  acute <- common_risks()
  acute <- acute[acute$micromorts > 0, ]

  # Scale acute risk to the comparison window:
  # - Genuine repeatable rates (period_type in day/hour/month/year): project to
  #   `time_period_days` via the unrounded `micromorts_per_day_raw`. Using the
  #   unrounded value prevents low-rate annual/monthly rows from collapsing to
  #   0 after rounding, which would produce wrong quiz values and wrong ratios.
  # - `period_type == "period"` is NOT a single homogeneous case — it covers
  #   two different phrasings of `period` that parse_period_type() cannot
  #   currently tell apart, and each needs opposite treatment:
  #     (a) plain "N weeks (YEAR)" surveillance-rate rows, e.g. "11 weeks
  #         (2022)" (CDC MMWR age-stratified COVID mortality) — these ARE
  #         repeatable rates ("this is your risk for any 11-week window while
  #         unvaccinated") and must scale the same as day/hour/month/year, via
  #         `micromorts_per_day_raw * time_period_days`.
  #     (b) "per N weeks"/"per N months" bounded-window rows, e.g.
  #         "per 8 weeks" for "Living in NYC COVID-19 (Mar-May 2020)" — the
  #         activity name pins this to a specific historical interval that
  #         already happened and is not repeatable; scaling it inflates it
  #         (e.g. 50µm/8-weeks -> 228µm/year). Use raw micromorts as-is, same
  #         as event-type rows.
  #   Distinguish (a) from (b) by the leading "per " token, which only
  #   appears on the bounded-window phrasing.
  # - Event-type rows: the row already represents a complete one-off total
  #   (e.g. "one expedition", "one jump"). Use raw micromorts as-is.
  # Without any distinction, chronic-rate rows (e.g. "Living one day in
  # Lesotho" at 463 µm/day) were silently treated as one-off events; with
  # the day/hour/month/year vs event split, bounded `period` rows were still
  # wrongly conflated with rate `period` rows. See roborev clusters
  # #934/#3523.
  period_is_bounded_window <- acute$period_type == "period" &
    grepl("^per\\s", acute$period)
  scales_with_time <- acute$period_type %in% c("day", "hour", "month", "year") |
    (acute$period_type == "period" & !period_is_bounded_window)
  effective_micromorts <- ifelse(
    scales_with_time,
    acute$micromorts_per_day_raw * time_period_days,
    acute$micromorts
  )

  acute_common <- tibble::tibble(
    activity_a = acute$activity,
    type_a = "acute",
    value_a = acute$micromorts,
    unit_a = "micromorts",
    category_a = acute$category,
    period_a = acute$period,
    period_type_a = acute$period_type,
    effective_micromorts_a = effective_micromorts,
    common_value_a = effective_micromorts * MICROMORT_TO_MICROLIFE
  )

  # ---- Chronic risks ----
  chronic <- chronic_risks()
  # Exclude extreme outliers (>10 ml/day) that make every pair trivial
  chronic <- chronic[abs(chronic$microlives_per_day) <= 10, ]

  # Cumulative microlife impact over time_period_days
  chronic_common <- tibble::tibble(
    factor_b = chronic$factor,
    type_b = "chronic",
    value_b = chronic$microlives_per_day,
    unit_b = "microlives/day",
    category_b = chronic$category,
    direction_b = chronic$direction,
    common_value_b = abs(chronic$microlives_per_day) * time_period_days
  )

  # ---- Generate all valid pairs ----
  n_acute <- nrow(acute_common)
  n_chronic <- nrow(chronic_common)

  if (n_acute == 0L || n_chronic == 0L) {
    cli::cli_abort(c(
      "x" = "Not enough data to generate combined quiz pairs.",
      "i" = "acute: {n_acute} rows, chronic: {n_chronic} rows"
    ))
  }

  # Build full Cartesian product of valid pairs
  acute_idx <- rep(seq_len(n_acute), each = n_chronic)
  chronic_idx <- rep(seq_len(n_chronic), times = n_acute)

  candidates <- tibble::tibble(
    activity_a = acute_common$activity_a[acute_idx],
    type_a = acute_common$type_a[acute_idx],
    value_a = acute_common$value_a[acute_idx],
    unit_a = acute_common$unit_a[acute_idx],
    category_a = acute_common$category_a[acute_idx],
    period_a = acute_common$period_a[acute_idx],
    period_type_a = acute_common$period_type_a[acute_idx],
    effective_micromorts_a = acute_common$effective_micromorts_a[acute_idx],
    common_value_a = acute_common$common_value_a[acute_idx],
    factor_b = chronic_common$factor_b[chronic_idx],
    type_b = chronic_common$type_b[chronic_idx],
    value_b = chronic_common$value_b[chronic_idx],
    unit_b = chronic_common$unit_b[chronic_idx],
    category_b = chronic_common$category_b[chronic_idx],
    direction_b = chronic_common$direction_b[chronic_idx],
    common_value_b = chronic_common$common_value_b[chronic_idx]
  )

  # ---- Filter: require ratio 1.1–10 for non-trivial pairs ----
  candidates$ratio <- pmax(candidates$common_value_a, candidates$common_value_b) /
    pmin(candidates$common_value_a, candidates$common_value_b)

  candidates <- candidates[
    is.finite(candidates$ratio) &
      candidates$ratio >= 1.1 &
      candidates$ratio <= 10,
  ]

  if (nrow(candidates) == 0L) {
    cli::cli_abort(c(
      "x" = "No valid pairs found after filtering (ratio 1.1-10).",
      "i" = "Try adjusting {.arg time_period_days} or using a different seed."
    ))
  }

  # Shuffle before greedy selection for variety across calls with different seeds
  candidates <- candidates[sample(nrow(candidates)), ]

  # Greedy selection: each activity/factor appears at most 2 times
  candidates <- candidates[order(candidates$ratio), ]
  selected <- logical(nrow(candidates))
  item_counts <- list()
  max_pairs <- n

  for (i in seq_len(nrow(candidates))) {
    if (sum(selected) >= max_pairs) break
    a <- candidates$activity_a[i]
    b <- candidates$factor_b[i]
    ca <- if (is.null(item_counts[[a]])) 0L else item_counts[[a]]
    cb <- if (is.null(item_counts[[b]])) 0L else item_counts[[b]]
    if (ca < 2L && cb < 2L) {
      selected[i] <- TRUE
      item_counts[[a]] <- ca + 1L
      item_counts[[b]] <- cb + 1L
    }
  }
  candidates <- candidates[selected, ]

  if (nrow(candidates) == 0L) {
    cli::cli_abort(c(
      "x" = "Could not select {n} pairs after greedy deduplication.",
      "i" = "Reduce {.arg n} or use a different seed."
    ))
  }

  # ---- Correct answer: which has higher common_value ----
  candidates$correct_answer <- ifelse(
    candidates$common_value_a >= candidates$common_value_b, "a", "b"
  )
  candidates$common_unit <- "microlives"

  # ---- Explanation ----
  acute_phrase <- ifelse(
    candidates$period_type_a == "event",
    paste0(
      candidates$activity_a, " (acute) carries ",
      round(candidates$value_a, 2), " micromorts (one-off) \u2248 ",
      round(candidates$common_value_a, 1), " microlives"
    ),
    paste0(
      candidates$activity_a, " (acute, ", candidates$period_a, ") carries ",
      round(candidates$value_a, 2), " micromorts \u2192 over ",
      round(time_period_days), " days = ",
      round(candidates$effective_micromorts_a, 1), " micromorts \u2248 ",
      round(candidates$common_value_a, 1), " microlives"
    )
  )

  candidates$explanation <- paste0(
    acute_phrase, ". ",
    candidates$factor_b,
    " (chronic) costs/gains ",
    abs(candidates$value_b),
    " microlives/day \u00d7 ",
    round(time_period_days),
    " days = ",
    round(candidates$common_value_b, 1),
    " microlives total. ",
    ifelse(
      candidates$correct_answer == "a",
      paste0(candidates$activity_a, " has the larger impact."),
      paste0(candidates$factor_b, " has the larger impact.")
    )
  )

  # ---- Final column selection and shuffle ----
  result <- candidates[sample(nrow(candidates)), ]
  rownames(result) <- NULL

  col_order <- c(
    "activity_a", "type_a", "value_a", "unit_a", "category_a", "period_a",
    "period_type_a", "effective_micromorts_a",
    "factor_b", "type_b", "value_b", "unit_b", "category_b", "direction_b",
    "common_unit", "common_value_a", "common_value_b",
    "correct_answer", "ratio", "explanation"
  )
  tibble::as_tibble(result[, col_order])
}


#' Export combined quiz pairs to CSV for Shinylive
#'
#' Generates a representative set of combined quiz pairs and writes them to
#' `inst/extdata/combined_quiz_pairs.csv`. The Shinylive combined quiz can
#' read this CSV directly without requiring R computation in the browser.
#'
#' @param n Integer. Number of pairs to export. Default `50`.
#' @param time_period_days Numeric. Time period for chronic risk accumulation.
#'   Default `365` (1 year).
#' @param seed Integer. Random seed for reproducibility. Default `42`.
#' @param path Character. Output file path. Default writes to
#'   `inst/extdata/combined_quiz_pairs.csv` under the package root.
#' @return Path to the written CSV (invisibly).
#'
#' @examples
#' \dontrun{
#' export_combined_quiz_csv()
#' }
#'
#' @export
export_combined_quiz_csv <- function(n = 50L,
                                      time_period_days = 365,
                                      seed = 42L,
                                      path = NULL) {
  checkmate::assert_int(n, lower = 1L)
  checkmate::assert_number(time_period_days, lower = 1)
  checkmate::assert_int(seed, lower = 1L)

  if (is.null(path)) {
    pkg_root <- tryCatch(
      rprojroot::find_root(rprojroot::is_r_package),
      error = function(e) "."
    )
    path <- file.path(pkg_root, "inst", "extdata", "combined_quiz_pairs.csv")
  }

  pairs <- combined_quiz_pairs(n = n, time_period_days = time_period_days,
                                seed = seed)
  utils::write.csv(pairs, path, row.names = FALSE)
  cli::cli_inform(c(
    "v" = "Wrote {nrow(pairs)} combined quiz pairs to {.path {path}}"
  ))
  invisible(path)
}
