#' Convert Probability to Micromorts
#'
#' A micromort represents a one-in-a-million chance of death.
#' This function converts a raw probability of death into micromorts.
#'
#' @param prob Numeric. Probability of death (0 to 1).
#' @return Numeric value in micromorts.
#' @export
#' @examples
#' as_micromort(1/1000000) # 1 micromort
#' as_micromort(1/10000)   # 100 micromorts
as_micromort <- function(prob) {
  checkmate::assert_numeric(prob, lower = 0, upper = 1)
  prob * 1e6
}

#' Convert Micromorts to Probability
#'
#' @param micromorts Numeric. Risk in micromorts.
#' @return Numeric probability.
#' @export
#' @examples
#' as_probability(1) # 1e-6
as_probability <- function(micromorts) {
  checkmate::assert_numeric(micromorts, lower = 0)
  micromorts / 1e6
}

#' Value of a Statistical Life (VSL) to Micromort Value
#'
#' Calculates the monetary value of one micromort based on the Value of a Statistical Life (VSL).
#'
#' @param vsl Numeric. Value of a Statistical Life (default $10,000,000).
#' @return Numeric value of one micromort.
#' @export
#' @examples
#' value_of_micromort(10000000) # $10
value_of_micromort <- function(vsl = 10000000) {
  checkmate::assert_numeric(vsl, lower = 0)
  vsl / 1e6
}

#' Loss of Life Expectancy (LLE)
#'
#' Estimates the average time lost from a lifespan due to a specific risk.
#'
#' @param prob Numeric. Probability of death.
#' @param life_expectancy Numeric. Remaining life expectancy in years (default 40).
#' @return Numeric. Loss of life expectancy in seconds, minutes, or days (estimated).
#' @export
#' @examples
#' lle(1/1000000, 40) # Loss from 1 micromort
lle <- function(prob, life_expectancy = 40) {
  checkmate::assert_numeric(prob, lower = 0, upper = 1)
  checkmate::assert_numeric(life_expectancy, lower = 0)
  
  # Simple calculation: prob * remaining_life
  # This is a simplification; true LLE requires actuarial tables.
  loss_years <- prob * life_expectancy
  loss_days <- loss_years * 365.25
  loss_minutes <- loss_days * 24 * 60
  
  structure(loss_minutes, class = c("micromort_lle", "numeric"), units = "minutes")
}

#' Convert to Microlives
#'
#' A microlife represents a 30-minute change in life expectancy.
#' This function estimates the impact of a chronic risk in microlives.
#'
#' @param minutes_lost Numeric. Life expectancy lost in minutes.
#' @return Numeric. Value in microlives.
#' @export
#' @examples
#' as_microlife(30) # 1 microlife
as_microlife <- function(minutes_lost) {
  checkmate::assert_numeric(minutes_lost)
  minutes_lost / 30
}
