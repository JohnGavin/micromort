#' @name compare
#' @title Lifestyle Comparison Functions
#' @description Compare lifestyle interventions in microlives.

box::use(../data[load_chronic_risks])

#' Compare Lifestyle Interventions
#'
#' Compare the impact of multiple lifestyle changes in microlives.
#'
#' @param interventions Named list of interventions. Each element should have:
#'   \describe{
#'     \item{factor}{Name of the chronic risk factor}
#'     \item{change}{Numeric change (e.g., -5 for losing 5kg)}
#'   }
#' @return A tibble comparing annual and lifetime effects
#' @export
#' @examples
#' \dontrun{
#' compare_interventions(list(
#'   "Lose weight" = list(factor = "Being 5 kg overweight", change = -1),
#'   "Quit smoking" = list(factor = "Smoking 10 cigarettes", change = -1)
#' ))
#' }
compare_interventions <- function(interventions) {
  chronic <- load_chronic_risks()

  results <- purrr::imap(interventions, function(int, name) {
    factor_data <- chronic[chronic$factor == int$factor, ]

    if (nrow(factor_data) == 0) {
      cli::cli_warn("Factor not found: {int$factor}")
      return(NULL)
    }

    ml_per_day <- factor_data$microlives_per_day[1]
    change <- int$change

    # If factor is a "loss" and change is negative, user is removing the loss
    # e.g., quitting smoking removes -5 ml/day -> gains +5 ml/day
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
#' Calculate how much of one bad habit compensates for another.
#'
#' @param bad_habit Factor name of the bad habit
#' @param good_habit Factor name of the compensating behavior
#' @return A tibble showing the tradeoff ratio
#' @export
#' @examples
#' \dontrun{
#' # How much exercise to offset one cigarette?
#' lifestyle_tradeoff("Smoking 2 cigarettes", "20 min moderate exercise")
#' }
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
