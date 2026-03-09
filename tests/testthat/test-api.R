# Tests for inst/plumber/api.R (27 endpoints)
# Strategy: source api.R to get named handler functions, call directly.
# Plumber decorators (#*) are comments, ignored by source().

# Source the API file to load helpers and handlers
api_env <- new.env(parent = globalenv())
source(
  system.file("plumber", "api.R", package = "micromort"),
  local = api_env
)

# Mock response object for handlers that set res$status
mock_res <- function() {
  env <- new.env(parent = emptyenv())
  env$status <- 200L
  env
}

# Mock request object for POST handlers
mock_req <- function(body = NULL) {

  env <- new.env(parent = emptyenv())
  env$body <- body
  env
}

# --- Helpers ------------------------------------------------------------------

test_that("api_response creates correct envelope", {
  result <- api_env$api_response(mtcars, "/test", list(x = 1))
  expect_named(result, c("data", "meta"))
  expect_named(result$meta, c("source", "endpoint", "n_rows", "timestamp",
    "params"))
  expect_equal(result$meta$endpoint, "/test")
  expect_equal(result$meta$n_rows, 32)
  expect_true(grepl("^micromort v", result$meta$source))
  expect_equal(result$meta$params, list(x = 1))
})

test_that("api_response handles list data", {
  result <- api_env$api_response(list(a = 1, b = 2), "/test")
  expect_equal(result$meta$n_rows, 2)
})

test_that("api_error sets status and returns error object", {
  res <- mock_res()
  result <- api_env$api_error(res, "bad request", 400L)
  expect_equal(res$status, 400L)
  expect_equal(result$error, "bad request")
  expect_equal(result$status, 400L)
})

test_that("parse_int_vec parses comma-separated integers", {
  expect_equal(api_env$parse_int_vec("1,2,3"), c(1L, 2L, 3L))
  expect_equal(api_env$parse_int_vec("10, 20, 40"), c(10L, 20L, 40L))
  expect_equal(api_env$parse_int_vec("5"), 5L)
})

# --- Group 1: Core Risks -----------------------------------------------------

test_that("handle_acute returns envelope with data", {
  res <- mock_res()
  result <- api_env$handle_acute(res)
  expect_named(result, c("data", "meta"))
  expect_true(is.data.frame(result$data))
  expect_equal(result$meta$endpoint, "/v1/risks/acute")
  expect_true(result$meta$n_rows > 0)
})

test_that("handle_acute filters by category", {
  res <- mock_res()
  full <- api_env$handle_acute(res, limit = 1000)
  filtered <- api_env$handle_acute(res, category = "Mountaineering",
    limit = 1000)
  expect_true(filtered$meta$n_rows < full$meta$n_rows)
  expect_true(all(filtered$data$category == "Mountaineering"))
})

test_that("handle_acute respects min_micromorts and limit", {
  res <- mock_res()
  result <- api_env$handle_acute(res, min_micromorts = 100, limit = 5)
  expect_true(all(result$data$micromorts >= 100))
  expect_true(nrow(result$data) <= 5)
})

test_that("handle_atomic returns envelope", {
  res <- mock_res()
  result <- api_env$handle_atomic(res)
  expect_named(result, c("data", "meta"))
  expect_equal(result$meta$endpoint, "/v1/risks/acute/atomic")
})

test_that("handle_chronic filters by direction", {
  res <- mock_res()
  result <- api_env$handle_chronic(res, direction = "gain")
  expect_true(all(result$data$direction == "gain"))
})

test_that("handle_cancer filters by sex", {
  res <- mock_res()
  result <- api_env$handle_cancer(res, sex = "Male")
  expect_true(all(result$data$sex == "Male"))
})

test_that("handle_vaccination returns envelope", {
  res <- mock_res()
  result <- api_env$handle_vaccination(res)
  expect_named(result, c("data", "meta"))
  expect_true(result$meta$n_rows > 0)
})

test_that("handle_covid_vaccine returns envelope", {
  res <- mock_res()
  result <- api_env$handle_covid_vaccine(res)
  expect_named(result, c("data", "meta"))
})

test_that("handle_conditional filters by disease", {
  res <- mock_res()
  result <- api_env$handle_conditional(res, disease = "cancer")
  expect_named(result, c("data", "meta"))
  expect_equal(result$meta$params$disease, "cancer")
})

test_that("handle_demographic returns envelope", {
  res <- mock_res()
  result <- api_env$handle_demographic(res)
  expect_named(result, c("data", "meta"))
  expect_equal(result$meta$endpoint, "/v1/risks/demographic")
})

# --- Group 2: Regional -------------------------------------------------------

test_that("handle_life_expectancy returns envelope", {
  res <- mock_res()
  result <- api_env$handle_life_expectancy(res)
  expect_named(result, c("data", "meta"))
  expect_true(result$meta$n_rows > 0)
})

test_that("handle_vanguard returns envelope", {
  res <- mock_res()
  result <- api_env$handle_vanguard(res)
  expect_named(result, c("data", "meta"))
})

test_that("handle_laggard returns envelope", {
  res <- mock_res()
  result <- api_env$handle_laggard(res)
  expect_named(result, c("data", "meta"))
})

test_that("handle_mortality_multiplier requires region_code", {
  res <- mock_res()
  result <- api_env$handle_mortality_multiplier(res)
  expect_equal(res$status, 400L)
  expect_true(grepl("region_code", result$error))
})

# --- Group 3: Radiation -------------------------------------------------------

test_that("handle_radiation_profiles parses comma-sep milestones", {
  res <- mock_res()
  result <- api_env$handle_radiation_profiles(res, milestones = "5,15")
  expect_named(result, c("data", "meta"))
  expect_equal(result$meta$params$milestones, c(5L, 15L))
})

test_that("handle_patient_comparison returns envelope", {
  res <- mock_res()
  result <- api_env$handle_patient_comparison(res)
  expect_named(result, c("data", "meta"))
  expect_true(result$meta$n_rows > 0)
})

# --- Group 4: Analysis -------------------------------------------------------

test_that("handle_equivalence requires reference", {
  res <- mock_res()
  result <- api_env$handle_equivalence(res)
  expect_equal(res$status, 400L)
  expect_true(grepl("reference", result$error))
})

test_that("handle_tradeoff requires both params", {
  res <- mock_res()
  result <- api_env$handle_tradeoff(res, bad_habit = "Smoking 20 cigarettes")
  expect_equal(res$status, 400L)
  expect_true(grepl("good_habit", result$error))
})

test_that("handle_exchange_matrix works with NULL activities (defaults)", {
  res <- mock_res()
  req <- mock_req()
  result <- api_env$handle_exchange_matrix(req, res)
  expect_named(result, c("data", "meta"))
  expect_equal(result$meta$endpoint, "/v1/analysis/exchange-matrix")
})

test_that("handle_interventions requires body", {
  res <- mock_res()
  req <- mock_req()
  result <- api_env$handle_interventions(req, res)
  expect_equal(res$status, 400L)
  expect_true(grepl("interventions", result$error))
})

test_that("handle_budget requires activities", {
  res <- mock_res()
  req <- mock_req()
  result <- api_env$handle_budget(req, res)
  expect_equal(res$status, 400L)
  expect_true(grepl("activities", result$error))
})

test_that("handle_hedged_portfolio returns list data", {
  res <- mock_res()
  req <- mock_req()
  result <- api_env$handle_hedged_portfolio(req, res)
  expect_named(result, c("data", "meta"))
  expect_equal(result$meta$endpoint, "/v1/analysis/hedged-portfolio")
  expect_true(result$meta$n_rows > 0)
})

# --- Group 5: Conversion -----------------------------------------------------

test_that("handle_to_micromort requires prob", {
  res <- mock_res()
  result <- api_env$handle_to_micromort(res)
  expect_equal(res$status, 400L)
})

test_that("handle_to_micromort converts correctly", {
  res <- mock_res()
  result <- api_env$handle_to_micromort(res, prob = "0.000001")
  expect_equal(result$data$micromorts, 1)
})

test_that("handle_to_probability requires micromorts", {
  res <- mock_res()
  result <- api_env$handle_to_probability(res)
  expect_equal(res$status, 400L)
})

test_that("handle_to_microlife requires minutes", {
  res <- mock_res()
  result <- api_env$handle_to_microlife(res)
  expect_equal(res$status, 400L)
})

test_that("handle_value uses default vsl", {
  res <- mock_res()
  result <- api_env$handle_value(res)
  expect_named(result, c("data", "meta"))
  expect_true(result$data$value_per_micromort > 0)
})

test_that("handle_lle strips S3 class", {
  res <- mock_res()
  result <- api_env$handle_lle(res, prob = "0.001")
  expect_type(result$data$lle_minutes, "double")
  expect_true(result$data$lle_minutes > 0)
})

test_that("handle_hazard_rate requires age", {
  res <- mock_res()
  result <- api_env$handle_hazard_rate(res)
  expect_equal(res$status, 400L)
  expect_true(grepl("age", result$error))
})

test_that("handle_hazard_rate returns envelope", {
  res <- mock_res()
  result <- api_env$handle_hazard_rate(res, age = "35")
  expect_named(result, c("data", "meta"))
  expect_true(is.data.frame(result$data))
})

# --- Group 6: Quiz ------------------------------------------------------------

test_that("handle_quiz_pairs returns envelope", {
  res <- mock_res()
  result <- api_env$handle_quiz_pairs(res, seed = "42")
  expect_named(result, c("data", "meta"))
  expect_equal(result$meta$endpoint, "/v1/quiz/pairs")
  expect_equal(result$meta$params$seed, 42L)
})

# --- Group 7: Metadata -------------------------------------------------------

test_that("handle_sources filters by type", {
  res <- mock_res()
  full <- api_env$handle_sources(res)
  filtered <- api_env$handle_sources(res, type = "Academic")
  expect_true(filtered$meta$n_rows <= full$meta$n_rows)
  if (filtered$meta$n_rows > 0) {
    expect_true(all(filtered$data$type == "Academic"))
  }
})

test_that("handle_meta lists all endpoint groups", {
  res <- mock_res()
  result <- api_env$handle_meta(res)
  expect_true("endpoints" %in% names(result))
  eps <- result$endpoints
  expect_named(eps, c("risks", "regional", "radiation", "analysis",
    "convert", "quiz", "metadata"))
  # 30 total endpoints (8+4+2+6+6+1+3)
  total <- sum(vapply(eps, length, integer(1)))
  expect_equal(total, 30)
})

test_that("handle_health returns status", {
  result <- api_env$handle_health()
  expect_equal(result$status, "healthy")
  expect_true("r_version" %in% names(result))
})
