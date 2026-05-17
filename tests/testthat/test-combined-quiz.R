# ---- combined_quiz_pairs() basic structure ----

test_that("combined_quiz_pairs() returns tibble with correct columns", {
  pairs <- combined_quiz_pairs(n = 5, seed = 42)
  expect_s3_class(pairs, "tbl_df")
  expected_cols <- c(
    "activity_a", "type_a", "value_a", "unit_a", "category_a", "period_a",
    "factor_b", "type_b", "value_b", "unit_b", "category_b", "direction_b",
    "common_unit", "common_value_a", "common_value_b",
    "correct_answer", "ratio", "explanation"
  )
  expect_true(all(expected_cols %in% names(pairs)))
})

test_that("combined_quiz_pairs() column names snapshot", {
  pairs <- combined_quiz_pairs(n = 5, seed = 42)
  expect_snapshot(sort(names(pairs)))
})

test_that("combined_quiz_pairs() n parameter controls number of rows", {
  pairs3 <- combined_quiz_pairs(n = 3, seed = 42)
  pairs7 <- combined_quiz_pairs(n = 7, seed = 42)
  expect_lte(nrow(pairs3), 3L)
  expect_lte(nrow(pairs7), 7L)
  expect_gte(nrow(pairs3), 1L)
})

test_that("combined_quiz_pairs() correct_answer is always 'a' or 'b'", {
  pairs <- combined_quiz_pairs(n = 10, seed = 42)
  expect_true(all(pairs$correct_answer %in% c("a", "b")))
})

test_that("combined_quiz_pairs() common_value_a and common_value_b are positive", {
  pairs <- combined_quiz_pairs(n = 10, seed = 42)
  expect_true(all(pairs$common_value_a > 0))
  expect_true(all(pairs$common_value_b > 0))
})

test_that("combined_quiz_pairs() common_unit is microlives", {
  pairs <- combined_quiz_pairs(n = 5, seed = 42)
  expect_true(all(pairs$common_unit == "microlives"))
})

test_that("combined_quiz_pairs() type_a is always 'acute'", {
  pairs <- combined_quiz_pairs(n = 5, seed = 42)
  expect_true(all(pairs$type_a == "acute"))
})

test_that("combined_quiz_pairs() type_b is always 'chronic'", {
  pairs <- combined_quiz_pairs(n = 5, seed = 42)
  expect_true(all(pairs$type_b == "chronic"))
})

test_that("combined_quiz_pairs() unit_a is micromorts", {
  pairs <- combined_quiz_pairs(n = 5, seed = 42)
  expect_true(all(pairs$unit_a == "micromorts"))
})

test_that("combined_quiz_pairs() unit_b is microlives/day", {
  pairs <- combined_quiz_pairs(n = 5, seed = 42)
  expect_true(all(pairs$unit_b == "microlives/day"))
})

test_that("combined_quiz_pairs() direction_b is gain or loss", {
  pairs <- combined_quiz_pairs(n = 10, seed = 42)
  expect_true(all(pairs$direction_b %in% c("gain", "loss")))
})


# ---- correct_answer logic ----

test_that("combined_quiz_pairs() correct_answer matches larger common value", {
  pairs <- combined_quiz_pairs(n = 10, seed = 42)
  for (i in seq_len(nrow(pairs))) {
    if (pairs$correct_answer[i] == "a") {
      expect_gte(pairs$common_value_a[i], pairs$common_value_b[i])
    } else {
      expect_gte(pairs$common_value_b[i], pairs$common_value_a[i])
    }
  }
})

test_that("combined_quiz_pairs() ratio matches common values", {
  pairs <- combined_quiz_pairs(n = 10, seed = 42)
  expected_ratio <- pmax(pairs$common_value_a, pairs$common_value_b) /
    pmin(pairs$common_value_a, pairs$common_value_b)
  expect_equal(pairs$ratio, expected_ratio, tolerance = 1e-9)
})

test_that("combined_quiz_pairs() ratio is always >= 1", {
  pairs <- combined_quiz_pairs(n = 10, seed = 42)
  expect_true(all(pairs$ratio >= 1))
})


# ---- conversion factor ----

test_that("combined_quiz_pairs() acute conversion uses 0.7 factor on effective micromorts", {
  pairs <- combined_quiz_pairs(n = 10, seed = 42)
  # common_value_a = effective_micromorts_a * 0.7
  expected <- pairs$effective_micromorts_a * 0.7
  expect_equal(pairs$common_value_a, expected, tolerance = 1e-9)
})

test_that("combined_quiz_pairs() event-type rows use raw micromorts as effective", {
  pairs <- combined_quiz_pairs(n = 20, seed = 42)
  evt <- pairs[pairs$period_type_a == "event", ]
  skip_if(nrow(evt) == 0, "No event-type rows in this sample")
  expect_equal(evt$effective_micromorts_a, evt$value_a, tolerance = 1e-9)
})

test_that("combined_quiz_pairs() non-event acute rows scale by time_period_days", {
  pairs_365 <- combined_quiz_pairs(n = 30, time_period_days = 365, seed = 42)
  pairs_90 <- combined_quiz_pairs(n = 30, time_period_days = 90, seed = 42)
  common <- intersect(
    pairs_365$activity_a[pairs_365$period_type_a != "event"],
    pairs_90$activity_a[pairs_90$period_type_a != "event"]
  )
  skip_if(length(common) == 0, "No common non-event acute rows to compare")
  a <- common[1]
  v365 <- pairs_365$effective_micromorts_a[pairs_365$activity_a == a][1]
  v90 <- pairs_90$effective_micromorts_a[pairs_90$activity_a == a][1]
  expect_equal(v90 / v365, 90 / 365, tolerance = 1e-6)
})

test_that("combined_quiz_pairs() chronic uses abs(microlives_per_day) * time_period_days", {
  pairs <- combined_quiz_pairs(n = 10, time_period_days = 365, seed = 42)
  expected <- abs(pairs$value_b) * 365
  expect_equal(pairs$common_value_b, expected, tolerance = 1e-9)
})

test_that("combined_quiz_pairs() time_period_days scales chronic impact", {
  # Use large n to maximise overlap between the two calls
  pairs_90 <- combined_quiz_pairs(n = 20, time_period_days = 90, seed = 42)
  pairs_365 <- combined_quiz_pairs(n = 20, time_period_days = 365, seed = 42)
  # Both calls use the same seed so the same factors appear; check common ones
  common_factors <- intersect(pairs_90$factor_b, pairs_365$factor_b)
  skip_if(length(common_factors) == 0, "No common factors to compare")
  f <- common_factors[1]
  v90 <- pairs_90$common_value_b[pairs_90$factor_b == f][1]
  v365 <- pairs_365$common_value_b[pairs_365$factor_b == f][1]
  expect_equal(v90 / v365, 90 / 365, tolerance = 0.01)
})


# ---- reproducibility ----

test_that("combined_quiz_pairs() seed produces reproducible results", {
  p1 <- combined_quiz_pairs(n = 10, seed = 99)
  p2 <- combined_quiz_pairs(n = 10, seed = 99)
  expect_identical(p1, p2)
})

test_that("combined_quiz_pairs() different seeds produce different results", {
  p1 <- combined_quiz_pairs(n = 10, seed = 1)
  p2 <- combined_quiz_pairs(n = 10, seed = 2)
  # Allow for occasional identical small samples but expect differences
  expect_false(identical(p1$activity_a, p2$activity_a) &&
               identical(p1$factor_b, p2$factor_b))
})


# ---- explanation column ----

test_that("combined_quiz_pairs() explanation is a non-empty character", {
  pairs <- combined_quiz_pairs(n = 5, seed = 42)
  expect_type(pairs$explanation, "character")
  expect_true(all(nzchar(pairs$explanation)))
})

test_that("combined_quiz_pairs() explanation mentions both activity and factor", {
  pairs <- combined_quiz_pairs(n = 5, seed = 42)
  for (i in seq_len(nrow(pairs))) {
    expect_true(grepl(pairs$activity_a[i], pairs$explanation[i], fixed = TRUE))
    expect_true(grepl(pairs$factor_b[i], pairs$explanation[i], fixed = TRUE))
  }
})


# ---- deduplication ----

test_that("combined_quiz_pairs() no duplicate activity+factor combinations", {
  pairs <- combined_quiz_pairs(n = 20, seed = 42)
  pair_key <- paste(pairs$activity_a, pairs$factor_b, sep = "|||")
  expect_equal(length(pair_key), length(unique(pair_key)))
})

test_that("combined_quiz_pairs() each activity appears at most 2 times", {
  pairs <- combined_quiz_pairs(n = 20, seed = 42)
  counts <- table(pairs$activity_a)
  expect_true(all(counts <= 2L))
})

test_that("combined_quiz_pairs() each factor appears at most 2 times", {
  pairs <- combined_quiz_pairs(n = 20, seed = 42)
  counts <- table(pairs$factor_b)
  expect_true(all(counts <= 2L))
})


# ---- input validation ----

test_that("combined_quiz_pairs() rejects n < 1", {
  expect_error(combined_quiz_pairs(n = 0))
})

test_that("combined_quiz_pairs() rejects negative time_period_days", {
  expect_error(combined_quiz_pairs(time_period_days = -1))
})
