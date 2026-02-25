#' @name hazard
#' @title Hazard Rate Calculations
#' @description Calculate daily mortality risk and risk budgets by age.

#' Daily Hazard Rate by Age
#'
#' Calculates the daily probability of death based on age using
#' the Gompertz-Makeham mortality model.
#'
#' @param age Age in years
#' @param sex "male" or "female" (default: "male")
#' @return A tibble with daily mortality probability and micromorts
#' @export
#' @examples
#' \dontrun{
#' daily_hazard_rate(30)
#' daily_hazard_rate(65, "female")
#' }
daily_hazard_rate <- function(age, sex = "male") {
  # Gompertz-Makeham parameters (approximate for developed countries)
  # Based on Human Mortality Database estimates
  if (sex == "male") {
    a <- 0.0001  # Background mortality
    b <- 0.00005  # Initial mortality
    c <- 0.085   # Rate of mortality increase
  } else {
    a <- 0.00008
    b <- 0.00003
    c <- 0.080
  }

  # Daily probability of death: q(x) = a + b * exp(c * x)
  daily_prob <- (a + b * exp(c * age)) / 365

  # Convert to micromorts (1 micromort = 1e-6 probability)
  micromorts <- daily_prob * 1e6

  # Microlives consumed: how much life expectancy lost per day
  # At age x with remaining life expectancy E(x), each day costs
  # approximately 1 + (daily_prob * remaining_years * 365 / 48) microlives
  remaining_years <- pmax(85 - age, 1)  # Simple approximation
  microlives_consumed <- round(48 * daily_prob * remaining_years * 365 / 48, 2)

  tibble::tibble(
    age = age,
    sex = sex,
    daily_prob = daily_prob,
    micromorts = round(micromorts, 1),
    microlives_consumed = microlives_consumed,
    interpretation = sprintf(
      "At age %d (%s): %.1f micromorts/day baseline risk",
      age, sex, micromorts
    )
  )
}

#' Annual Risk Budget
#'
#' Calculate total annual micromort exposure from a list of activities.
#'
#' @param activities Named vector of activity frequencies per year.
#'   Names should match activity names in the acute risks dataset.
#' @param age Optional age for baseline risk calculation
#' @return A tibble with risk budget breakdown
#' @export
#' @examples
#' \dontrun{
#' annual_risk_budget(c(
#'   "Skydiving (per jump, US)" = 10,
#'   "Scuba diving (per dive, trained)" = 20,
#'   "Running a marathon" = 2
#' ), age = 35)
#' }
annual_risk_budget <- function(activities, age = NULL) {
  box::use(../data[load_acute_risks])
  acute <- load_acute_risks()

  results <- purrr::imap(activities, function(freq, act) {
    act_data <- acute[acute$activity == act, ]

    if (nrow(act_data) == 0) {
      cli::cli_warn("Activity not found: {act}")
      return(tibble::tibble(
        activity = act,
        frequency = freq,
        micromorts_per = NA_real_,
        annual_micromorts = NA_real_
      ))
    }

    tibble::tibble(
      activity = act,
      frequency = freq,
      micromorts_per = act_data$micromorts[1],
      annual_micromorts = freq * act_data$micromorts[1]
    )
  })

  budget <- dplyr::bind_rows(results)

  # Add baseline aging if age provided
  if (!is.null(age)) {
    baseline <- daily_hazard_rate(age)
    baseline_annual <- baseline$micromorts * 365

    budget <- dplyr::bind_rows(
      tibble::tibble(
        activity = sprintf("Baseline (age %d)", age),
        frequency = 365,
        micromorts_per = baseline$micromorts,
        annual_micromorts = baseline_annual
      ),
      budget
    )
  }

  budget <- budget |>
    dplyr::mutate(
      pct_of_total = round(annual_micromorts / sum(annual_micromorts, na.rm = TRUE) * 100, 1)
    )

  # Add summary row
  total <- tibble::tibble(
    activity = "TOTAL",
    frequency = NA_real_,
    micromorts_per = NA_real_,
    annual_micromorts = sum(budget$annual_micromorts, na.rm = TRUE),
    pct_of_total = 100
  )

  dplyr::bind_rows(budget, total)
}
