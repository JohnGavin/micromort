#' @name endpoints
#' @title Plumber API Endpoint Definitions
#' @description Functions to create and launch the Plumber API.

box::use(../data[load_acute_risks, load_chronic_risks, load_sources])
box::use(../models[compare_interventions, daily_hazard_rate])

#' Create Plumber API
#'
#' Creates a Plumber API object with all endpoints configured.
#'
#' @return A plumber::pr object
#' @export
create_api <- function() {
  api <- plumber::pr()

  # Metadata endpoint
  api$handle("GET", "/v1/meta", function() {
    list(
      version = "1.0.0",
      package_version = as.character(utils::packageVersion("micromort")),
      endpoints = c("/v1/acute", "/v1/chronic", "/v1/sources", "/v1/hazard"),
      documentation = "https://johngavin.github.io/micromort/"
    )
  })

  # Acute risks endpoint
  api$handle("GET", "/v1/acute", function(category = NULL, min_micromorts = 0) {
    data <- load_acute_risks()

    if (!is.null(category)) {
      data <- data[data$category == category, ]
    }

    data <- data[data$micromorts >= as.numeric(min_micromorts), ]
    as.list(data)
  })

  # Chronic risks endpoint
  api$handle("GET", "/v1/chronic", function(direction = NULL) {
    data <- load_chronic_risks()

    if (!is.null(direction)) {
      data <- data[data$direction == direction, ]
    }

    as.list(data)
  })

  # Sources endpoint
  api$handle("GET", "/v1/sources", function() {
    as.list(load_sources())
  })

  # Hazard rate endpoint
  api$handle("GET", "/v1/hazard", function(age = 30, sex = "male") {
    as.list(daily_hazard_rate(as.numeric(age), sex))
  })

  api
}

#' Launch Plumber API
#'
#' Starts the Plumber API server.
#'
#' @param host Host to bind to (default: "127.0.0.1")
#' @param port Port to listen on (default: 8080)
#' @return Invisible NULL
#' @export
launch_api <- function(host = "127.0.0.1", port = 8080) {
  api <- create_api()
  cli::cli_alert_info("Starting Micromort API at http://{host}:{port}")
  cli::cli_alert_info("Documentation: http://{host}:{port}/__docs__/")
  plumber::pr_run(api, host = host, port = port)
}
