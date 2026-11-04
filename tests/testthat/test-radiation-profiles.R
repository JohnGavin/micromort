# ── msv_to_micromorts() ────────────────────────────────────────────────────────

test_that("msv_to_micromorts() converts correctly using LNT model", {
  # LNT: 50 mm/mSv (FDA CT-risk guidance + ICRP 103 via NRC SECY-08-0197;
  # a prior version of this function used 50 mm/Sv = 0.05 mm/mSv, a 1000x
  # units-label mismatch fixed in this PR)

  expect_equal(msv_to_micromorts(1), 50)
  expect_equal(msv_to_micromorts(0), 0)
  expect_equal(msv_to_micromorts(20), 1000)     # ICRP annual occupational limit
  expect_equal(msv_to_micromorts(2.4), 120)     # Global average background
  expect_equal(msv_to_micromorts(1000), 50000)  # 1 Sv
})


# ── radiation_profiles() ──────────────────────────────────────────────────────

test_that("radiation_profiles() returns expected columns", {
  rp <- radiation_profiles()
  expected <- c(
    "activity_id", "activity", "category", "annual_msv", "annual_micromorts",
    "mm_10y", "mm_20y", "mm_40y",
    "regulatory_limit_msv", "xray_equivalents_per_year"
  )
  expect_true(all(expected %in% names(rp)))
})

test_that("radiation_profiles() returns correct row count", {
  rp <- radiation_profiles()
  # 11 annual radiation profiles

  expect_equal(nrow(rp), 11)
})

test_that("milestones scale linearly", {
  rp <- radiation_profiles()
  # LNT: cumulative = annual * years
  expect_equal(rp$mm_20y, rp$mm_10y * 2)
  expect_equal(rp$mm_40y, rp$mm_10y * 4)
})

test_that("custom milestones work", {
  rp <- radiation_profiles(milestones = c(5, 25))
  expect_true("mm_5y" %in% names(rp))
  expect_true("mm_25y" %in% names(rp))
  expect_false("mm_10y" %in% names(rp))
})

test_that("ordering is correct: pilot > xray_tech > dental", {

  rp <- radiation_profiles()
  pilot <- rp$annual_micromorts[rp$activity_id == "airline_pilot_annual"]
  xray_tech <- rp$annual_micromorts[rp$activity_id == "xray_tech_annual"]
  dental <- rp$annual_micromorts[rp$activity_id == "dental_radiographer_annual"]
  expect_gt(pilot, xray_tech)
  expect_gt(xray_tech, dental)
})

test_that("regulatory limits are correct", {
  rp <- radiation_profiles()
  # Occupational profiles should have 20 mSv limit (ICRP 103)
  occupational <- rp[rp$category == "Occupation", ]
  expect_true(all(occupational$regulatory_limit_msv == 20))
  # Public profiles should have 1 mSv limit
  public <- rp[rp$category %in% c("Travel", "Environment"), ]
  expect_true(all(public$regulatory_limit_msv == 1))
})

test_that("xray_equivalents_per_year is correct", {
  rp <- radiation_profiles()
  # xray_equivalents = annual_micromorts / chest X-ray micromorts (read from
  # atomic_risks(); see test-radiation-consistency.R)
  ar <- atomic_risks()
  xray <- ar$micromorts[ar$activity == "Chest X-ray (radiation per scan)"]
  expect_equal(rp$xray_equivalents_per_year, rp$annual_micromorts / xray)
})


# ── patient_radiation_comparison() ────────────────────────────────────────────

test_that("patient_radiation_comparison() returns expected structure", {
  prc <- patient_radiation_comparison()
  expect_s3_class(prc, "tbl_df")
  expect_true("occupation" %in% names(prc))
  expect_true("xray_count" %in% names(prc))
  expect_true("career_years" %in% names(prc))
  expect_true("patient_micromorts" %in% names(prc))
  expect_true("occupational_micromorts" %in% names(prc))
  expect_true("ratio" %in% names(prc))
})

test_that("patient_radiation_comparison() has correct dimensions", {
  prc <- patient_radiation_comparison()
  # Default: 3 xray_counts x 3 career_years x 5 occupations = 45 rows
  expect_equal(nrow(prc), 45)
})

test_that("100 X-rays > 40-year X-ray tech career", {
  prc <- patient_radiation_comparison()
  row <- prc[prc$occupation == "X-ray technician (annual radiation)" &
             prc$xray_count == 100 &
             prc$career_years == 40, ]
  # 100 chest X-rays = 100 mm (50 micromorts/mSv x 0.02 mSv x 100);
  # 40 years of the (still unsourced, #201-#204) technician literal = 2 mm
  expect_gt(row$patient_micromorts, row$occupational_micromorts)
  expect_gt(row$ratio, 1)
})

test_that("custom xray_counts and career_years work", {
  prc <- patient_radiation_comparison(
    xray_counts = c(50, 200),
    career_years = c(5, 30)
  )
  expect_equal(length(unique(prc$xray_count)), 2)
  expect_equal(length(unique(prc$career_years)), 2)
})


# ── annual_msv is consistent with annual_micromorts (one home) ────────────────

test_that("micromorts_to_msv() inverts msv_to_micromorts()", {
  expect_equal(micromorts_to_msv(50), 1)
  expect_equal(micromorts_to_msv(0), 0)
  expect_equal(micromorts_to_msv(msv_to_micromorts(3.11)), 3.11)
})

test_that("radiation_profiles() annual_msv round-trips to annual_micromorts", {
  rp <- radiation_profiles()
  # Old bug: annual_msv = micromorts / 0.05 was 1000x too large.
  expect_equal(msv_to_micromorts(rp$annual_msv), rp$annual_micromorts,
               tolerance = 0.01, scale = 1)
  bg <- rp[rp$activity_id == "background_radiation_annual", ]
  expect_equal(bg$annual_msv, 3.11)
  pilot <- rp[rp$activity_id == "airline_pilot_annual", ]
  expect_equal(pilot$annual_msv, round(0.035 / 5 * 700, 4))
})
