#' Convert Probability to Micromorts
#'
#' A micromort represents a one-in-a-million chance of death.
#' This function converts a raw probability of death into micromorts.
#'
#' @param prob Numeric. Probability of death (0 to 1).
#' @return Numeric value in micromorts.
#' @family conversion
#' @seealso [as_probability()], [as_microlife()], [value_of_micromort()]
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
#' @family conversion
#' @seealso [as_micromort()], [as_microlife()]
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
#' @family conversion
#' @seealso [as_micromort()], [lle()]
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
#' @family conversion
#' @seealso [as_micromort()], [as_microlife()], [value_of_micromort()]
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

#' Convert Minutes to Microlives
#'
#' A microlife represents a 30-minute change in life expectancy per day.
#' This function converts minutes of life expectancy change to microlives.
#'
#' @param minutes Numeric. Life expectancy change in minutes.
#'   - Positive values = life gained (e.g., from exercise)
#'   - Negative values = life lost (e.g., from smoking)
#' @return Numeric. Value in microlives (same sign as input).
#' @details
#' **Unit definition:** 1 microlife = 30 minutes of life expectancy change per day.
#'
#' **Sign convention:**
#' - Negative microlives = life expectancy loss (harmful)
#' - Positive microlives = life expectancy gain (beneficial)
#'
#' @family conversion
#' @seealso [as_micromort()], [lle()], [chronic_risks()]
#' @export
#' @examples
#' # Smoking 20 cigarettes/day: each costs ~30 mins = -600 mins total
#' as_microlife(-20 * 30)  # -20 microlives (life lost)
#'
#' # Exercise 20 mins/day: gains ~60 mins life expectancy
#' as_microlife(60)        # +2 microlives (life gained)
#'
#' # Being 5kg overweight: costs ~30 mins/day
#' as_microlife(-30)       # -1 microlife (life lost)
as_microlife <- function(minutes) {
  checkmate::assert_numeric(minutes)
  minutes / 30
}
