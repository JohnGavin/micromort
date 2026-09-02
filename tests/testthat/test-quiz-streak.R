# ---- Streak-key UTC->local migration shim removal (#107) --------------------
#
# Context: a one-time migration shim (added 2026-05-17, commit b4461ad) used
# to rewrite a legacy UTC-format streak key into the current local-date key
# whenever it matched `todayUtc`/`yestUtc`. The shim's migration window has
# long since closed (see the dated comment on streak_core_js() in R/quiz.R)
# and the match was ambiguous by construction for negative-UTC-offset users:
# a *local*-format key written earlier the same calendar day could coincide
# with `yestUtc` once UTC rolled past midnight, causing a spurious extra
# `streak += 1` for a single day's play. The fix removes the shim entirely
# from all five sites it appeared in (two in R/quiz.R, one each in the three
# Shinylive vignettes) rather than replacing it with a cleverer one, since it
# can no longer migrate anything.
#
# This file has two kinds of coverage:
#   1. Source-level checks directly on the shipped JS strings/files (the
#      tests that actually gate what ships).
#   2. An R port of the exact deleted JS algorithm, used only to demonstrate
#      the double-count bug analytically (RED) and confirm the fix (GREEN).
#      No JS execution engine (e.g. V8) is wired into this package's test
#      harness, so this is the honest fallback for exercising the algorithm
#      itself rather than merely its absence from the source text.

# ---- 1a. No shim text remains in the R-side generated JS -------------------

test_that("streak_js() and leaderboard_js() contain no legacy UTC migration shim (#107)", {
  streak_out <- streak_js()
  leaderboard_out <- leaderboard_js()

  for (needle in c("utcDateKey", "todayUtc", "yestUtc")) {
    expect_false(
      grepl(needle, streak_out, fixed = TRUE),
      label = paste0("streak_js() contains '", needle, "'")
    )
    expect_false(
      grepl(needle, leaderboard_out, fixed = TRUE),
      label = paste0("leaderboard_js() contains '", needle, "'")
    )
  }
})

# ---- 1b. streak_js() and leaderboard_js() share one implementation ---------
# Regression guard for the duplication that let #102's fix land in one copy
# and miss the other: both callers must inject the exact same
# streak_core_js() text, not a hand-copied twin that can silently diverge.

test_that("streak_js() and leaderboard_js() share one streak-core implementation (#107)", {
  core <- streak_core_js()
  expect_true(nchar(core) > 0)

  expect_true(
    grepl(core, streak_js(), fixed = TRUE),
    label = "streak_js() includes streak_core_js() verbatim"
  )
  expect_true(
    grepl(core, leaderboard_js(), fixed = TRUE),
    label = "leaderboard_js() includes streak_core_js() verbatim"
  )
})

# ---- 1c. Shinylive vignette copies are shim-free and stay identical --------
# quiz_shinylive.qmd / chronic_quiz_shinylive.qmd / ranking_quiz_shinylive.qmd
# are standalone WASM apps (#| standalone: true) with no cross-file include
# mechanism for JS in this repo (vignettes/_includes/ only holds a
# site-wide toolbar.html wired through _quarto.yml, not a per-chunk partial).
# Introducing one here would be untested against the shinylive filter, so
# the three copies stay independently maintained -- this test is the
# regression guard that keeps them from silently diverging, the way #107's
# own two R/quiz.R sites did.

extract_update_streak_display <- function(qmd_lines) {
  start <- grep("^function localDateKey\\(d\\) \\{", qmd_lines)
  end <- grep("^function updateStreakDisplay\\(scorePct\\) \\{", qmd_lines)
  stopifnot(length(start) == 1, length(end) == 1)
  # Function bodies are closed by a `}` at column 0; find the first one at or
  # after `end`, which closes updateStreakDisplay itself (localDateKey's own
  # closing brace is skipped because it precedes `end`).
  close_candidates <- grep("^\\}$", qmd_lines)
  close <- min(close_candidates[close_candidates > end])
  qmd_lines[start:close]
}

test_that("shinylive vignette streak shims are removed and identical across all three quizzes (#107)", {
  qmd_paths <- list(
    quiz = test_path("..", "..", "vignettes", "quiz_shinylive.qmd"),
    chronic = test_path("..", "..", "vignettes", "chronic_quiz_shinylive.qmd"),
    ranking = test_path("..", "..", "vignettes", "ranking_quiz_shinylive.qmd")
  )
  for (p in qmd_paths) {
    skip_if_not(file.exists(p), paste(p, "not found"))
  }

  blocks <- lapply(qmd_paths, function(p) extract_update_streak_display(readLines(p)))

  for (nm in names(blocks)) {
    block_text <- paste(blocks[[nm]], collapse = "\n")
    for (needle in c("utcDateKey", "todayUtc", "yestUtc")) {
      expect_false(
        grepl(needle, block_text, fixed = TRUE),
        label = paste0(nm, ": updateStreakDisplay() contains '", needle, "'")
      )
    }
  }

  expect_identical(blocks$quiz, blocks$chronic, label = "quiz vs chronic updateStreakDisplay() block")
  expect_identical(blocks$quiz, blocks$ranking, label = "quiz vs ranking updateStreakDisplay() block")
})

# ---- 2. Algorithmic RED -> GREEN reproduction (UTC-10 double-count) --------
#
# R port of the deleted shim's decision logic (was: R/quiz.R streak_js()'s
# updateStreak(), before #107):
#
#   if (lastPlay === todayUtc) {
#     lastPlay = today;
#   } else if (lastPlay === yestUtc) {
#     lastPlay = yesterday;
#   }
#   if (lastPlay === today) {
#     // already played today
#   } else if (lastPlay) {
#     if (lastPlay === yesterday) { streak += 1; } else { streak = 1; }
#   } else {
#     streak = 1;
#   }
#
# localDateKey(d) === local calendar date; utcDateKey(d) === d.toISOString()
# UTC calendar date. Ported below using base R POSIXct + format(..., tz=).

.streak_local_date_key <- function(instant, tz) format(instant, "%Y-%m-%d", tz = tz)
.streak_utc_date_key <- function(instant) format(instant, "%Y-%m-%d", tz = "UTC")

# Pre-fix (buggy) port -- includes the deleted UTC-key migration shim.
.streak_update_pre_fix <- function(now, last_play, streak, tz) {
  today <- .streak_local_date_key(now, tz)
  yest_instant <- now - 24 * 60 * 60
  yesterday <- .streak_local_date_key(yest_instant, tz)
  today_utc <- .streak_utc_date_key(now)
  yest_utc <- .streak_utc_date_key(yest_instant)

  if (identical(last_play, today_utc)) {
    last_play <- today
  } else if (identical(last_play, yest_utc)) {
    last_play <- yesterday
  }

  if (identical(last_play, today)) {
    # already played today
  } else if (!is.null(last_play) && !is.na(last_play) && nzchar(last_play)) {
    if (identical(last_play, yesterday)) {
      streak <- streak + 1
    } else {
      streak <- 1
    }
  } else {
    streak <- 1
  }
  list(last_play = today, streak = streak)
}

# Post-fix port -- matches the current streak_core_js() updateStreak(), no shim.
.streak_update_post_fix <- function(now, last_play, streak, tz) {
  today <- .streak_local_date_key(now, tz)
  yest_instant <- now - 24 * 60 * 60
  yesterday <- .streak_local_date_key(yest_instant, tz)

  if (identical(last_play, today)) {
    # already played today
  } else if (!is.null(last_play) && !is.na(last_play) && nzchar(last_play)) {
    if (identical(last_play, yesterday)) {
      streak <- streak + 1
    } else {
      streak <- 1
    }
  } else {
    streak <- 1
  }
  list(last_play = today, streak = streak)
}

test_that("RED: pre-fix migration shim double-counts a same-local-day replay at UTC-10 (#107)", {
  tz <- "Pacific/Honolulu" # fixed UTC-10, no DST

  # First play: 2026-05-20 08:00 local. lastPlay is written in LOCAL format
  # (post-#102 behaviour) -- no prior key, so no shim branch fires.
  first_play <- as.POSIXct("2026-05-20 08:00:00", tz = tz)
  r1 <- .streak_update_pre_fix(first_play, last_play = NULL, streak = 0, tz = tz)
  expect_equal(r1$last_play, "2026-05-20")
  expect_equal(r1$streak, 1)

  # Second play: SAME local calendar day (2026-05-20), 20:00 local. UTC has
  # already rolled past midnight to 2026-05-21 06:00, so yestUtc(now2) ==
  # "2026-05-20" == the stored (local-format) lastPlay from the first play.
  second_play <- as.POSIXct("2026-05-20 20:00:00", tz = tz)
  r2 <- .streak_update_pre_fix(second_play, last_play = r1$last_play, streak = r1$streak, tz = tz)

  # BUG: two plays on the same local day should never increment the streak
  # a second time -- but the shim's UTC-key match rewrites lastPlay to
  # "yesterday", so the streak logic treats this as a fresh consecutive day.
  expect_equal(r2$streak, 2)
})

test_that("GREEN: post-fix logic does not double-count a same-local-day replay at UTC-10 (#107)", {
  tz <- "Pacific/Honolulu"

  first_play <- as.POSIXct("2026-05-20 08:00:00", tz = tz)
  r1 <- .streak_update_post_fix(first_play, last_play = NULL, streak = 0, tz = tz)
  expect_equal(r1$last_play, "2026-05-20")
  expect_equal(r1$streak, 1)

  second_play <- as.POSIXct("2026-05-20 20:00:00", tz = tz)
  r2 <- .streak_update_post_fix(second_play, last_play = r1$last_play, streak = r1$streak, tz = tz)

  # FIXED: same local day, second play -- streak is unchanged, not incremented.
  expect_equal(r2$last_play, "2026-05-20")
  expect_equal(r2$streak, 1)
})

test_that("post-fix logic still increments streak correctly on a genuine next-day play at UTC-10 (#107)", {
  tz <- "Pacific/Honolulu"

  day1_play <- as.POSIXct("2026-05-20 20:00:00", tz = tz)
  r1 <- .streak_update_post_fix(day1_play, last_play = NULL, streak = 0, tz = tz)
  expect_equal(r1$streak, 1)

  day2_play <- as.POSIXct("2026-05-21 08:00:00", tz = tz)
  r2 <- .streak_update_post_fix(day2_play, last_play = r1$last_play, streak = r1$streak, tz = tz)
  expect_equal(r2$streak, 2)

  # A play after a genuine gap day resets to 1.
  day4_play <- as.POSIXct("2026-05-23 08:00:00", tz = tz)
  r3 <- .streak_update_post_fix(day4_play, last_play = r2$last_play, streak = r2$streak, tz = tz)
  expect_equal(r3$streak, 1)
})
