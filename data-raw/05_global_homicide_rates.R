# data-raw/05_global_homicide_rates.R
# Source: UNODC Global Study on Homicide 2023
# https://www.unodc.org/unodc/en/data-and-analysis/global-study-on-homicide.html
#
# Conversion: rate_per_100k_year / 365 * 10 = micromorts/day
#   (rate per 100k → per million = *10, then /365 for daily)
#
# This script documents the derivation; it does NOT download data at runtime.
# Values are hardcoded in R/atomic_risks.R.

library(tibble)

homicide <- tribble(
  ~country, ~iso2, ~unodc_rate_per_100k_year, ~mm_per_day,
  "United States", "US",  6.4, 0.18,
  "United Kingdom", "UK",  1.2, 0.03,
  "Japan",          "JP",  0.3, 0.008,
  "India",          "IN",  3.0, 0.08,
  "Brazil",         "BR", 22.5, 0.62,
  "Honduras",       "HN", 38.9, 1.07
)

# Verify derivation
homicide$check_mm_day <- round(
  homicide$unodc_rate_per_100k_year / 365 * 10, 3
)

# Note: Rates are national averages; urban/rural variation is substantial.
# Honduras included as a high-homicide reference point.
# condition_variable = "country" with ISO-2 codes.

homicide
