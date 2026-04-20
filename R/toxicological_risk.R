# Suppress R CMD check notes for NSE column references
utils::globalVariables(c(
  "ld50_value", "ld50_unit", "ld50_mg_per_kg", "fraction_of_ld50"
))

#' Calculate micromorts from substance exposure using LD50 data
#'
#' Uses human LD50 estimates from `inst/extdata/ld50_human.csv` to translate a
#' dose into a micromort risk estimate via linear extrapolation from the
#' LD50 reference point. At the LD50, 50% lethality equals 500,000 micromorts.
#'
#' @param substance Character scalar. Name of substance (case-insensitive,
#'   partial match supported). Pass `NULL` (default) to return the full
#'   reference table of all substances with their LD50 values.
#' @param dose_mg Numeric scalar. Dose in milligrams. Required when `substance`
#'   is specified; ignored otherwise.
#' @param body_weight_kg Numeric scalar. Body weight in kg. Default `70`.
#' @return A tibble. When `substance = NULL`, returns all substances with
#'   columns `substance`, `route`, `ld50_mg_per_kg`, `source`. When a
#'   substance is specified, returns a single-row tibble with additional
#'   columns: `dose_mg`, `fraction_of_ld50`, `micromorts`, `risk_category`.
#' @family analysis
#' @seealso [common_risks()], [risk_sensitivity()]
#' @export
#' @examples
#' # Full reference table
#' toxicological_risk()
#'
#' # Risk from 1 mg nicotine for a 70 kg person
#' toxicological_risk("Nicotine", dose_mg = 1)
#'
#' # Partial name matching
#' toxicological_risk("nico", dose_mg = 1)
#'
#' # Different body weight
#' toxicological_risk("Caffeine", dose_mg = 200, body_weight_kg = 80)
toxicological_risk <- function(substance = NULL,
                               dose_mg = NULL,
                               body_weight_kg = 70) {
  checkmate::assert_number(body_weight_kg, lower = 1, finite = TRUE)

  ld50_path <- system.file("extdata", "ld50_human.csv", package = "micromort")
  if (!nzchar(ld50_path)) {
    cli::cli_abort(c(
      "Cannot locate {.file inst/extdata/ld50_human.csv} in the {.pkg micromort} package.",
      "i" = "Re-install the package or run {.code devtools::load_all()}."
    ))
  }

  ld50_data <- readr::read_csv(
    ld50_path,
    col_types = readr::cols(
      substance  = readr::col_character(),
      route      = readr::col_character(),
      ld50_value = readr::col_double(),
      ld50_unit  = readr::col_character(),
      source     = readr::col_character()
    ),
    show_col_types = FALSE
  ) |>
    dplyr::mutate(ld50_mg_per_kg = .data$ld50_value / 1000) |>
    dplyr::select("substance", "route", "ld50_mg_per_kg", "source")

  # Reference table mode
  if (is.null(substance)) {
    return(ld50_data)
  }

  # Substance lookup mode
  checkmate::assert_character(substance, len = 1, any.missing = FALSE)
  if (!is.null(dose_mg)) {
    checkmate::assert_number(dose_mg, lower = 0, finite = TRUE)
  }

  matches <- ld50_data |>
    dplyr::filter(grepl(.env$substance, .data$substance, ignore.case = TRUE))

  if (nrow(matches) == 0L) {
    cli::cli_abort(c(
      "No substance matching {.val {substance}} found in LD50 reference data.",
      "i" = "Use {.fn toxicological_risk} with no arguments to see all substances."
    ))
  }

  if (is.null(dose_mg)) {
    cli::cli_abort(c(
      "{.arg dose_mg} is required when {.arg substance} is specified.",
      "i" = "Supply a dose in milligrams, e.g. {.code dose_mg = 1}."
    ))
  }

  matches |>
    dplyr::mutate(
      dose_mg        = dose_mg,
      fraction_of_ld50 = dose_mg / (.data$ld50_mg_per_kg * body_weight_kg),
      micromorts     = .data$fraction_of_ld50 * 500000,
      risk_category  = dplyr::case_when(
        .data$micromorts <     1 ~ "negligible",
        .data$micromorts <    10 ~ "low",
        .data$micromorts <   100 ~ "moderate",
        .data$micromorts <  1000 ~ "high",
        .default                 = "extreme"
      )
    )
}
