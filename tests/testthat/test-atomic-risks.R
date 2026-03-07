# ── atomic_risks() schema tests ───────────────────────────────────────────────

test_that("atomic_risks() returns correct schema", {
  ar <- atomic_risks()

  expected_cols <- c(
    "component_id", "activity_id", "activity", "component", "risk_category",
    "component_label", "micromorts", "duration_hours", "category", "period",
    "period_type", "hedgeable", "hedge_description", "hedge_reduction_pct",
    "condition_variable", "condition_value", "confidence", "source_url", "notes"
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
  # 61 legacy all_causes + 16 flight components + 8 medical radiation + 7 mundane = 92
  expect_equal(nrow(ar), 92)
  # 61 legacy + 4 flight activities + 8 medical + 7 mundane = 80 unique IDs
  expect_equal(length(unique(ar$activity_id)), 80)
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

test_that("undecomposed activities are not hedgeable", {
  ar <- atomic_risks()
  all_causes <- ar[ar$component == "all_causes", ]
  expect_true(all(!all_causes$hedgeable))
  expect_true(all(is.na(all_causes$hedge_description)))
  expect_true(all(is.na(all_causes$hedge_reduction_pct)))
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


# ── common_risks() backward compatibility ────────────────────────────────────

test_that("common_risks() has correct activity count", {
  cr <- common_risks()
  # 61 legacy (without old Flying) + 4 flight durations + 8 medical + 7 mundane
  expect_equal(nrow(cr), 80)
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
  # crash(2.0) + dvt_healthy(2.5) + radiation(0.4) = 4.9
  expect_equal(fly8$micromorts, 4.9)
  expect_equal(fly8$n_components, 3L)
  expect_equal(fly8$hedgeable_pct, 51, tolerance = 0.1)
})

test_that("common_risks() with DVT risk profile changes flight totals", {
  cr_dvt <- common_risks(profile = list(health_profile = "dvt_risk_factors"))
  fly8 <- cr_dvt[cr_dvt$activity == "Flying (8h long-haul)", ]
  # crash(2.0) + dvt_risk(8.0) + radiation(0.4) = 10.4
  expect_equal(fly8$micromorts, 10.4)
})

test_that("n_components is 1 for undecomposed activities", {
  cr <- common_risks()
  legacy_subset <- cr[!grepl("Flying \\(\\d+h", cr$activity), ]
  expect_true(all(legacy_subset$n_components == 1))
})

test_that("hedgeable_pct is 0 for undecomposed activities", {
  cr <- common_risks()
  legacy_subset <- cr[cr$n_components == 1, ]
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
  expect_true("Chest X-ray (radiation)" %in% cr$activity)
  expect_true("CT scan chest (radiation)" %in% cr$activity)
  xray <- cr[cr$activity == "Chest X-ray (radiation)", ]
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
