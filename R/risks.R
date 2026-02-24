#' Acute Risks in Micromorts
#'
#' A comprehensive dataset of activities and their associated acute mortality
#' risk in micromorts, with calculated microlives and source references.
#'
#' Micromort: one-in-a-million chance of death (acute risk).
#' Microlife: 30 minutes of life expectancy lost.
#'
#' Data sources: Wikipedia, micromorts.rip, CDC MMWR, academic literature.
#'
#' @return A tibble with columns: activity, micromorts, microlives, category,
#'   period, source_url.
#' @export
#' @references
#' Howard RA (1980). "On Making Life and Death Decisions." In Schwing & Albers
#' (eds), Societal Risk Assessment: How Safe Is Safe Enough?
#'
#' \url{https://en.wikipedia.org/wiki/Micromort}
#'
#' \url{https://micromorts.rip/}
#' @examples
#' common_risks()
#' common_risks() |> dplyr::filter(category == "COVID-19")
#' common_risks() |> dplyr::filter(micromorts > 100)
common_risks <- function() {
  # Helper: convert micromorts to microlives
  # 1 micromort with 40 years remaining = 21.075 minutes = 0.7 microlives
  mm_to_ml <- function(mm) round(mm * 0.7, 1)

 wiki_mm <- "https://en.wikipedia.org/wiki/Micromort"
  mm_rip <- "https://micromorts.rip/"
  cdc_mmwr <- "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm"

 tibble::tribble(
    ~activity, ~micromorts, ~category, ~period, ~source_url,

    # Extreme Risk (>1000 micromorts)
    "Mt. Everest ascent", 37932, "Mountaineering", "per ascent", mm_rip,
    "Himalayan mountaineering", 12000, "Mountaineering", "per expedition", mm_rip,
    "COVID-19 infection (unvaccinated)", 10000, "Disease", "per infection", mm_rip,
    "Spanish flu infection", 3000, "Disease", "per infection", mm_rip,
    "Matterhorn ascent", 2840, "Mountaineering", "per ascent", mm_rip,

    # Very High Risk (100-1000 micromorts)
    "Living in US during COVID-19 (Jul 2020)", 500, "Disease", "per month", mm_rip,
    "Living (one day, age 90)", 463, "Daily Life", "per day", mm_rip,
    "Base jumping (per jump)", 430, "Sport", "per event", mm_rip,
    "First day of life (newborn)", 430, "Daily Life", "per day", mm_rip,
    "COVID-19 unvaccinated (age 80+)", 234, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Caesarean birth (mother)", 170, "Medical", "per event", mm_rip,
    "Scuba diving (per year, trained)", 164, "Sport", "per year", mm_rip,
    "Vaginal birth (mother)", 120, "Medical", "per event", mm_rip,
    "Living (one day, age 75)", 105, "Daily Life", "per day", mm_rip,

    # High Risk (10-100 micromorts)
    "COVID-19 unvaccinated (age 65-79)", 76, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Night in hospital", 75, "Medical", "per night", mm_rip,
    "COVID-19 monovalent vaccine (age 80+)", 55, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Living in NYC COVID-19 (Mar-May 2020)", 50, "Disease", "per 8 weeks", mm_rip,
    "Heroin use (per dose)", 30, "Drugs", "per dose", mm_rip,
    "US military in Afghanistan (2010)", 25, "Military", "per day", mm_rip,
    "COVID-19 bivalent booster (age 80+)", 23, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "COVID-19 unvaccinated (all ages)", 20, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "American football (per game)", 20, "Sport", "per game", mm_rip,
    "Living (one day, under age 1)", 15, "Daily Life", "per day", mm_rip,
    "Ecstasy/MDMA (per dose)", 13, "Drugs", "per dose", mm_rip,
    "Swimming (drowning risk)", 12, "Sport", "per swim", mm_rip,
    "General anesthesia (emergency)", 10, "Medical", "per event", mm_rip,
    "Motorcycling (60 miles)", 10, "Travel", "per trip", wiki_mm,
    "Skydiving (per jump, general)", 10, "Sport", "per event", mm_rip,

    # Moderate Risk (1-10 micromorts)
    "COVID-19 monovalent vaccine (age 65-79)", 9, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Skydiving (per jump, US)", 8, "Sport", "per event", mm_rip,
    "Skydiving (per jump, UK)", 8, "Sport", "per event", mm_rip,
    "COVID-19 unvaccinated (age 50-64)", 8, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Hang gliding (per flight)", 8, "Sport", "per event", mm_rip,
    "Running a marathon", 7, "Sport", "per event", wiki_mm,
    "Living in Maryland COVID-19 (Mar-May 2020)", 7, "Disease", "per 8 weeks", mm_rip,
    "Living (one day, age 45)", 6, "Daily Life", "per day", mm_rip,
    "Scuba diving (per dive, trained)", 5, "Sport", "per event", wiki_mm,
    "Living (one day, age 50)", 4, "Daily Life", "per day", wiki_mm,
    "COVID-19 monovalent vaccine (all ages)", 4, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Rock climbing (per climb)", 3, "Sport", "per event", mm_rip,
    "COVID-19 bivalent booster (age 65-79)", 3, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "COVID-19 monovalent vaccine (age 50-64)", 2, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "COVID-19 unvaccinated (age 18-49)", 1, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Living 2 months with a smoker", 1, "Environment", "per 2 months", mm_rip,
    "Walking (20 miles)", 1, "Travel", "per trip", wiki_mm,
    "Driving (230 miles)", 1, "Travel", "per trip", wiki_mm,
    "Flying (1000 miles)", 1, "Travel", "per trip", wiki_mm,
    "Train (1000 miles)", 1, "Travel", "per trip", mm_rip,
    "Eating 1000 bananas (radiation)", 1, "Diet", "per event", mm_rip,
    "1 hour in a coal mine", 1, "Occupation", "per hour", mm_rip,
    "Eating 40 tbsp peanut butter (aflatoxin)", 1, "Diet", "per event", wiki_mm,
    "Eating 100 charbroiled steaks", 1, "Diet", "per event", mm_rip,
    "Living (one day, age 20)", 1, "Daily Life", "per day", wiki_mm,
    "Living (one day, age 30)", 1, "Daily Life", "per day", wiki_mm,
    "COVID-19 bivalent booster (all ages)", 1, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "COVID-19 bivalent booster (age 50-64)", 1, "COVID-19", "11 weeks (2022)", cdc_mmwr,

    # Low Risk (<1 micromort)
    "Skiing (per day)", 0.7, "Sport", "per day", mm_rip,
    "Horseback riding", 0.5, "Sport", "per ride", mm_rip,
    "COVID-19 monovalent vaccine (age 18-49)", 0.2, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Kangaroo encounter", 0.1, "Wildlife", "per encounter", mm_rip,
    "COVID-19 bivalent booster (age 18-49)", 0.05, "COVID-19", "11 weeks (2022)", cdc_mmwr
  ) |>
    dplyr::mutate(microlives = mm_to_ml(micromorts)) |>
    dplyr::select(activity, micromorts, microlives, category, period, source_url)
}

#' Chronic Risks in Microlives
#'
#' A dataset of chronic lifestyle factors and their impact on life expectancy,
#' measured in microlives (30 minutes of life expectancy per day).
#'
#' Positive values indicate life expectancy gains; negative values indicate losses.
#' Effects are cumulative over a lifetime of adult exposure (~57 years).
#'
#' @return A tibble with columns: factor, microlives_per_day, category,
#'   direction, annual_effect_days, source_url.
#' @export
#' @references
#' Spiegelhalter D (2012). "Using speed of ageing and 'microlives' to
#' communicate the effects of lifetime habits and environment."
#' BMJ 2012;345:e8223. \doi{10.1136/bmj.e8223}
#'
#' \url{https://en.wikipedia.org/wiki/Microlife}
#'
#' \url{https://pubmed.ncbi.nlm.nih.gov/23247978/}
#' @examples
#' chronic_risks()
#' chronic_risks() |> dplyr::filter(direction == "loss")
#' chronic_risks() |> dplyr::filter(category == "Exercise")
chronic_risks <- function() {
  wiki_ml <- "https://en.wikipedia.org/wiki/Microlife"
  bmj_2012 <- "https://pubmed.ncbi.nlm.nih.gov/23247978/"

  tibble::tribble(
    ~factor, ~microlives_per_day, ~category, ~description,

    # Losses (negative microlives)
    "Smoking 20 cigarettes", -10, "Smoking", "Heavy smoking accelerates aging to 29 hours/day",
    "Smoking 10 cigarettes", -5, "Smoking", "Moderate smoking",
    "Smoking 2 cigarettes", -1, "Smoking", "Each cigarette costs ~15 minutes",
    "Being 5 kg overweight", -1, "Weight", "Per 5 kg above optimum BMI weight",
    "Being 10 kg overweight", -2, "Weight", "Cumulative effect of excess weight",
    "Being 15 kg overweight", -3, "Weight", "Cumulative effect of excess weight",
    "2nd-3rd alcoholic drink", -1, "Alcohol", "After first drink, additional drinks cost",
    "4th-5th alcoholic drink", -2, "Alcohol", "Heavy drinking costs more",
    "Red meat (1 portion/day)", -1, "Diet", "Daily red meat consumption",
    "Processed meat (1 portion/day)", -1, "Diet", "Bacon, sausages, etc.",
    "2 hours TV watching", -1, "Sedentary", "Prolonged sitting/inactivity",
    "Living with a smoker", -1, "Environment", "Second-hand smoke exposure",
    "2-3 cups coffee (men)", -1, "Diet", "Heavy coffee consumption (men only)",
    "Air pollution (high)", -1, "Environment", "Living in polluted urban area",
    "Being male (vs female)", -4, "Demographics", "Male sex disadvantage",

    # Gains (positive microlives)
    "First alcoholic drink", 1, "Alcohol", "Moderate alcohol has protective effect",
    "20 min moderate exercise", 2, "Exercise", "Daily moderate physical activity",
    "5 servings fruit/veg", 4, "Diet", "Daily fruit and vegetable intake",
    "Statin therapy (if indicated)", 1, "Medical", "Cholesterol-lowering medication",
    "Being female (vs male)", 4, "Demographics", "Female sex advantage",
    "Living in 2010 vs 1910", 15, "Historical", "Medical/social progress",
    "Living in Sweden vs Russia (male)", 21, "Demographics", "Geographic health advantage"
  ) |>
    dplyr::mutate(
      direction = ifelse(microlives_per_day < 0, "loss", "gain"),
      # Annual effect: microlives * 365 days * 30 min / (24*60) = days/year
      annual_effect_days = round(microlives_per_day * 365 * 30 / (24 * 60), 1),
      source_url = bmj_2012
    ) |>
    dplyr::select(factor, microlives_per_day, category, direction,
                  description, annual_effect_days, source_url)
}

#' Demographic Life Expectancy Factors
#'
#' Population-level factors affecting baseline life expectancy,
#' expressed as microlives per day relative to a reference population.
#'
#' Based on actuarial data and epidemiological studies.
#'
#' @return A tibble with demographic factors and their microlife effects.
#' @export
#' @references
#' Spiegelhalter D (2012). BMJ 2012;345:e8223.
#'
#' \url{https://en.wikipedia.org/wiki/Microlife}
#' @examples
#' demographic_factors()
demographic_factors <- function() {
  tibble::tribble(
    ~factor, ~comparison, ~microlives_per_day, ~source,

    "Sex", "Female vs Male", 4, "BMJ 2012",
    "Era", "2010 vs 1910", 15, "BMJ 2012",
    "Country (male)", "Sweden vs Russia", 21, "BMJ 2012",
    "Country (male)", "UK vs Russia", 15, "BMJ 2012",
    "Socioeconomic", "Professional vs Unskilled (UK)", 4, "BMJ 2012",
    "Education", "Degree vs No qualifications (UK)", 4, "BMJ 2012"
  ) |>
    dplyr::mutate(
      source_url = "https://en.wikipedia.org/wiki/Microlife"
    )
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

#' Data Sources for Micromort and Microlife Research
#'
#' Returns a tibble of authoritative data sources for mortality risk research.
#'
#' @return A tibble with source names, URLs, types, and descriptions.
#' @export
#' @examples
#' risk_data_sources()
risk_data_sources <- function() {
  tibble::tribble(
    ~source, ~url, ~type, ~description,

    # Primary Academic Sources
    "Howard (1980)", "https://brieswax.substack.com/p/micromort-ronald-howard-1989-idea",
      "Academic", "Original micromort concept paper",
    "Spiegelhalter (2012) BMJ", "https://pubmed.ncbi.nlm.nih.gov/23247978/",
      "Academic", "Introduced microlives; DOI: 10.1136/bmj.e8223",
    "The Norm Chronicles", "https://www.penguin.co.uk/books/186892/the-norm-chronicles",
      "Book", "Comprehensive micromort/microlife tables by Blastland & Spiegelhalter",

    # Wikipedia
    "Wikipedia: Micromort", "https://en.wikipedia.org/wiki/Micromort",
      "Encyclopedia", "Comprehensive overview with cited values",
    "Wikipedia: Microlife", "https://en.wikipedia.org/wiki/Microlife",
      "Encyclopedia", "Chronic risk factors and examples",

    # Online Databases
    "micromorts.rip", "https://micromorts.rip/",
      "Database", "Crowdsourced database with 45+ activities",
    "Understanding Uncertainty", "https://plus.maths.org/content/understanding-uncertainty-microlives",
      "Educational", "Cambridge University risk communication",

    # Government Sources
    "CDC MMWR", "https://www.cdc.gov/mmwr/",
      "Government", "US mortality and morbidity data",
    "CDC Life Expectancy", "https://cdc.gov/nchs/hus/data-finder.htm?subject=Life+expectancy",
      "Government", "US life expectancy statistics",
    "WHO Global Health Estimates", "https://www.who.int/data/gho/data/themes/mortality-and-global-health-estimates",
      "Government", "Global mortality and life expectancy data",
    "UK ONS", "https://www.ons.gov.uk/",
      "Government", "UK death statistics",
    "NHTSA", "https://www.nhtsa.gov/",
      "Government", "US traffic fatality data",

    # Research Papers
    "COVID-19 vs Overdose (PMC)", "https://pmc.ncbi.nlm.nih.gov/articles/PMC8461265/",
      "Academic", "Micromort analysis comparing COVID and overdose mortality",
    "CDC COVID Vaccine Efficacy", "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",
      "Government", "Vaccinated vs unvaccinated death rates"
  )
}
