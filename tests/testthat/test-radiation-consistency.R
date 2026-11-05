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
