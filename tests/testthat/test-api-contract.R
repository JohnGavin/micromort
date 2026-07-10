# Layer-2 contract tests for inst/plumber/api.R
#
# test-api.R (Layer-1) sources the file and calls handler functions
# directly, in-process. This file (Layer-2) boots the *actual* Plumber
# process in the background and exercises it over real HTTP, catching
# issues Layer-1 cannot see: routing, serialization, param parsing from
# a real query string / JSON body, and the HTTP status code plumber
# actually sends back.
#
# Offline-safe: binds only to 127.0.0.1, no external network calls.

testthat::skip_on_cran()
testthat::skip_if_not_installed("callr")
testthat::skip_if_not_installed("httr2")
testthat::skip_if_not_installed("plumber")

# --- Helpers ------------------------------------------------------------------

#' Pick a free local port for the background API process
pick_port <- function() {
  if (requireNamespace("httpuv", quietly = TRUE) &&
      "randomPort" %in% getNamespaceExports("httpuv")) {
    return(httpuv::randomPort())
  }
  sample(19000:19999, 1)
}

#' Boot the Plumber API from inst/plumber/api.R in a background R process
start_api <- function(port) {
  pkg_root <- testthat::test_path("..", "..")
  api_path <- system.file("plumber", "api.R", package = "micromort")
  if (!nzchar(api_path)) {
    api_path <- file.path(pkg_root, "inst", "plumber", "api.R")
  }
  testthat::skip_if_not(file.exists(api_path), "api.R not found")

  callr::r_bg(
    function(pkg_root, api_path, port) {
      # api.R calls library(micromort); when the package is only
      # dev-loaded (not installed, e.g. under devtools::test()), load it
      # in this fresh background process so that call succeeds.
      if (!requireNamespace("micromort", quietly = TRUE)) {
        pkgload::load_all(pkg_root, quiet = TRUE)
      }
      pr <- plumber::plumb(api_path)
      plumber::pr_run(pr, host = "127.0.0.1", port = port)
    },
    args = list(pkg_root = pkg_root, api_path = api_path, port = port),
    supervise = TRUE
  )
}

#' Poll /health until the API responds or the timeout elapses
wait_for_api <- function(base_url, process, timeout_s = 10) {
  deadline <- Sys.time() + timeout_s
  repeat {
    if (!process$is_alive()) {
      testthat::fail(paste(
        "API process exited during startup. stderr:",
        paste(process$read_error_lines(), collapse = "\n")
      ))
      return(invisible(FALSE))
    }
    ready <- tryCatch({
      resp <- httr2::request(base_url) |>
        httr2::req_url_path("/health") |>
        httr2::req_timeout(1) |>
        httr2::req_perform()
      identical(httr2::resp_status(resp), 200L)
    }, error = function(e) FALSE)
    if (isTRUE(ready)) {
      return(invisible(TRUE))
    }
    if (Sys.time() > deadline) {
      testthat::fail("API did not become ready within timeout")
      return(invisible(FALSE))
    }
    Sys.sleep(0.2)
  }
}

# --- Contract test --------------------------------------------------------

test_that("plumber API boots and serves GET/POST/error contracts over HTTP", {
  port <- pick_port()
  base_url <- paste0("http://127.0.0.1:", port)
  proc <- start_api(port)
  on.exit(
    {
      if (proc$is_alive()) proc$kill()
    },
    add = TRUE
  )

  wait_for_api(base_url, proc)

  # --- GET /health --------------------------------------------------------
  resp <- httr2::request(base_url) |>
    httr2::req_url_path("/health") |>
    httr2::req_perform()
  expect_equal(httr2::resp_status(resp), 200L)
  health <- httr2::resp_body_json(resp, simplifyVector = TRUE)
  expect_equal(health$status, "healthy")

  # --- GET data endpoint: envelope shape + query params --------------------
  resp <- httr2::request(base_url) |>
    httr2::req_url_path("/v1/risks/acute") |>
    httr2::req_url_query(limit = 5) |>
    httr2::req_perform()
  expect_equal(httr2::resp_status(resp), 200L)
  acute <- httr2::resp_body_json(resp, simplifyVector = TRUE)
  expect_true(all(c("data", "meta") %in% names(acute)))
  expect_true(NROW(acute$data) <= 5)
  expect_equal(acute$meta$endpoint, "/v1/risks/acute")

  # --- POST endpoint with JSON body ----------------------------------------
  resp <- httr2::request(base_url) |>
    httr2::req_url_path("/v1/analysis/exchange-matrix") |>
    httr2::req_body_json(list()) |>
    httr2::req_perform()
  expect_equal(httr2::resp_status(resp), 200L)
  matrix_body <- httr2::resp_body_json(resp, simplifyVector = TRUE)
  expect_true(all(c("data", "meta") %in% names(matrix_body)))
  expect_equal(matrix_body$meta$endpoint, "/v1/analysis/exchange-matrix")

  # --- 400 error path: missing required param ------------------------------
  resp <- httr2::request(base_url) |>
    httr2::req_url_path("/v1/regional/mortality-multiplier") |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()
  expect_equal(httr2::resp_status(resp), 400L)
  err_body <- httr2::resp_body_json(resp, simplifyVector = TRUE)
  expect_true(grepl("region_code", err_body$error))
})
