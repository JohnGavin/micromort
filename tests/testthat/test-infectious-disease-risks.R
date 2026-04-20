# Tests for infectious_disease_risks()

# ── Schema ──────────────────────────────────────────────────────────────────

test_that("infectious_disease_risks() returns correct column names", {
  result <- infectious_disease_risks("GBR")
  expect_named(
    result,
    c("cause", "country", "iso3", "year", "deaths_per_100k",
      "daily_micromorts", "annual_micromorts")
  )
})

test_that("infectious_disease_risks() returns correct column types", {
  result <- infectious_disease_risks("GBR")
  expect_type(result$cause, "character")
  expect_type(result$country, "character")
  expect_type(result$iso3, "character")
  expect_type(result$year, "integer")
  expect_type(result$deaths_per_100k, "double")
  expect_type(result$daily_micromorts, "double")
  expect_type(result$annual_micromorts, "double")
})

# ── Default behaviour ────────────────────────────────────────────────────────

test_that("infectious_disease_risks() defaults to GBR", {
  result_default <- infectious_disease_risks()
  result_gbr     <- infectious_disease_risks("GBR")
  expect_equal(result_default, result_gbr)
})

test_that("infectious_disease_risks() returns 7 causes for a single country", {
  result <- infectious_disease_risks("GBR")
  expect_equal(nrow(result), 7L)
})

test_that("infectious_disease_risks() iso3 column matches requested country", {
  result <- infectious_disease_risks("USA")
  expect_true(all(result$iso3 == "USA"))
})

# ── Multi-country ────────────────────────────────────────────────────────────

test_that("infectious_disease_risks() returns 21 rows for 3 countries", {
  result <- infectious_disease_risks(c("GBR", "USA", "IND"))
  expect_equal(nrow(result), 21L)
  expect_setequal(result$iso3, c("GBR", "USA", "IND"))
})

test_that("infectious_disease_risks('all') returns all countries in dataset", {
  result <- infectious_disease_risks("all")
  expect_gt(nrow(result), 100L)
  expect_true("GBR" %in% result$iso3)
  expect_true("USA" %in% result$iso3)
  expect_true("NGA" %in% result$iso3)
})

# ── Conversion formula ────────────────────────────────────────────────────────

test_that("daily_micromorts = deaths_per_100k / 365 * 10", {
  result <- infectious_disease_risks("GBR")
  expected <- round(result$deaths_per_100k / 365 * 10, 4)
  expect_equal(result$daily_micromorts, expected)
})

test_that("annual_micromorts = deaths_per_100k * 10", {
  result <- infectious_disease_risks("GBR")
  expected <- round(result$deaths_per_100k * 10, 1)
  expect_equal(result$annual_micromorts, expected)
})

test_that("daily_micromorts values are non-negative", {
  result <- infectious_disease_risks("all")
  expect_true(all(result$daily_micromorts >= 0))
})

test_that("daily_micromorts values are < 100 (sanity bound)", {
  result <- infectious_disease_risks("all")
  expect_true(all(result$daily_micromorts < 100))
})

# ── Year filtering ────────────────────────────────────────────────────────────

test_that("year argument filters to that year", {
  result <- infectious_disease_risks("GBR", year = 2019L)
  expect_true(all(result$year == 2019L))
})

test_that("invalid year raises informative error", {
  expect_snapshot(
    error = TRUE,
    infectious_disease_risks("GBR", year = 1900L)
  )
})

# ── Bad country argument ────────────────────────────────────────────────────

test_that("unknown ISO-3 raises informative error", {
  expect_snapshot(
    error = TRUE,
    infectious_disease_risks("XYZ")
  )
})

test_that("ISO-3 matching is case-insensitive", {
  result_upper <- infectious_disease_risks("GBR")
  result_lower <- infectious_disease_risks("gbr")
  expect_equal(result_upper, result_lower)
})

# ── High-burden countries show higher rates ───────────────────────────────────

test_that("Nigeria malaria rate exceeds UK malaria rate", {
  uk  <- infectious_disease_risks("GBR") |>
    dplyr::filter(.data$cause == "Malaria")
  nga <- infectious_disease_risks("NGA") |>
    dplyr::filter(.data$cause == "Malaria")
  expect_gt(nga$deaths_per_100k, uk$deaths_per_100k)
})

test_that("South Africa HIV/AIDS rate exceeds UK HIV/AIDS rate", {
  uk  <- infectious_disease_risks("GBR") |>
    dplyr::filter(.data$cause == "HIV/AIDS")
  zaf <- infectious_disease_risks("ZAF") |>
    dplyr::filter(.data$cause == "HIV/AIDS")
  expect_gt(zaf$deaths_per_100k, uk$deaths_per_100k)
})

# ── Snapshot: GBR column names and structure ──────────────────────────────────

test_that("infectious_disease_risks() GBR structure snapshot", {
  result <- infectious_disease_risks("GBR")
  expect_snapshot(names(result))
  expect_snapshot(nrow(result))
})
