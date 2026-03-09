#' Launch Micromort REST API
#'
#' Starts a Plumber API server exposing 27 endpoints for accessing micromort
#' and microlife risk datasets. Every response uses a standard JSON envelope
#' with `data` and `meta` fields including source provenance.
#'
#' @section Core Risks (8 GET):
#' \itemize{
#'   \item `GET /v1/risks/acute` — Enriched acute risks (common_risks)
#'   \item `GET /v1/risks/acute/atomic` — Atomic risk components
#'   \item `GET /v1/risks/chronic` — Chronic microlife gains/losses
#'   \item `GET /v1/risks/cancer` — Cancer risk by type/sex/age
#'   \item `GET /v1/risks/vaccination` — Vaccination risk reduction
#'   \item `GET /v1/risks/covid-vaccine` — COVID vaccine relative risks
#'   \item `GET /v1/risks/conditional` — Conditional risk given disease
#'   \item `GET /v1/risks/demographic` — Demographic risk factors
#' }
#'
#' @section Regional (4 GET):
#' \itemize{
#'   \item `GET /v1/regional/life-expectancy` — Regional life expectancy
#'   \item `GET /v1/regional/vanguard` — Best-performing regions
#'   \item `GET /v1/regional/laggard` — Worst-performing regions
#'   \item `GET /v1/regional/mortality-multiplier` — Mortality multiplier
#' }
#'
#' @section Radiation (2 GET):
#' \itemize{
#'   \item `GET /v1/radiation/profiles` — Exposure by career milestones
#'   \item `GET /v1/radiation/patient-comparison` — Patient vs occupational
#' }
#'
#' @section Analysis (2 GET + 4 POST):
#' \itemize{
#'   \item `GET /v1/analysis/equivalence` — Risk equivalence lookup
#'   \item `GET /v1/analysis/tradeoff` — Lifestyle tradeoff calculator
#'   \item `POST /v1/analysis/exchange-matrix` — Risk exchange matrix
#'   \item `POST /v1/analysis/interventions` — Compare interventions
#'   \item `POST /v1/analysis/budget` — Annual risk budget
#'   \item `POST /v1/analysis/hedged-portfolio` — Hedged risk portfolio
#' }
#'
#' @section Conversion (6 GET):
#' \itemize{
#'   \item `GET /v1/convert/to-micromort` — Probability to micromorts
#'   \item `GET /v1/convert/to-probability` — Micromorts to probability
#'   \item `GET /v1/convert/to-microlife` — Minutes to microlives
#'   \item `GET /v1/convert/value` — Monetary value of one micromort
#'   \item `GET /v1/convert/lle` — Loss of life expectancy
#'   \item `GET /v1/convert/hazard-rate` — Daily hazard rate by age
#' }
#'
#' @section Quiz (1 GET):
#' \itemize{
#'   \item `GET /v1/quiz/pairs` — Quiz pairs for comparison game
#' }
#'
#' @section Metadata (3 endpoints):
#' \itemize{
#'   \item `GET /v1/sources` — Risk data sources registry
#'   \item `GET /v1/meta` — API metadata and endpoint listing
#'   \item `GET /health` — Health check
#' }
#'
#' @param host Host to bind to (default: "127.0.0.1")
#' @param port Port to listen on (default: 8080)
#' @param docs Enable Swagger documentation (default: TRUE)
#' @return Invisible NULL. Runs the API server until interrupted.
#' @export
#' @examples
#' \dontrun{
#' launch_api()
#'
#' # Example requests (from another terminal):
#' # curl http://localhost:8080/v1/risks/acute?category=Sport
#' # curl http://localhost:8080/v1/risks/chronic?direction=gain
#' # curl http://localhost:8080/v1/convert/hazard-rate?age=35
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
