#' Compare Lifestyle Interventions
#'
#' Compare the impact of multiple lifestyle changes in microlives.
#' Uses the chronic risks dataset to calculate daily, annual, and
#' lifetime effects of interventions.
#'
#' @param interventions Named list of interventions. Each element should have:
#' \describe{
#'   \item{factor}{Name of the chronic risk factor (must match [chronic_risks()])}
#'   \item{change}{Numeric change multiplier (e.g., -1 to remove the factor)}
#' }
#' @return A tibble comparing effects of each intervention:
#' \describe{
#'   \item{intervention}{Name of the intervention}
#'   \item{factor}{Original factor name}
#'   \item{original_ml_per_day}{Original microlives per day}
#'   \item{change}{Change multiplier applied}
#'   \item{net_ml_per_day}{Net microlives gained/lost per day}
#'   \item{annual_days}{Days of life gained/lost per year}
#'   \item{lifetime_years}{Years of life gained/lost over 57 years}
#' }
#' @family analysis
#' @seealso [lifestyle_tradeoff()], [daily_hazard_rate()], [annual_risk_budget()]
#' @export
#' @examples
#' # Compare quitting smoking vs losing weight
#' compare_interventions(list(
#'   "Quit 10 cigarettes/day" = list(factor = "Smoking 10 cigarettes", change = -1),
#'   "Lose 5kg" = list(factor = "Being 5 kg overweight", change = -1)
#' ))
compare_interventions <- function(interventions) {
  chronic <- load_chronic_risks()

  results <- lapply(names(interventions), function(name) {
    int <- interventions[[name]]
    factor_data <- chronic[chronic$factor == int$factor, ]

    if (nrow(factor_data) == 0) {
      cli::cli_warn("Factor not found: {int$factor}")
      return(NULL)
    }

    ml_per_day <- factor_data$microlives_per_day[1]
    change <- int$change

    # Removing a loss = gaining
    daily_effect <- -ml_per_day * change

    tibble::tibble(
      intervention = name,
      factor = int$factor,
      original_ml_per_day = ml_per_day,
      change = change,
      net_ml_per_day = daily_effect,
      annual_days = round(daily_effect * 365 * 30 / (24 * 60), 1),
      lifetime_years = round(daily_effect * 365 * 57 * 30 / (24 * 60 * 365), 2)
    )
  })

  dplyr::bind_rows(results)
}

#' Calculate Lifestyle Tradeoff
#'
#' Calculate how much of one good habit compensates for a bad habit.
#'
#' @param bad_habit Factor name of the bad habit (from [chronic_risks()])
#' @param good_habit Factor name of the compensating behavior (from [chronic_risks()])
#' @return A tibble showing the tradeoff ratio
#' @family analysis
#' @seealso [compare_interventions()], [chronic_risks()]
#' @export
#' @examples
#' # How much exercise offsets 2 cigarettes?
#' lifestyle_tradeoff("Smoking 2 cigarettes", "20 min moderate exercise")
lifestyle_tradeoff <- function(bad_habit, good_habit) {
  chronic <- load_chronic_risks()

  bad <- chronic[chronic$factor == bad_habit, ]
  good <- chronic[chronic$factor == good_habit, ]

  if (nrow(bad) == 0) {
    cli::cli_abort("Bad habit not found: {bad_habit}")
  }
  if (nrow(good) == 0) {
    cli::cli_abort("Good habit not found: {good_habit}")
  }

  bad_ml <- abs(bad$microlives_per_day[1])
  good_ml <- good$microlives_per_day[1]

  ratio <- bad_ml / good_ml

 tibble::tibble(
    bad_habit = bad_habit,
    bad_ml_per_day = -bad_ml,
    good_habit = good_habit,
    good_ml_per_day = good_ml,
    units_needed = round(ratio, 2),
    interpretation = sprintf(
      "%.1f units of '%s' offset 1 unit of '%s'",
      ratio, good_habit, bad_habit
    )
  )
}

#' Daily Hazard Rate by Age
#'
#' Calculates the daily probability of death based on age using
#' a simplified Gompertz-Makeham mortality model.
#'
#' @param age Age in years
#' @param sex "male" or "female" (default: "male")
#' @return A tibble with:
#' \describe{
#'   \item{age}{Input age}
#'   \item{sex}{Input sex}
#'   \item{daily_prob}{Daily probability of death}
#'   \item{micromorts}{Daily baseline risk in micromorts}
#'   \item{microlives_consumed}{Estimated microlives consumed per day}
#'   \item{interpretation}{Human-readable summary}
#' }
#' @family analysis
#' @seealso [annual_risk_budget()], [compare_interventions()]
#' @export
#' @references
#' Gompertz B (1825). "On the Nature of the Function Expressive of the Law of
#' Human Mortality." Philosophical Transactions of the Royal Society.
#' @examples
#' # Baseline risk at age 30
#' daily_hazard_rate(30)
#'
#' # Compare male vs female at age 65
#' daily_hazard_rate(65, "male")
#' daily_hazard_rate(65, "female")
daily_hazard_rate <- function(age, sex = "male") {
  checkmate::assert_number(age, lower = 0, upper = 120)
  checkmate::assert_choice(sex, c("male", "female"))

  # Gompertz-Makeham parameters (approximate for developed countries)
  if (sex == "male") {
    a <- 0.0001   # Background mortality
    b <- 0.00005  # Initial mortality
    c <- 0.085    # Rate of mortality increase
  } else {
    a <- 0.00008
    b <- 0.00003
    c <- 0.080
  }

  # Annual probability, then daily
  daily_prob <- (a + b * exp(c * age)) / 365
  micromorts <- daily_prob * 1e6

  # Estimate microlives consumed
  remaining_years <- pmax(85 - age, 1)
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
#' @param activities Named numeric vector of activity frequencies per year.
#'   Names should match activity names in [load_acute_risks()].
#' @param age Optional age for baseline risk calculation
#' @return A tibble with risk budget breakdown including:
#' \describe{
#'   \item{activity}{Activity name}
#'   \item{frequency}{Times per year}
#'   \item{micromorts_per}{Micromorts per occurrence}
#'   \item{annual_micromorts}{Total annual micromorts}
#'   \item{pct_of_total}{Percentage of total risk budget}
#' }
#' @family analysis
#' @seealso [daily_hazard_rate()], [load_acute_risks()]
#' @export
#' @examples
#' # Calculate annual risk from recreational activities
#' annual_risk_budget(c(
#'   "Skydiving (US)" = 10,
#'   "Scuba diving, trained" = 20,
#'   "Running a marathon" = 2
#' ), age = 35)
annual_risk_budget <- function(activities, age = NULL) {
  checkmate::assert_numeric(activities, names = "named")

  acute <- load_acute_risks()

  results <- lapply(names(activities), function(act) {
    freq <- activities[[act]]
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

  # Add baseline if age provided
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

  budget$pct_of_total <- round(
    budget$annual_micromorts / sum(budget$annual_micromorts, na.rm = TRUE) * 100, 1
  )

  # Add total row
  total <- tibble::tibble(
    activity = "TOTAL",
    frequency = NA_real_,
    micromorts_per = NA_real_,
    annual_micromorts = sum(budget$annual_micromorts, na.rm = TRUE),
    pct_of_total = 100
  )

  dplyr::bind_rows(budget, total)
}
