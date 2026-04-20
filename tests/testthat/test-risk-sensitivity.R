test_that("risk_sensitivity returns expected columns for all activities", {
  result <- risk_sensitivity()
  expect_s3_class(result, "tbl_df")
  expect_named(
    result,
    c("activity", "micromorts_base", "micromorts_low", "micromorts_high",
      "rank_base", "rank_change")
  )
})

test_that("risk_sensitivity low < base < high for all activities", {
  result <- risk_sensitivity()
  expect_true(all(result$micromorts_low < result$micromorts_base))
  expect_true(all(result$micromorts_high > result$micromorts_base))
})

test_that("risk_sensitivity respects pct parameter", {
  result <- risk_sensitivity(pct = 10)
  ratio_low  <- result$micromorts_low  / result$micromorts_base
  ratio_high <- result$micromorts_high / result$micromorts_base
  expect_true(all(abs(ratio_low  - 0.9) < 1e-9))
  expect_true(all(abs(ratio_high - 1.1) < 1e-9))
})

test_that("risk_sensitivity filters to a single activity", {
  result <- risk_sensitivity("Skydiving (US)")
  expect_equal(nrow(result), 1L)
  expect_equal(result$activity, "Skydiving (US)")
})

test_that("risk_sensitivity rank_change is non-negative integer", {
  result <- risk_sensitivity()
  expect_true(all(result$rank_change >= 0))
  expect_true(all(result$rank_change == floor(result$rank_change)))
})

test_that("risk_sensitivity aborts on unknown activity", {
  expect_error(
    risk_sensitivity("Not A Real Activity"),
    class = "rlang_error"
  )
})

test_that("risk_sensitivity aborts on invalid pct", {
  expect_error(risk_sensitivity(pct = 0))
  expect_error(risk_sensitivity(pct = 100))
  expect_error(risk_sensitivity(pct = -5))
})

test_that("risk_sensitivity snapshot: column names", {
  result <- risk_sensitivity()
  expect_snapshot(names(result))
})

test_that("risk_sensitivity snapshot: error message for unknown activity", {
  expect_snapshot(
    error = TRUE,
    risk_sensitivity("NONEXISTENT_ACTIVITY_XYZ")
  )
})
