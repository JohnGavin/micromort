# ── msv_to_micromorts() ────────────────────────────────────────────────────────

test_that("msv_to_micromorts() converts correctly using LNT model", {
  # LNT: 50 mm/Sv = 0.05 mm/mSv

  expect_equal(msv_to_micromorts(1), 0.05)
  expect_equal(msv_to_micromorts(0), 0)
  expect_equal(msv_to_micromorts(20), 1)       # ICRP annual occupational limit
  expect_equal(msv_to_micromorts(2.4), 0.12)   # Global average background
  expect_equal(msv_to_micromorts(1000), 50)    # 1 Sv
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
  # xray_equivalents = annual_micromorts / 0.1 (chest X-ray = 0.1 mm)
  expect_equal(rp$xray_equivalents_per_year, rp$annual_micromorts / 0.1)
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
  # 100 X-rays = 10 mm, 40 years at 0.05 mm/yr = 2 mm
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
