# Download and process Eurostat regional life expectancy data
# Source: Eurostat demo_r_mlifexp dataset
# https://ec.europa.eu/eurostat/databrowser/product/view/demo_r_mlifexp

library(dplyr)
library(tidyr)
library(stringr)

# ============================================================================
# DOWNLOAD FROM EUROSTAT
# ============================================================================

# Check if eurostat package is available
if (!requireNamespace("eurostat", quietly = TRUE)) {

  cli::cli_abort(c(
    "x" = "Package {.pkg eurostat} is required to download regional data.",
    "i" = "Install it with: {.code install.packages('eurostat')}"
  ))
}

cli::cli_alert_info("Downloading Eurostat demo_r_mlifexp dataset...")

# Download life expectancy at birth by NUTS2 region
# This may take a minute
raw_data <- eurostat::get_eurostat(

  id = "demo_r_mlifexp",
  time_format = "num",
  filters = list(
    age = "Y_LT1"  # Life expectancy at birth (age < 1)
  )
)

cli::cli_alert_success("Downloaded {nrow(raw_data)} rows")

# ============================================================================
# PROCESS DATA
# ============================================================================

# Get region labels
region_labels <- eurostat::get_eurostat_dic("geo") |>
  rename(geo = code, region_name = name)

# Western European countries (matching Nature Communications study scope)
western_europe <- c(

  "AT",  # Austria
  "BE",  # Belgium
  "CH",
  # Switzerland (EFTA, included in Eurostat)
  "DE",  # Germany
  "DK",  # Denmark
  "ES",  # Spain
  "FI",  # Finland
  "FR",  # France

  "IE",  # Ireland
  "IT",  # Italy
  "LU",  # Luxembourg
  "NL",  # Netherlands
  "NO",  # Norway (EFTA)
  "PT",  # Portugal
  "SE",  # Sweden
  "UK"   # United Kingdom (historical data pre-Brexit)
)

# Process and filter
regional_le <- raw_data |>
  # Join region names
  left_join(region_labels, by = "geo") |>
  # Extract country code from NUTS code (first 2 characters)
  mutate(
    country_code = str_sub(geo, 1, 2),
    nuts_level = case_when(
      nchar(geo) == 2 ~ 0L,  # Country level
      nchar(geo) == 3 ~ 1L,  # NUTS1
      nchar(geo) == 4 ~ 2L,  # NUTS2
      nchar(geo) >= 5 ~ 3L,  # NUTS3
      TRUE ~ NA_integer_
    )
  ) |>
  # Filter to Western Europe and NUTS2 level
  filter(
    country_code %in% western_europe,
    nuts_level == 2,
    !is.na(values)
  ) |>
  # Rename and select columns
  transmute(
    region_code = geo,
    region_name = region_name,
    country_code = country_code,
    year = as.integer(time),
    sex = case_when(
      sex == "T" ~ "Total",
      sex == "M" ~ "Male",
      sex == "F" ~ "Female",
      TRUE ~ sex
    ),
    life_expectancy = values
  ) |>
  # Filter to 1992-2023 (matching Nature Communications + recent data)
  filter(year >= 1992, year <= 2023) |>
  arrange(country_code, region_code, year, sex)

cli::cli_alert_success("Processed to {nrow(regional_le)} rows")

# ============================================================================
# ADD DERIVED METRICS
# ============================================================================

# Calculate EU average by year and sex for comparison
eu_avg <- regional_le |>
  group_by(year, sex) |>
  summarise(
    eu_avg_le = mean(life_expectancy, na.rm = TRUE),
    .groups = "drop"
  )

# Add microlives comparison and trend classification
regional_le <- regional_le |>
  left_join(eu_avg, by = c("year", "sex")) |>
  mutate(
    # Microlives per day difference from EU average
    # 1 year LE difference = 365 days * 48 microlives/day = 17,520 microlives/year
    # Daily equivalent: (LE_diff_years * 17520) / (remaining_life * 365)
    # Simplified: LE_diff * 1.2 microlives/day (assuming 40 years remaining)
    microlives_vs_eu_avg = round((life_expectancy - eu_avg_le) * 1.2, 2)
  )

# Calculate annual trends (5-year rolling average gain)
regional_trends <- regional_le |>
  filter(sex == "Total") |>
  group_by(region_code) |>
  arrange(year) |>
  mutate(
    le_lag5 = lag(life_expectancy, 5),
    annual_gain_months = round((life_expectancy - le_lag5) / 5 * 12, 2)
  ) |>
  ungroup() |>
  select(region_code, year, annual_gain_months) |>
  filter(!is.na(annual_gain_months))

# Classify regions as vanguard/laggard based on 2019 data and trends
classification_2019 <- regional_le |>
  filter(year == 2019, sex == "Total") |>
  left_join(
    regional_trends |> filter(year == 2019),
    by = c("region_code", "year")
  ) |>
  mutate(
    # Vanguard: top 20% LE AND positive trend
    # Laggard: bottom 20% LE OR negative/stagnant trend
    le_percentile = percent_rank(life_expectancy),
    classification = case_when(
      le_percentile >= 0.8 & annual_gain_months >= 1.5 ~ "vanguard",
      le_percentile <= 0.2 | annual_gain_months < 0.5 ~ "laggard",
      TRUE ~ "average"
    )
  ) |>
  select(region_code, classification, le_percentile_2019 = le_percentile)

# Add classification to main data
regional_le <- regional_le |>
  left_join(classification_2019 |> select(region_code, classification), by = "region_code") |>
  mutate(
    classification = if_else(is.na(classification), "average", classification),
    source_url = "https://doi.org/10.1038/s41467-026-68828-z"
  ) |>
  select(-eu_avg_le)

# ============================================================================
# SAVE DATA
# ============================================================================

# Save as parquet
arrow::write_parquet(
  regional_le,
  here::here("inst/extdata/regional_life_expectancy.parquet")
)

cli::cli_alert_success(

  "Saved {nrow(regional_le)} rows to inst/extdata/regional_life_expectancy.parquet"
)

# Summary stats
cli::cli_h2("Summary")
cli::cli_alert_info("Countries: {length(unique(regional_le$country_code))}")
cli::cli_alert_info("Regions: {length(unique(regional_le$region_code))}")
cli::cli_alert_info("Years: {min(regional_le$year)}-{max(regional_le$year)}")
cli::cli_alert_info("Rows: {nrow(regional_le)}")

# Classification breakdown (2019)
regional_le |>
  filter(year == 2019, sex == "Total") |>
  count(classification) |>
  print()
