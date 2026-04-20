# Tests for chronic_disease_risks()

# ── Schema ──────────────────────────────────────────────────────────────────

test_that("chronic_disease_risks() returns correct column names", {
  result <- chronic_disease_risks("GBR")
  expect_named(
    result,
    c("cause", "country", "iso3", "year", "deaths_per_100k",
      "daily_micromorts", "annual_micromorts")
  )
})

test_that("chronic_disease_risks() returns correct column types", {
  result <- chronic_disease_risks("GBR")
  expect_type(result$cause, "character")
  expect_type(result$country, "character")
  expect_type(result$iso3, "character")
  expect_type(result$year, "integer")
  expect_type(result$deaths_per_100k, "double")
  expect_type(result$daily_micromorts, "double")
  expect_type(result$annual_micromorts, "double")
})

# ── Default behaviour ────────────────────────────────────────────────────────

test_that("chronic_disease_risks() defaults to GBR", {
  result_default <- chronic_disease_risks()
  result_gbr     <- chronic_disease_risks("GBR")
  expect_equal(result_default, result_gbr)
})

test_that("chronic_disease_risks() returns 7 causes for a single country", {
  result <- chronic_disease_risks("GBR")
  expect_equal(nrow(result), 7L)
})

test_that("chronic_disease_risks() iso3 column matches requested country", {
  result <- chronic_disease_risks("USA")
  expect_true(all(result$iso3 == "USA"))
})

# ── Multi-country ────────────────────────────────────────────────────────────

test_that("chronic_disease_risks() returns 21 rows for 3 countries", {
  result <- chronic_disease_risks(c("GBR", "USA", "JPN"))
  expect_equal(nrow(result), 21L)
  expect_setequal(result$iso3, c("GBR", "USA", "JPN"))
})

test_that("chronic_disease_risks('all') returns all countries in dataset", {
  result <- chronic_disease_risks("all")
  expect_gt(nrow(result), 100L)
  expect_true("GBR" %in% result$iso3)
  expect_true("USA" %in% result$iso3)
  expect_true("JPN" %in% result$iso3)
})

# ── Conversion formula ────────────────────────────────────────────────────────

test_that("daily_micromorts = deaths_per_100k / 365 * 10", {
  result <- chronic_disease_risks("GBR")
  expected <- round(result$deaths_per_100k / 365 * 10, 4)
  expect_equal(result$daily_micromorts, expected)
})

test_that("annual_micromorts = deaths_per_100k * 10", {
  result <- chronic_disease_risks("GBR")
  expected <- round(result$deaths_per_100k * 10, 1)
  expect_equal(result$annual_micromorts, expected)
})

test_that("daily_micromorts values are positive", {
  result <- chronic_disease_risks("all")
  expect_true(all(result$daily_micromorts > 0))
})

test_that("daily_micromorts values are < 100 (sanity bound)", {
  result <- chronic_disease_risks("all")
  expect_true(all(result$daily_micromorts < 100))
})

# ── Year filtering ────────────────────────────────────────────────────────────

test_that("year argument filters to that year", {
  result <- chronic_disease_risks("GBR", year = 2019L)
  expect_true(all(result$year == 2019L))
})

test_that("invalid year raises informative error", {
  expect_snapshot(
    error = TRUE,
    chronic_disease_risks("GBR", year = 1900L)
  )
})

# ── Bad country argument ────────────────────────────────────────────────────

test_that("unknown ISO-3 raises informative error", {
  expect_snapshot(
    error = TRUE,
    chronic_disease_risks("XYZ")
  )
})

test_that("ISO-3 matching is case-insensitive", {
  result_upper <- chronic_disease_risks("GBR")
  result_lower <- chronic_disease_risks("gbr")
  expect_equal(result_upper, result_lower)
})

# ── Snapshot: GBR column names and structure ──────────────────────────────────

test_that("chronic_disease_risks() GBR structure snapshot", {
  result <- chronic_disease_risks("GBR")
  expect_snapshot(names(result))
  expect_snapshot(nrow(result))
})
