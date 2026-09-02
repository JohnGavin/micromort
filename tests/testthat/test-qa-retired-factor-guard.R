# Tests for the retired-chronic-factor guard (issue #110 / roborev cluster).
#
# The PM2.5 refactor in chronic_risks() renamed "Air pollution (high)" to a
# PM2.5 ladder, but a stale rendered artifact (docs/articles/palatable_units.html)
# kept shipping the retired name. .qa_retired_factor_scan() (defined in
# R/tar_plans/plan_qa_gates.R) scans committed docs/ artifacts for retired
# factor names and must distinguish three outcomes -- OK, STALE, ERROR
# (indeterminate) -- per the checks-must-distinguish-unknown discipline: an
# indeterminate scan (docs/ missing, canonical data unreadable, nothing
# scannable) must never be silently treated as a pass.
#
# plan_qa_gates.R is a targets plan file, not part of the package's R/
# directory, so devtools::load_all() does not source it (verified: the
# helper functions are undefined after load_all() alone). It is sourced
# explicitly here, mirroring how tar_plans files are sourced by _targets.R.

source(testthat::test_path("..", "..", "R", "tar_plans", "plan_qa_gates.R"))

# ---------------------------------------------------------------------------
# .qa_retired_factor_scan() -- the pure scanning function
# ---------------------------------------------------------------------------

test_that("scan reports ERROR (not OK) when canonical names are unreadable", {
  tmp <- withr::local_tempdir()
  dir.create(file.path(tmp, "docs"))
  writeLines("<html>irrelevant</html>", file.path(tmp, "docs", "index.html"))

  result <- .qa_retired_factor_scan(file.path(tmp, "docs"), NULL, c("Air pollution (high)"))

  expect_equal(result$status, "ERROR")
  expect_match(result$message, "canonical", ignore.case = TRUE)
  expect_length(result$violations, 0)
})

test_that("scan reports ERROR (not OK) when docs dir is missing", {
  tmp <- withr::local_tempdir()

  result <- .qa_retired_factor_scan(
    file.path(tmp, "docs-does-not-exist"),
    c("Air pollution (PM2.5 ~25 μg/m³)"),
    c("Air pollution (high)")
  )

  expect_equal(result$status, "ERROR")
  expect_match(result$message, "not found")
})

test_that("scan reports ERROR (not OK) when nothing is scannable", {
  tmp <- withr::local_tempdir()
  docs_dir <- file.path(tmp, "docs")
  dir.create(docs_dir)
  # Only a non-html/md file present -- there is genuinely nothing to check.
  writeLines("data", file.path(docs_dir, "data.csv"))

  result <- .qa_retired_factor_scan(
    docs_dir,
    c("Air pollution (PM2.5 ~25 μg/m³)"),
    c("Air pollution (high)")
  )

  expect_equal(result$status, "ERROR")
  expect_match(result$message, "no scannable")
})

test_that("scan is RED: reports STALE with file:line when a retired name is present", {
  tmp <- withr::local_tempdir()
  docs_dir <- file.path(tmp, "docs")
  dir.create(file.path(docs_dir, "articles"), recursive = TRUE)
  target_file <- file.path(docs_dir, "articles", "palatable_units.html")
  writeLines(
    c(
      "<html><body>",
      '"data":[["Air pollution (high)","Air pollution (PM2.5 ~25 μg/m³)"]]',
      "</body></html>"
    ),
    target_file
  )

  result <- .qa_retired_factor_scan(
    docs_dir,
    c("Air pollution (PM2.5 ~25 μg/m³)"),
    c("Air pollution (high)")
  )

  expect_equal(result$status, "STALE")
  expect_length(result$violations, 1)
  expect_match(result$violations[1], "palatable_units\\.html:2")
  expect_match(result$violations[1], "Air pollution \\(high\\)")
})

test_that("scan is GREEN: same fixture with the retired name removed is OK", {
  tmp <- withr::local_tempdir()
  docs_dir <- file.path(tmp, "docs")
  dir.create(file.path(docs_dir, "articles"), recursive = TRUE)
  target_file <- file.path(docs_dir, "articles", "palatable_units.html")
  writeLines(
    c(
      "<html><body>",
      '"data":[["Air pollution (PM2.5 ~25 μg/m³)"]]',
      "</body></html>"
    ),
    target_file
  )

  result <- .qa_retired_factor_scan(
    docs_dir,
    c("Air pollution (PM2.5 ~25 μg/m³)"),
    c("Air pollution (high)")
  )

  expect_equal(result$status, "OK")
  expect_length(result$violations, 0)
})

test_that("scan does not false-positive on a retired name inside CHANGELOG.md/html", {
  tmp <- withr::local_tempdir()
  docs_dir <- file.path(tmp, "docs")
  dir.create(docs_dir)
  writeLines(
    c(
      "# Changelog",
      "- Replaced retired `Air pollution (high)` row with 4 PM2.5 ladder rows."
    ),
    file.path(docs_dir, "CHANGELOG.md")
  )
  writeLines(
    "<html><body>Replaced retired Air pollution (high) row.</body></html>",
    file.path(docs_dir, "CHANGELOG.html")
  )
  # A genuinely stale article alongside the changelog, to prove exclusion is
  # scoped to CHANGELOG.* and not swallowing every violation.
  dir.create(file.path(docs_dir, "articles"))
  writeLines(
    'Air pollution (high)',
    file.path(docs_dir, "articles", "stale.html")
  )

  result <- .qa_retired_factor_scan(
    docs_dir,
    c("Air pollution (PM2.5 ~25 μg/m³)"),
    c("Air pollution (high)")
  )

  expect_equal(result$status, "STALE")
  expect_length(result$violations, 1)
  expect_match(result$violations[1], "stale\\.html")
})

test_that("a denylist name reinstated into canonical data is not enforced", {
  tmp <- withr::local_tempdir()
  docs_dir <- file.path(tmp, "docs")
  dir.create(docs_dir)
  writeLines(
    "Air pollution (high) is mentioned here as live text.",
    file.path(docs_dir, "page.html")
  )

  # Simulate: the "retired" name is actually back in the canonical set
  # (e.g. a denylist entry that has gone stale). The guard must not
  # false-fail on it.
  result <- .qa_retired_factor_scan(
    docs_dir,
    c("Air pollution (high)"),
    c("Air pollution (high)")
  )

  expect_equal(result$status, "OK")
  expect_length(result$checked_names, 0)
})

# ---------------------------------------------------------------------------
# Gate wrapper logic (mirrors test-qa-chronic-csv-gate.R): the target must
# cli_abort() on anything other than OK -- STALE and ERROR alike must never
# be silently treated as a pass.
# ---------------------------------------------------------------------------

run_retired_factor_gate <- function(check) {
  if (check$status != "OK") {
    cli::cli_abort(c(
      "x" = "Retired-factor gate FAILED: status = {check$status}",
      if (check$status == "STALE") {
        setNames(check$violations, rep("i", length(check$violations)))
      } else {
        c("i" = check$message)
      },
      "i" = if (check$status == "STALE") {
        "Regenerate the stale docs/ artifact(s) from current chronic_risks() output"
      } else {
        "Fix the underlying cause (missing docs/, unreadable chronic_risks()) before trusting this gate"
      }
    ))
  }
  list(status = check$status, timestamp = Sys.time())
}

test_that("gate passes silently when status is OK", {
  result <- run_retired_factor_gate(list(status = "OK", violations = character(0)))
  expect_equal(result$status, "OK")
})

test_that("gate aborts when status is STALE", {
  check_stale <- list(
    status = "STALE",
    violations = "docs/articles/palatable_units.html:307 -- retired factor 'Air pollution (high)'"
  )
  expect_error(
    run_retired_factor_gate(check_stale),
    regexp = "Retired-factor gate FAILED.*STALE",
    class = "rlang_error"
  )
})

test_that("gate aborts when status is ERROR (indeterminate is never a pass)", {
  check_error <- list(status = "ERROR", message = "docs directory 'docs' not found")
  expect_error(
    run_retired_factor_gate(check_error),
    regexp = "Retired-factor gate FAILED.*ERROR",
    class = "rlang_error"
  )
})

# ---------------------------------------------------------------------------
# Live smoke test: the function must run cleanly against the real package
# tree without erroring. This intentionally does NOT assert a specific
# status -- docs/ content changes independently of this guard's logic (see
# issue #110 follow-up for the currently-known palatable_units.html
# violation) -- it only proves the scan executes end-to-end on real data.
# ---------------------------------------------------------------------------

test_that("scan runs cleanly against the real package docs/ tree", {
  skip_if_not(dir.exists(testthat::test_path("..", "..", "docs")))
  canonical <- chronic_risks()$factor
  result <- .qa_retired_factor_scan(
    testthat::test_path("..", "..", "docs"),
    canonical,
    RETIRED_CHRONIC_FACTOR_NAMES
  )
  expect_true(result$status %in% c("OK", "STALE", "ERROR"))
  expect_true(is.character(result$violations))
})
