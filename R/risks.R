#' Common Risks in Micromorts
#'
#' A dataset of common activities and their associated risk in micromorts,
#' with calculated microlives and source references.
#'
#' Micromort: one-in-a-million chance of death (acute risk).
#' Microlife: 30 minutes of life expectancy lost (chronic risk).
#'
#' COVID-19 data from CDC MMWR (Sep-Dec 2022, Omicron BA.4/BA.5 period).
#'
#' @return A tibble with columns: activity, micromorts, microlives, category,
#'   period, source_url.
#' @export
#' @examples
#' common_risks()
#' common_risks() |> dplyr::filter(category == "COVID-19")
common_risks <- function() {
  # Helper: convert micromorts to microlives

  # 1 micromort with 40 years remaining = 21.075 minutes = 0.7 microlives
  mm_to_ml <- function(mm) round(mm * 0.7, 1)

  tibble::tribble(
    ~activity, ~micromorts, ~category, ~period, ~source_url,
    # Sports
    "Skydiving (one jump)", 7, "Sport", "per event", "https://en.wikipedia.org/wiki/Micromort",
    "Running a marathon", 7, "Sport", "per event", "https://en.wikipedia.org/wiki/Micromort",
    "Scuba diving (per dive)", 5, "Sport", "per event", "https://en.wikipedia.org/wiki/Micromort",
    "Skiing (one day)", 0.5, "Sport", "per day", "https://en.wikipedia.org/wiki/Micromort",
    # Travel
    "Motorcycling (60 miles)", 10, "Travel", "per trip", "https://en.wikipedia.org/wiki/Micromort",
    "Walking (20 miles)", 1, "Travel", "per trip", "https://en.wikipedia.org/wiki/Micromort",
    "Bicycling (20 miles)", 1, "Travel", "per trip", "https://en.wikipedia.org/wiki/Micromort",
    "Driving (230 miles)", 1, "Travel", "per trip", "https://en.wikipedia.org/wiki/Micromort",
    "Jet plane (1000 miles)", 1, "Travel", "per trip", "https://en.wikipedia.org/wiki/Micromort",
    # Medical
    "General Anesthesia", 10, "Medical", "per event", "https://en.wikipedia.org/wiki/Micromort",
    # Daily Life
    "Living (one day, age 30)", 1, "Daily Life", "per day", "https://en.wikipedia.org/wiki/Micromort",
    "Living (one day, age 50)", 4, "Daily Life", "per day", "https://en.wikipedia.org/wiki/Micromort",
    "Living (one day, age 90)", 400, "Daily Life", "per day", "https://en.wikipedia.org/wiki/Micromort",
    # Diet
    "Eating 40 tbsp peanut butter", 1, "Diet", "per event", "https://en.wikipedia.org/wiki/Micromort",
    # Chronic
    "Smoking 1.4 cigarettes", 1, "Chronic", "per event", "https://en.wikipedia.org/wiki/Micromort",
    # COVID-19 (CDC data, Sep-Dec 2022, ~11 weeks, BA.4/BA.5 period)
    "COVID-19 unvaccinated (all ages)", 20, "COVID-19", "11 weeks (2022)", "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",
    "COVID-19 monovalent vaccine (all ages)", 4, "COVID-19", "11 weeks (2022)", "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",
    "COVID-19 bivalent booster (all ages)", 1, "COVID-19", "11 weeks (2022)", "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",
    "COVID-19 unvaccinated (age 65-79)", 76, "COVID-19", "11 weeks (2022)", "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",
    "COVID-19 bivalent booster (age 65-79)", 3, "COVID-19", "11 weeks (2022)", "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",
    "COVID-19 unvaccinated (age 80+)", 234, "COVID-19", "11 weeks (2022)", "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",
    "COVID-19 bivalent booster (age 80+)", 23, "COVID-19", "11 weeks (2022)", "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm"
  ) |>
    dplyr::mutate(microlives = mm_to_ml(micromorts)) |>
    dplyr::select(activity, micromorts, microlives, category, period, source_url)
}

#' COVID-19 Vaccine Relative Risks
#'
#' Mortality risk comparison between vaccinated and unvaccinated populations
#' during the Omicron BA.4/BA.5 period (Sep-Dec 2022).
#'
#' Data source: CDC MMWR Vol. 72, No. 6 (Feb 2023).
#'
#' @return A tibble with vaccination status, death rates, micromorts, microlives,
#'   and relative risk compared to bivalent booster recipients.
#' @export
#' @references
#' Link SC, et al. COVID-19 Incidence and Death Rates Among Unvaccinated and
#' Fully Vaccinated Adults with and Without Booster Doses During Periods of
#' Delta and Omicron Variant Emergence. MMWR 2023;72:132-138.
#' \url{https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm}
#' @examples
#' covid_vaccine_rr()
#' covid_vaccine_rr() |> dplyr::filter(age_group == "All ages")
covid_vaccine_rr <- function() {

  # CDC MMWR data: deaths per 100,000 during Sep 18 - Dec 3, 2022 (~11 weeks)
  # Convert to micromorts: rate per 100k * 10 = rate per million

  tibble::tribble(
    ~age_group, ~vaccination_status, ~deaths_per_100k, ~micromorts,
    "All ages", "Unvaccinated", 2.0, 20,
    "All ages", "Monovalent only", 0.4, 4,
    "All ages", "Bivalent booster", 0.1, 1,
    "18-49", "Unvaccinated", 0.1, 1,
    "18-49", "Monovalent only", 0.02, 0.2,
    "18-49", "Bivalent booster", 0.005, 0.05,
    "50-64", "Unvaccinated", 0.8, 8,
    "50-64", "Monovalent only", 0.2, 2,
    "50-64", "Bivalent booster", 0.1, 1,
    "65-79", "Unvaccinated", 7.6, 76,
    "65-79", "Monovalent only", 0.9, 9,
    "65-79", "Bivalent booster", 0.3, 3,
    "80+", "Unvaccinated", 23.4, 234,
    "80+", "Monovalent only", 5.5, 55,
    "80+", "Bivalent booster", 2.3, 23
  ) |>
    dplyr::group_by(age_group) |>
    dplyr::mutate(
      # Microlives: 1 micromort ≈ 0.7 microlives (assuming 40 years remaining)
      microlives = round(micromorts * 0.7, 1),
      # Relative risk vs bivalent booster within age group
      relative_risk = round(micromorts / micromorts[vaccination_status == "Bivalent booster"], 1),
      period = "Sep-Dec 2022 (Omicron BA.4/BA.5)",
      source_url = "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm"
    ) |>
    dplyr::ungroup()
}
