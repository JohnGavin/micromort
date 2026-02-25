#' Launch Micromort REST API
#'
#' Starts a Plumber API server for accessing micromort datasets.
#'
#' The API provides endpoints for:
#' \itemize{
#'   \item GET /v1/acute - Acute risks dataset
#'   \item GET /v1/chronic - Chronic risks dataset
#'   \item GET /v1/sources - Risk sources registry
#'   \item GET /v1/hazard - Daily hazard rate by age
#'   \item GET /v1/categories - Unique categories
#'   \item GET /v1/meta - API metadata
#'   \item GET /health - Health check
#' }
#'
#' @param host Host to bind to (default: "127.0.0.1")
#' @param port Port to listen on (default: 8080)
#' @param docs Enable Swagger documentation (default: TRUE)
#' @return Invisible NULL. Runs the API server until interrupted.
#' @export
#' @examples
#' \dontrun{
#' # Start the API server
#' launch_api()
#'
#' # Then in another session or browser:
#' # curl http://localhost:8080/v1/acute
#' # curl http://localhost:8080/v1/chronic?direction=gain
#' # curl http://localhost:8080/v1/hazard?age=35
#' }
launch_api <- function(host = "127.0.0.1", port = 8080, docs = TRUE) {
  if (!requireNamespace("plumber", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "Package 'plumber' is required to run the API",
      "i" = "Install with: install.packages('plumber')"
    ))
  }

  api_path <- system.file("plumber", "api.R", package = "micromort")
  if (api_path == "") {
    api_path <- "inst/plumber/api.R"
  }

  if (!file.exists(api_path)) {
    cli::cli_abort("API file not found at {api_path}")
  }

  cli::cli_h1("Micromort Data API")
  cli::cli_alert_info("Starting server at http://{host}:{port}")

  if (docs) {
    cli::cli_alert_info("Swagger docs: http://{host}:{port}/__docs__/")
  }

  cli::cli_alert_info("Press Ctrl+C to stop")

  pr <- plumber::plumb(api_path)
  plumber::pr_run(pr, host = host, port = port, docs = docs)
}
