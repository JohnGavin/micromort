test_that("daily_hazard_rate returns a tibble with expected columns", {
  result <- daily_hazard_rate(30)
  expect_s3_class(result, "tbl_df")
  expect_named(
    result,
    c("age", "sex", "daily_prob", "micromorts", "micromorts_lower",
      "micromorts_upper", "microlives_consumed", "precision_note",
      "interpretation")
  )
})

test_that("daily_hazard_rate credible bounds bracket the estimate", {
  result <- daily_hazard_rate(45, "male")
  expect_lt(result$micromorts_lower, result$micromorts)
  expect_gt(result$micromorts_upper, result$micromorts)
})

test_that("daily_hazard_rate bounds bracket estimate for female", {
  result <- daily_hazard_rate(65, "female")
  expect_lt(result$micromorts_lower, result$micromorts)
  expect_gt(result$micromorts_upper, result$micromorts)
})

test_that("daily_hazard_rate bounds are approximately ±10% of estimate", {
  result <- daily_hazard_rate(50, "male")
  # With a and b both at ±10%, the extreme combinations give roughly ±10–20%
  # on the total. At minimum the bounds must be within 20% of centre.
  ratio_lower <- result$micromorts_lower / result$micromorts
  ratio_upper <- result$micromorts_upper / result$micromorts
  expect_gt(ratio_lower, 0.8)
  expect_lt(ratio_upper, 1.25)
})

test_that("daily_hazard_rate rejects invalid inputs", {
  expect_error(daily_hazard_rate(-1))
  expect_error(daily_hazard_rate(121))
  expect_error(daily_hazard_rate(30, "other"))
})

test_that("daily_hazard_rate snapshot: column structure at age 40", {
  result <- daily_hazard_rate(40)
  expect_snapshot(names(result))
})

test_that("daily_hazard_rate: male risk higher than female at same age", {
  male   <- daily_hazard_rate(60, "male")
  female <- daily_hazard_rate(60, "female")
  expect_gt(male$micromorts, female$micromorts)
})
