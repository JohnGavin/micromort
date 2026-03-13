test_that("quiz_pairs() returns tibble with expected columns", {
  qp <- quiz_pairs(seed = 42)
  expect_s3_class(qp, "tbl_df")
  expected_cols <- c(
    "activity_a", "micromorts_a", "category_a", "hedgeable_pct_a", "period_a",
    "activity_b", "micromorts_b", "category_b", "hedgeable_pct_b", "period_b",
    "description_a", "help_url_a", "description_b", "help_url_b",
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

test_that("quiz_pairs() has description and help_url columns", {
  qp <- quiz_pairs(seed = 42)
  expect_type(qp$description_a, "character")
  expect_type(qp$description_b, "character")
  expect_type(qp$help_url_a, "character")
  expect_type(qp$help_url_b, "character")
  expect_true(all(nzchar(qp$description_a)))
  expect_true(all(nzchar(qp$description_b)))
  expect_true(all(grepl("^https?://", qp$help_url_a)))
  expect_true(all(grepl("^https?://", qp$help_url_b)))
})


# ---- activity_descriptions() tests ----

test_that("activity_descriptions() covers all common_risks activities", {
  desc <- activity_descriptions()
  cr <- common_risks()
  expect_true(all(cr$activity %in% desc$activity))
  # desc may have more rows than cr (covers conditional variants like low_income)
  expect_true(nrow(desc) >= nrow(cr))
})

test_that("activity_descriptions() has required columns", {
  desc <- activity_descriptions()
  expect_true(all(c("activity", "description", "help_url") %in% names(desc)))
  expect_true(all(nzchar(desc$description)))
  expect_true(all(grepl("^https?://", desc$help_url)))
})


# ---- format_activity_name() tests ----

test_that("format_activity_name() inserts <br> before parenthetical", {
  result <- format_activity_name("airline pilot (annual radiation)")
  expect_s3_class(result, "html")
  expect_match(as.character(result), "airline pilot<br>\\(annual radiation\\)")
})

test_that("format_activity_name() leaves names without parens unchanged", {
  result <- format_activity_name("Skydiving")
  expect_s3_class(result, "html")
  expect_equal(as.character(result), "Skydiving")
})

test_that("format_activity_name() handles multiple parentheses (only first)", {
  result <- format_activity_name("COVID-19 (age 50-64) (2022)")
  expect_match(as.character(result), "^COVID-19<br>\\(age 50-64\\) \\(2022\\)$")
})


# ---- Sync validation: R/quiz.R vs vignettes/quiz_shinylive.qmd ----

test_that("shinylive quiz code is in sync with R/quiz.R", {
  pkg_path <- test_path("..", "..", "R", "quiz.R")
  qmd_path <- test_path("..", "..", "vignettes", "quiz_shinylive.qmd")
  skip_if_not(file.exists(pkg_path), "R/quiz.R not found")
  skip_if_not(file.exists(qmd_path), "vignettes/quiz_shinylive.qmd not found")

  pkg_code <- readLines(pkg_path)
  qmd_code <- readLines(qmd_path)

  # Extract key function signatures that must match
  extract_fun_sigs <- function(lines) {
    sig_lines <- grep("^(quiz_encouragement_lines|quiz_result_phrase|format_activity_name|quiz_title_ui)\\s*<-\\s*function", lines, value = TRUE)
    trimws(sig_lines)
  }

  # Check encouragement lines match
  pkg_enc <- grep("your inner actuary", pkg_code, value = TRUE)
  qmd_enc <- grep("your inner actuary", qmd_code, value = TRUE)
  expect_equal(
    length(pkg_enc), length(qmd_enc),
    label = "encouragement lines presence"
  )

  # Check CSS key properties match
  pkg_has_title_css <- any(grepl("\\.quiz-title", pkg_code))
  qmd_has_title_css <- any(grepl("\\.quiz-title", qmd_code))
  expect_true(pkg_has_title_css, label = "R/quiz.R has .quiz-title CSS")
  expect_true(qmd_has_title_css, label = "qmd has .quiz-title CSS")

  pkg_has_user_select <- any(grepl("user-select:\\s*text", pkg_code))
  qmd_has_user_select <- any(grepl("user-select:\\s*text", qmd_code))
  expect_true(pkg_has_user_select, label = "R/quiz.R has user-select: text")
  expect_true(qmd_has_user_select, label = "qmd has user-select: text")

  # Check format_activity_name exists in both
  pkg_has_fan <- any(grepl("format_activity_name", pkg_code))
  qmd_has_fan <- any(grepl("format_activity_name", qmd_code))
  expect_true(pkg_has_fan, label = "R/quiz.R has format_activity_name")
  expect_true(qmd_has_fan, label = "qmd has format_activity_name")

  # Check nav at top (not bottom) pattern
  pkg_has_top_nav <- any(grepl("d-flex justify-content-between align-items-center mb-3", pkg_code))
  qmd_has_top_nav <- any(grepl("d-flex justify-content-between align-items-center mb-3", qmd_code))
  expect_true(pkg_has_top_nav, label = "R/quiz.R has top nav pattern")
  expect_true(qmd_has_top_nav, label = "qmd has top nav pattern")

  # Check share button exists in both
  pkg_has_share <- any(grepl("share_btn", pkg_code))
  qmd_has_share <- any(grepl("share_btn", qmd_code))
  expect_true(pkg_has_share, label = "R/quiz.R has share button")
  expect_true(qmd_has_share, label = "qmd has share button")

  # Check try_again_detail observer exists in both
  pkg_has_tad <- any(grepl("try_again_detail", pkg_code))
  qmd_has_tad <- any(grepl("try_again_detail", qmd_code))
  expect_true(pkg_has_tad, label = "R/quiz.R has try_again_detail")
  expect_true(qmd_has_tad, label = "qmd has try_again_detail")

  # Check tooltip/help patterns exist in both
  pkg_has_tooltip <- any(grepl("help-icon", pkg_code))
  qmd_has_tooltip <- any(grepl("help-icon", qmd_code))
  expect_true(pkg_has_tooltip, label = "R/quiz.R has help-icon CSS")
  expect_true(qmd_has_tooltip, label = "qmd has help-icon CSS")

  # Check explanation panel exists in both
  pkg_has_explanation <- any(grepl("explanation-panel", pkg_code))
  qmd_has_explanation <- any(grepl("explanation-panel", qmd_code))
  expect_true(pkg_has_explanation, label = "R/quiz.R has explanation-panel")
  expect_true(qmd_has_explanation, label = "qmd has explanation-panel")

  # Check description columns in embedded CSV
  qmd_has_desc_cols <- any(grepl("description_a", qmd_code))
  expect_true(qmd_has_desc_cols, label = "qmd CSV has description columns")

  # Check leaderboard/submit button pattern
  pkg_has_submit <- any(grepl("submit_btn", pkg_code))
  qmd_has_submit <- any(grepl("submit_btn", qmd_code))
  expect_true(pkg_has_submit, label = "R/quiz.R has submit button")
  expect_true(qmd_has_submit, label = "qmd has submit button")
})
