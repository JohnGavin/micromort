# Suppress R CMD check notes for NSE column references
utils::globalVariables(c(
  "annual_micromorts", "annual_msv", "regulatory_limit_msv",
  "xray_equivalents_per_year", "patient_micromorts",
  "occupational_micromorts", "occupation", "xray_count",
  "career_years"
))

#' Chest X-ray micromorts from the single home (atomic_risks())
#'
#' @param ar Output of [atomic_risks()]; computed if omitted.
#' @return Single numeric: micromorts for one chest X-ray.
#' @noRd
chest_xray_micromorts <- function(ar = atomic_risks()) {
  value <- ar$micromorts[ar$activity == "Chest X-ray (radiation per scan)"]
  if (length(value) != 1L || is.na(value)) {
    cli::cli_abort(c(
      "x" = "Expected exactly one non-missing chest X-ray row in {.fn atomic_risks}.",
      "i" = "Found {length(value)} row{?s}."
    ))
  }
  value
}

#' Radiation Exposure Profiles
#'
#' Compares annual and cumulative radiation exposure across occupational,
#' passenger, and environmental profiles. Uses the Linear No-Threshold (LNT)
#' model for dose-to-risk conversion.
#'
#' @param milestones Integer vector of career/exposure years for cumulative
#'   columns. Default `c(10, 20, 40)`.
#' @return A tibble with columns: activity_id, activity, category,
#'   annual_msv, annual_micromorts, milestone columns (mm_Ny for each N),
#'   regulatory_limit_msv, limit_basis, xray_equivalents_per_year.
#'   `regulatory_limit_msv` is 20 for occupational rows and `NA` for rows with
#'   no applicable limit (natural background, radon, passenger cosmic
#'   radiation, patient medical exposure): ICRP 103 dose limits apply only to
#'   planned exposure situations. `limit_basis` states which case applies.
#' @export
#' @seealso [atomic_risks()], [patient_radiation_comparison()]
#' @references
#' ICRP Publication 103 (2007). Recommendations of the International
#' Commission on Radiological Protection.
#'
#' Brenner DJ, Hall EJ (2007). "Computed Tomography — An Increasing Source
#' of Radiation Exposure." NEJM 357:2277-2284.
#'
#' UNSCEAR 2020. Sources, Effects and Risks of Ionizing Radiation.
#' @examples
#' radiation_profiles()
#' radiation_profiles(milestones = c(5, 25, 50))
radiation_profiles <- function(milestones = c(10, 20, 40)) {
  ar <- atomic_risks()
  annual <- ar[grepl("_annual$", ar$activity_id), ]

  # Annual dose in mSv: inverse of msv_to_micromorts() (single factor home)
  result <- tibble::tibble(
    activity_id = annual$activity_id,
    activity = annual$activity,
    category = annual$category,
    annual_msv = round(micromorts_to_msv(annual$micromorts), 4),
    annual_micromorts = annual$micromorts
  )

  # Add milestone columns (LNT: cumulative = annual x years)
  for (m in milestones) {
    col_name <- paste0("mm_", m, "y")
    result[[col_name]] <- result$annual_micromorts * m
  }

  # Regulatory limits (ICRP 103). The dose limits apply ONLY to planned
  # exposure situations. Natural background, home radon, altitude, passenger
  # (incl. frequent-flyer) cosmic radiation and patient medical exposure are
  # not covered by a limit (radon is managed by reference levels, medical
  # exposure of patients by justification and optimisation), so they get NA.
  # Aircrew are occupational (category "Occupation"), hence 20 mSv. No row
  # here is a planned PUBLIC exposure, so the 1 mSv public limit is unused.
  limit_map <- list(
    Occupation = list(limit = 20, basis = "ICRP 103 occupational limit (planned exposure)"),
    Travel = list(limit = NA_real_, basis = "No limit: passenger exposure is not a planned exposure situation"),
    Environment = list(limit = NA_real_, basis = "No limit: natural source (radon is managed by reference levels)"),
    Medical = list(limit = NA_real_, basis = "No limit: patient medical exposure (justification and optimisation)")
  )
  unknown <- setdiff(unique(result$category), names(limit_map))
  if (length(unknown) > 0) {
    cli::cli_abort(c(
      "x" = "No ICRP limit classification for categor{?y/ies}: {.val {unknown}}.",
      "i" = "Add each to {.code limit_map} in {.fn radiation_profiles}."
    ))
  }
  result$regulatory_limit_msv <- vapply(
    result$category, function(k) limit_map[[k]]$limit, numeric(1), USE.NAMES = FALSE
  )
  result$limit_basis <- vapply(
    result$category, function(k) limit_map[[k]]$basis, character(1), USE.NAMES = FALSE
  )

  # Chest X-ray equivalents per year (value read from atomic_risks())
  result$xray_equivalents_per_year <-
    result$annual_micromorts / chest_xray_micromorts(ar)

  result
}


#' Regulatory-limit insight for the vignette prose
#'
#' Derives, from the regulatory comparison table, the sentence quoted in the
#' risk-equivalence vignette: how far below the occupational limit the rows
#' that HAVE a limit sit (fold range, with the row at each end), plus a clause
#' that rows with `NA` limit (natural, passenger, medical) have no ICRP dose
#' limit because limits apply only to planned exposure situations. A row
#' exactly at its limit is not above it. Fold values are rounded to two
#' significant figures here so the vignette does no arithmetic. Activity names
#' are shown without their trailing parenthetical (avoids doubled brackets).
#'
#' @param reg Data frame with columns `activity`, `category`, `annual_msv`,
#'   `regulatory_limit_msv` (as returned by [radiation_profiles()]).
#' @return A list: `occ_fold_min`, `occ_fold_min_activity`, `occ_fold_max`,
#'   `occ_fold_max_activity`, `occ_limit_msv`, `above_activity`, `text`.
#' @noRd
regulatory_limit_insight <- function(reg) {
  need <- c("activity", "category", "annual_msv", "regulatory_limit_msv")
  miss <- setdiff(need, names(reg))
  if (length(miss) > 0) {
    cli::cli_abort(c(
      "x" = "{.arg reg} is missing column{?s}: {.field {miss}}.",
      "i" = "Expected the output of {.fn radiation_profiles}."
    ))
  }

  has_limit <- !is.na(reg$regulatory_limit_msv)
  occ <- reg[has_limit, , drop = FALSE]
  if (nrow(occ) == 0) {
    cli::cli_abort("{.arg reg} has no rows with a non-missing limit.")
  }
  short <- function(x) trimws(sub("\\s*\\([^()]*\\)\\s*$", "", x))
  fold <- occ$regulatory_limit_msv / occ$annual_msv
  i_min <- which.min(fold)
  i_max <- which.max(fold)
  occ_limit <- unique(occ$regulatory_limit_msv)[1]

  above <- occ[occ$annual_msv > occ$regulatory_limit_msv, , drop = FALSE]
  above_names <- short(above$activity)

  text <- paste0(
    "Occupational doses here range from about ", signif(fold[i_min], 2),
    "x (", short(occ$activity[i_min]), ") to ", signif(fold[i_max], 2),
    "x (", short(occ$activity[i_max]), ") below the ", occ_limit,
    " mSv occupational limit",
    if (length(above_names) > 0) {
      paste0("; above the limit: ", paste(above_names, collapse = ", "))
    } else {
      ""
    },
    ". Natural background, home radon and passenger-flight exposures have ",
    "no ICRP dose limit, because ICRP 103 limits apply to planned exposure ",
    "situations only."
  )

  list(
    occ_fold_min = signif(fold[i_min], 2),
    occ_fold_min_activity = short(occ$activity[i_min]),
    occ_fold_max = signif(fold[i_max], 2),
    occ_fold_max_activity = short(occ$activity[i_max]),
    occ_limit_msv = occ_limit,
    above_activity = above_names,
    text = text
  )
}


#' Patient vs Occupational Radiation Comparison
#'
#' Cross-tabulates patient X-ray exposure against occupational career
#' radiation to reveal equivalences. Both sides are converted to micromorts
#' with the same dose-to-risk factor, so `ratio` equals the ratio of the two
#' cumulative doses in mSv. Values come from [atomic_risks()]; none are
#' hand-typed here.
#'
#' @param xray_counts Integer vector of patient X-ray counts to compare.
#'   Default `c(1, 10, 100)`.
#' @param career_years Integer vector of occupational career durations.
#'   Default `c(10, 20, 40)`.
#' @return A tibble with columns: occupation, xray_count, career_years,
#'   patient_micromorts, occupational_micromorts, ratio.
#' @export
#' @seealso [radiation_profiles()], [atomic_risks()]
#' @examples
#' patient_radiation_comparison()
#' patient_radiation_comparison(xray_counts = c(50, 200), career_years = c(5, 30))
patient_radiation_comparison <- function(
  xray_counts = c(1, 10, 100),
  career_years = c(10, 20, 40)
) {
  # Chest X-ray micromorts: single home is the atomic_risks() med_rad row
  xray_mm <- chest_xray_micromorts()

  # Get occupational profiles
  rp <- radiation_profiles(milestones = integer(0))
  occupational <- rp[rp$category == "Occupation", ]

  # Cross-tabulate
  grid <- expand.grid(
    occupation = occupational$activity,
    xray_count = xray_counts,
    career_years = career_years,
    stringsAsFactors = FALSE
  )

  # Look up annual micromorts for each occupation
  occ_lookup <- stats::setNames(
    occupational$annual_micromorts,
    occupational$activity
  )

  result <- tibble::as_tibble(grid) |>
    dplyr::mutate(
      patient_micromorts = xray_count * xray_mm,
      occupational_micromorts = occ_lookup[occupation] * career_years,
      ratio = round(patient_micromorts / occupational_micromorts, 2)
    )

  result
}
