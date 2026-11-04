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
#'   regulatory_limit_msv, xray_equivalents_per_year.
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

  # Regulatory limits (ICRP 103)
  result$regulatory_limit_msv <- dplyr::if_else(
    result$category == "Occupation",
    20,  # 20 mSv/yr occupational limit
    1    # 1 mSv/yr public limit
  )

  # Chest X-ray equivalents per year (value read from atomic_risks())
  result$xray_equivalents_per_year <-
    result$annual_micromorts / chest_xray_micromorts(ar)

  result
}


#' Patient vs Occupational Radiation Comparison
#'
#' Cross-tabulates patient X-ray exposure against occupational career
#' radiation to reveal surprising equivalences. For example, 100 lifetime
#' chest X-rays (10 micromorts) exceeds a 40-year X-ray technician career
#' (2 micromorts).
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
