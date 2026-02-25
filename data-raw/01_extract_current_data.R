# Extract current hardcoded data from R functions to CSV source files
# This script is run once to initialize the data-raw/sources/ directory

library(readr)
library(dplyr)

# Source the package functions
devtools::load_all(".")

# 1. Export acute risks (common_risks)
acute_risks <- common_risks() |>
  mutate(
    source_id = case_when(
      grepl("wikipedia", source_url, ignore.case = TRUE) ~ "wikipedia_micromort",
      grepl("micromorts.rip", source_url) ~ "micromorts_rip",
      grepl("cdc.gov/mmwr", source_url) ~ "cdc_mmwr",
      TRUE ~ "unknown"
    ),
    confidence = case_when(
      source_id == "cdc_mmwr" ~ "high",
      source_id == "wikipedia_micromort" ~ "medium",
      source_id == "micromorts_rip" ~ "medium",
      TRUE ~ "low"
    ),
    year = 2025,
    geography = "global",
    age_group = "all",
    last_accessed = Sys.Date()
  )

write_csv(acute_risks, "data-raw/sources/acute_risks_base.csv")
cat("Exported", nrow(acute_risks), "acute risks to data-raw/sources/acute_risks_base.csv\n")

# 2. Export chronic risks
chronic_data <- chronic_risks() |>
  mutate(
    source_id = "spiegelhalter_2012",
    confidence = "high",
    last_accessed = Sys.Date()
  )

write_csv(chronic_data, "data-raw/sources/chronic_risks_base.csv")
cat("Exported", nrow(chronic_data), "chronic risks to data-raw/sources/chronic_risks_base.csv\n")

# 3. Export COVID vaccine data
covid_data <- covid_vaccine_rr() |>
  mutate(
    source_id = "cdc_mmwr",
    confidence = "high",
    last_accessed = Sys.Date()
  )

write_csv(covid_data, "data-raw/sources/covid_vaccine_rr.csv")
cat("Exported", nrow(covid_data), "COVID vaccine records to data-raw/sources/covid_vaccine_rr.csv\n")

# 4. Export demographic factors
demo_data <- demographic_factors() |>
  mutate(
    source_id = "spiegelhalter_2012",
    confidence = "high",
    last_accessed = Sys.Date()
  )

write_csv(demo_data, "data-raw/sources/demographic_factors.csv")
cat("Exported", nrow(demo_data), "demographic factors to data-raw/sources/demographic_factors.csv\n")

# 5. Export source registry
source_registry <- risk_data_sources() |>
  mutate(
    source_id = case_when(
      grepl("Howard", source) ~ "howard_1980",
      grepl("Spiegelhalter.*BMJ", source) ~ "spiegelhalter_2012",
      grepl("Norm Chronicles", source) ~ "norm_chronicles",
      grepl("Wikipedia: Micromort", source) ~ "wikipedia_micromort",
      grepl("Wikipedia: Microlife", source) ~ "wikipedia_microlife",
      grepl("micromorts.rip", source) ~ "micromorts_rip",
      grepl("CDC MMWR$", source) ~ "cdc_mmwr",
      grepl("CDC Life", source) ~ "cdc_life_expectancy",
      grepl("WHO", source) ~ "who_ghe",
      grepl("ONS", source) ~ "uk_ons",
      grepl("NHTSA", source) ~ "nhtsa",
      grepl("Understanding Uncertainty", source) ~ "understanding_uncertainty",
      grepl("COVID.*Overdose", source) ~ "pmc_covid_overdose",
      grepl("COVID Vaccine Efficacy", source) ~ "cdc_vaccine_efficacy",
      TRUE ~ tolower(gsub("[^a-zA-Z0-9]", "_", source))
    ),
    data_types = case_when(
      source_id %in% c("spiegelhalter_2012", "wikipedia_microlife") ~ "chronic",
      source_id %in% c("howard_1980", "wikipedia_micromort", "micromorts_rip", "cdc_mmwr") ~ "acute",
      TRUE ~ "both"
    ),
    last_accessed = Sys.Date()
  ) |>
  rename(
    citation = source,
    primary_url = url
  )

write_csv(source_registry, "data-raw/sources/risk_sources.csv")
cat("Exported", nrow(source_registry), "sources to data-raw/sources/risk_sources.csv\n")

cat("\nAll data exported successfully!\n")
cat("Next steps:\n")
cat("1. Run the targets pipeline with tar_make()\n")
cat("2. This will generate parquet files in inst/extdata/\n")
