# Tests for validate_quiz_submissions() (#215): the weekly leaderboard
# pipeline re-derives what it can from each Google Form submission and
# REPORTS what it rejects, counts only.

NOW <- as.POSIXct("2026-11-07 12:00:00", tz = "UTC")

row <- function(score = 3, total = 5, timestamp = "2026-11-01T10:00:00.000Z",
                quiz_type = "acute", difficulty = "mixed", n_questions = 5,
                avg_confidence_pct = 50) {
  tibble::tibble(
    score = score, total = total, timestamp = timestamp,
    quiz_type = quiz_type, difficulty = difficulty,
    n_questions = n_questions, avg_confidence_pct = avg_confidence_pct
  )
}

rej <- function(res, rule) {
  res$rejected$count[res$rejected$rule == rule]
}

test_that("a plain valid row is kept and nothing is rejected", {
  res <- validate_quiz_submissions(row(), now = NOW)
  expect_equal(nrow(res$kept), 1L)
  expect_equal(sum(res$rejected$count), 0L)
})

test_that("empty input returns empty kept and an all-zero rejection table", {
  res <- validate_quiz_submissions(row()[0, ], now = NOW)
  expect_equal(nrow(res$kept), 0L)
  expect_setequal(res$rejected$rule, quiz_validation_rules())
  expect_true(all(res$rejected$count == 0L))
})

test_that("score == total is kept, score == total + 1 is rejected", {
  expect_equal(nrow(validate_quiz_submissions(row(score = 5, total = 5), now = NOW)$kept), 1L)
  res <- validate_quiz_submissions(row(score = 6, total = 5), now = NOW)
  expect_equal(nrow(res$kept), 0L)
  expect_equal(rej(res, "score_out_of_range"), 1L)
})

test_that("score 0 is kept, score -1 is rejected", {
  expect_equal(nrow(validate_quiz_submissions(row(score = 0), now = NOW)$kept), 1L)
  res <- validate_quiz_submissions(row(score = -1), now = NOW)
  expect_equal(rej(res, "score_out_of_range"), 1L)
})

test_that("non-whole score or total is rejected", {
  res <- validate_quiz_submissions(
    dplyr::bind_rows(row(score = 2.5), row(total = 5.5)), now = NOW
  )
  expect_equal(rej(res, "score_or_total_not_whole"), 2L)
  expect_equal(nrow(res$kept), 0L)
})

test_that("missing score or total is rejected and counted", {
  res <- validate_quiz_submissions(
    dplyr::bind_rows(row(score = NA_real_), row(total = NA_real_)), now = NOW
  )
  expect_equal(rej(res, "score_or_total_missing"), 2L)
})

test_that("total must be a length the quiz can produce", {
  # acute/chronic: 1..max(quiz length options); ranking: always 100
  expect_equal(nrow(validate_quiz_submissions(row(score = 1, total = 10, n_questions = 10), now = NOW)$kept), 1L)
  res <- validate_quiz_submissions(row(score = 1, total = 11, n_questions = 10), now = NOW)
  expect_equal(rej(res, "total_not_producible"), 1L)
  res0 <- validate_quiz_submissions(row(score = 0, total = 0), now = NOW)
  expect_equal(rej(res0, "total_not_producible"), 1L)
  rk <- row(score = 70, total = 100, quiz_type = "ranking", difficulty = "3items")
  expect_equal(nrow(validate_quiz_submissions(rk, now = NOW)$kept), 1L)
  rk_bad <- row(score = 70, total = 99, quiz_type = "ranking", difficulty = "3items")
  expect_equal(rej(validate_quiz_submissions(rk_bad, now = NOW), "total_not_producible"), 1L)
})

test_that("early ranking rows with a raw pair-count total are kept only before the cutover", {
  legacy <- row(score = 9, total = 15, quiz_type = "ranking", difficulty = "3items",
                timestamp = "2026-03-25T10:00:00.000Z")
  expect_equal(nrow(validate_quiz_submissions(legacy, now = NOW)$kept), 1L)
  legacy_mixed <- legacy
  legacy_mixed$difficulty <- "mixed" # early Shinylive version sent a plain difficulty
  expect_equal(nrow(validate_quiz_submissions(legacy_mixed, now = NOW)$kept), 1L)
  after <- legacy
  after$timestamp <- "2026-04-01T10:00:00.000Z"
  expect_equal(rej(validate_quiz_submissions(after, now = NOW), "total_not_producible"), 1L)
  odd <- legacy
  odd$total <- 14
  expect_equal(rej(validate_quiz_submissions(odd, now = NOW), "total_not_producible"), 1L)
})

test_that("n_questions must be an offered length and cover total", {
  ok <- row(score = 1, total = 5, n_questions = 10) # fewer questions than asked: allowed
  expect_equal(nrow(validate_quiz_submissions(ok, now = NOW)$kept), 1L)
  bad_n <- row(n_questions = 7)
  expect_equal(rej(validate_quiz_submissions(bad_n, now = NOW), "n_questions_inconsistent"), 1L)
  bad_total <- row(score = 1, total = 8, n_questions = 5)
  expect_equal(rej(validate_quiz_submissions(bad_total, now = NOW), "n_questions_inconsistent"), 1L)
  legacy <- row(n_questions = NA_real_) # rows from before the field existed
  expect_equal(nrow(validate_quiz_submissions(legacy, now = NOW)$kept), 1L)
})

test_that("quiz_type must be a known type", {
  res <- validate_quiz_submissions(row(quiz_type = "hacked"), now = NOW)
  expect_equal(rej(res, "quiz_type_unknown"), 1L)
  for (qt in c("acute", "chronic")) {
    expect_equal(nrow(validate_quiz_submissions(row(quiz_type = qt), now = NOW)$kept), 1L)
  }
})

test_that("difficulty must be known when present, NA is fine", {
  for (d in c("easy", "medium", "hard", "mixed", NA_character_)) {
    expect_equal(nrow(validate_quiz_submissions(row(difficulty = d), now = NOW)$kept), 1L)
  }
  res <- validate_quiz_submissions(row(difficulty = "impossible"), now = NOW)
  expect_equal(rej(res, "difficulty_unknown"), 1L)
  rk <- row(score = 50, total = 100, quiz_type = "ranking", difficulty = "5items")
  expect_equal(rej(validate_quiz_submissions(rk, now = NOW), "difficulty_unknown"), 1L)
})

test_that("timestamp exactly now + skew is kept, one second later is rejected", {
  edge <- format(NOW + as.difftime(1, units = "days"), "%Y-%m-%dT%H:%M:%S.000Z", tz = "UTC")
  late <- format(NOW + as.difftime(1, units = "days") + 1, "%Y-%m-%dT%H:%M:%S.000Z", tz = "UTC")
  expect_equal(nrow(validate_quiz_submissions(row(timestamp = edge), now = NOW)$kept), 1L)
  res <- validate_quiz_submissions(row(timestamp = late), now = NOW)
  expect_equal(rej(res, "timestamp_in_future"), 1L)
})

test_that("timestamp exactly at the launch instant is kept, one second before is rejected", {
  launch <- quiz_submission_launch()
  on_edge <- format(launch, "%Y-%m-%dT%H:%M:%S.000Z", tz = "UTC")
  before <- format(launch - 1, "%Y-%m-%dT%H:%M:%S.000Z", tz = "UTC")
  expect_equal(nrow(validate_quiz_submissions(row(timestamp = on_edge), now = NOW)$kept), 1L)
  expect_equal(rej(validate_quiz_submissions(row(timestamp = before), now = NOW), "timestamp_before_launch"), 1L)
})

test_that("unparseable or missing timestamp is rejected", {
  res <- validate_quiz_submissions(
    dplyr::bind_rows(row(timestamp = "not a date"), row(timestamp = NA_character_)),
    now = NOW
  )
  expect_equal(rej(res, "timestamp_unparseable"), 2L)
})

test_that("confidence 0 and 100 are kept, 100.1 and -0.1 rejected, NA kept", {
  for (cv in c(0, 100, NA_real_)) {
    expect_equal(nrow(validate_quiz_submissions(row(avg_confidence_pct = cv), now = NOW)$kept), 1L)
  }
  for (cv in c(100.1, -0.1)) {
    res <- validate_quiz_submissions(row(avg_confidence_pct = cv), now = NOW)
    expect_equal(rej(res, "confidence_out_of_range"), 1L)
  }
})

test_that("exact duplicates keep the first row and count the rest", {
  d <- dplyr::bind_rows(row(), row(), row(), row(score = 4))
  res <- validate_quiz_submissions(d, now = NOW)
  expect_equal(nrow(res$kept), 2L)
  expect_equal(rej(res, "duplicate_row"), 2L)
  expect_equal(res$kept$score, c(3, 4)) # keep-first, order preserved
})

test_that("a row failing several rules is counted once, so counts sum to rejections", {
  d <- row(score = 99, total = 99, quiz_type = "hacked", timestamp = "garbage")
  res <- validate_quiz_submissions(d, now = NOW)
  expect_equal(sum(res$rejected$count), 1L)
  expect_equal(nrow(res$kept) + sum(res$rejected$count), nrow(d))
})

test_that("the rejection table holds rule names and counts only, never row values", {
  secret <- "DEVICE-ID-abc123"
  d <- dplyr::bind_rows(row(quiz_type = secret), row(timestamp = secret), row(difficulty = secret))
  res <- validate_quiz_submissions(d, now = NOW)
  expect_named(res$rejected, c("rule", "count"))
  expect_type(res$rejected$count, "integer")
  expect_false(any(grepl(secret, unlist(res$rejected), fixed = TRUE)))
  expect_setequal(res$rejected$rule, quiz_validation_rules())
})

test_that("rejected_counts_list gives a named list covering every rule", {
  res <- validate_quiz_submissions(row(score = 9), now = NOW)
  lst <- rejected_counts_list(res$rejected)
  expect_setequal(names(lst), quiz_validation_rules())
  expect_equal(lst$score_out_of_range, 1L)
  expect_setequal(names(rejected_counts_list(NULL)), quiz_validation_rules())
})

test_that("allowed sets match what the quiz pages and R generators can produce", {
  vig <- testthat::test_path("..", "..", "vignettes")
  skip_if_not(dir.exists(vig), "vignettes/ not available in this test context")
  for (f in c("micromort-quiz.qmd", "microlife-quiz.qmd")) {
    src <- paste(readLines(file.path(vig, f), warn = FALSE), collapse = "\n")
    for (n in QUIZ_N_QUESTIONS_OPTIONS) {
      expect_true(grepl(sprintf("S.selNq=%d;", n), src, fixed = TRUE), info = f)
    }
    for (d in QUIZ_DIFFICULTIES) {
      expect_true(grepl(sprintf("S.selDifficulty='%s'", d), src, fixed = TRUE), info = f)
    }
  }
  # ranking quiz: items_per_question is 2..4 (R/ranking_quiz.R assert_int)
  rq <- testthat::test_path("..", "..", "R", "ranking_quiz.R")
  if (file.exists(rq)) {
    src <- paste(readLines(rq, warn = FALSE), collapse = "\n")
    expect_true(grepl("items_per_question, lower = 2L, upper = 4L", src, fixed = TRUE))
    expect_equal(QUIZ_RANKING_ITEMS, 2:4)
  }
})
