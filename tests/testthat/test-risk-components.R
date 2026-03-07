# ── risk_components() tests ───────────────────────────────────────────────────

test_that("risk_components returns correct components for flying", {
  rc <- risk_components("flying_8h")
  expect_true("crash" %in% rc$component)
  expect_true("dvt" %in% rc$component)
  expect_true("radiation" %in% rc$component)
  expect_equal(nrow(rc), 3)
})

test_that("risk_components sums to approximately common_risks total", {
  rc <- risk_components("flying_8h")
  cr <- common_risks()
  fly8 <- cr[cr$activity == "Flying (8h long-haul)", ]
  expect_equal(sum(rc$micromorts), fly8$micromorts, tolerance = 0.01)
})

test_that("DVT is negligible for <4h flights", {
  rc <- risk_components("flying_2h")
  dvt_row <- rc[rc$component == "dvt", ]
  expect_equal(dvt_row$micromorts, 0)
})

test_that("health profile changes DVT component", {
  rc_healthy <- risk_components("flying_8h")
  rc_risk <- risk_components("flying_8h",
                             profile = list(health_profile = "dvt_risk_factors"))

  dvt_healthy <- rc_healthy$micromorts[rc_healthy$component == "dvt"]
  dvt_risk <- rc_risk$micromorts[rc_risk$component == "dvt"]

  expect_true(dvt_risk > dvt_healthy)
  expect_equal(dvt_healthy, 2.5)
  expect_equal(dvt_risk, 8.0)
})

test_that("unknown activity_id raises error", {
  expect_error(
    risk_components("nonexistent_activity"),
    "Unknown activity_id"
  )
})

test_that("risk_components works for single-component activities", {
  rc <- risk_components("mt_everest_ascent")
  expect_equal(nrow(rc), 1)
  expect_equal(rc$component, "all_causes")
  expect_equal(rc$micromorts, 37932)
})

test_that("risk_components for medical radiation is atomic", {
  rc <- risk_components("chest_x_ray_radiation")
  expect_equal(nrow(rc), 1)
  expect_equal(rc$component, "radiation")
  expect_equal(rc$risk_category, "radiation")
  expect_equal(rc$micromorts, 0.1)
})


# ── risk_for_duration() tests ────────────────────────────────────────────────

test_that("risk_for_duration returns nearest bucket across all durations", {
  rd <- risk_for_duration("flying", duration_hours = 7)
  # Nearest to 7h is 8h bucket (|8-7|=1 < |5-7|=2)
  expect_equal(rd$duration_hours, 8)
})

test_that("risk_for_duration selects 2h bucket for short duration", {
  rd <- risk_for_duration("flying", duration_hours = 1)
  expect_equal(rd$duration_hours, 2)
})

test_that("risk_for_duration selects 12h bucket for long duration", {
  rd <- risk_for_duration("flying", duration_hours = 15)
  expect_equal(rd$duration_hours, 12)
})

test_that("risk_for_duration errors for non-duration activities", {
  expect_error(
    risk_for_duration("mt_everest", duration_hours = 5),
    "not duration-dependent"
  )
})

test_that("risk_for_duration errors for unknown prefix", {
  expect_error(
    risk_for_duration("nonexistent", duration_hours = 5),
    "No activities match"
  )
})


# ── plot_risk_components() tests ─────────────────────────────────────────────

test_that("plot_risk_components returns ggplot", {
  p <- plot_risk_components(c("flying_2h", "flying_8h"))
  expect_s3_class(p, "ggplot")
})

test_that("plot_risk_components errors for unknown activity", {
  expect_error(
    plot_risk_components("nonexistent"),
    "Unknown activity_ids"
  )
})
