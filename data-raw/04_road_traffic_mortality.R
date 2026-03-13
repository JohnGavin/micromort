# data-raw/04_road_traffic_mortality.R
# Source: WHO Global Status Report on Road Safety 2023
# https://www.who.int/publications/i/item/9789240086517
#
# Conversion: rate_per_100k_year / 365 * 10 = micromorts/day
#   (rate per 100k → per million = *10, then /365 for daily)
#
# This script documents the derivation; it does NOT download data at runtime.
# Values are hardcoded in R/atomic_risks.R.

library(tibble)

road_traffic <- tribble(
  ~country, ~iso2, ~who_rate_per_100k_year, ~mm_per_day,
  "United States",  "US", 12.7, 0.35,
  "United Kingdom", "UK",  2.9, 0.08,
  "Germany",        "DE",  3.6, 0.10,
  "Japan",          "JP",  2.6, 0.07,
  "India",          "IN", 22.8, 0.62,
  "Brazil",         "BR", 18.1, 0.50
)

# Verify derivation
road_traffic$check_mm_day <- round(
  road_traffic$who_rate_per_100k_year / 365 * 10, 2
)

# Note: These are population-level rates (all ages, both sexes).
# Actual individual risk varies by driving exposure, age, and vehicle type.
# condition_variable = "country" with ISO-2 codes.

road_traffic
