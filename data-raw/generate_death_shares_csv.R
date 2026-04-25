## data-raw/generate_death_shares_csv.R
##
## Combines chronic + infectious death CSVs into a single death_shares.csv
## for the death-share treemap vignette (#93).
##
## Run: Rscript data-raw/generate_death_shares_csv.R

library(dplyr)
library(readr)

chronic <- read_csv(
  here::here("inst", "extdata", "owid_chronic_deaths.csv"),
  show_col_types = FALSE
) |>
  mutate(category = "Non-communicable")

infectious <- read_csv(
  here::here("inst", "extdata", "owid_infectious_deaths.csv"),
  show_col_types = FALSE
) |>
  rename(iso3 = country_iso3, country = country_name) |>
  mutate(category = "Infectious")

combined <- bind_rows(chronic, infectious) |>
  group_by(country) |>
  mutate(share_pct = round(deaths_per_100k / sum(deaths_per_100k) * 100, 1)) |>
  ungroup() |>
  select(country, iso3, category, cause, year, deaths_per_100k, share_pct) |>
  arrange(country, category, desc(deaths_per_100k))

out_path <- here::here("inst", "extdata", "death_shares.csv")
write_csv(combined, out_path)
message("Saved ", nrow(combined), " rows to ", out_path)
