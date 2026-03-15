# ---- chronic_quiz_pairs() basic structure ----

test_that("chronic_quiz_pairs() returns tibble with expected columns", {
  qp <- chronic_quiz_pairs(seed = 42)
  expect_s3_class(qp, "tbl_df")
  expected_cols <- c(
    "factor_a", "microlives_a", "direction_a", "category_a", "annual_days_a",
    "factor_b", "microlives_b", "direction_b", "category_b", "annual_days_b",
    "description_a", "help_url_a", "description_b", "help_url_b",
    "ratio", "answer"
  )
  expect_true(all(expected_cols %in% names(qp)))
})

test_that("chronic_quiz_pairs() all ratios within min_ratio and max_ratio", {
  qp <- chronic_quiz_pairs(min_ratio = 1.1, max_ratio = 2.0, seed = 42)
  expect_true(all(qp$ratio >= 1.1))
  expect_true(all(qp$ratio <= 2.0))
})

test_that("chronic_quiz_pairs() answer is always 'a' or 'b'", {
  qp <- chronic_quiz_pairs(seed = 42)
  expect_true(all(qp$answer %in% c("a", "b")))
})

test_that("chronic_quiz_pairs() answer matches larger absolute microlives", {
  qp <- chronic_quiz_pairs(seed = 42)
  for (i in seq_len(nrow(qp))) {
    if (qp$answer[i] == "a") {
      expect_gte(abs(qp$microlives_a[i]), abs(qp$microlives_b[i]))
    } else {
      expect_gte(abs(qp$microlives_b[i]), abs(qp$microlives_a[i]))
    }
  }
})

test_that("chronic_quiz_pairs() microlives are numeric", {
  qp <- chronic_quiz_pairs(seed = 42)
  expect_type(qp$microlives_a, "double")
  expect_type(qp$microlives_b, "double")
})

test_that("chronic_quiz_pairs() direction is gain or loss", {
  qp <- chronic_quiz_pairs(seed = 42)
  expect_true(all(qp$direction_a %in% c("gain", "loss")))
  expect_true(all(qp$direction_b %in% c("gain", "loss")))
})

test_that("chronic_quiz_pairs() no pair has identical factors", {
  qp <- chronic_quiz_pairs(seed = 42)
  expect_true(all(qp$factor_a != qp$factor_b))
})

test_that("chronic_quiz_pairs() returns >= 10 pairs", {
  qp <- chronic_quiz_pairs(seed = 42)
  expect_gte(nrow(qp), 10)
})


# ---- cross-category and greedy selection ----

test_that("chronic_quiz_pairs() cross-category pairs dominate when preferred", {
  qp <- chronic_quiz_pairs(prefer_cross_category = TRUE, seed = 42)
  cross <- sum(qp$category_a != qp$category_b)
  expect_gt(cross, nrow(qp) / 2)
})

test_that("chronic_quiz_pairs() each factor appears at most 3 times", {
  qp <- chronic_quiz_pairs(seed = 42)
  all_factors <- c(qp$factor_a, qp$factor_b)
  counts <- table(all_factors)
  expect_true(all(counts <= 3))
})

test_that("chronic_quiz_pairs() narrower ratio range returns fewer or equal pairs", {
  qp_wide <- chronic_quiz_pairs(min_ratio = 1.0, max_ratio = 3.0, seed = 42)
  qp_narrow <- chronic_quiz_pairs(min_ratio = 1.5, max_ratio = 2.0, seed = 42)
  expect_lte(nrow(qp_narrow), nrow(qp_wide))
})


# ---- difficulty feature ----

test_that("difficulty='easy' returns only easy pairs", {
  qp <- chronic_quiz_pairs(difficulty = "easy", seed = 42)
  expect_true(all(qp$difficulty == "easy"))
  expect_true("difficulty" %in% names(qp))
})

test_that("difficulty='hard' returns only hard pairs", {
  qp <- chronic_quiz_pairs(difficulty = "hard", seed = 42)
  expect_true(all(qp$difficulty == "hard"))
})

test_that("difficulty='medium' returns only medium pairs", {
  qp <- chronic_quiz_pairs(difficulty = "medium", seed = 42)
  expect_true(all(qp$difficulty == "medium"))
})

test_that("difficulty='mixed' returns all three tiers", {
  qp <- chronic_quiz_pairs(difficulty = "mixed", seed = 42)
  expect_true(all(c("easy", "medium", "hard") %in% qp$difficulty))
})

test_that("difficulty=NULL preserves legacy behavior (no difficulty column)", {
  qp <- chronic_quiz_pairs(seed = 42)
  expect_false("difficulty" %in% names(qp))
})

test_that("difficulty overrides min_ratio/max_ratio", {
  qp <- chronic_quiz_pairs(difficulty = "easy", seed = 42)
  expect_true(all(qp$ratio > 2.0))
})


# ---- descriptions ----

test_that("chronic_quiz_pairs() has description and help_url columns", {
  qp <- chronic_quiz_pairs(seed = 42)
  expect_type(qp$description_a, "character")
  expect_type(qp$description_b, "character")
  expect_type(qp$help_url_a, "character")
  expect_type(qp$help_url_b, "character")
  expect_true(all(nzchar(qp$description_a)))
  expect_true(all(nzchar(qp$description_b)))
  expect_true(all(grepl("^https?://", qp$help_url_a)))
  expect_true(all(grepl("^https?://", qp$help_url_b)))
})

test_that("chronic_quiz_pairs() has annual_days columns", {
  qp <- chronic_quiz_pairs(seed = 42)
  expect_type(qp$annual_days_a, "double")
  expect_type(qp$annual_days_b, "double")
})


# ---- reproducibility ----

test_that("chronic_quiz_pairs() seed produces reproducible results", {
  qp1 <- chronic_quiz_pairs(seed = 123)
  qp2 <- chronic_quiz_pairs(seed = 123)
  expect_identical(qp1, qp2)
})

test_that("chronic_quiz_pairs() different seeds produce different results", {
  qp1 <- chronic_quiz_pairs(seed = 1)
  qp2 <- chronic_quiz_pairs(seed = 2)
  expect_false(identical(qp1, qp2))
})


# ---- factor_descriptions() ----

test_that("factor_descriptions() covers all chronic_risks factors", {
  desc <- factor_descriptions()
  cr <- chronic_risks()
  expect_true(all(cr$factor %in% desc$factor))
  expect_equal(nrow(desc), nrow(cr))
})

test_that("factor_descriptions() has required columns", {
  desc <- factor_descriptions()
  expect_true(all(c("factor", "description", "help_url") %in% names(desc)))
  expect_true(all(nzchar(desc$description)))
  expect_true(all(grepl("^https?://", desc$help_url)))
})
