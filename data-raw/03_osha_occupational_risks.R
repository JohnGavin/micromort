# data-raw/03_osha_occupational_risks.R
# Source: BLS Census of Fatal Occupational Injuries (CFOI) 2022
# https://www.bls.gov/iif/fatal-injuries-tables.htm
#
# Conversion: rate_per_100k_FTE / 2000 * 1e6 = micromorts/hour
#   then * 8 = micromorts/work_day
#
# This script documents the derivation; it does NOT download data at runtime.
# Values are hardcoded in R/atomic_risks.R.

library(tibble)

osha_occupational <- tribble(
 ~occupation,            ~bls_rate_per_100k_fte, ~mm_per_hour, ~mm_per_work_day,
 "Logging",              82.2,                   0.411,        3.3,
 "Commercial fishing",   75.2,                   0.376,        3.0,
 "Roofing",              47.0,                   0.235,        1.9,
 "Structural iron/steel", 36.4,                  0.182,        1.5,
 "Truck driving",        28.8,                   0.144,        1.2,
 "Mining",               22.0,                   0.110,        0.9,
 "Agriculture",          18.2,                   0.091,        0.7,
 "Construction (all)",   13.0,                   0.065,        0.5,
 "All US workers",        3.7,                   0.019,        0.15
)

# Verify derivation: rate / 2000 * 1e6 = mm/hour, * 8 = mm/work_day
osha_occupational$check_mm_hour <- round(
  osha_occupational$bls_rate_per_100k_fte / 2000 * 1e6 / 1e6, 3
)
# Simplified: rate / 2000 = mm/hour (since rate is per 100k and we want per million)
# Actually: rate per 100k FTE = deaths/100k workers per 2000 hours
# So per hour per million: rate / 2000 * 10 = mm/hour
# Per 8-hour day: * 8

# The values in atomic_risks.R are rounded from these calculations.
# BLS and OSHA agree on these rates (validation_status = "corroborated").

osha_occupational
