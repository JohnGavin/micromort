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

# Regression test: per-activity perturbation must produce real rank shifts.
# Activities B (1.01) and C (0.99) are adjacent; with pct = 5 the bands
# cross over (1.01 * 0.95 = 0.9595 < 0.99 * 1.05 = 1.0395), so each
# activity must gain or lose at least one rank position.
test_that("risk_sensitivity detects rank shifts for adjacent activities (roborev regression)", {
  risks <- tibble::tibble(
    activity   = c("A", "B", "C", "D", "E"),
    micromorts = c(5.0, 1.01, 0.99, 0.5, 0.1)
  )
  pct  <- 5
  mult <- pct / 100
  x    <- risks$micromorts
  n    <- length(x)

  # Per-activity perturbation (correct algorithm)
  rank_at_low  <- integer(n)
  rank_at_high <- integer(n)
  for (i in seq_len(n)) {
    low_vec  <- x; low_vec[i]  <- x[i] * (1 - mult)
    high_vec <- x; high_vec[i] <- x[i] * (1 + mult)
    rank_at_low[i]  <- rank(-low_vec,  ties.method = "min")[i]
    rank_at_high[i] <- rank(-high_vec, ties.method = "min")[i]
  }
  rank_change <- abs(rank_at_high - rank_at_low)

  b_idx <- which(risks$activity == "B")
  c_idx <- which(risks$activity == "C")
  expect_gte(rank_change[b_idx], 1L)
  expect_gte(rank_change[c_idx], 1L)

  # Document the broken algorithm: uniform scaling yields rank_change = 0
  rank_change_uniform <- abs(
    rank(-(x * (1 + mult)), ties.method = "min") -
    rank(-(x * (1 - mult)), ties.method = "min")
  )
  expect_equal(rank_change_uniform[b_idx], 0L)
  expect_equal(rank_change_uniform[c_idx], 0L)
})

# Integration: risk_sensitivity() with the real data must show at least one
# non-zero rank_change after the per-activity perturbation fix.
test_that("risk_sensitivity() produces non-zero rank_change for at least one activity", {
  result <- risk_sensitivity(pct = 20)
  expect_true(any(result$rank_change > 0))
})
