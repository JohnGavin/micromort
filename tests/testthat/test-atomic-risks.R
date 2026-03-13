# ── atomic_risks() schema tests ───────────────────────────────────────────────

test_that("atomic_risks() returns correct schema", {
  ar <- atomic_risks()

  expected_cols <- c(
    "component_id", "activity_id", "activity", "component", "risk_category",
    "component_label", "micromorts", "duration_hours", "category", "period",
    "period_type", "hedgeable", "hedge_description", "hedge_reduction_pct",
    "condition_variable", "condition_value", "confidence", "source_url", "notes",
    "validation_status", "source_count", "estimate_range"
  )
  expect_identical(names(ar), expected_cols)
})

test_that("atomic_risks() has correct column types", {
  ar <- atomic_risks()

  expect_type(ar$component_id, "character")
  expect_type(ar$activity_id, "character")
  expect_type(ar$activity, "character")
  expect_type(ar$component, "character")
  expect_type(ar$risk_category, "character")
  expect_type(ar$component_label, "character")
  expect_type(ar$micromorts, "double")
  expect_type(ar$duration_hours, "double")
  expect_type(ar$category, "character")
  expect_type(ar$period, "character")
  expect_type(ar$period_type, "character")
  expect_type(ar$hedgeable, "logical")
  expect_type(ar$hedge_description, "character")
  expect_type(ar$hedge_reduction_pct, "double")
  expect_type(ar$condition_variable, "character")
  expect_type(ar$condition_value, "character")
  expect_type(ar$confidence, "character")
  expect_type(ar$source_url, "character")
  expect_type(ar$notes, "character")
})

test_that("atomic_risks() has expected row count", {

  ar <- atomic_risks()
  # 61 legacy + 16 flights + 8 medical + 7 mundane + 11 annual radiation + 7 wildlife
  # + 9 occupational + 6 road traffic + 6 homicide = 131
  expect_equal(nrow(ar), 131)
  # 61 legacy + 4 flights + 8 medical + 7 mundane + 11 annual radiation + 7 wildlife
  # + 9 occupational + 1 road traffic + 1 homicide = 109 unique IDs
  expect_equal(length(unique(ar$activity_id)), 109)
})

test_that("component_id values are unique", {
  ar <- atomic_risks()
  expect_equal(length(ar$component_id), length(unique(ar$component_id)))
})

test_that("every activity_id has at least one component", {
  ar <- atomic_risks()
  counts <- table(ar$activity_id)
  expect_true(all(counts >= 1))
})

test_that("decomposed activities have multiple components", {
  ar <- atomic_risks()
  flight_components <- unique(ar$component[ar$activity_id == "flying_8h"])
  expect_true(length(flight_components) >= 3)
  expect_true("crash" %in% flight_components)
  expect_true("dvt" %in% flight_components)
  expect_true("radiation" %in% flight_components)
})

test_that("component types are valid", {
  ar <- atomic_risks()
  valid_components <- c("all_causes", "crash", "dvt", "radiation", "drowning")
  expect_true(all(ar$component %in% valid_components))
})

test_that("risk_category values are valid", {
  ar <- atomic_risks()
  valid <- c("mixed", "physical", "medical", "radiation", "environmental")
  expect_true(all(ar$risk_category %in% valid))
})

test_that("micromorts are non-negative", {
  ar <- atomic_risks()
  expect_true(all(ar$micromorts >= 0))
})

test_that("legacy undecomposed activities are not hedgeable", {
  ar <- atomic_risks()
  # Legacy all_causes (exclude wildlife which are all_causes but hedgeable)
  legacy_all_causes <- ar[ar$component == "all_causes" & ar$category != "Wildlife", ]
  expect_true(all(!legacy_all_causes$hedgeable))
  expect_true(all(is.na(legacy_all_causes$hedge_description)))
  expect_true(all(is.na(legacy_all_causes$hedge_reduction_pct)))
})

test_that("hedgeable components have descriptions", {
  ar <- atomic_risks()
  hedgeable <- ar[ar$hedgeable, ]
  expect_true(all(!is.na(hedgeable$hedge_description)))
  expect_true(all(!is.na(hedgeable$hedge_reduction_pct)))
  expect_true(all(hedgeable$hedge_reduction_pct > 0))
  expect_true(all(hedgeable$hedge_reduction_pct <= 100))
})

test_that("confidence levels are valid", {
  ar <- atomic_risks()
  valid <- c("high", "medium", "low", "estimated")
  expect_true(all(ar$confidence %in% valid))
})

test_that("period_type values are valid", {
  ar <- atomic_risks()
  valid <- c("event", "day", "hour", "year", "month", "period")
  expect_true(all(ar$period_type %in% valid))
})

test_that("duration_hours is set for flight components only", {
  ar <- atomic_risks()
  has_duration <- !is.na(ar$duration_hours)
  expect_true(all(grepl("^flying_", ar$activity_id[has_duration])))
})


# ── Part 5: Annual radiation rows ─────────────────────────────────────────────

test_that("annual radiation rows are present", {
  ar <- atomic_risks()
  annual <- ar[grepl("_annual$", ar$activity_id), ]
  expect_equal(nrow(annual), 11)
})

test_that("annual radiation rows have correct schema", {
  ar <- atomic_risks()
  annual <- ar[grepl("_annual$", ar$activity_id), ]
  expect_true(all(annual$component == "radiation"))
  expect_true(all(annual$risk_category == "radiation"))
  expect_true(all(annual$period_type == "year"))
  expect_true(all(annual$period == "per year"))
})

test_that("annual radiation categories are correct", {
  ar <- atomic_risks()
  annual <- ar[grepl("_annual$", ar$activity_id), ]
  valid_cats <- c("Occupation", "Travel", "Environment")
  expect_true(all(annual$category %in% valid_cats))
})


# ── common_risks() backward compatibility ────────────────────────────────────

test_that("common_risks() has correct activity count", {
  cr <- common_risks()
  # 61 legacy + 4 flights + 8 medical + 7 mundane + 11 annual radiation + 5 wildlife (default)
  # + 9 occupational = 105
  # But road traffic + homicide excluded (condition_value not in defaults)
  # Kangaroo is legacy Wildlife; default filter: shark, dog_US, bee_general, snake_US = +4 new
  expect_equal(nrow(cr), 104)
})

test_that("common_risks() has expected columns", {
  cr <- common_risks()

  legacy_cols <- c("activity", "micromorts", "microlives", "category", "period",
                   "period_type", "period_days", "micromorts_per_day", "source_url")
  expect_true(all(legacy_cols %in% names(cr)))
  expect_true("n_components" %in% names(cr))
  expect_true("hedgeable_pct" %in% names(cr))
})

test_that("legacy activity values preserved", {
  cr <- common_risks()

  everest <- cr[cr$activity == "Mt. Everest ascent", ]
  expect_equal(everest$micromorts, 37932)
  expect_equal(everest$microlives, round(37932 * 0.7, 1))
  expect_equal(everest$category, "Mountaineering")
  expect_equal(everest$period_type, "event")

  kangaroo <- cr[cr$activity == "Kangaroo encounter", ]
  expect_equal(kangaroo$micromorts, 0.1)
})

test_that("common_risks() preserves insertion order for legacy", {
  cr <- common_risks()
  expect_equal(cr$activity[1], "Mt. Everest ascent")
})

test_that("common_risks() ordering is deterministic across calls", {
  cr1 <- common_risks()
  cr2 <- common_risks()
  expect_identical(cr1$activity, cr2$activity)
})

test_that("flight activities are aggregated correctly", {
  cr <- common_risks()
  fly8 <- cr[cr$activity == "Flying (8h long-haul)", ]
  # crash(1.0) + dvt_healthy(2.5) + radiation(0.4) = 3.9
  expect_equal(fly8$micromorts, 3.9)
  expect_equal(fly8$n_components, 3L)
  expect_equal(fly8$hedgeable_pct, 64.1, tolerance = 0.1)
})

test_that("common_risks() with DVT risk profile changes flight totals", {
  cr_dvt <- common_risks(profile = list(health_profile = "dvt_risk_factors"))
  fly8 <- cr_dvt[cr_dvt$activity == "Flying (8h long-haul)", ]
  # crash(1.0) + dvt_risk(8.0) + radiation(0.4) = 9.4
  expect_equal(fly8$micromorts, 9.4)
})

test_that("n_components is 1 for undecomposed activities", {
  cr <- common_risks()
  legacy_subset <- cr[!grepl("Flying \\(\\d+h", cr$activity), ]
  expect_true(all(legacy_subset$n_components == 1))
})

test_that("hedgeable_pct is 0 for legacy all_causes undecomposed activities", {
  cr <- common_risks()
  # Exclude annual radiation rows and wildlife (single-component but hedgeable)
  legacy_subset <- cr[cr$n_components == 1 &
                      !grepl("annual", cr$activity, ignore.case = TRUE) &
                      !cr$category %in% c("Wildlife"), ]
  expect_true(all(legacy_subset$hedgeable_pct == 0))
})

test_that("microlives = micromorts * 0.7 rounded to 1 decimal", {
  cr <- common_risks()
  expected_ml <- round(cr$micromorts * 0.7, 1)
  expect_equal(cr$microlives, expected_ml)
})

test_that("micromorts_per_day = micromorts / period_days rounded to 2", {
  cr <- common_risks()
  expected_mpd <- round(cr$micromorts / cr$period_days, 2)
  expect_equal(cr$micromorts_per_day, expected_mpd)
})

test_that("new medical radiation activities present", {
  cr <- common_risks()
  expect_true("Chest X-ray (radiation per scan)" %in% cr$activity)
  expect_true("CT scan chest (radiation per scan)" %in% cr$activity)
  xray <- cr[cr$activity == "Chest X-ray (radiation per scan)", ]
  expect_equal(xray$micromorts, 0.1)
  expect_equal(xray$category, "Medical")
})

test_that("new mundane activities present", {
  cr <- common_risks()
  expect_true("Cup of coffee" %in% cr$activity)
  expect_true("Crossing a road" %in% cr$activity)
  coffee <- cr[cr$activity == "Cup of coffee", ]
  expect_equal(coffee$micromorts, 0.01)
})


# ── Helper function tests ────────────────────────────────────────────────────

test_that("make_activity_id produces snake_case", {
  expect_equal(
    make_activity_id("Mt. Everest ascent"),
    "mt_everest_ascent"
  )
  expect_equal(
    make_activity_id("COVID-19 infection (unvaccinated)"),
    "covid_19_infection_unvaccinated"
  )
})

test_that("parse_period_type handles all period formats", {
  expect_equal(parse_period_type("per day"), "day")
  expect_equal(parse_period_type("per night"), "day")
  expect_equal(parse_period_type("per hour"), "hour")
  expect_equal(parse_period_type("per year"), "year")
  expect_equal(parse_period_type("per month"), "month")
  expect_equal(parse_period_type("11 weeks (2022)"), "period")
  expect_equal(parse_period_type("per event"), "event")
  expect_equal(parse_period_type("per jump"), "event")
  expect_equal(parse_period_type("per infection"), "event")
})

test_that("compute_period_days returns correct values", {
  expect_equal(compute_period_days("per day", "day"), 1)
  expect_equal(compute_period_days("per hour", "hour"), 1 / 24)
  expect_equal(compute_period_days("per year", "year"), 365)
  expect_equal(compute_period_days("per month", "month"), 30)
  expect_equal(compute_period_days("11 weeks (2022)", "period"), 77)
  expect_equal(compute_period_days("per ascent", "event"), 60)
  expect_equal(compute_period_days("per expedition", "event"), 45)
  expect_equal(compute_period_days("per trip", "event"), 0.17)
  # Duration-specific flights
  expect_equal(compute_period_days("per 8h flight", "event"), 8 / 24)
  expect_equal(compute_period_days("per 2h flight", "event"), 2 / 24)
})

test_that("filter_by_profile with empty profile filters dvt_risk rows", {
  ar <- atomic_risks()
  filtered <- filter_by_profile(ar, list())
  # Should exclude dvt_risk_factors rows
  dvt_risk <- filtered[!is.na(filtered$condition_value) &
                        filtered$condition_value == "dvt_risk_factors", ]
  expect_equal(nrow(dvt_risk), 0)
})

test_that("filter_by_profile with health_profile keeps correct rows", {
  ar <- atomic_risks()
  filtered <- filter_by_profile(ar, list(health_profile = "dvt_risk_factors"))
  # Should include dvt_risk_factors and exclude healthy for DVT
  dvt_rows <- filtered[filtered$component == "dvt", ]
  expect_true(all(dvt_rows$condition_value == "dvt_risk_factors"))
})


# ── Part 6: Wildlife encounters ──────────────────────────────────────────────

test_that("wildlife entries exist with correct structure", {
  ar <- atomic_risks()
  wildlife <- ar[ar$category == "Wildlife", ]
  # 1 legacy (kangaroo) + 7 new = 8 total wildlife rows
  expect_equal(nrow(wildlife), 8)
  # 7 unique wildlife activity_ids (kangaroo + 6 new)
  expect_equal(length(unique(wildlife$activity_id)), 8)
})

test_that("geographic conditioning rows exist", {
  ar <- atomic_risks()
  geo <- ar[!is.na(ar$condition_variable) & ar$condition_variable == "geography", ]
  # dog_bite_us, dog_bite_rabies, snake_bite_us, snake_bite_africa = 4 rows
  expect_equal(nrow(geo), 4)
  expect_true(all(geo$condition_value %in% c("high_income", "low_income")))
})

test_that("default filter returns high_income, not low_income", {
  ar <- atomic_risks()
  filtered <- filter_by_profile(ar)
  geo_filtered <- filtered[!is.na(filtered$condition_variable) &
                            filtered$condition_variable == "geography", ]
  expect_true(all(geo_filtered$condition_value == "high_income"))
  expect_equal(nrow(geo_filtered), 2)  # dog_US + snake_US
})

test_that("low_income filter returns low_income geography", {
  ar <- atomic_risks()
  filtered <- filter_by_profile(ar, list(geography = "low_income"))
  geo_filtered <- filtered[!is.na(filtered$condition_variable) &
                            filtered$condition_variable == "geography", ]
  expect_true(all(geo_filtered$condition_value == "low_income"))
  expect_equal(nrow(geo_filtered), 2)  # dog_rabies + snake_africa
})

test_that("partial profile defaults unspecified condition variables", {
  ar <- atomic_risks()
  # geography=low_income should still default health_profile to "healthy"
  filtered <- filter_by_profile(ar, list(geography = "low_income"))
  bee_rows <- filtered[grepl("bee_sting", filtered$activity_id), ]
  expect_equal(nrow(bee_rows), 1)
  expect_equal(bee_rows$condition_value, "healthy")
})

test_that("common_risks() aggregates wildlife correctly", {
  cr <- common_risks()
  wildlife <- cr[cr$category == "Wildlife", ]
  # Default filter: kangaroo, shark, dog_US, bee_general, snake_US = 5

  expect_equal(nrow(wildlife), 5)
  expect_true("Shark encounter (ocean swim)" %in% wildlife$activity)
  expect_true("Dog bite (US)" %in% wildlife$activity)
  expect_true("Snake bite (US, with antivenom)" %in% wildlife$activity)
})


# ── Part 7: Occupational fatality risks ──────────────────────────────────────

test_that("occupational entries exist with correct structure", {
  ar <- atomic_risks()
  occ <- ar[ar$category == "Occupation" & ar$period == "per day", ]
  expect_equal(nrow(occ), 9)
  expect_true(all(occ$confidence == "high"))
  expect_true(all(occ$validation_status == "corroborated"))
  expect_true(all(occ$source_count == 2L))
  expect_true(all(grepl("bls.gov", occ$source_url)))
})

test_that("logging is highest occupational risk", {
  ar <- atomic_risks()
  occ <- ar[ar$category == "Occupation" & ar$period == "per day", ]
  expect_equal(occ$activity_id[which.max(occ$micromorts)], "logging_work_day")
})

test_that("occupational entries included in default common_risks()", {
  cr <- common_risks()
  occ <- cr[cr$category == "Occupation" & cr$period == "per day", ]
  expect_equal(nrow(occ), 9)
})


# ── Part 8: Road traffic mortality ──────────────────────────────────────────

test_that("road traffic entries exist with correct structure", {
  ar <- atomic_risks()
  rt <- ar[ar$activity_id == "daily_road_traffic", ]
  expect_equal(nrow(rt), 6)
  expect_true(all(rt$condition_variable == "country"))
  expect_true(all(rt$category == "Travel"))
  expect_true(all(rt$confidence == "high"))
  expect_true(all(rt$validation_status == "corroborated"))
})

test_that("road traffic hidden from default common_risks()", {
  cr <- common_risks()
  expect_false("daily_road_traffic" %in%
    cr$activity[grepl("Daily road traffic", cr$activity)])
})

test_that("road traffic included with country profile", {
  cr <- common_risks(profile = list(country = "US"))
  rt <- cr[grepl("Daily road traffic", cr$activity), ]
  expect_equal(nrow(rt), 1)
  expect_equal(rt$micromorts, 0.35)
})


# ── Part 9: Homicide rates ─────────────────────────────────────────────────

test_that("homicide entries exist with correct structure", {
  ar <- atomic_risks()
  hom <- ar[ar$activity_id == "daily_homicide", ]
  expect_equal(nrow(hom), 6)
  expect_true(all(hom$condition_variable == "country"))
  expect_true(all(hom$category == "Daily Life"))
  expect_true(all(hom$confidence == "high"))
})

test_that("homicide hidden from default common_risks()", {
  cr <- common_risks()
  expect_false(any(grepl("Daily homicide", cr$activity)))
})

test_that("homicide included with country profile", {
  cr <- common_risks(profile = list(country = "US"))
  hom <- cr[grepl("Daily homicide", cr$activity), ]
  expect_equal(nrow(hom), 1)
  expect_equal(hom$micromorts, 0.18)
})

test_that("country-conditioned entries hidden from default view", {
  ar <- atomic_risks()
  country <- ar[!is.na(ar$condition_variable) & ar$condition_variable == "country", ]
  expect_equal(nrow(country), 12)  # 6 road + 6 homicide

  cr <- common_risks()
  # None of these should appear in default common_risks
  cr_country <- cr[grepl("Daily road traffic|Daily homicide", cr$activity), ]
  expect_equal(nrow(cr_country), 0)
})


# ── Schema: validation columns ───────────────────────────────────────────────

test_that("validation_status has valid values", {
  ar <- atomic_risks()
  valid <- c("single_source", "corroborated", "cross_validated")
  expect_true(all(ar$validation_status %in% valid))
})

test_that("source_count is positive integer", {
  ar <- atomic_risks()
  expect_type(ar$source_count, "integer")
  expect_true(all(ar$source_count >= 1L))
})

test_that("estimate_range is character or NA", {
  ar <- atomic_risks()
  expect_type(ar$estimate_range, "character")
  # Wildlife entries have ranges; most legacy entries are NA
  wildlife_ranges <- ar[ar$category == "Wildlife" & !is.na(ar$estimate_range), ]
  expect_true(nrow(wildlife_ranges) >= 6)  # all new wildlife have ranges
})

test_that("flight entries are corroborated", {
  ar <- atomic_risks()
  flights <- ar[grepl("^flying_", ar$activity_id), ]
  expect_true(all(flights$validation_status == "corroborated"))
  expect_true(all(flights$source_count >= 2L))
})

test_that("parse_period_type handles bite and sting", {
  expect_equal(parse_period_type("per bite"), "event")
  expect_equal(parse_period_type("per sting"), "event")
})
