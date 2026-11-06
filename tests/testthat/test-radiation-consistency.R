# One home per value for radiation doses (roborev 13730).
# Micromorts for every radiation row must be derived from a dose via
# msv_to_micromorts(), and downstream helpers must read the chest X-ray
# value from atomic_risks() instead of re-typing it.

chest_xray_mm <- function() {
  ar <- atomic_risks()
  ar$micromorts[ar$activity == "Chest X-ray (radiation per scan)"]
}

test_that("chest X-ray micromorts equals 0.02 mSv at 50 micromorts/mSv", {
  expect_equal(chest_xray_mm(), msv_to_micromorts(0.02))
})

test_that("patient_radiation_comparison() uses the atomic_risks chest X-ray value", {
  prc <- patient_radiation_comparison(xray_counts = 1, career_years = 10)
  expect_equal(unique(prc$patient_micromorts), chest_xray_mm())
})

test_that("radiation_profiles() xray_equivalents uses the atomic_risks chest X-ray value", {
  rp <- radiation_profiles()
  expect_equal(
    rp$xray_equivalents_per_year,
    rp$annual_micromorts / chest_xray_mm()
  )
})

test_that("flight radiation rows equal msv_to_micromorts(per-hour dose * hours)", {
  ar <- atomic_risks()
  fr <- ar[ar$component == "radiation" & !is.na(ar$duration_hours), ]
  expect_gt(nrow(fr), 0)
  expect_equal(fr$micromorts, msv_to_micromorts((0.035 / 5) * fr$duration_hours))
})

test_that("flight radiation notes derive the hourly rate from the conversion", {
  ar <- atomic_risks()
  fr <- ar[ar$component == "radiation" & !is.na(ar$duration_hours), ]
  rate <- format(msv_to_micromorts(0.035 / 5))
  expect_true(all(grepl(paste0("Linear ~", rate, " micromorts/hour"), fr$notes, fixed = TRUE)))
})

test_that("background radiation cites its own source, not the air-travel page", {
  ar <- atomic_risks()
  bg <- ar[ar$activity == "Normal background radiation", ]
  expect_false(grepl("air-travel", bg$source_url, fixed = TRUE))
  expect_match(bg$source_url, "^https://www\\.cdc\\.gov/")
})

# roborev 15234: the 5 rows with no independently sourced dose were on the old
# 0.05 micromorts/mSv scale, 1000x below every other row.
test_that("every annual radiation row sits on the single msv_to_micromorts() scale", {
  rp <- radiation_profiles()
  expect_gt(nrow(rp), 0)
  expect_equal(
    rp$annual_micromorts / rp$annual_msv,
    rep(msv_to_micromorts(1), nrow(rp)),
    tolerance = 1e-3
  )
})

test_that("occupational annual doses are of order mSv, not micro-mSv", {
  rp <- radiation_profiles()
  occ <- rp[rp$category == "Occupation", ]
  expect_gt(nrow(occ), 0)
  expect_true(all(occ$annual_msv >= 0.1))
})

test_that("the 5 unsourced rows keep their legacy dose in mSv", {
  rp <- radiation_profiles()
  dose <- stats::setNames(rp$annual_msv, rp$activity_id)
  ids <- c("xray_tech_annual", "dental_radiographer_annual",
           "nuclear_worker_annual", "interventional_cardiologist_annual",
           "granite_resident_annual")
  expect_equal(
    unname(dose[ids]),
    c(1, 0.2, 2, 3.5, 2),
    tolerance = 1e-6
  )
})

test_that("patient_radiation_comparison() ratio equals the dose ratio in mSv", {
  prc <- patient_radiation_comparison()
  rp <- radiation_profiles()
  dose <- stats::setNames(rp$annual_msv, rp$activity)
  xray_msv <- micromorts_to_msv(chest_xray_mm())
  expected <- round(
    (prc$xray_count * xray_msv) / (dose[prc$occupation] * prc$career_years),
    2
  )
  expect_equal(unname(prc$ratio), unname(expected), tolerance = 1e-6)
  # One chest X-ray (0.02 mSv) must not exceed a 10-year technician career.
  one <- prc[prc$occupation == "X-ray technician (annual radiation)" &
               prc$xray_count == 1 & prc$career_years == 10, ]
  expect_lt(one$ratio, 1)
})
