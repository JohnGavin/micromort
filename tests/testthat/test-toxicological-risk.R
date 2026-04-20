# ── toxicological_risk() tests ─────────────────────────────────────────────

# ── Reference table ──────────────────────────────────────────────────────────

test_that("toxicological_risk(NULL) returns the full reference table", {
  ref <- toxicological_risk()

  expect_s3_class(ref, "tbl_df")
  expect_equal(nrow(ref), 16L)
  expect_true(all(c("substance", "route", "ld50_mg_per_kg", "source") %in% names(ref)))
})

test_that("reference table has correct column names (snapshot)", {
  ref <- toxicological_risk()
  expect_snapshot(names(ref))
})

test_that("reference table LD50 values are in mg/kg (positive, finite)", {
  ref <- toxicological_risk()
  expect_true(all(is.finite(ref$ld50_mg_per_kg)))
  expect_true(all(ref$ld50_mg_per_kg > 0))
})

# ── Micromort calculation ─────────────────────────────────────────────────────

test_that("correct micromort calculation for 1 mg nicotine, 70 kg person", {
  # Nicotine LD50: 6500 ug/kg = 6.5 mg/kg
  # fraction = 1 / (6.5 * 70) = 1 / 455 ≈ 0.002198
  # micromorts = fraction * 500000 ≈ 1099
  result <- toxicological_risk("Nicotine", dose_mg = 1, body_weight_kg = 70)

  expect_equal(result$ld50_mg_per_kg, 6.5)
  expected_fraction <- 1 / (6.5 * 70)
  expect_equal(result$fraction_of_ld50, expected_fraction, tolerance = 1e-10)
  expect_equal(result$micromorts, expected_fraction * 500000, tolerance = 1e-10)
})

test_that("dose_mg and body_weight_kg are reflected correctly in output", {
  result <- toxicological_risk("Caffeine", dose_mg = 200, body_weight_kg = 80)

  expect_equal(result$dose_mg, 200)
  # Caffeine LD50: 192000 ug/kg = 192 mg/kg
  expect_equal(result$ld50_mg_per_kg, 192, tolerance = 1e-6)
  expect_equal(result$fraction_of_ld50, 200 / (192 * 80), tolerance = 1e-10)
})

# ── Partial name matching ─────────────────────────────────────────────────────

test_that("partial name matching works ('nico' matches 'Nicotine')", {
  result <- toxicological_risk("nico", dose_mg = 1)

  expect_equal(nrow(result), 1L)
  expect_true(grepl("Nicotine", result$substance, ignore.case = TRUE))
})

test_that("partial name matching is case-insensitive", {
  result_lower <- toxicological_risk("nicotine", dose_mg = 1)
  result_upper <- toxicological_risk("NICOTINE", dose_mg = 1)

  expect_equal(result_lower$micromorts, result_upper$micromorts)
})

# ── Risk category assignment ──────────────────────────────────────────────────

test_that("risk_category is assigned correctly", {
  # Nicotine (LD50 6.5 mg/kg): 1 mg / 70 kg → fraction ≈ 0.0022 → ~1099 micromorts → "extreme"
  expect_equal(toxicological_risk("Nicotine", dose_mg = 1)$risk_category, "extreme")

  # Ethanol (LD50 7060 mg/kg): 1 mg / 70 kg → fraction ≈ 2e-6 → ~1.01 micromorts → "low"
  # Use "^Ethanol" to avoid partial match with "Methanol"
  expect_equal(
    toxicological_risk("^Ethanol", dose_mg = 1)$risk_category,
    "low"
  )
})

test_that("risk_category boundaries are correct", {
  # Use table salt: LD50 3000 mg/kg, body_weight 70 kg → lethal dose = 210000 mg
  # negligible (<1 mm): dose = 0.1 mg → mm = 0.1 / 210000 * 500000 ≈ 0.24
  # moderate (10–100 mm): dose = 21 mg → mm = 21 / 210000 * 500000 = 50
  # high (100–1000 mm): dose = 42 mg → mm = 42 / 210000 * 500000 = 100 → "high"
  negligible <- toxicological_risk("NaCl", dose_mg = 0.1)
  expect_equal(negligible$risk_category, "negligible")

  moderate <- toxicological_risk("NaCl", dose_mg = 21)
  expect_equal(moderate$risk_category, "moderate")

  high <- toxicological_risk("NaCl", dose_mg = 42)
  expect_equal(high$risk_category, "high")
})

# ── Error handling ────────────────────────────────────────────────────────────

test_that("unknown substance raises an error", {
  expect_snapshot(
    error = TRUE,
    toxicological_risk("xyzzy_nonexistent_substance", dose_mg = 1)
  )
})

test_that("dose_mg required when substance is given", {
  expect_snapshot(
    error = TRUE,
    toxicological_risk("Nicotine")
  )
})

test_that("invalid body_weight_kg raises an error", {
  expect_error(
    toxicological_risk("Nicotine", dose_mg = 1, body_weight_kg = 0),
    class = "error"
  )
  expect_error(
    toxicological_risk("Nicotine", dose_mg = 1, body_weight_kg = -5),
    class = "error"
  )
})
