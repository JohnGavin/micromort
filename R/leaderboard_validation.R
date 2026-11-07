# Recheck of Google Form quiz submissions for the leaderboard pipeline (#215).
#
# The Form is public and anonymous: any client can post any value, so the
# weekly pipeline re-derives what it can and REPORTS what it rejects.
# Counts only: the rejection table never carries row contents or IDs
# (the repo is public).

# One home for the values the quiz pages and R generators can produce.
# The test file asserts these against the vignettes/ and R/ sources, so a
# change to the quiz UI that is not mirrored here fails a test.

# Quiz lengths offered in the UI (S.selNq=5 / S.selNq=10 buttons in the
# acute and chronic vignettes; radioButtons "5"/"10" in R/quiz.R).
# The submitted total is min(selection, pool size), so any 1..max is valid.
QUIZ_N_QUESTIONS_OPTIONS <- c(5L, 10L)

# Difficulty buttons in the acute/chronic vignettes (R/quiz.R assert_choice).
QUIZ_DIFFICULTIES <- c("easy", "medium", "hard", "mixed")

# Ranking quiz: items per question 2..4 (R/ranking_quiz.R assert_int);
# the page submits difficulty as "<N>items" and total = 100 (a percentage).
QUIZ_RANKING_ITEMS <- 2:4
QUIZ_RANKING_TOTAL <- 100L

# Quiz types the pages submit (entry.268026248).
QUIZ_TYPES <- c("acute", "chronic", "ranking")

# Early ranking quiz (Shinylive version, 2026-03-24 to the pure-JS rewrite,
# commit d2f2335 on 2026-03-26) submitted the RAW pair score and pair count
# as total (choose(k, 2) pairs for k items), not a percentage out of 100.
# Rows stamped before the cutover below may carry such a total. The upper
# bound k = 6 is NOT derivable from the code (the Shinylive source is
# retired); it is the largest value seen in the real Sheet (total 15).
# Those rows also carry a plain difficulty ("mixed") instead of "<N>items".
QUIZ_RANKING_LEGACY_CUTOVER <- as.POSIXct("2026-03-27 00:00:00", tz = "UTC")
QUIZ_RANKING_LEGACY_TOTALS <- choose(2:6, 2)

# Earliest plausible submission: the commit that first wired the
# leaderboard Sheet into the repo (git log --reverse -S<sheet id>) is
# 2026-03-11. Anything stamped earlier cannot be a genuine submission.
quiz_submission_launch <- function() {
  as.POSIXct("2026-03-11 00:00:00", tz = "UTC")
}

# Rule names in precedence order. A row is attributed to the FIRST rule it
# fails, so counts never double-count and sum to the number rejected.
quiz_validation_rules <- function() {
  c(
    "score_or_total_missing",
    "score_or_total_not_whole",
    "quiz_type_unknown",
    "score_out_of_range",
    "total_not_producible",
    "n_questions_inconsistent",
    "difficulty_unknown",
    "timestamp_unparseable",
    "timestamp_in_future",
    "timestamp_before_launch",
    "confidence_out_of_range",
    "duplicate_row"
  )
}

#' Parse the ISO timestamp the quiz pages send (`new Date().toISOString()`)
#' @param x Character vector, e.g. "2026-11-01T10:00:00.000Z".
#' @return POSIXct (UTC), NA where unparseable.
#' @noRd
parse_quiz_timestamp <- function(x) {
  x <- sub("Z$", "", sub("\\.[0-9]+Z?$", "", as.character(x)))
  as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
}

#' Recheck quiz submissions and report what was rejected
#'
#' Applies explicit rules to the raw Sheet rows. Each rejected row is counted
#' under the first rule it fails (see `quiz_validation_rules()` for the
#' order). Exact duplicates (same timestamp, score, total and quiz type) are
#' counted under `duplicate_row` and the FIRST occurrence is kept, since the
#' timestamp has millisecond resolution and a repeat is a re-post, not a
#' second attempt.
#'
#' @param df Tibble with `score`, `total` (numeric), `timestamp`, `quiz_type`,
#'   `difficulty` (character), `n_questions`, `avg_confidence_pct` (numeric).
#' @param now POSIXct "current time", injectable for tests.
#' @param skew_days Clock skew tolerated for future timestamps. Default 1.
#' @return List with `kept` (the valid rows, original order) and `rejected`
#'   (tibble of `rule`, `count` with one row per rule, zeros included).
#'   No row values are ever placed in `rejected`.
#' @noRd
validate_quiz_submissions <- function(df, now = Sys.time(), skew_days = 1) {
  n <- nrow(df)
  rules <- quiz_validation_rules()
  verdict <- rep(NA_character_, n) # first failed rule per row
  flag <- function(bad, rule) {
    bad[is.na(bad)] <- FALSE
    hit <- bad & is.na(verdict)
    verdict[hit] <<- rule
  }

  score <- df$score
  total <- df$total
  qt <- df$quiz_type
  is_ranking <- !is.na(qt) & qt == "ranking"

  flag(is.na(score) | is.na(total), "score_or_total_missing")
  flag(score != round(score) | total != round(total), "score_or_total_not_whole")
  flag(is.na(qt) | !qt %in% QUIZ_TYPES, "quiz_type_unknown")
  flag(score < 0 | score > total, "score_out_of_range")

  ts <- parse_quiz_timestamp(df$timestamp)
  legacy_ranking <- is_ranking & !is.na(ts) & ts < QUIZ_RANKING_LEGACY_CUTOVER

  max_total <- max(QUIZ_N_QUESTIONS_OPTIONS)
  producible <- ifelse(
    is_ranking,
    total == QUIZ_RANKING_TOTAL |
      (legacy_ranking & total %in% QUIZ_RANKING_LEGACY_TOTALS),
    total >= 1 & total <= max_total
  )
  flag(!producible, "total_not_producible")

  nq <- df$n_questions
  flag(
    !is.na(nq) & (!nq %in% QUIZ_N_QUESTIONS_OPTIONS |
      (!is_ranking & total > nq)),
    "n_questions_inconsistent"
  )

  d <- df$difficulty
  d_ok <- ifelse(
    is_ranking,
    d %in% paste0(QUIZ_RANKING_ITEMS, "items") |
      (legacy_ranking & d %in% QUIZ_DIFFICULTIES),
    d %in% QUIZ_DIFFICULTIES
  )
  flag(!is.na(d) & nzchar(d) & !d_ok, "difficulty_unknown")

  flag(is.na(ts), "timestamp_unparseable")
  flag(ts > now + as.difftime(skew_days, units = "days"), "timestamp_in_future")
  flag(ts < quiz_submission_launch(), "timestamp_before_launch")

  flag(
    !is.na(df$avg_confidence_pct) &
      (df$avg_confidence_pct < 0 | df$avg_confidence_pct > 100),
    "confidence_out_of_range"
  )

  # Duplicates are judged among rows that passed every other rule, so a
  # malformed row never causes a valid one to be called a duplicate.
  ok <- is.na(verdict)
  key <- paste(df$timestamp, df$score, df$total, df$quiz_type, sep = "\r")
  dup <- ok & duplicated(ifelse(ok, key, NA_character_)) & !is.na(key)
  flag(dup, "duplicate_row")

  counts <- vapply(
    rules, function(r) sum(verdict == r, na.rm = TRUE), integer(1)
  )
  list(
    kept = df[is.na(verdict), , drop = FALSE],
    rejected = tibble::tibble(rule = rules, count = unname(counts))
  )
}

#' Convert a rejection table to a named list (counts by rule) for JSON
#' @param rejected Tibble from `validate_quiz_submissions()$rejected`, or NULL.
#' @return Named list of integer counts, one entry per rule.
#' @noRd
rejected_counts_list <- function(rejected) {
  rules <- quiz_validation_rules()
  out <- stats::setNames(as.list(rep(0L, length(rules))), rules)
  if (!is.null(rejected)) {
    for (i in seq_len(nrow(rejected))) {
      out[[rejected$rule[i]]] <- as.integer(rejected$count[i])
    }
  }
  out
}
