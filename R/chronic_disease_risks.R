#' Chronic Disease Risks by Country and Year
#'
#' Returns daily micromorts from chronic diseases for one or more countries,
#' using a bundled snapshot of IHME Global Burden of Disease data sourced via
#' Our World in Data.
#'
#' The bundled CSV (`inst/extdata/owid_chronic_deaths.csv`) covers seven
#' chronic cause categories across ~20 countries. To refresh the snapshot from
#' the live OWID catalog, run `data-raw/owid_chronic_deaths.R`.
#'
#' ## Conversion formula
#'
#' `daily_micromorts = (deaths_per_100k / 365) * 10`
#'
#' Because: annual deaths per 100,000 → divide by 100,000 for annual
#' probability → divide by 365 for daily probability → multiply by 1,000,000
#' for micromorts. The 100,000 and 1,000,000 cancel to a factor of 10:
#' `rate / 100,000 / 365 × 1,000,000 = rate / 365 × 10`.
#'
#' @param country Character vector of ISO-3 country codes (e.g. `"GBR"`,
#'   `c("GBR", "USA")`). Default is `"GBR"`. Use `"all"` to return every
#'   country in the bundled dataset.
#' @param year Integer or `NULL`. If `NULL` (default), the most recent
#'   available year is returned. If a specific year is supplied, only rows
#'   matching that year are returned; an error is raised if the year is absent.
#' @return A [tibble::tibble()] with columns:
#'   \describe{
#'     \item{cause}{Disease cause label (character)}
#'     \item{country}{Country name (character)}
#'     \item{iso3}{ISO-3 country code (character)}
#'     \item{year}{Data year (integer)}
#'     \item{deaths_per_100k}{Age-standardised deaths per 100,000 per year (double)}
#'     \item{daily_micromorts}{Daily micromort risk (double)}
#'     \item{annual_micromorts}{Annual micromort risk (double)}
#'   }
#' @export
#' @references
#' Institute for Health Metrics and Evaluation (IHME). Global Burden of
#' Disease Study 2019. Seattle, WA: IHME, 2020.
#' \url{https://www.healthdata.org/research-analysis/gbd}
#'
#' Our World in Data. Cause of Death.
#' \url{https://ourworldindata.org/causes-of-death}
#' @seealso [chronic_risks()] for microlife-based chronic lifestyle factors.
#' @examples
#' # Default: UK, latest year
#' chronic_disease_risks()
#'
#' # Specific country
#' chronic_disease_risks("USA")
#'
#' # Multiple countries
#' chronic_disease_risks(c("GBR", "USA", "JPN"))
#'
#' # All countries in bundled dataset
#' chronic_disease_risks("all")
#'
#' # Filter by cause after calling
#' chronic_disease_risks("GBR") |>
#'   dplyr::filter(cause == "Cardiovascular diseases")
chronic_disease_risks <- function(country = "GBR", year = NULL) {
  checkmate::assert_character(country, min.len = 1L, any.missing = FALSE)
  checkmate::assert_integerish(year, len = 1L, null.ok = TRUE, any.missing = FALSE)

  csv_path <- system.file(
    "extdata", "owid_chronic_deaths.csv",
    package = "micromort",
    mustWork = TRUE
  )

  raw <- readr::read_csv(
    csv_path,
    col_types = readr::cols(
      country         = readr::col_character(),
      iso3            = readr::col_character(),
      cause           = readr::col_character(),
      year            = readr::col_integer(),
      deaths_per_100k = readr::col_double()
    ),
    show_col_types = FALSE
  )

  # Validate year argument against available data
  available_years <- sort(unique(raw$year))
  if (!is.null(year)) {
    if (!year %in% available_years) {
      cli::cli_abort(c(
        "x" = "Year {.val {year}} not found in the bundled dataset.",
        "i" = "Available years: {.val {available_years}}."
      ))
    }
    raw <- dplyr::filter(raw, .data$year == .env$year)
  } else {
    # Use the most recent year per country-cause combination
    raw <- raw |>
      dplyr::group_by(.data$iso3, .data$cause) |>
      dplyr::filter(.data$year == max(.data$year)) |>
      dplyr::ungroup()
  }

  # Filter by country
  if (!identical(country, "all")) {
    country_upper <- toupper(country)
    available_iso3 <- sort(unique(raw$iso3))
    missing_iso3 <- setdiff(country_upper, available_iso3)
    if (length(missing_iso3) > 0L) {
      cli::cli_abort(c(
        "x" = "ISO-3 code{?s} not found in the bundled dataset: {.val {missing_iso3}}.",
        "i" = "Available codes: {.val {available_iso3}}.",
        "i" = "Use {.code country = \"all\"} to return all available countries."
      ))
    }
    raw <- dplyr::filter(raw, .data$iso3 %in% country_upper)
  }

  raw |>
    dplyr::mutate(
      # daily_micromorts = (deaths_per_100k / 365) * 10
      daily_micromorts  = round(.data$deaths_per_100k / 365 * 10, 4),
      annual_micromorts = round(.data$deaths_per_100k * 10, 1)
    ) |>
    dplyr::select(
      "cause", "country", "iso3", "year",
      "deaths_per_100k", "daily_micromorts", "annual_micromorts"
    ) |>
    dplyr::arrange(.data$country, .data$cause)
}
