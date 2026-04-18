# Suppress R CMD check notes for NSE column references
utils::globalVariables(c(
 "activity_id", "component_id", "component", "risk_category",
 "component_label", "duration_hours", "hedgeable", "hedge_description",
 "hedge_reduction_pct", "condition_variable", "condition_value",
 "confidence", "notes", ".row_order", "n_components", "hedgeable_pct",
 "dist", ".env", ".data", "estimate_range", "source_count",
 # risk_equivalence.R
 "ratio", "reference_micromorts", "equivalence",
 # visualization.R
 "hedge_label"
))

#' Atomic Risk Components
#'
#' Returns a tibble where each row represents ONE risk component of ONE
#' activity. Different risk types (physical, medical, radiation) are never
#' mixed in the same row. This is the foundational dataset from which
#' [common_risks()] aggregates composite values.
#'
#' Activities that have not yet been decomposed use `component = "all_causes"`
#' and `risk_category = "mixed"` as honest placeholders.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{component_id}{Unique identifier: `{activity_id}_{component}_{condition}`}
#'     \item{activity_id}{Groups components into one activity}
#'     \item{activity}{Human-readable activity name with duration}
#'     \item{component}{Risk component: `"all_causes"`, `"crash"`, `"dvt"`, `"radiation"`, etc.}
#'     \item{risk_category}{`"physical"`, `"medical"`, `"radiation"`, `"environmental"`, `"mixed"`}
#'     \item{component_label}{Human-readable label for this component}
#'     \item{micromorts}{Risk for this component at this duration for this condition}
#'     \item{duration_hours}{Activity duration this row applies to (`NA` for non-duration-dependent)}
#'     \item{category}{Activity category: `"Travel"`, `"Medical"`, `"Daily Life"`, etc.}
#'     \item{period}{Human-readable period: `"per day"`, `"per event"`, etc.}
#'     \item{period_type}{`"event"`, `"day"`, `"hour"`, `"year"`, `"month"`, `"period"`}
#'     \item{hedgeable}{Can this component be mitigated?}
#'     \item{hedge_description}{How to mitigate (if hedgeable)}
#'     \item{hedge_reduction_pct}{Estimated percent reduction from hedging}
#'     \item{condition_variable}{What this risk depends on: `"health_profile"`, `"geography"`, `"country"`, `"age"`, or `NA`}
#'     \item{condition_value}{Condition value: `"healthy"`, `"dvt_risk_factors"`, `"high_income"`, `"low_income"`, `"allergic"`, `"all_ages"`, age groups (e.g. `"under_65"`, `"65_74_male"`, `"85_plus_male"`), ISO-2 country codes (e.g. `"US"`, `"UK"`), or `NA`}
#'     \item{confidence}{Data confidence: `"high"`, `"medium"`, `"low"`, `"estimated"`}
#'     \item{source_url}{Citation URL}
#'     \item{notes}{Scaling behavior, caveats}
#'     \item{validation_status}{`"single_source"`, `"corroborated"`, or `"cross_validated"`}
#'     \item{source_count}{Integer count of independent sources checked}
#'     \item{estimate_range}{Character range (e.g. `"0.05-0.15"`) or `NA` for point estimates}
#'   }
#' @export
#' @seealso [common_risks()] for the aggregated view.
#' @examples
#' atomic_risks()
#' atomic_risks() |> dplyr::filter(component != "all_causes")
#' atomic_risks() |> dplyr::filter(hedgeable)
atomic_risks <- function() {
  wiki_mm <- "https://en.wikipedia.org/wiki/Micromort"
  mm_rip <- "https://micromorts.rip/"
  cdc_mmwr <- "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm"
  nrc_url <- "https://www.nrc.gov/about-nrc/radiation/health-effects.html"

  # ── Part 1: Legacy all_causes activities (undecomposed) ──────────────────
  # "Flying (1000 miles)" removed — replaced by decomposed flight rows
  legacy_raw <- tibble::tribble(
    ~activity, ~micromorts, ~category, ~period, ~source_url,

    # Extreme Risk (>1000 micromorts)
    "Mt. Everest ascent", 37932, "Mountaineering", "per ascent", mm_rip,
    "Himalayan mountaineering", 12000, "Mountaineering", "per expedition", mm_rip,
    "COVID-19 infection (unvaccinated)", 10000, "COVID-19", "per infection", mm_rip,
    "Spanish flu infection", 3000, "Disease", "per infection", mm_rip,
    "Matterhorn ascent", 2840, "Mountaineering", "per ascent", mm_rip,

    # Very High Risk (100-1000 micromorts)
    "Living in US during COVID-19 (Jul 2020)", 500, "COVID-19", "per month", mm_rip,
    "Living (one day, age 90)", 463, "Daily Life", "per day", mm_rip,
    "Base jumping (per jump)", 430, "Sport", "per jump", mm_rip,
    "First day of life (newborn)", 430, "Daily Life", "per day", mm_rip,
    "COVID-19 unvaccinated (age 80+)", 234, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Caesarean birth (mother)", 170, "Medical", "per event", mm_rip,
    "Scuba diving, trained (yearly)", 164, "Sport", "per year", mm_rip,
    "Vaginal birth (mother)", 120, "Medical", "per event", mm_rip,
    "Living (one day, age 75)", 105, "Daily Life", "per day", mm_rip,

    # High Risk (10-100 micromorts)
    "COVID-19 unvaccinated (age 65-79)", 76, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Night in hospital", 75, "Medical", "per night", mm_rip,
    "COVID-19 monovalent vaccine (age 80+)", 55, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Living in NYC COVID-19 (Mar-May 2020)", 50, "COVID-19", "per 8 weeks", mm_rip,
    "Heroin use (per dose)", 30, "Drugs", "per dose", mm_rip,
    "US military in Afghanistan (2010)", 25, "Military", "per day", mm_rip,
    "COVID-19 bivalent booster (age 80+)", 23, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "COVID-19 unvaccinated (all ages)", 20, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "American football", 20, "Sport", "per game", mm_rip,
    "Living (one day, under age 1)", 15, "Daily Life", "per day", mm_rip,
    "Ecstasy/MDMA (per dose)", 13, "Drugs", "per dose", mm_rip,
    "Swimming", 12, "Sport", "per swim", mm_rip,
    "General anesthesia (emergency)", 10, "Medical", "per event", mm_rip,
    "Motorcycling (60 miles)", 10, "Travel", "per trip", wiki_mm,
    "Skydiving (per jump)", 10, "Sport", "per jump", mm_rip,

    # Moderate Risk (1-10 micromorts)
    "COVID-19 monovalent vaccine (age 65-79)", 9, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Skydiving (US)", 8, "Sport", "per event", mm_rip,
    "Skydiving (UK)", 8, "Sport", "per event", mm_rip,
    "COVID-19 unvaccinated (age 50-64)", 8, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Hang gliding (per flight)", 8, "Sport", "per flight", mm_rip,
    "Running a marathon", 7, "Sport", "per event", wiki_mm,
    "Living in Maryland COVID-19 (Mar-May 2020)", 7, "COVID-19", "per 8 weeks", mm_rip,
    "Living (one day, age 45)", 6, "Daily Life", "per day", mm_rip,
    "Scuba diving, trained (per dive)", 5, "Sport", "per dive", wiki_mm,
    "Living (one day, age 50)", 4, "Daily Life", "per day", wiki_mm,
    "COVID-19 monovalent vaccine (all ages)", 4, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Rock climbing (per day)", 3, "Sport", "per day", mm_rip,
    "COVID-19 bivalent booster (age 65-79)", 3, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "COVID-19 monovalent vaccine (age 50-64)", 2, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "COVID-19 unvaccinated (age 18-49)", 1, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Living 2 months with a smoker", 1, "Environment", "per 2 months", mm_rip,
    "Walking (20 miles)", 1, "Travel", "per trip", wiki_mm,
    "Walking (1 trip, NYC)", 0.09, "Travel", "per trip", "https://www.nature.com/articles/s44284-025-00383-y",
    "Driving (230 miles)", 1, "Travel", "per trip", wiki_mm,
    "Train (1000 miles)", 1, "Travel", "per trip", mm_rip,
    "Eating 1000 bananas (radiation)", 1, "Diet", "per event", mm_rip,
    "1 hour in a coal mine", 1, "Occupation", "per hour", mm_rip,
    "Eating 40 tbsp peanut butter (aflatoxin)", 1, "Diet", "per event", wiki_mm,
    "Eating 100 charbroiled steaks (cumulative benzopyrene)", 1, "Diet", "per 100 steaks", mm_rip,
    "Living (one day, age 20)", 1, "Daily Life", "per day", wiki_mm,
    "Living (one day, age 30)", 1, "Daily Life", "per day", wiki_mm,
    "COVID-19 bivalent booster (all ages)", 1, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "COVID-19 bivalent booster (age 50-64)", 1, "COVID-19", "11 weeks (2022)", cdc_mmwr,

    # Low Risk (<1 micromort)
    "Skiing", 0.7, "Sport", "per day", mm_rip,
    "Horse riding", 0.5, "Sport", "per ride", mm_rip,
    "COVID-19 monovalent vaccine (age 18-49)", 0.2, "COVID-19", "11 weeks (2022)", cdc_mmwr,
    "Kangaroo encounter", 0.1, "Wildlife", "per encounter", mm_rip,
    "COVID-19 bivalent booster (age 18-49)", 0.05, "COVID-19", "11 weeks (2022)", cdc_mmwr
  )

  legacy_raw$period_type <- parse_period_type(legacy_raw$period)

  legacy <- legacy_raw |>
    dplyr::mutate(
      activity_id = make_activity_id(activity),
      component = "all_causes",
      risk_category = "mixed",
      component_label = activity,
      component_id = paste0(activity_id, "_all_causes"),
      duration_hours = NA_real_,
      hedgeable = FALSE,
      hedge_description = NA_character_,
      hedge_reduction_pct = NA_real_,
      condition_variable = NA_character_,
      condition_value = NA_character_,
      confidence = "medium",
      notes = NA_character_
    )

  # ── Part 2: Decomposed flight components ─────────────────────────────────
  # Crash: ~1 mm per flight (dominated by takeoff/landing phases, roughly
  #   constant regardless of flight duration). Boeing Statistical Summary:
  #   ~80% of fatal accidents occur during takeoff, initial climb, approach,
  #   and landing — phases whose duration is independent of flight length.
  # DVT: zero below 4h, then nonlinear, medical, IS hedgeable (~65% reduction)
  # Cosmic radiation: ~0.05 mm/hour (linear), radiation, NOT hedgeable
  # Sources: Aviation Safety Network, Boeing Statistical Summary, Lancet Haematology, NCRP Report 160
  flight_source <- wiki_mm

  flights <- tibble::tribble(
    ~activity, ~activity_id, ~component, ~risk_category, ~component_label,
    ~micromorts, ~duration_hours, ~period,
    ~hedgeable, ~hedge_description, ~hedge_reduction_pct,
    ~condition_variable, ~condition_value, ~confidence,

    # ─ 2h short-haul ─
    "Flying (2h short-haul)", "flying_2h", "crash", "physical", "Aircraft crash",
    1.0, 2, "per 2h flight",
    FALSE, NA_character_, NA_real_,
    NA_character_, NA_character_, "high",

    "Flying (2h short-haul)", "flying_2h", "dvt", "medical", "Deep vein thrombosis",
    0.0, 2, "per 2h flight",
    TRUE, "Compression socks + hydration + aisle walks", 65,
    "health_profile", "healthy", "medium",

    "Flying (2h short-haul)", "flying_2h", "radiation", "radiation", "Cosmic radiation",
    0.1, 2, "per 2h flight",
    FALSE, NA_character_, NA_real_,
    NA_character_, NA_character_, "high",

    # DVT risk factors row for 2h (still zero below 4h threshold)
    "Flying (2h short-haul)", "flying_2h", "dvt", "medical", "Deep vein thrombosis",
    0.0, 2, "per 2h flight",
    TRUE, "Compression socks + hydration + aisle walks", 65,
    "health_profile", "dvt_risk_factors", "medium",

    # ─ 5h medium-haul ─
    "Flying (5h medium-haul)", "flying_5h", "crash", "physical", "Aircraft crash",
    1.0, 5, "per 5h flight",
    FALSE, NA_character_, NA_real_,
    NA_character_, NA_character_, "high",

    "Flying (5h medium-haul)", "flying_5h", "dvt", "medical", "Deep vein thrombosis",
    0.5, 5, "per 5h flight",
    TRUE, "Compression socks + hydration + aisle walks", 65,
    "health_profile", "healthy", "medium",

    "Flying (5h medium-haul)", "flying_5h", "dvt", "medical", "Deep vein thrombosis",
    1.5, 5, "per 5h flight",
    TRUE, "Compression socks + hydration + aisle walks", 65,
    "health_profile", "dvt_risk_factors", "medium",

    "Flying (5h medium-haul)", "flying_5h", "radiation", "radiation", "Cosmic radiation",
    0.25, 5, "per 5h flight",
    FALSE, NA_character_, NA_real_,
    NA_character_, NA_character_, "high",

    # ─ 8h long-haul ─
    "Flying (8h long-haul)", "flying_8h", "crash", "physical", "Aircraft crash",
    1.0, 8, "per 8h flight",
    FALSE, NA_character_, NA_real_,
    NA_character_, NA_character_, "high",

    "Flying (8h long-haul)", "flying_8h", "dvt", "medical", "Deep vein thrombosis",
    2.5, 8, "per 8h flight",
    TRUE, "Compression socks + hydration + aisle walks", 65,
    "health_profile", "healthy", "medium",

    "Flying (8h long-haul)", "flying_8h", "dvt", "medical", "Deep vein thrombosis",
    8.0, 8, "per 8h flight",
    TRUE, "Compression socks + hydration + aisle walks", 65,
    "health_profile", "dvt_risk_factors", "medium",

    "Flying (8h long-haul)", "flying_8h", "radiation", "radiation", "Cosmic radiation",
    0.4, 8, "per 8h flight",
    FALSE, NA_character_, NA_real_,
    NA_character_, NA_character_, "high",

    # ─ 12h ultra-long-haul ─
    "Flying (12h ultra-long-haul)", "flying_12h", "crash", "physical", "Aircraft crash",
    1.0, 12, "per 12h flight",
    FALSE, NA_character_, NA_real_,
    NA_character_, NA_character_, "high",

    "Flying (12h ultra-long-haul)", "flying_12h", "dvt", "medical", "Deep vein thrombosis",
    5.0, 12, "per 12h flight",
    TRUE, "Compression socks + hydration + aisle walks", 65,
    "health_profile", "healthy", "medium",

    "Flying (12h ultra-long-haul)", "flying_12h", "dvt", "medical", "Deep vein thrombosis",
    15.0, 12, "per 12h flight",
    TRUE, "Compression socks + hydration + aisle walks", 65,
    "health_profile", "dvt_risk_factors", "medium",

    "Flying (12h ultra-long-haul)", "flying_12h", "radiation", "radiation", "Cosmic radiation",
    0.6, 12, "per 12h flight",
    FALSE, NA_character_, NA_real_,
    NA_character_, NA_character_, "high"
  ) |>
    dplyr::mutate(
      category = "Travel",
      period_type = "event",
      source_url = flight_source,
      component_id = paste0(
        activity_id, "_",
        duration_hours, "h_",
        component, "_",
        dplyr::coalesce(condition_value, "uncon")
      ),
      notes = dplyr::case_when(
        component == "crash" ~ "~1 mm per flight; dominated by takeoff/landing phases (Boeing Statistical Summary)",
        component == "dvt" ~ "Zero below 4h threshold; nonlinear growth above",
        component == "radiation" ~ "Linear ~0.05 mm/hour; NCRP Report 160"
      )
    )

  # ── Part 3: Medical radiation activities (already atomic) ────────────────
  med_rad <- tibble::tribble(
    ~activity, ~micromorts, ~component, ~component_label,
    "Chest X-ray (radiation per scan)", 0.1, "radiation", "Ionizing radiation dose",
    "CT scan chest (radiation per scan)", 7, "radiation", "Ionizing radiation dose",
    "CT scan abdomen (radiation per scan)", 10, "radiation", "Ionizing radiation dose",
    "Mammogram (radiation per scan)", 0.1, "radiation", "Ionizing radiation dose",
    "Dental X-ray (radiation per scan)", 0.05, "radiation", "Ionizing radiation dose",
    "Coronary angiogram (radiation per scan)", 5, "radiation", "Ionizing radiation dose",
    "Barium enema (radiation per scan)", 3, "radiation", "Ionizing radiation dose",
    "CT scan head (radiation per scan)", 2, "radiation", "Ionizing radiation dose"
  ) |>
    dplyr::mutate(
      activity_id = make_activity_id(activity),
      risk_category = "radiation",
      category = "Medical",
      period = "per event",
      period_type = "event",
      source_url = nrc_url,
      component_id = paste0(activity_id, "_radiation"),
      duration_hours = NA_real_,
      hedgeable = FALSE,
      hedge_description = NA_character_,
      hedge_reduction_pct = NA_real_,
      condition_variable = NA_character_,
      condition_value = NA_character_,
      confidence = "high",
      notes = "Radiation dose is the primary risk; procedural risks separate"
    )

  # ── Part 4: Mundane everyday activities ──────────────────────────────────
  mundane <- tibble::tribble(
    ~activity, ~micromorts, ~component, ~risk_category, ~component_label,
    ~category, ~period,
    "Cup of coffee", 0.01, "all_causes", "mixed",
    "Caffeine effects", "Daily Life", "per event",
    "Commuting by car (30 min)", 0.13, "crash", "physical",
    "Vehicle crash", "Travel", "per trip",
    "Commuting by bicycle (30 min)", 0.12, "all_causes", "mixed",
    "Traffic collision + exertion", "Travel", "per trip",
    "Working in an office (8 hours)", 0.03, "all_causes", "mixed",
    "Background mortality rate", "Daily Life", "per day",
    "Taking a bath", 0.07, "drowning", "physical",
    "Drowning risk", "Daily Life", "per event",
    "Crossing a road", 0.02, "crash", "physical",
    "Pedestrian collision", "Daily Life", "per event"
  ) |>
    dplyr::mutate(
      activity_id = make_activity_id(activity),
      period_type = parse_period_type(period),
      source_url = wiki_mm,
      component_id = paste0(activity_id, "_", component),
      duration_hours = NA_real_,
      hedgeable = FALSE,
      hedge_description = NA_character_,
      hedge_reduction_pct = NA_real_,
      condition_variable = NA_character_,
      condition_value = NA_character_,
      confidence = "medium",
      notes = NA_character_
    )

  # ── Part 5: Annual occupational/environmental/passenger radiation ────────
  # LNT model (Brenner & Hall 2007 NEJM): 50 micromorts per Sv = 0.05 mm/mSv
  # Annual doses from UNSCEAR 2020, ICRP 103, FAA CARI-7
  unscear_url <- "https://www.unscear.org/unscear/en/publications/2020.html"

  annual_rad <- tibble::tribble(
    ~activity, ~activity_id, ~micromorts, ~category,
    ~hedgeable, ~hedge_description, ~confidence,

    # Occupational
    "Airline pilot (annual radiation)", "airline_pilot_annual",
    0.15, "Occupation",
    TRUE, "Flight hour limits + route planning", "medium",

    "X-ray technician (annual radiation)", "xray_tech_annual",
    0.05, "Occupation",
    TRUE, "Lead shielding + ALARA protocols", "medium",

    "Dental radiographer (annual radiation)", "dental_radiographer_annual",
    0.01, "Occupation",
    TRUE, "Lead apron + distance protocols", "medium",

    "Nuclear plant worker (annual radiation)", "nuclear_worker_annual",
    0.10, "Occupation",
    TRUE, "Shielding + dosimetry + ALARA", "medium",

    "Interventional cardiologist (annual radiation)", "interventional_cardiologist_annual",
    0.175, "Occupation",
    TRUE, "Lead apron + ceiling shield + dosimetry", "medium",

    # Passenger (cosmic)
    "Frequent executive flyer (annual cosmic)", "executive_flyer_annual",
    0.15, "Travel",
    FALSE, NA_character_, "medium",

    "Business traveller (annual cosmic)", "business_traveller_annual",
    0.0375, "Travel",
    FALSE, NA_character_, "estimated",

    "Annual tourist flyer (annual cosmic)", "annual_tourist_annual",
    0.006, "Travel",
    FALSE, NA_character_, "estimated",

    # Environmental
    "Granite resident (annual radon)", "granite_resident_annual",
    0.10, "Environment",
    TRUE, "Radon mitigation + ventilation", "medium",

    "High-altitude resident (annual cosmic)", "high_altitude_resident_annual",
    0.035, "Environment",
    FALSE, NA_character_, "medium",

    "Normal background radiation", "background_radiation_annual",
    0.12, "Environment",
    FALSE, NA_character_, "high"
  ) |>
    dplyr::mutate(
      component = "radiation",
      risk_category = "radiation",
      component_label = "Ionizing radiation dose",
      period = "per year",
      period_type = "year",
      source_url = unscear_url,
      component_id = paste0(activity_id, "_radiation"),
      duration_hours = NA_real_,
      hedge_reduction_pct = dplyr::if_else(hedgeable, 50, NA_real_),
      condition_variable = NA_character_,
      condition_value = NA_character_,
      notes = "LNT model: 0.05 mm/mSv (Brenner & Hall 2007 NEJM)"
    )

  # ── Part 6: Wildlife encounters ──────────────────────────────────────────

  # Sources: ISAF (shark), CDC (dog US, bee, snake US), WHO/Lancet (dog/snake

  # low-income), OWID Deadliest Animals. Geographic conditioning reuses
  # condition_variable/condition_value infrastructure (same as health_profile).
  cdc_url <- "https://www.cdc.gov/injury/"
  who_snakebite <- "https://www.who.int/news-room/fact-sheets/detail/snakebite-envenoming"
  isaf_url <- "https://www.floridamuseum.ufl.edu/shark-attacks/"

  wildlife <- tibble::tribble(
    ~activity, ~activity_id, ~micromorts, ~component, ~risk_category,
    ~component_label, ~category, ~period,
    ~hedgeable, ~hedge_description, ~hedge_reduction_pct,
    ~condition_variable, ~condition_value, ~confidence, ~source_url,

    # Shark: ~6 deaths/yr / ~100M ocean interactions = 0.06 mm (ISAF)
    "Shark encounter (ocean swim)", "shark_encounter",
    0.06, "all_causes", "mixed", "Shark attack fatality",
    "Wildlife", "per swim",
    TRUE, "Avoid murky water, dawn/dusk, seal colonies", 50,
    NA_character_, NA_character_, "medium", isaf_url,

    # Dog bite US: ~30 deaths/yr / ~4.5M bites = 6.7 mm (CDC)
    "Dog bite (US)", "dog_bite_us",
    6.7, "all_causes", "mixed", "Dog bite fatality (high-income setting)",
    "Wildlife", "per bite",
    TRUE, "Avoid unfamiliar dogs, rabies PEP available", 80,
    "geography", "high_income", "medium", cdc_url,

    # Dog bite rabies-endemic: ~40k deaths/yr / ~250k bites = 160 mm (WHO)
    "Dog bite (rabies-endemic)", "dog_bite_rabies",
    160, "all_causes", "mixed", "Dog bite fatality (rabies-endemic, limited PEP)",
    "Wildlife", "per bite",
    TRUE, "Pre-exposure rabies vaccine, seek immediate PEP", 90,
    "geography", "low_income", "low", who_snakebite,

    # Bee/wasp general: ~62 US deaths/yr / ~2M stings = 0.03 mm
    "Bee/wasp sting (general)", "bee_sting_general",
    0.03, "all_causes", "mixed", "Bee/wasp sting fatality (non-allergic)",
    "Wildlife", "per sting",
    TRUE, "Avoid nests, wear shoes outdoors", 30,
    "health_profile", "healthy", "medium", cdc_url,

    # Bee/wasp allergic: ~62 deaths among ~200k allergic exposures = 31 mm
    "Bee/wasp sting (allergic)", "bee_sting_allergic",
    31, "all_causes", "mixed", "Anaphylactic bee/wasp sting fatality",
    "Wildlife", "per sting",
    TRUE, "Carry epinephrine auto-injector, immunotherapy", 95,
    "health_profile", "allergic", "low", cdc_url,

    # Snake US: ~5 deaths/yr / ~10k bites = 0.5 mm (CDC)
    "Snake bite (US, with antivenom)", "snake_bite_us",
    0.5, "all_causes", "mixed", "Snake bite fatality (antivenom available)",
    "Wildlife", "per bite",
    TRUE, "Wear boots in snake habitat, carry pressure bandage", 60,
    "geography", "high_income", "medium", cdc_url,

    # Snake rural Africa: ~100k deaths/yr / ~5.4M bites = 18.5 mm (WHO/Lancet)
    "Snake bite (rural sub-Saharan Africa)", "snake_bite_africa",
    18.5, "all_causes", "mixed", "Snake bite fatality (limited antivenom access)",
    "Wildlife", "per bite",
    TRUE, "Footwear, torch at night, proximity to clinic", 40,
    "geography", "low_income", "low", who_snakebite
  ) |>
    dplyr::mutate(
      period_type = parse_period_type(period),
      component_id = paste0(
        activity_id, "_all_causes_",
        dplyr::coalesce(condition_value, "uncon")
      ),
      duration_hours = NA_real_,
      notes = dplyr::case_when(
        grepl("shark", activity_id) ~ "ISAF: ~6 fatalities/yr among ~100M ocean interactions",
        grepl("dog.*us", activity_id) ~ "CDC: ~30 deaths/yr among ~4.5M bites requiring medical attention",
        grepl("dog.*rabies", activity_id) ~ "WHO: ~40k rabies deaths/yr, mostly dog-mediated",
        grepl("bee.*general", activity_id) ~ "CDC: ~62 deaths/yr among ~2M stings/yr (non-allergic)",
        grepl("bee.*allergic", activity_id) ~ "CDC: ~62 deaths concentrated among ~200k allergic exposures",
        grepl("snake.*us", activity_id) ~ "CDC: ~5 deaths/yr among ~10k bites",
        grepl("snake.*africa", activity_id) ~ "WHO/Lancet: ~100k deaths/yr among ~5.4M bites in sub-Saharan Africa"
      ),
      validation_status = "corroborated",
      source_count = 2L,
      estimate_range = dplyr::case_when(
        grepl("shark", activity_id) ~ "0.03-0.10",
        grepl("dog.*us", activity_id) ~ "5-10",
        grepl("dog.*rabies", activity_id) ~ "100-250",
        grepl("bee.*general", activity_id) ~ "0.02-0.05",
        grepl("bee.*allergic", activity_id) ~ "20-50",
        grepl("snake.*us", activity_id) ~ "0.3-1.0",
        grepl("snake.*africa", activity_id) ~ "10-30"
      )
    )

  # ── Part 7: Occupational fatality risks (BLS CFOI 2022) ────────────────
  # Source: BLS Census of Fatal Occupational Injuries 2022
  # Conversion: rate_per_100k_FTE → mm/work_day (see data-raw/03_osha_occupational_risks.R)
  bls_url <- "https://www.bls.gov/iif/fatal-injuries-tables.htm"

  occupational <- tibble::tribble(
    ~activity, ~activity_id, ~micromorts,

    "Logging (per work day)",                  "logging_work_day",          3.3,
    "Commercial fishing (per work day)",       "fishing_work_day",          3.0,
    "Roofing (per work day)",                  "roofing_work_day",          1.9,
    "Structural iron/steel work (per work day)", "ironworker_work_day",     1.5,
    "Truck driving (per work day)",            "truck_driving_work_day",    1.2,
    "Mining (per work day)",                   "mining_work_day",           0.9,
    "Agriculture (per work day)",              "agriculture_work_day",      0.7,
    "Construction (all trades, per work day)",  "construction_work_day",     0.5,
    "All US workers baseline (per work day)",  "all_workers_baseline",      0.15
  ) |>
    dplyr::mutate(
      component = "all_causes",
      risk_category = "mixed",
      component_label = activity,
      category = "Occupation",
      period = "per day",
      period_type = "day",
      source_url = bls_url,
      component_id = paste0(activity_id, "_all_causes"),
      duration_hours = NA_real_,
      hedgeable = FALSE,
      hedge_description = NA_character_,
      hedge_reduction_pct = NA_real_,
      condition_variable = NA_character_,
      condition_value = NA_character_,
      confidence = "high",
      notes = "BLS CFOI 2022; rate_per_100k_FTE / 2000 * 8 = mm/work_day",
      validation_status = "corroborated",
      source_count = 2L,
      estimate_range = NA_character_
    )

  # ── Part 8: Road traffic mortality by country (WHO 2023) ───────────────
  # Source: WHO Global Status Report on Road Safety 2023
  # Conversion: rate_per_100k_year / 365 * 10 = mm/day
  who_road_url <- "https://www.who.int/publications/i/item/9789240086517"

  road_traffic <- tibble::tribble(
    ~activity, ~condition_value, ~micromorts,

    "Daily road traffic risk (US)", "US", 0.35,
    "Daily road traffic risk (UK)", "UK", 0.08,
    "Daily road traffic risk (Germany)", "DE", 0.10,
    "Daily road traffic risk (Japan)", "JP", 0.07,
    "Daily road traffic risk (India)", "IN", 0.62,
    "Daily road traffic risk (Brazil)", "BR", 0.50
  ) |>
    dplyr::mutate(
      activity_id = "daily_road_traffic",
      component = "all_causes",
      risk_category = "mixed",
      component_label = activity,
      category = "Travel",
      period = "per day",
      period_type = "day",
      source_url = who_road_url,
      component_id = paste0("daily_road_traffic_all_causes_", condition_value),
      duration_hours = NA_real_,
      hedgeable = FALSE,
      hedge_description = NA_character_,
      hedge_reduction_pct = NA_real_,
      condition_variable = "country",
      confidence = "high",
      notes = "WHO 2023; rate_per_100k_year / 365 * 10 = mm/day",
      validation_status = "corroborated",
      source_count = 2L,
      estimate_range = NA_character_
    )

  # ── Part 9: Homicide rates by country (UNODC 2023) ────────────────────
  # Source: UNODC Global Study on Homicide 2023
  # Conversion: rate_per_100k_year / 365 * 10 = mm/day
  unodc_url <- "https://www.unodc.org/unodc/en/data-and-analysis/global-study-on-homicide.html"

  homicide <- tibble::tribble(
    ~activity, ~condition_value, ~micromorts,

    "Daily homicide risk (US)", "US", 0.18,
    "Daily homicide risk (UK)", "UK", 0.03,
    "Daily homicide risk (Japan)", "JP", 0.008,
    "Daily homicide risk (India)", "IN", 0.08,
    "Daily homicide risk (Brazil)", "BR", 0.62,
    "Daily homicide risk (Honduras)", "HN", 1.07
  ) |>
    dplyr::mutate(
      activity_id = "daily_homicide",
      component = "all_causes",
      risk_category = "mixed",
      component_label = activity,
      category = "Daily Life",
      period = "per day",
      period_type = "day",
      source_url = unodc_url,
      component_id = paste0("daily_homicide_all_causes_", condition_value),
      duration_hours = NA_real_,
      hedgeable = FALSE,
      hedge_description = NA_character_,
      hedge_reduction_pct = NA_real_,
      condition_variable = "country",
      confidence = "high",
      notes = "UNODC 2023; rate_per_100k_year / 365 * 10 = mm/day",
      validation_status = "corroborated",
      source_count = 2L,
      estimate_range = NA_character_
    )

  # ── Part 10: Age-conditioned activities (CDC / NHS data) ───────────────
  # These activities have dramatic age-dependent risk (confounding vignette).
  # condition_variable = "age", with "all_ages" as the population-average default.
  cpsc_url <- "https://www.cpsc.gov/Newsroom/News-Releases/2022/Older-Americans-Are-More-Likely-to-Suffer-Fatalities-from-Falls-and-Fire-CPSC-Report-Highlights-Hidden-Hazards-Around-the-Home"
  cdc_falls_url <- "https://www.cdc.gov/nchs/products/databriefs/db532.htm"
  cdc_drowning_url <- "https://www.cdc.gov/drowning/data/index.html"

  age_conditioned <- tibble::tribble(
    ~activity, ~activity_id, ~micromorts, ~component, ~risk_category,
    ~component_label, ~category, ~period,
    ~condition_variable, ~condition_value, ~confidence, ~source_url, ~notes,

    # ─ Bed falls (CDC Data Brief 532 + CPSC) ─
    # ~450 US deaths/yr; 2500-fold age difference
    "Bed fall (per night)", "bed_fall",
    0.004, "all_causes", "physical", "Fall from bed",
    "Daily Life", "per night",
    "age", "under_65", "high", cdc_falls_url,
    "CDC: ~0.4 deaths/100k/yr for under-65; / 365 * 10 = 0.004 mm/night",

    "Bed fall (per night)", "bed_fall",
    0.68, "all_causes", "physical", "Fall from bed",
    "Daily Life", "per night",
    "age", "65_74_male", "high", cdc_falls_url,
    "CDC: 24.7 deaths/100k/yr for 65-74 males; / 365 * 10 = 0.68 mm/night",

    "Bed fall (per night)", "bed_fall",
    0.39, "all_causes", "physical", "Fall from bed",
    "Daily Life", "per night",
    "age", "65_74_female", "high", cdc_falls_url,
    "CDC: 14.2 deaths/100k/yr for 65-74 females; / 365 * 10 = 0.39 mm/night",

    "Bed fall (per night)", "bed_fall",
    10.2, "all_causes", "physical", "Fall from bed",
    "Daily Life", "per night",
    "age", "85_plus_male", "high", cdc_falls_url,
    "CDC: 373.3 deaths/100k/yr for 85+ males; / 365 * 10 = 10.2 mm/night",

    "Bed fall (per night)", "bed_fall",
    8.8, "all_causes", "physical", "Fall from bed",
    "Daily Life", "per night",
    "age", "85_plus_female", "high", cdc_falls_url,
    "CDC: 319.7 deaths/100k/yr for 85+ females; / 365 * 10 = 8.8 mm/night",

    # Population average (default for unspecified age)
    "Bed fall (per night)", "bed_fall",
    0.004, "all_causes", "physical", "Fall from bed",
    "Daily Life", "per night",
    "age", "all_ages", "high", cdc_falls_url,
    "Population average: ~450 deaths/yr / 330M / 365 * 1e6 ≈ 0.004 mm/night (dominated by elderly)",

    # ─ General anaesthesia (age-stratified) ─
    # Population average is ~10mm (emergency) but elective varies enormously by age
    # NHS/Lancet data: elective mortality 1:100k (young) to 1:10k (elderly)
    "General anaesthesia (elective)", "anaesthesia_elective",
    0.5, "all_causes", "medical", "Anaesthesia mortality",
    "Medical", "per event",
    "age", "under_60", "medium", "https://doi.org/10.1016/S0140-6736(02)11626-6",
    "Lancet: ~1:200k elective cases in under-60s; ~0.5 mm/event",

    "General anaesthesia (elective)", "anaesthesia_elective",
    5.0, "all_causes", "medical", "Anaesthesia mortality",
    "Medical", "per event",
    "age", "60_79", "medium", "https://doi.org/10.1016/S0140-6736(02)11626-6",
    "Lancet: ~1:20k elective cases age 60-79; ~5 mm/event",

    "General anaesthesia (elective)", "anaesthesia_elective",
    50.0, "all_causes", "medical", "Anaesthesia mortality",
    "Medical", "per event",
    "age", "80_plus", "medium", "https://doi.org/10.1016/S0140-6736(02)11626-6",
    "Lancet: ~1:2k elective cases age 80+; ~50 mm/event (100x young-adult rate)",

    # Population average (default)
    "General anaesthesia (elective)", "anaesthesia_elective",
    2.0, "all_causes", "medical", "Anaesthesia mortality",
    "Medical", "per event",
    "age", "all_ages", "medium", "https://doi.org/10.1016/S0140-6736(02)11626-6",
    "Population-weighted average elective anaesthesia mortality",

    # ─ Drowning (bath) — age-stratified ─
    # CDC: ~4000 US drowning deaths/yr, bimodal (children + elderly)
    "Taking a bath (age-conditioned)", "bath_age",
    0.3, "drowning", "physical", "Bathtub drowning",
    "Daily Life", "per event",
    "age", "under_5", "medium", cdc_drowning_url,
    "CDC: children 1-4 drown rate 7.6/100k/yr; bathtub subset ~0.3 mm/bath",

    "Taking a bath (age-conditioned)", "bath_age",
    0.02, "drowning", "physical", "Bathtub drowning",
    "Daily Life", "per event",
    "age", "5_64", "medium", cdc_drowning_url,
    "CDC: adults 5-64 bathtub drowning ~0.02 mm/bath",

    "Taking a bath (age-conditioned)", "bath_age",
    0.5, "drowning", "physical", "Bathtub drowning",
    "Daily Life", "per event",
    "age", "65_plus", "medium", cdc_drowning_url,
    "CDC: elderly bathtub drowning elevated; ~0.5 mm/bath",

    # Population average (default)
    "Taking a bath (age-conditioned)", "bath_age",
    0.07, "drowning", "physical", "Bathtub drowning",
    "Daily Life", "per event",
    "age", "all_ages", "medium", cdc_drowning_url,
    "Population average matching existing 'Taking a bath' entry"
  ) |>
    dplyr::mutate(
      period_type = parse_period_type(period),
      component_id = paste0(activity_id, "_", component, "_", condition_value),
      duration_hours = NA_real_,
      hedgeable = FALSE,
      hedge_description = NA_character_,
      hedge_reduction_pct = NA_real_,
      validation_status = "corroborated",
      source_count = 2L,
      estimate_range = NA_character_
    )

  # ── Part 11: Country-level disease mortality (OWID/GBD 2023) ───────────
  # Source: IHME Global Burden of Disease 2023, via Our World in Data
  # Age-standardised death rates per 100k/year

  # Conversion: rate_per_100k_year / 365 * 10 = mm/day
  owid_cvd_url <- "https://ourworldindata.org/grapher/cardiovascular-disease-death-rate"
  owid_cancer_url <- "https://ourworldindata.org/grapher/cancer-death-rates"
  owid_lri_url <- "https://ourworldindata.org/grapher/pneumonia-death-rates-age-standardized"
  owid_diarrheal_url <- "https://ourworldindata.org/grapher/diarrheal-disease-death-rates"

  make_disease_rows <- function(tribble_data, activity_id, category_label,
                                source_url) {
    tribble_data |>
      dplyr::mutate(
        activity_id = activity_id,
        component = "all_causes",
        risk_category = "medical",
        component_label = activity,
        category = "Disease",
        period = "per day",
        period_type = "day",
        source_url = source_url,
        component_id = paste0(activity_id, "_all_causes_", condition_value),
        duration_hours = NA_real_,
        hedgeable = FALSE,
        hedge_description = NA_character_,
        hedge_reduction_pct = NA_real_,
        condition_variable = "country",
        confidence = "high",
        notes = paste0(
          "IHME GBD 2023 via OWID; age-standardised ",
          category_label,
          " death rate / 365 * 10 = mm/day"
        ),
        validation_status = "corroborated",
        source_count = 2L,
        estimate_range = NA_character_
      )
  }

  # Cardiovascular disease (IHME GBD 2023)
  cvd_mortality <- make_disease_rows(
    tibble::tribble(
      ~activity, ~condition_value, ~micromorts,
      "Daily CVD mortality risk (UK)", "UK", round(118.38 / 365 * 10, 2),
      "Daily CVD mortality risk (US)", "US", round(144.15 / 365 * 10, 2),
      "Daily CVD mortality risk (Japan)", "JP", round(76.47 / 365 * 10, 2),
      "Daily CVD mortality risk (India)", "IN", round(279.11 / 365 * 10, 2),
      "Daily CVD mortality risk (Nigeria)", "NG", round(267.58 / 365 * 10, 2),
      "Daily CVD mortality risk (Brazil)", "BR", round(146.97 / 365 * 10, 2)
    ),
    "daily_cvd_mortality", "cardiovascular", owid_cvd_url
  )

  # Cancer — all neoplasms (IHME GBD 2023)
  cancer_mortality <- make_disease_rows(
    tibble::tribble(
      ~activity, ~condition_value, ~micromorts,
      "Daily cancer mortality risk (UK)", "UK", round(144.33 / 365 * 10, 2),
      "Daily cancer mortality risk (US)", "US", round(115.04 / 365 * 10, 2),
      "Daily cancer mortality risk (Japan)", "JP", round(119.39 / 365 * 10, 2),
      "Daily cancer mortality risk (India)", "IN", round(83.92 / 365 * 10, 2),
      "Daily cancer mortality risk (Nigeria)", "NG", round(101.88 / 365 * 10, 2),
      "Daily cancer mortality risk (Brazil)", "BR", round(110.10 / 365 * 10, 2)
    ),
    "daily_cancer_mortality", "cancer (neoplasms)", owid_cancer_url
  )

  # Lower respiratory infections (IHME GBD 2023)
  lri_mortality <- make_disease_rows(
    tibble::tribble(
      ~activity, ~condition_value, ~micromorts,
      "Daily LRI mortality risk (UK)", "UK", round(19.20 / 365 * 10, 2),
      "Daily LRI mortality risk (US)", "US", round(10.47 / 365 * 10, 2),
      "Daily LRI mortality risk (Japan)", "JP", round(15.84 / 365 * 10, 2),
      "Daily LRI mortality risk (India)", "IN", round(39.75 / 365 * 10, 2),
      "Daily LRI mortality risk (Nigeria)", "NG", round(64.54 / 365 * 10, 2),
      "Daily LRI mortality risk (Brazil)", "BR", round(40.08 / 365 * 10, 2)
    ),
    "daily_lri_mortality", "lower respiratory infection", owid_lri_url
  )

  # Diarrheal diseases (IHME GBD 2023)
  diarrheal_mortality <- make_disease_rows(
    tibble::tribble(
      ~activity, ~condition_value, ~micromorts,
      "Daily diarrheal mortality risk (UK)", "UK", round(0.69 / 365 * 10, 2),
      "Daily diarrheal mortality risk (US)", "US", round(1.36 / 365 * 10, 2),
      "Daily diarrheal mortality risk (Japan)", "JP", round(0.68 / 365 * 10, 2),
      "Daily diarrheal mortality risk (India)", "IN", round(46.69 / 365 * 10, 2),
      "Daily diarrheal mortality risk (Nigeria)", "NG", round(32.19 / 365 * 10, 2),
      "Daily diarrheal mortality risk (Brazil)", "BR", round(2.83 / 365 * 10, 2)
    ),
    "daily_diarrheal_mortality", "diarrheal disease", owid_diarrheal_url
  )

  # ── Part 12: Risk-factor-attributed mortality (OWID/GBD 2023) ──────────
  # Deaths attributable to specific risk factors (not disease categories).
  # Source: IHME GBD 2023 risk factor data via Our World in Data API.
  # These are ATTRIBUTABLE deaths — the fraction of total deaths caused by

  # each risk factor. They overlap with Part 11 disease categories (e.g.,
  # smoking-attributed deaths include lung cancer + CVD + COPD).
  # Conversion: rate_per_100k_year / 365 * 10 = mm/day
  owid_smoking_url <- "https://ourworldindata.org/grapher/death-rate-smoking"
  owid_pollution_url <- "https://ourworldindata.org/grapher/death-rate-from-air-pollution-per-100000"
  owid_obesity_url <- "https://ourworldindata.org/grapher/death-rate-from-obesity"
  owid_alcohol_url <- "https://ourworldindata.org/grapher/rate-of-premature-deaths-due-to-alcohol-gbd"

  # Hedging estimates: % of attributed deaths avoidable by eliminating
  # exposure (theoretical maximum). Real-world reduction is lower.
  risk_factor_hedge_pct <- c(
    "tobacco smoking" = 80, "air pollution" = 50,
    "high body mass index" = 60, "alcohol use" = 70
  )

  make_risk_factor_rows <- function(tribble_data, activity_id, factor_label,
                                    source_url) {
    tribble_data |>
      dplyr::mutate(
        activity_id = activity_id,
        component = "attributed",
        risk_category = "mixed",
        component_label = activity,
        category = "Environment",
        period = "per day",
        period_type = "day",
        source_url = source_url,
        component_id = paste0(activity_id, "_attributed_", condition_value),
        duration_hours = NA_real_,
        hedgeable = TRUE,
        hedge_description = paste0("Reduce exposure to ", factor_label),
        hedge_reduction_pct = unname(risk_factor_hedge_pct[factor_label]),
        condition_variable = "country",
        confidence = "high",
        notes = paste0(
          "IHME GBD 2023 via OWID; age-standardised deaths attributed to ",
          factor_label, " / 365 * 10 = mm/day"
        ),
        validation_status = "corroborated",
        source_count = 2L,
        estimate_range = NA_character_
      )
  }

  # Smoking-attributed deaths (IHME GBD 2023)
  # Includes lung cancer, COPD, CVD, etc. attributable to tobacco use
  smoking_mortality <- make_risk_factor_rows(
    tibble::tribble(
      ~activity, ~condition_value, ~micromorts,
      "Daily smoking-attributed mortality (UK)", "UK", round(54.28 / 365 * 10, 2),
      "Daily smoking-attributed mortality (US)", "US", round(54.94 / 365 * 10, 2),
      "Daily smoking-attributed mortality (Japan)", "JP", round(35.95 / 365 * 10, 2),
      "Daily smoking-attributed mortality (India)", "IN", round(65.38 / 365 * 10, 2),
      "Daily smoking-attributed mortality (Nigeria)", "NG", round(11.56 / 365 * 10, 2),
      "Daily smoking-attributed mortality (Brazil)", "BR", round(44.34 / 365 * 10, 2)
    ),
    "daily_smoking_mortality", "tobacco smoking", owid_smoking_url
  )

  # Air pollution-attributed deaths (ambient + household, IHME GBD 2023)
  pollution_mortality <- make_risk_factor_rows(
    tibble::tribble(
      ~activity, ~condition_value, ~micromorts,
      "Daily air pollution mortality (UK)", "UK", round(14.46 / 365 * 10, 2),
      "Daily air pollution mortality (US)", "US", round(13.04 / 365 * 10, 2),
      "Daily air pollution mortality (Japan)", "JP", round(17.06 / 365 * 10, 2),
      "Daily air pollution mortality (India)", "IN", round(186.24 / 365 * 10, 2),
      "Daily air pollution mortality (Nigeria)", "NG", round(150.55 / 365 * 10, 2),
      "Daily air pollution mortality (Brazil)", "BR", round(34.63 / 365 * 10, 2)
    ),
    "daily_pollution_mortality", "air pollution", owid_pollution_url
  )

  # High BMI / obesity-attributed deaths (IHME GBD 2023)
  obesity_mortality <- make_risk_factor_rows(
    tibble::tribble(
      ~activity, ~condition_value, ~micromorts,
      "Daily obesity-attributed mortality (UK)", "UK", round(31.96 / 365 * 10, 2),
      "Daily obesity-attributed mortality (US)", "US", round(55.85 / 365 * 10, 2),
      "Daily obesity-attributed mortality (Japan)", "JP", round(11.07 / 365 * 10, 2),
      "Daily obesity-attributed mortality (India)", "IN", round(32.07 / 365 * 10, 2),
      "Daily obesity-attributed mortality (Nigeria)", "NG", round(59.98 / 365 * 10, 2),
      "Daily obesity-attributed mortality (Brazil)", "BR", round(51.58 / 365 * 10, 2)
    ),
    "daily_obesity_mortality", "high body mass index", owid_obesity_url
  )

  # Alcohol-attributed deaths (IHME GBD 2023)
  alcohol_mortality <- make_risk_factor_rows(
    tibble::tribble(
      ~activity, ~condition_value, ~micromorts,
      "Daily alcohol-attributed mortality (UK)", "UK", round(30.81 / 365 * 10, 2),
      "Daily alcohol-attributed mortality (US)", "US", round(30.79 / 365 * 10, 2),
      "Daily alcohol-attributed mortality (Japan)", "JP", round(20.97 / 365 * 10, 2),
      "Daily alcohol-attributed mortality (India)", "IN", round(9.51 / 365 * 10, 2),
      "Daily alcohol-attributed mortality (Nigeria)", "NG", round(6.15 / 365 * 10, 2),
      "Daily alcohol-attributed mortality (Brazil)", "BR", round(22.30 / 365 * 10, 2)
    ),
    "daily_alcohol_mortality", "alcohol use", owid_alcohol_url
  )

  # ── Combine all parts ───────────────────────────────────────────────────
  all_cols <- c(
    "component_id", "activity_id", "activity", "component", "risk_category",
    "component_label", "micromorts", "duration_hours", "category", "period",
    "period_type", "hedgeable", "hedge_description", "hedge_reduction_pct",
    "condition_variable", "condition_value", "confidence", "source_url", "notes",
    "validation_status", "source_count", "estimate_range"
  )

  # Add new columns with defaults to legacy parts
  add_defaults <- function(df) {
    df$validation_status <- "single_source"
    df$source_count <- 1L
    df$estimate_range <- NA_character_
    df
  }

  # Flight decomposed entries: corroborated (Boeing + NCRP + medical literature)
  flights$validation_status <- "corroborated"
  flights$source_count <- 2L
  flights$estimate_range <- NA_character_

  dplyr::bind_rows(
    add_defaults(legacy)[, all_cols],
    flights[, all_cols],
    add_defaults(med_rad)[, all_cols],
    add_defaults(mundane)[, all_cols],
    add_defaults(annual_rad)[, all_cols],
    wildlife[, all_cols],
    occupational[, all_cols],
    road_traffic[, all_cols],
    homicide[, all_cols],
    age_conditioned[, all_cols],
    cvd_mortality[, all_cols],
    cancer_mortality[, all_cols],
    lri_mortality[, all_cols],
    diarrheal_mortality[, all_cols],
    smoking_mortality[, all_cols],
    pollution_mortality[, all_cols],
    obesity_mortality[, all_cols],
    alcohol_mortality[, all_cols]
  )
}


#' Convert activity name to snake_case ID
#'
#' @param x Character vector of activity names.
#' @return Character vector of IDs.
#' @noRd
make_activity_id <- function(x) {
  x |>
    tolower() |>
    gsub("[^a-z0-9]+", "_", x = _) |>
    gsub("^_|_$", "", x = _)
}


#' Parse period string to period type
#'
#' @param period Character vector of period strings.
#' @return Character vector of period types.
#' @noRd
parse_period_type <- function(period) {
  dplyr::case_when(
    grepl("per day|per night", period) ~ "day",
    grepl("per hour", period) ~ "hour",
    grepl("per year", period) ~ "year",
    grepl("per month", period) ~ "month",
    grepl("weeks", period) ~ "period",
    grepl("per event|per jump|per dose|per swim|per climb|per flight|per ride|per encounter|per game|per trip|per ascent|per expedition|per infection|per bite|per sting", period) ~ "event",
    TRUE ~ "event"
  )
}


#' Compute period duration in days
#'
#' Converts period strings and types to duration in days for cross-activity
#' comparison. Replicates the logic from the original [common_risks()].
#'
#' @param period Character vector of period descriptions.
#' @param period_type Character vector of period types.
#' @return Numeric vector of durations in days.
#' @noRd
compute_period_days <- function(period, period_type) {
  # Extract hours from "per Xh flight" patterns (e.g., "per 2h flight" → 2)
  has_flight_hours <- grepl("per \\d+h flight", period)
  flight_hours <- rep(NA_real_, length(period))
  flight_hours[has_flight_hours] <- as.numeric(
    gsub(".*per (\\d+)h flight.*", "\\1", period[has_flight_hours])
  )

  dplyr::case_when(
    # Duration-specific flights: "per 2h flight" → 2/24 days
    has_flight_hours ~ flight_hours / 24,
    period_type == "day" ~ 1,
    period_type == "hour" ~ 1 / 24,
    period_type == "year" ~ 365,
    period_type == "month" ~ 30,
    grepl("11 weeks", period) ~ 77,
    grepl("8 weeks", period) ~ 56,
    grepl("2 months", period) ~ 60,
    # Event durations (typical values)
    grepl("Everest|ascent", period) ~ 60,
    grepl("expedition", period) ~ 45,
    grepl("infection", period) ~ 14,
    grepl("birth|anesthesia|surgery", period) ~ 0.04,
    grepl("jump|skydiving|base", period) ~ 0.003,
    grepl("dive", period) ~ 0.04,
    grepl("flight|gliding", period) ~ 0.08,
    grepl("marathon", period) ~ 0.17,
    grepl("game", period) ~ 0.13,
    grepl("climb", period) ~ 0.25,
    grepl("swim", period) ~ 0.04,
    grepl("ride", period) ~ 0.08,
    grepl("trip", period) ~ 0.17,
    grepl("dose", period) ~ 0.01,
    grepl("encounter|bite|sting", period) ~ 0.01,
    TRUE ~ 1
  )
}


#' Filter atomic risks by health profile
#'
#' Filters conditional risk components based on a user's health profile.
#' When no profile is specified, returns unconditional rows and healthy-default
#' conditional rows.
#'
#' @param risks A tibble from [atomic_risks()].
#' @param profile A named list of condition variables and their values,
#'   e.g. `list(health_profile = "dvt_risk_factors")` or
#'   `list(age = "85_plus_male")`.
#' @return Filtered tibble.
#' @noRd
filter_by_profile <- function(risks, profile = list()) {
  if (length(profile) == 0L) {
    # No profile: keep unconditional rows + default condition values
    return(
      risks |>
        dplyr::filter(
          is.na(condition_variable) |
            condition_value %in% c("healthy", "unconditional", "high_income", "all_ages")
        )
    )
  }


  defaults <- c("healthy", "unconditional", "high_income", "all_ages")

  # For each condition variable in profile, keep matching rows
  # For condition variables NOT in profile, keep default
  for (var in names(profile)) {
    val <- profile[[var]]
    risks <- risks |>
      dplyr::filter(
        is.na(condition_variable) |
          condition_variable != var |
          (condition_variable == var & condition_value == val)
      )
  }

  # Apply defaults for condition variables not specified in profile
  risks |>
    dplyr::filter(
      is.na(condition_variable) |
        condition_variable %in% names(profile) |
        condition_value %in% defaults
    )
}


#' Filter to nearest duration bucket
#'
#' For duration-dependent activities, selects the nearest pre-computed
#' duration bucket. Non-duration-dependent activities are passed through.
#'
#' @param risks A tibble from [atomic_risks()].
#' @param duration_hours Numeric. Desired duration in hours.
#' @return Filtered tibble with nearest duration bucket for duration-dependent
#'   activities.
#' @noRd
filter_to_duration <- function(risks, duration_hours) {
  # Separate duration-dependent and independent rows
  has_duration <- !is.na(risks$duration_hours)
  independent <- risks[!has_duration, ]
  dependent <- risks[has_duration, ]

  if (nrow(dependent) == 0L) {
    return(risks)
  }

  # For each activity_id + component + condition, find nearest duration bucket
  nearest <- dependent |>
    dplyr::mutate(
      dist = abs(duration_hours - .env$duration_hours)
    ) |>
    dplyr::group_by(activity_id, component, condition_value) |>
    dplyr::slice_min(dist, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::select(-dist)

  dplyr::bind_rows(independent, nearest)
}


#' View Risk Components for an Activity
#'
#' Returns the atomic risk components for a specified activity, optionally
#' filtered by health profile. Useful for understanding what contributes to
#' a composite risk value.
#'
#' @param activity_id Character. The activity ID (e.g., `"flying_8h"`).
#'   Use `atomic_risks()$activity_id` to see available IDs.
#' @param profile A named list of condition variables, e.g.
#'   `list(health_profile = "dvt_risk_factors")`.
#' @param risks Optional pre-computed [atomic_risks()] tibble.
#' @return A tibble of atomic components for the requested activity.
#' @export
#' @seealso [atomic_risks()], [common_risks()]
#' @examples
#' risk_components("flying_8h")
#' risk_components("flying_8h", profile = list(health_profile = "dvt_risk_factors"))
risk_components <- function(activity_id, profile = list(), risks = NULL) {
  if (is.null(risks)) risks <- atomic_risks()

  available <- unique(risks$activity_id)
  if (!activity_id %in% available) {
    cli::cli_abort(c(
      "x" = "Unknown activity_id: {.val {activity_id}}",
      "i" = "Use {.code atomic_risks()$activity_id} to see available IDs."
    ))
  }

  risks |>
    dplyr::filter(.data$activity_id == .env$activity_id) |>
    filter_by_profile(profile)
}


#' Calculate Risk for Custom Duration
#'
#' For duration-dependent activities, finds the nearest pre-computed
#' duration bucket across all variants of an activity family and returns
#' the aggregated risk.
#'
#' @param activity_prefix Character. Activity family prefix (e.g.,
#'   `"flying"` matches `flying_2h`, `flying_5h`, `flying_8h`,
#'   `flying_12h`). Also accepts a full `activity_id`.
#' @param duration_hours Numeric. Desired duration in hours.
#' @param profile A named list of condition variables.
#' @param risks Optional pre-computed [atomic_risks()] tibble.
#' @return A tibble with one row per component at the nearest duration
#'   bucket, plus summary columns.
#' @export
#' @seealso [risk_components()], [common_risks()]
#' @examples
#' risk_for_duration("flying", duration_hours = 7)
#' risk_for_duration("flying", duration_hours = 3)
risk_for_duration <- function(activity_prefix, duration_hours, profile = list(),
                              risks = NULL) {
  if (is.null(risks)) risks <- atomic_risks()

  # Match all activity_ids starting with the prefix
  pattern <- paste0("^", activity_prefix)
  matching <- risks |>
    dplyr::filter(grepl(pattern, activity_id))

  if (nrow(matching) == 0L) {
    cli::cli_abort(c(
      "x" = "No activities match prefix {.val {activity_prefix}}",
      "i" = "Use {.code atomic_risks()$activity_id} to see available IDs."
    ))
  }

  # Filter by profile

  matching <- filter_by_profile(matching, profile)

  # Must have duration-dependent rows
  if (all(is.na(matching$duration_hours))) {
    cli::cli_abort(c(
      "x" = "Activities matching {.val {activity_prefix}} are not duration-dependent.",
      "i" = "Use {.fn risk_components} instead."
    ))
  }

  # Find the single nearest duration bucket across all matching activity_ids
  available_durations <- unique(stats::na.omit(matching$duration_hours))
  nearest_dur <- available_durations[which.min(abs(available_durations - duration_hours))]

  matching |>
    dplyr::filter(.data$duration_hours == .env$nearest_dur) |>
    dplyr::summarise(
      activity = dplyr::first(activity),
      activity_id = dplyr::first(activity_id),
      hedgeable_pct = dplyr::if_else(
        sum(micromorts) > 0,
        round(sum(hedgeable * micromorts) / sum(micromorts) * 100, 1),
        0
      ),
      micromorts = sum(micromorts),
      n_components = dplyr::n(),
      duration_hours = nearest_dur
    )
}


#' Convert millisieverts to micromorts
#'
#' Uses the Linear No-Threshold (LNT) model: 50 micromorts per Sv,
#' i.e. 0.05 micromorts per mSv.
#'
#' @param msv Numeric vector of doses in millisieverts.
#' @return Numeric vector of micromorts.
#' @references
#' Brenner DJ, Hall EJ (2007). "Computed Tomography — An Increasing Source
#' of Radiation Exposure." NEJM 357:2277-2284.
#' @noRd
msv_to_micromorts <- function(msv) {
  round(msv * 0.05, 4)
}
