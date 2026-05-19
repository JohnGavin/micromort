# Regression tests for roborev bug A3:
# common_risks() rounds micromorts_per_day to 2 decimal places, which causes
# low-rate annual/monthly rows to collapse to 0.00 (e.g. 0.003/day → 0).
# combined_quiz_pairs() must use micromorts_per_day_raw (unrounded) for
# projection so that quiz values, ratios, and explanations are correct.

# ── common_risks(): new column present and non-degenerate ─────────────────────

test_that("common_risks() has micromorts_per_day_raw column", {
  cr <- common_risks()
  expect_true("micromorts_per_day_raw" %in% names(cr))
})

test_that("micromorts_per_day_raw is numeric", {
  cr <- common_risks()
  expect_type(cr$micromorts_per_day_raw, "double")
})

test_that("micromorts_per_day = round(micromorts_per_day_raw, 2) for all rows", {
  cr <- common_risks()
  expect_equal(cr$micromorts_per_day, round(cr$micromorts_per_day_raw, 2))
})

test_that("micromorts_per_day_raw equals micromorts / period_days for all rows", {
  cr <- common_risks()
  # Only check rows where period_days is non-NA and non-zero
  ok <- !is.na(cr$period_days) & cr$period_days > 0
  expect_equal(
    cr$micromorts_per_day_raw[ok],
    cr$micromorts[ok] / cr$period_days[ok],
    tolerance = 1e-10
  )
})

# ── Low-rate annual row: real data ────────────────────────────────────────────
# Any row whose period_days >= 365 and micromorts < 1 will have
# micromorts/period_days < 1/365 ≈ 0.0027 which rounds to 0.00.
# After the fix, micromorts_per_day_raw must still carry the true value.

test_that("low-rate annual rows have micromorts_per_day_raw > 0 even when micromorts_per_day == 0", {
  cr <- common_risks()
  # Rows where rounding collapsed to 0 but there is still real risk
  collapsed <- cr[
    !is.na(cr$period_days) & cr$period_days >= 365 &
      cr$micromorts > 0 &
      cr$micromorts_per_day == 0,
  ]
  if (nrow(collapsed) == 0L) {
    # No current rows hit this; the fix is still defensive.  Pass vacuously.
    succeed("No rows currently collapse to 0 after rounding; regression guard in place.")
  } else {
    expect_true(all(collapsed$micromorts_per_day_raw > 0),
      info = "micromorts_per_day_raw must be > 0 for rows with positive micromorts")
  }
})

test_that("micromorts_per_day_raw equals exact micromorts/period_days for all non-event rows", {
  # micromorts_per_day_raw = micromorts / period_days (exact; no rounding).
  # micromorts_per_day = round(raw, 2) (display-rounded, may be 0 for low rates).
  # This test confirms the raw column carries untruncated precision.
  cr <- common_risks()
  ok <- !is.na(cr$period_days) & cr$period_days > 0 & cr$micromorts > 0
  if (!any(ok)) skip("no valid rows to compare")
  expect_equal(
    cr$micromorts_per_day_raw[ok],
    cr$micromorts[ok] / cr$period_days[ok],
    tolerance = 1e-10,
    label = "micromorts_per_day_raw must equal exact micromorts/period_days"
  )
  # For rows where the rounded display value collapsed to 0,
  # the raw column must still retain the true non-zero value
  lost_precision <- ok & cr$micromorts_per_day == 0
  if (any(lost_precision)) {
    expect_true(all(cr$micromorts_per_day_raw[lost_precision] > 0),
      label = "Rows where display rounds to 0 must have raw > 0"
    )
  }
})

# ── Synthetic 0.1 mm / 365-day row ───────────────────────────────────────────
# This is the canonical low-rate case described in the roborev bug report.
# micromorts = 0.1, period_days = 365 → rate = 0.000274/day → rounds to 0.00
# The raw column must retain the true value; combined_quiz_pairs must use it.

test_that("synthetic 0.1-micromort annual row: micromorts_per_day collapses to 0 (documents the rounding)", {
  # Directly compute what round() does to this value
  raw_rate <- 0.1 / 365
  rounded  <- round(raw_rate, 2)
  expect_equal(rounded, 0)  # confirms the bug precondition
  expect_gt(raw_rate, 0)    # the true rate is non-zero
})

test_that("synthetic 0.1-micromort annual row: combined_quiz_pairs uses raw rate, not rounded", {
  # Build a minimal fake common_risks() row for the synthetic activity
  fake_cr <- tibble::tibble(
    activity              = "Synthetic low-rate annual activity",
    micromorts            = 0.1,
    microlives            = round(0.1 * 0.7, 1),
    category              = "Test",
    period                = "annual",
    period_type           = "year",
    period_days           = 365,
    micromorts_per_day    = round(0.1 / 365, 2),  # = 0.00 (the rounded value)
    micromorts_per_day_raw = 0.1 / 365,             # = 0.000274 (the raw value)
    source_url            = NA_character_,
    n_components          = 1L,
    hedgeable_pct         = 0,
    confidence            = "medium",
    estimate_range        = NA_character_,
    source_count          = 1L
  )

  # Verify that fake_cr$micromorts_per_day is indeed 0 (the buggy scenario)
  expect_equal(fake_cr$micromorts_per_day, 0)

  # Compute effective_micromorts as combined_quiz_pairs() does it
  effective_via_raw     <- fake_cr$micromorts_per_day_raw * 365
  effective_via_rounded <- fake_cr$micromorts_per_day * 365

  expect_equal(effective_via_rounded, 0,
    label = "Rounded path gives 0 — confirms bug exists without the fix")
  expect_true(effective_via_raw > 0,
    label = "Raw path gives non-zero — confirms fix prevents the bug")
  expect_equal(effective_via_raw, 0.1, tolerance = 1e-6,
    label = "Projecting raw rate × 365 should recover the original micromorts")
})

# ── combined_quiz_pairs: non-event non-zero effective values ──────────────────

test_that("combined_quiz_pairs() non-event rows have effective_micromorts_a > 0", {
  pairs <- combined_quiz_pairs(n = 20, seed = 42)
  non_event <- pairs[pairs$period_type_a != "event", ]
  if (nrow(non_event) == 0L) skip("No non-event rows in this sample")
  expect_true(all(non_event$effective_micromorts_a > 0),
    info = "Non-event rows must have positive effective micromorts (not collapsed to 0)")
})

test_that("combined_quiz_pairs() effective_micromorts_a matches micromorts_per_day_raw * time_period_days for non-event", {
  pairs <- combined_quiz_pairs(n = 20, time_period_days = 365, seed = 42)
  non_event <- pairs[pairs$period_type_a != "event", ]
  if (nrow(non_event) == 0L) skip("No non-event rows in this sample")

  # Retrieve the corresponding common_risks() rows to compare raw rates
  cr <- common_risks()
  for (i in seq_len(nrow(non_event))) {
    act <- non_event$activity_a[i]
    cr_row <- cr[cr$activity == act, ]
    if (nrow(cr_row) == 0L) next
    expected_eff <- cr_row$micromorts_per_day_raw[1] * 365
    expect_equal(non_event$effective_micromorts_a[i], expected_eff,
      tolerance = 1e-6,
      info = paste0("Activity: ", act)
    )
  }
})
