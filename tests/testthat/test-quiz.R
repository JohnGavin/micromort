test_that("quiz_pairs() returns tibble with expected columns", {
  qp <- quiz_pairs(seed = 42)
  expect_s3_class(qp, "tbl_df")
  expected_cols <- c(
    "activity_a", "micromorts_a", "category_a", "hedgeable_pct_a", "period_a",
    "activity_b", "micromorts_b", "category_b", "hedgeable_pct_b", "period_b",
    "ratio", "answer"
  )
  expect_true(all(expected_cols %in% names(qp)))
})

test_that("quiz_pairs() all ratios within min_ratio and max_ratio", {
  qp <- quiz_pairs(min_ratio = 1.1, max_ratio = 2.0, seed = 42)
  expect_true(all(qp$ratio >= 1.1))
  expect_true(all(qp$ratio <= 2.0))
})

test_that("quiz_pairs() answer is always 'a' or 'b'", {
  qp <- quiz_pairs(seed = 42)
  expect_true(all(qp$answer %in% c("a", "b")))
})

test_that("quiz_pairs() micromorts are positive", {
  qp <- quiz_pairs(seed = 42)
  expect_true(all(qp$micromorts_a > 0))
  expect_true(all(qp$micromorts_b > 0))
})

test_that("quiz_pairs() cross-category pairs dominate when preferred", {
  qp <- quiz_pairs(prefer_cross_category = TRUE, seed = 42)
  cross <- sum(qp$category_a != qp$category_b)
  expect_gt(cross, nrow(qp) / 2)
})

test_that("quiz_pairs() each activity appears at most 3 times", {
  qp <- quiz_pairs(seed = 42)
  all_activities <- c(qp$activity_a, qp$activity_b)
  counts <- table(all_activities)
  expect_true(all(counts <= 3))
})

test_that("quiz_pairs() returns >= 20 pairs", {
  qp <- quiz_pairs(seed = 42)
  expect_gte(nrow(qp), 20)
})

test_that("quiz_pairs() narrower ratio range returns fewer or equal pairs", {
  qp_wide <- quiz_pairs(min_ratio = 1.0, max_ratio = 2.0, seed = 42)
  qp_narrow <- quiz_pairs(min_ratio = 1.5, max_ratio = 2.0, seed = 42)
  expect_lte(nrow(qp_narrow), nrow(qp_wide))
})

test_that("quiz_pairs() seed produces reproducible results", {
  qp1 <- quiz_pairs(seed = 123)
  qp2 <- quiz_pairs(seed = 123)

  expect_identical(qp1, qp2)
})

test_that("quiz_pairs() no pair has identical activities", {
  qp <- quiz_pairs(seed = 42)
  expect_true(all(qp$activity_a != qp$activity_b))
})

test_that("quiz_pairs() hedgeable_pct columns are numeric 0-100", {
  qp <- quiz_pairs(seed = 42)
  expect_type(qp$hedgeable_pct_a, "double")
  expect_type(qp$hedgeable_pct_b, "double")
  expect_true(all(qp$hedgeable_pct_a >= 0 & qp$hedgeable_pct_a <= 100))
  expect_true(all(qp$hedgeable_pct_b >= 0 & qp$hedgeable_pct_b <= 100))
})
