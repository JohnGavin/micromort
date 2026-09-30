# Regression tests for the Sheet confidence-column unit bug (#132):
# gviz returns percent-formatted cells as FRACTIONS (0.75), not 0-100.

test_that("confidence_fraction_to_pct scales a single fraction to percent", {
  expect_equal(confidence_fraction_to_pct(0.75), 75)
})

test_that("confidence_fraction_to_pct handles every value the Form allows", {
  expect_equal(
    confidence_fraction_to_pct(c(0, 0.25, 0.5, 0.75, 1)),
    c(0, 25, 50, 75, 100)
  )
})

test_that("confidence_fraction_to_pct keeps NA as NA without warning", {
  expect_no_warning(res <- confidence_fraction_to_pct(c(NA, 0.5, NA_real_)))
  expect_equal(res, c(NA, 50, NA))
})

test_that("confidence_fraction_to_pct rejects already-scaled values loudly", {
  expect_warning(res <- confidence_fraction_to_pct(75), "Rejected 1 confidence value")
  expect_true(is.na(res))
})

test_that("confidence_fraction_to_pct rejects out-of-range values and counts them", {
  expect_warning(
    res <- confidence_fraction_to_pct(c(-0.1, 0.5, 1.5)),
    "Rejected 2 confidence values"
  )
  expect_equal(res, c(NA, 50, NA))
})

test_that("confidence_fraction_to_pct handles an empty vector", {
  expect_no_warning(res <- confidence_fraction_to_pct(numeric(0)))
  expect_equal(res, numeric(0))
})

test_that("mean confidence 0.75 with a 60% score gives calibration 0.0225", {
  # Regression: unscaled 0.75 gave (0.0075 - 0.6)^2 = 0.3511
  conf_pct <- confidence_fraction_to_pct(0.75)
  expect_equal(confidence_calibration_score(conf_pct, 60), 0.0225)
  expect_equal(confidence_calibration_score(conf_pct, 87), 0.0144)
})
