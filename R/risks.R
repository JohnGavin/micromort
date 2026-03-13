#' Acute Risks in Micromorts
#'
#' A comprehensive dataset of activities and their associated acute mortality
#' risk in micromorts, with calculated microlives and source references.
#'
#' Aggregates from [atomic_risks()], summing component-level micromorts
#' per activity.
#'
#' Micromort: one-in-a-million chance of death (acute risk).
#' Microlife: 30 minutes of life expectancy lost.
#'
#' Data sources: Wikipedia, micromorts.rip, CDC MMWR, academic literature.
#'
#' @param profile A named list of condition variables for filtering conditional
#'   risks, e.g. `list(health_profile = "dvt_risk_factors")` or
#'   `list(country = "US")` for country-specific road traffic and homicide
#'   risks. Default `list()` returns unconditional/healthy defaults.
#' @param duration_hours Optional numeric. For duration-dependent activities,
#'   selects the nearest pre-computed duration bucket *within each activity*.
#'   All flying variants (2h, 5h, 8h, 12h) are retained. `NULL` (default)
#'   returns all duration buckets. Use [risk_for_duration()] to select a
#'   single activity family result.
#' @return A tibble with columns:
#'   \describe{
#'     \item{activity}{Activity name}
#'     \item{micromorts}{Risk in micromorts (1 = 1-in-a-million death probability)}
#'     \item{microlives}{Equivalent microlives (micromorts x 0.7)}
#'     \item{category}{Activity category}
#'     \item{period}{Human-readable period description}
#'     \item{period_type}{Normalized period type: "event", "day", "hour", "year", "period"}
#'     \item{period_days}{Typical duration in days (for cross-activity comparison)}
#'     \item{micromorts_per_day}{Micromorts normalized per day}
#'     \item{source_url}{Data source URL}
#'     \item{n_components}{Number of atomic components summed}
#'     \item{hedgeable_pct}{Percent of total micromorts that are hedgeable}
#'   }
#' @export
#' @references
#' Howard RA (1980). "On Making Life and Death Decisions." In Schwing & Albers
#' (eds), Societal Risk Assessment: How Safe Is Safe Enough?
#'
#' \url{https://en.wikipedia.org/wiki/Micromort}
#'
#' \url{https://micromorts.rip/}
#' @seealso [atomic_risks()] for the component-level data.
#' @examples
#' common_risks()
#' common_risks() |> dplyr::filter(category == "COVID-19")
#' common_risks() |> dplyr::filter(micromorts > 100)
common_risks <- function(profile = list(), duration_hours = NULL) {
  risks <- atomic_risks() |>
    filter_by_profile(profile)

  if (!is.null(duration_hours)) {
    risks <- filter_to_duration(risks, duration_hours)
  }

  # Preserve insertion order via row number (AFTER filtering so order is stable)
  risks <- risks |>
    dplyr::mutate(.row_order = dplyr::row_number())

  risks |>
    dplyr::group_by(activity_id, activity, category, period, period_type,
                    source_url) |>
    dplyr::summarise(
      # hedgeable_pct MUST be computed before micromorts is overwritten
      hedgeable_pct = dplyr::if_else(
        sum(micromorts) > 0,
        round(sum(hedgeable * micromorts) / sum(micromorts) * 100, 1),
        0
      ),
      micromorts = sum(micromorts),
      n_components = dplyr::n(),
      .row_order = min(.row_order),
      .groups = "drop"
    ) |>
    dplyr::arrange(.row_order) |>
    dplyr::mutate(
      microlives = round(micromorts * 0.7, 1),
      period_days = compute_period_days(period, period_type),
      micromorts_per_day = round(micromorts / period_days, 2)
    ) |>
    dplyr::select(
      activity, micromorts, microlives, category, period,
      period_type, period_days, micromorts_per_day, source_url,
      n_components, hedgeable_pct
    )
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
    # Smoking
    "Smoking 20 cigarettes", -10, "Smoking", "Heavy smoking accelerates aging to 29 hours/day",
    "Smoking 10 cigarettes", -5, "Smoking", "Moderate smoking",
    "Smoking 2 cigarettes", -1, "Smoking", "Each cigarette costs ~15 minutes",

    # Weight
    "Being 5 kg overweight", -1, "Weight", "Per 5 kg above optimum BMI weight",
    "Being 10 kg overweight", -2, "Weight", "Cumulative effect of excess weight",
    "Being 15 kg overweight", -3, "Weight", "Cumulative effect of excess weight",

    # Alcohol
    "2nd-3rd alcoholic drink", -1, "Alcohol", "After first drink, additional drinks cost",
    "4th-5th alcoholic drink", -2, "Alcohol", "Heavy drinking costs more",

    # Diet
    "Red meat (1 portion/day)", -1, "Diet", "Daily red meat consumption",
    "Processed meat (1 portion/day)", -1, "Diet", "Bacon, sausages, etc. (cancer risk)",
    "Low fiber diet", -1, "Diet", "Less than 25g fiber daily (colorectal cancer risk)",
    "High sugar diet", -1, "Diet", "Excess refined sugar (diabetes, CVD risk)",

    # Sedentary
    "2 hours TV watching", -1, "Sedentary", "Prolonged sitting/inactivity",
    "Sitting 8+ hours/day", -2, "Sedentary", "Office work without breaks (CVD risk)",

    # Environment
    "Living with a smoker", -1, "Environment", "Second-hand smoke exposure",
    "Air pollution (high)", -1, "Environment", "Living in polluted urban area",

    # Cardiovascular disease risk factors
    "Untreated hypertension", -4, "Cardiovascular", "Systolic BP >140 mmHg untreated",
    "Type 2 diabetes (poorly controlled)", -3, "Cardiovascular", "HbA1c >8% increases CVD risk",
    "High LDL cholesterol (untreated)", -2, "Cardiovascular", "LDL >160 mg/dL without statins",
    "Family history of heart disease", -2, "Cardiovascular", "First-degree relative with CVD <55y",

    # Cancer risk factors
    "Family history of cancer", -1, "Cancer", "First-degree relative with cancer",
    "Low physical activity", -1, "Cancer", "Less than 150 min exercise/week (cancer risk)",
    "Excessive alcohol (cancer)", -1, "Cancer", "More than 2 drinks/day increases cancer risk",

    # Other
    "2-3 cups coffee (men)", -1, "Diet", "Heavy coffee consumption (men only)",
    "Being male (vs female)", -4, "Demographics", "Male sex disadvantage",
    "Chronic stress/poor sleep", -1, "Mental Health", "Cortisol elevation, inflammation",

    # Gains (positive microlives)
    "First alcoholic drink", 1, "Alcohol", "Moderate alcohol has protective effect",
    "20 min moderate exercise", 2, "Exercise", "Daily moderate physical activity",
    "150 min weekly exercise", 3, "Exercise", "Meeting WHO recommendations (CVD/cancer prevention)",
    "5 servings fruit/veg", 4, "Diet", "Daily fruit and vegetable intake",
    "High fiber diet", 2, "Diet", "25g+ fiber daily (colorectal cancer prevention)",
    "Mediterranean diet", 2, "Diet", "Reduces CVD and cancer risk",
    "Statin therapy (if indicated)", 1, "Medical", "Cholesterol-lowering medication",
    "Blood pressure control", 2, "Medical", "Achieving target BP <130/80 mmHg",
    "Cancer screening (age-appropriate)", 1, "Medical", "Early detection improves outcomes",
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

#' Cancer Risks by Type, Sex, and Age
#'
#' Mortality rates for major cancers stratified by sex and age group,
#' expressed in micromorts per year and daily microlives.
#'
#' Data from SEER Cancer Statistics (NCI) and American Cancer Society 2024-2026.
#'
#' @return A tibble with columns: cancer_type, sex, age_group, deaths_per_100k,
#'   micromorts_per_year, microlives_per_day, family_history_rr, rank_by_sex,
#'   source_url.
#' @export
#' @references
#' SEER Cancer Statistics Factsheets. National Cancer Institute.
#' \url{https://seer.cancer.gov/statfacts/}
#'
#' Siegel RL, et al. Cancer statistics, 2024. CA Cancer J Clin. 2024;74:12-49.
#' @family conditional-risk
#' @seealso [vaccination_risks()], [conditional_risk()], [hedged_portfolio()]
#' @examples
#' cancer_risks()
#' cancer_risks() |> dplyr::filter(sex == "Female")
#' cancer_risks() |> dplyr::filter(age_group == "50-64")
cancer_risks <- function() {
  seer_url <- "https://seer.cancer.gov/statfacts/"
  acs_url <- "https://www.cancer.org/research/cancer-facts-statistics.html"


  # Death rates per 100,000 population (age-adjusted, SEER 2019-2023)
  # Convert: deaths per 100k/year * 10 = micromorts per year
  # Then: micromorts_per_year / 365 * 0.7 = microlives per day (approximate)

  tibble::tribble(
    ~cancer_type, ~sex, ~age_group, ~deaths_per_100k, ~family_history_rr,

    # Males - All ages (ranked by mortality)
    "Lung & Bronchus", "Male", "All ages", 37.2, 2.0,
    "Prostate", "Male", "All ages", 19.2, 2.5,
    "Colon & Rectum", "Male", "All ages", 15.3, 2.0,
    "Pancreas", "Male", "All ages", 12.9, 1.8,
    "Liver", "Male", "All ages", 10.2, 1.5,
    "Leukemia", "Male", "All ages", 7.8, 1.3,
    "Esophagus", "Male", "All ages", 7.1, 1.5,
    "Bladder", "Male", "All ages", 6.5, 1.8,
    "Non-Hodgkin Lymphoma", "Male", "All ages", 5.6, 1.7,
    "Multiple Myeloma", "Male", "All ages", 3.3, 3.7,
    "Hodgkin Lymphoma", "Male", "All ages", 0.4, 3.0,
    "All cancers", "Male", "All ages", 183.5, 1.5,

    # Females - All ages (ranked by mortality)
    "Lung & Bronchus", "Female", "All ages", 27.1, 2.0,
    "Breast", "Female", "All ages", 19.2, 2.0,
    "Colon & Rectum", "Female", "All ages", 10.8, 2.0,
    "Pancreas", "Female", "All ages", 9.9, 1.8,
    "Ovary", "Female", "All ages", 6.1, 3.0,
    "Uterus", "Female", "All ages", 5.3, 2.5,
    "Leukemia", "Female", "All ages", 4.8, 1.3,
    "Liver", "Female", "All ages", 4.2, 1.5,
    "Non-Hodgkin Lymphoma", "Female", "All ages", 3.6, 1.7,
    "Multiple Myeloma", "Female", "All ages", 2.1, 3.7,
    "Hodgkin Lymphoma", "Female", "All ages", 0.3, 3.0,
    "All cancers", "Female", "All ages", 128.1, 1.5,

    # Age-stratified (both sexes, all cancers)
    "All cancers", "Both", "0-19", 2.3, 1.2,
    "All cancers", "Both", "20-34", 4.0, 1.3,
    "All cancers", "Both", "35-49", 24.0, 1.4,
    "All cancers", "Both", "50-64", 125.0, 1.5,
    "All cancers", "Both", "65-74", 380.0, 1.5,
    "All cancers", "Both", "75-84", 750.0, 1.4,
    "All cancers", "Both", "85+", 1200.0, 1.3,

    # Top 3 male cancers by age
    "Lung & Bronchus", "Male", "50-64", 45.0, 2.0,
    "Prostate", "Male", "50-64", 8.0, 2.5,
    "Colon & Rectum", "Male", "50-64", 18.0, 2.0,
    "Lung & Bronchus", "Male", "65-74", 120.0, 2.0,
    "Prostate", "Male", "65-74", 45.0, 2.5,
    "Colon & Rectum", "Male", "65-74", 40.0, 2.0,

    # Top 3 female cancers by age
    "Lung & Bronchus", "Female", "50-64", 35.0, 2.0,
    "Breast", "Female", "50-64", 25.0, 2.0,
    "Colon & Rectum", "Female", "50-64", 12.0, 2.0,
    "Lung & Bronchus", "Female", "65-74", 95.0, 2.0,
    "Breast", "Female", "65-74", 45.0, 2.0,
    "Colon & Rectum", "Female", "65-74", 28.0, 2.0
  ) |>
    dplyr::mutate(
      # Convert deaths per 100k/year to micromorts per year
      micromorts_per_year = deaths_per_100k * 10,
      # Convert to microlives per day (1 mm ≈ 0.7 ml)
      microlives_per_day = round(micromorts_per_year / 365 * 0.7, 2),
      # With family history
      micromorts_with_family_history = round(micromorts_per_year * family_history_rr, 0),
      source_url = seer_url
    ) |>
    dplyr::group_by(sex, age_group) |>
    dplyr::mutate(
      rank_by_sex = dplyr::row_number(dplyr::desc(deaths_per_100k))
    ) |>
    dplyr::ungroup() |>
    dplyr::select(
      cancer_type, sex, age_group, deaths_per_100k,
      micromorts_per_year, microlives_per_day,
      family_history_rr, micromorts_with_family_history,
      rank_by_sex, source_url
    )
}

#' Vaccination Risk Reduction
#'
#' Mortality risk reduction from vaccination schedules compared to unvaccinated
#' baseline, expressed in micromorts avoided per year.
#'
#' Data from CDC, WHO, and Lancet 2024 Global Vaccine Impact Study.
#'
#' @return A tibble with vaccination schedules and their risk reduction metrics.
#' @export
#' @references
#' CDC. Health and Economic Benefits of Routine Childhood Immunizations.
#' MMWR 2024;73:1-8. \url{https://www.cdc.gov/mmwr/}
#'
#' Lancet 2024. Contribution of vaccination to improved survival: 50 years of EPI.
#' \doi{10.1016/S0140-6736(24)00850-X}
#' @family conditional-risk
#' @seealso [cancer_risks()], [conditional_risk()], [hedged_portfolio()]
#' @examples
#' vaccination_risks()
#' vaccination_risks() |> dplyr::filter(country == "US")
#' vaccination_risks() |> dplyr::filter(age_group == "0-5")  # Childhood vaccines
vaccination_risks <- function() {
  cdc_url <- "https://www.cdc.gov/mmwr/"
  lancet_url <- "https://www.thelancet.com/journals/lancet/article/PIIS0140-6736(24)00850-X/fulltext"

  tibble::tribble(
    ~vaccine_schedule, ~age_group, ~country, ~mortality_reduction_pct,
    ~micromorts_avoided_per_year, ~description,

    # Childhood vaccination (complete schedule)
    "Complete childhood schedule", "0-5", "US", 27,
      500, "DTaP, MMR, Polio, Hib, HepB, PCV, Rotavirus, Varicella",
    "Complete childhood schedule", "0-5", "UK", 27,
      480, "6-in-1, MMR, PCV, MenB, Rotavirus",
    "Complete childhood schedule", "0-5", "Australia", 27,
      450, "DTPa, MMR, IPV, Hib, HepB, PCV, Rotavirus",
    "Complete childhood schedule", "0-5", "Global average", 24,
      400, "WHO EPI schedule coverage",

    # Individual childhood vaccines (annual risk avoided, ages 0-5)
    "Measles vaccine", "0-5", "US", 15,
      150, "Two-dose MMR; measles caused 2.6M deaths/year pre-vaccine",
    "DTP vaccine", "0-5", "US", 10,
      100, "Diphtheria, Tetanus, Pertussis",
    "Rotavirus vaccine", "0-5", "US", 4,
      40, "Prevents severe diarrhea mortality",
    "Hib vaccine", "0-5", "US", 3,
      30, "Haemophilus influenzae type b meningitis",
    "Pneumococcal vaccine", "0-5", "US", 2,
      20, "PCV13/PCV15 for pneumonia",

    # Adult vaccinations (annual risk reduction)
    "Annual influenza vaccine", "65+", "US", 4,
      200, "~40-60% efficacy; prevents 50k+ deaths/year in US",
    "Annual influenza vaccine", "65+", "UK", 4,
      180, "NHS winter vaccination programme",
    "Pneumococcal vaccine", "65+", "US", 2,
      100, "PPSV23 or PCV20; one-time or booster",
    "Shingles vaccine", "50+", "US", 1,
      30, "Shingrix; prevents PHN complications",
    "COVID-19 vaccine (annual)", "65+", "US", 15,
      800, "Bivalent/updated; high-risk age group",
    "COVID-19 vaccine (annual)", "18-64", "US", 3,
      50, "Lower baseline risk in younger adults",

    # Unvaccinated baseline (risk exposure)
    "Unvaccinated baseline", "0-5", "US", 0,
      0, "Reference: pre-vaccine era mortality risk",
    "Unvaccinated baseline", "65+", "US", 0,
      0, "Reference: no flu/pneumonia/COVID vaccines"
  ) |>
    dplyr::mutate(
      # Microlives gained per day from vaccination
      microlives_gained_per_day = round(micromorts_avoided_per_year / 365 * 0.7, 2),
      # Annual effect in days of life
      annual_life_days_gained = round(micromorts_avoided_per_year / 365 * 0.7 * 365 * 30 / (24 * 60), 1),
      source_url = cdc_url
    )
}

#' Conditional Risk Comparison (Hedged vs Unhedged)
#'
#' Compare mortality risk between "hedged" (optimal lifestyle/interventions) and
#' "unhedged" (baseline/suboptimal) scenarios for major disease categories.
#'
#' @param disease Character. Disease category: "cardiovascular", "cancer",
#'   "respiratory", "infectious", or "all".
#' @return A tibble comparing hedged vs unhedged risks in micromorts and microlives.
#' @export
#' @family conditional-risk
#' @seealso [cancer_risks()], [vaccination_risks()], [hedged_portfolio()]
#' @examples
#' conditional_risk("cardiovascular")
#' conditional_risk("cancer")
#' conditional_risk("all")
conditional_risk <- function(disease = "all") {
  checkmate::assert_choice(disease, c("cardiovascular", "cancer", "respiratory",
                                       "infectious", "all"))

  all_risks <- tibble::tribble(
    ~disease_category, ~risk_factor, ~unhedged_state, ~hedged_state,
    ~unhedged_microlives_per_day, ~hedged_microlives_per_day, ~reduction_pct, ~evidence_quality,

    # Cardiovascular disease
    "cardiovascular", "Smoking", "20 cigarettes/day", "Non-smoker",
      -10, 0, 100, "High",
    "cardiovascular", "Blood pressure", "Untreated hypertension", "Controlled <130/80",
      -4, 0, 100, "High",
    "cardiovascular", "Exercise", "Sedentary (<30 min/week)", "150 min moderate/week",
      -2, 2, 200, "High",
    "cardiovascular", "Diet", "Western diet (high processed)", "Mediterranean diet",
      -2, 2, 200, "High",
    "cardiovascular", "Cholesterol", "High LDL untreated", "Statin therapy if indicated",
      -2, 1, 150, "High",
    "cardiovascular", "Weight", "15 kg overweight", "Healthy BMI",
      -3, 0, 100, "High",
    "cardiovascular", "Diabetes", "Poorly controlled T2D", "Well-controlled HbA1c <7%",
      -3, -1, 67, "High",
    "cardiovascular", "Alcohol", "Heavy (4+ drinks/day)", "Moderate (1 drink/day)",
      -2, 1, 150, "Moderate",

    # Cancer
    "cancer", "Smoking", "20 cigarettes/day", "Non-smoker",
      -8, 0, 100, "High",
    "cancer", "Alcohol", "Heavy drinking", "No alcohol",
      -1, 0, 100, "High",
    "cancer", "Physical activity", "Sedentary", "Regular exercise",
      -1, 1, 200, "Moderate",
    "cancer", "Diet", "Low fiber, high processed meat", "High fiber, plant-based",
      -2, 1, 150, "Moderate",
    "cancer", "Screening", "No screening", "Age-appropriate screening",
      -1, 1, 200, "High",
    "cancer", "Sun exposure", "Frequent sunburn", "Sun protection",
      -0.5, 0, 100, "Moderate",
    "cancer", "Family history", "Strong family history, no surveillance", "Enhanced surveillance",
      -2, -1, 50, "Moderate",

    # Respiratory
    "respiratory", "Smoking", "Current smoker", "Never/quit 10+ years",
      -5, 0, 100, "High",
    "respiratory", "Air quality", "High pollution exposure", "Low pollution",
      -1, 0, 100, "High",
    "respiratory", "Vaccination", "No flu/pneumonia vaccines", "Annual flu + PPSV23",
      -1, 0, 100, "High",
    "respiratory", "Occupational", "Dust/fume exposure without PPE", "PPE compliant",
      -1, 0, 100, "Moderate",

    # Infectious disease
    "infectious", "Childhood vaccines", "Unvaccinated", "Complete schedule",
      -1.5, 0, 100, "High",
    "infectious", "Adult vaccines", "No flu/COVID vaccines", "Up to date",
      -1, 0, 100, "High",
    "infectious", "COVID-19 (age 65+)", "Unvaccinated", "Bivalent booster",
      -3, -0.1, 97, "High",
    "infectious", "Hygiene", "Poor hand hygiene", "Regular handwashing",
      -0.3, 0, 100, "Moderate"
  )

  if (disease != "all") {
    all_risks <- all_risks |>
      dplyr::filter(disease_category == disease)
  }

  all_risks |>
    dplyr::mutate(
      # Net microlives gained by hedging
      microlives_gained = hedged_microlives_per_day - unhedged_microlives_per_day,
      # Annual effect in days
      annual_days_gained = round(microlives_gained * 365 * 30 / (24 * 60), 1),
      # Convert to micromorts equivalent
      micromorts_equivalent_per_day = round(microlives_gained / 0.7, 1)
    )
}

#' Hedged Portfolio Risk Summary
#'
#' Calculate total risk reduction from adopting an optimal "hedged" lifestyle
#' across multiple disease categories.
#'
#' @param include_diseases Character vector. Which disease categories to include.
#'   Default is all: cardiovascular, cancer, respiratory, infectious.
#' @return A tibble with total hedged vs unhedged comparison and breakdown.
#' @export
#' @family conditional-risk
#' @seealso [cancer_risks()], [vaccination_risks()], [conditional_risk()]
#' @examples
#' hedged_portfolio()
#' hedged_portfolio(include_diseases = c("cardiovascular", "cancer"))
hedged_portfolio <- function(include_diseases = c("cardiovascular", "cancer",
                                                    "respiratory", "infectious")) {
  # Get all conditional risks
  all_risks <- conditional_risk("all") |>
    dplyr::filter(disease_category %in% include_diseases)

  # Sum by disease category (avoiding double-counting smoking)
  by_category <- all_risks |>
    dplyr::group_by(disease_category) |>
    dplyr::summarise(
      n_factors = dplyr::n(),
      total_unhedged_ml = sum(unhedged_microlives_per_day),
      total_hedged_ml = sum(hedged_microlives_per_day),
      total_ml_gained = sum(microlives_gained),
      .groups = "drop"
    )

  # Calculate portfolio totals
  # Note: Some factors (smoking) affect multiple diseases - we take max effect
  smoking_effect <- all_risks |>
    dplyr::filter(risk_factor == "Smoking") |>
    dplyr::summarise(max_effect = max(microlives_gained)) |>
    dplyr::pull(max_effect)

  # Deduplicated total (remove smoking overlap)
  overlap_adjustment <- smoking_effect * (length(unique(all_risks$disease_category[all_risks$risk_factor == "Smoking"])) - 1)

  portfolio_total <- tibble::tibble(
    metric = c(
      "Total microlives gained per day (raw)",
      "Overlap adjustment (smoking affects multiple diseases)",
      "Net microlives gained per day",
      "Annual days of life gained",
      "Equivalent micromorts avoided per day",
      "Life expectancy gain over 40 years (days)"
    ),
    value = c(
      sum(by_category$total_ml_gained),
      -overlap_adjustment,
      sum(by_category$total_ml_gained) - overlap_adjustment,
      round((sum(by_category$total_ml_gained) - overlap_adjustment) * 365 * 30 / (24 * 60), 1),
      round((sum(by_category$total_ml_gained) - overlap_adjustment) / 0.7, 1),
      round((sum(by_category$total_ml_gained) - overlap_adjustment) * 365 * 40 * 30 / (24 * 60), 0)
    )
  )

  list(
    by_category = by_category,
    portfolio_summary = portfolio_total,
    included_diseases = include_diseases,
    note = "Smoking effects deduplicated across disease categories to avoid double-counting."
  )
}
