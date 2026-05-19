# Tests for qa_chronic_csv_gate enforcement logic (Bug 4 fix)
#
# The gate target in plan_qa_gates.R must abort (cli::cli_abort) when
# vig_chronic_csv_check$status != "OK".  These tests exercise that logic
# directly — no tar_make() required.

# Helper: simulate the gate logic extracted from the target body
run_gate <- function(check) {
  status <- check$status
  if (status != "OK") {
    cli::cli_abort(c(
      "x" = "Chronic CSV gate FAILED: embedded CSV in chronic_quiz_shinylive.qmd is {status}",
      "i" = "canonical_rows = {check$canonical_rows}, embedded_rows = {check$embedded_rows}",
      "i" = "canonical_hash = {check$canonical_hash}",
      "i" = "embedded_hash  = {check$embedded_hash}",
      "i" = "Re-run the chronic_pairs pipeline target and update the embedded CSV"
    ))
  }
  list(status = status, rows = check$canonical_rows)
}

test_that("gate passes when vig_chronic_csv_check status is OK", {
  check_ok <- list(
    status = "OK",
    canonical_rows = 10L,
    embedded_rows = 10L,
    canonical_hash = "abc123",
    embedded_hash  = "abc123"
  )
  result <- run_gate(check_ok)
  expect_equal(result$status, "OK")
  expect_equal(result$rows, 10L)
})

test_that("gate aborts with informative message when status is STALE", {
  check_stale <- list(
    status = "STALE",
    canonical_rows = 12L,
    embedded_rows = 10L,
    canonical_hash = "abc123",
    embedded_hash  = "def456"
  )
  expect_error(
    run_gate(check_stale),
    regexp = "Chronic CSV gate FAILED.*STALE",
    class = "rlang_error"
  )
})

test_that("gate aborts when status is ERROR", {
  check_error <- list(
    status = "ERROR",
    canonical_rows = 0L,
    embedded_rows = 0L,
    canonical_hash = "",
    embedded_hash  = "",
    message = "Could not find ## file: chronic_pairs.csv in qmd"
  )
  expect_error(
    run_gate(check_error),
    regexp = "Chronic CSV gate FAILED.*ERROR",
    class = "rlang_error"
  )
})

test_that("gate error message includes row counts and hashes", {
  check_stale <- list(
    status = "STALE",
    canonical_rows = 12L,
    embedded_rows = 9L,
    canonical_hash = "canonical_abc",
    embedded_hash  = "embedded_xyz"
  )
  expect_snapshot(
    error = TRUE,
    run_gate(check_stale)
  )
})
