# Suppress R CMD check notes for NSE column references
utils::globalVariables(c(
 "activity_id", "component_id", "component", "risk_category",
 "component_label", "duration_hours", "hedgeable", "hedge_description",
 "hedge_reduction_pct", "condition_variable", "condition_value",
 "confidence", "notes", ".row_order", "n_components", "hedgeable_pct",
 "dist", ".env", ".data",
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
#'     \item{condition_variable}{What this risk depends on: `"health_profile"` or `NA`}
#'     \item{condition_value}{Condition value: `"healthy"`, `"dvt_risk_factors"`, or `NA`}
#'     \item{confidence}{Data confidence: `"high"`, `"medium"`, `"low"`, `"estimated"`}
#'     \item{source_url}{Citation URL}
#'     \item{notes}{Scaling behavior, caveats}
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
    "Living in NYC COVID-19 (Mar-May 2020)", 50, "COVID-19", "per 8 weeks", mm_rip,
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
    "Living in Maryland COVID-19 (Mar-May 2020)", 7, "COVID-19", "per 8 weeks", mm_rip,
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
  # Crash: ~0.25 mm/hour (linear), physical, NOT hedgeable
  # DVT: zero below 4h, then nonlinear, medical, IS hedgeable (~65% reduction)
  # Cosmic radiation: ~0.05 mm/hour (linear), radiation, NOT hedgeable
  # Sources: Aviation Safety Network, Lancet Haematology, NCRP Report 160
  flight_source <- wiki_mm

  flights <- tibble::tribble(
    ~activity, ~activity_id, ~component, ~risk_category, ~component_label,
    ~micromorts, ~duration_hours, ~period,
    ~hedgeable, ~hedge_description, ~hedge_reduction_pct,
    ~condition_variable, ~condition_value, ~confidence,

    # ─ 2h short-haul ─
    "Flying (2h short-haul)", "flying_2h", "crash", "physical", "Aircraft crash",
    0.5, 2, "per 2h flight",
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
    1.25, 5, "per 5h flight",
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
    2.0, 8, "per 8h flight",
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
    3.0, 12, "per 12h flight",
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
        component == "crash" ~ "Linear ~0.25 mm/hour based on fatal accident rate",
        component == "dvt" ~ "Zero below 4h threshold; nonlinear growth above",
        component == "radiation" ~ "Linear ~0.05 mm/hour; NCRP Report 160"
      )
    )

  # ── Part 3: Medical radiation activities (already atomic) ────────────────
  med_rad <- tibble::tribble(
    ~activity, ~micromorts, ~component, ~component_label,
    "Chest X-ray (radiation)", 0.1, "radiation", "Ionizing radiation dose",
    "CT scan chest (radiation)", 7, "radiation", "Ionizing radiation dose",
    "CT scan abdomen (radiation)", 10, "radiation", "Ionizing radiation dose",
    "Mammogram (radiation)", 0.1, "radiation", "Ionizing radiation dose",
    "Dental X-ray (radiation)", 0.05, "radiation", "Ionizing radiation dose",
    "Coronary angiogram (radiation)", 5, "radiation", "Ionizing radiation dose",
    "Barium enema (radiation)", 3, "radiation", "Ionizing radiation dose",
    "CT scan head (radiation)", 2, "radiation", "Ionizing radiation dose"
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
    "Drinking a glass of wine", 0.5, "all_causes", "mixed",
    "Acute alcohol effects", "Daily Life", "per event",
    "Cup of coffee", 0.01, "all_causes", "mixed",
    "Caffeine effects", "Daily Life", "per event",
    "Commuting by car (30 min)", 0.13, "crash", "physical",
    "Vehicle crash", "Travel", "per trip",
    "Commuting by bicycle (30 min)", 0.5, "all_causes", "mixed",
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

  # ── Combine all parts ───────────────────────────────────────────────────
  all_cols <- c(
    "component_id", "activity_id", "activity", "component", "risk_category",
    "component_label", "micromorts", "duration_hours", "category", "period",
    "period_type", "hedgeable", "hedge_description", "hedge_reduction_pct",
    "condition_variable", "condition_value", "confidence", "source_url", "notes"
  )

  dplyr::bind_rows(
    legacy[, all_cols],
    flights[, all_cols],
    med_rad[, all_cols],
    mundane[, all_cols]
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
    grepl("per event|per jump|per dose|per swim|per climb|per flight|per ride|per encounter|per game|per trip|per ascent|per expedition|per infection", period) ~ "event",
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
    grepl("encounter", period) ~ 0.01,
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
#'   e.g. `list(health_profile = "dvt_risk_factors")`.
#' @return Filtered tibble.
#' @noRd
filter_by_profile <- function(risks, profile = list()) {
  if (length(profile) == 0L) {
    # No profile: keep unconditional rows + default condition values
    return(
      risks |>
        dplyr::filter(
          is.na(condition_variable) |
            condition_value %in% c("healthy", "unconditional")
        )
    )
  }

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

  risks
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
