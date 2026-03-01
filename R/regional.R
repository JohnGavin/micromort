# Suppress NSE notes from R CMD check
utils::globalVariables(c(
  "country_code", "year", "sex", "classification", "life_expectancy",
  "region_code", "region_name", "microlives_vs_eu_avg", "source_url"
))

#' Regional Life Expectancy in Western Europe
#'
#' Life expectancy at birth by NUTS2 region for Western European countries,
#' based on Eurostat data and the methodology from Bonnet et al. (2026).
#'
#' @param country Character vector. Filter to specific countries using ISO 2-letter
#'   codes (e.g., "FR", "DE", "ES"). Default `NULL` returns all countries.
#' @param year Integer or vector. Filter to specific years. Default `NULL` returns
#'   all years (1992-2023).
#' @param sex Character. Filter by sex: "Male", "Female", or "Total". Default `NULL`
#'   returns all.
#' @param classification Character. Filter by region classification: "vanguard",
#'   "average", or "laggard". Default `NULL` returns all.
#'
#' @return A tibble with columns:
#' \describe{
#'   \item{region_code}{NUTS2 region code (e.g., "FR10" for Île-de-France)}
#'   \item{region_name}{Human-readable region name}
#'   \item{country_code}{ISO 2-letter country code}
#'   \item{year}{Data year (1992-2023)}
#'   \item{sex}{Sex category: "Male", "Female", or "Total"}
#'   \item{life_expectancy}{Life expectancy at birth in years}
#'   \item{microlives_vs_eu_avg}{Daily microlives difference vs EU average}
#'   \item{classification}{"vanguard", "average", or "laggard" based on 2019 trends}
#'   \item{source_url}{DOI link to source publication}
#' }
#'
#' @details
#' ## Data Source
#'
#' Primary data from Eurostat dataset `demo_r_mlifexp`. Regional classifications
#' based on Bonnet et al. (2026) methodology identifying:
#'
#' - **Vanguard regions**: Top 20% life expectancy with sustained gains (≥1.5 months/year)
#' - **Laggard regions**: Bottom 20% life expectancy or stagnant gains (<0.5 months/year)
#' - **Average regions**: All others
#'
#' ## Microlives Interpretation
#'
#' The `microlives_vs_eu_avg` column converts life expectancy differences to

#' daily microlives using the approximation: 1 year LE difference ≈ 1.2 microlives/day
#' (assuming 40 years remaining life expectancy).
#'
#' Example: A region with +2 years above EU average = +2.4 microlives/day,
#' equivalent to the benefit of 20 minutes daily exercise.
#'
#' ## Ecological Fallacy Warning
#'
#' **IMPORTANT:** Regional life expectancy reflects population averages, NOT
#' individual-level causation. High life expectancy in "vanguard" regions results
#' from multiple factors including:
#'
#' - Healthcare system quality and access
#' - Socioeconomic composition (income, education)
#' - Selection effects (healthy/wealthy people moving to certain regions
#' - Historical and cultural factors
#'
#' Moving to a high-LE region does NOT guarantee increased personal longevity.
#'
#' @references
#' Bonnet F, et al. (2026). "Potential and challenges for sustainable progress
#' in human longevity." Nature Communications 17, 996.
#' \doi{10.1038/s41467-026-68828-z}
#'
#' Eurostat (2024). Life expectancy by age, sex and NUTS 2 region (demo_r_mlifexp).
#' \url{https://ec.europa.eu/eurostat/databrowser/product/view/demo_r_mlifexp}
#'
#' @family regional
#' @seealso [demographic_factors()], [chronic_risks()]
#' @export
#' @examples
#' # All data
#' regional_life_expectancy()
#'
#' # French regions in 2019
#' regional_life_expectancy(country = "FR", year = 2019)
#'
#' # Compare vanguard vs laggard regions
#' regional_life_expectancy(year = 2019, sex = "Total") |>
#'   dplyr::group_by(classification) |>
#'   dplyr::summarise(mean_le = mean(life_expectancy))
#'
#' # Top 10 regions by life expectancy (2019, Total)
#' regional_life_expectancy(year = 2019, sex = "Total") |>
#'   dplyr::slice_max(life_expectancy, n = 10)
#'
#' # Microlives advantage of Catalonia vs EU average
#' regional_life_expectancy(country = "ES", year = 2019, sex = "Total") |>
#'   dplyr::filter(grepl("Catalonia", region_name))
regional_life_expectancy <- function(country = NULL,
                                     year = NULL,
                                     sex = NULL,
                                     classification = NULL) {

  # Load parquet data
  parquet_path <- system.file(
    "extdata", "regional_life_expectancy.parquet",
    package = "micromort"
  )

  if (parquet_path == "") {
    cli::cli_abort(c(
      "x" = "Regional life expectancy data not found.",
      "i" = "Run {.file data-raw/02_regional_life_expectancy.R} to download data."
    ))
  }

  data <- arrow::read_parquet(parquet_path)

  # Apply filters
  if (!is.null(country)) {
    data <- data |> dplyr::filter(country_code %in% country)
  }

  if (!is.null(year)) {
    data <- data |> dplyr::filter(year %in% !!year)
  }

  if (!is.null(sex)) {
    data <- data |> dplyr::filter(sex %in% !!sex)
  }

  if (!is.null(classification)) {
    data <- data |> dplyr::filter(classification %in% !!classification)
  }

  data
}


#' Vanguard Regions with Highest Life Expectancy
#'
#' Convenience function returning regions classified as "vanguard" - those with
#' the highest life expectancy and sustained improvement trends.
#'
#' @inheritParams regional_life_expectancy
#' @return A tibble filtered to vanguard regions only.
#' @family regional
#' @seealso [regional_life_expectancy()], [laggard_regions()]
#' @export
#' @examples
#' # Vanguard regions in 2019
#' vanguard_regions(year = 2019, sex = "Total")
vanguard_regions <- function(country = NULL, year = NULL, sex = NULL) {
  regional_life_expectancy(
    country = country,
    year = year,
    sex = sex,
    classification = "vanguard"
  )
}


#' Laggard Regions with Stalled Life Expectancy Gains
#'
#' Convenience function returning regions classified as "laggard" - those with
#' lower life expectancy or stagnant improvement trends since 2005.
#'
#' @inheritParams regional_life_expectancy
#' @return A tibble filtered to laggard regions only.
#' @family regional
#' @seealso [regional_life_expectancy()], [vanguard_regions()]
#' @export
#' @examples
#' # Laggard regions in 2019
#' laggard_regions(year = 2019, sex = "Total")
laggard_regions <- function(country = NULL, year = NULL, sex = NULL) {
  regional_life_expectancy(
    country = country,
    year = year,
    sex = sex,
    classification = "laggard"
  )
}


#' Regional Mortality Multiplier
#'
#' Calculate a mortality risk multiplier for a region relative to the national
#' or EU average. Useful for adjusting baseline micromort estimates by location.
#'
#' @param region_code Character. NUTS2 region code (e.g., "FR10").
#' @param reference Character. Compare against "national" average or "eu" average.
#'   Default is "eu".
#' @param year Integer. Reference year. Default is 2019 (pre-COVID).
#'
#' @return A tibble with the region's mortality multiplier and interpretation.
#'
#' @details
#' The mortality multiplier is derived from life expectancy differences using
#' the approximation that each year of life expectancy difference corresponds
#' to approximately 2.5% difference in annual mortality risk.
#'
#' A multiplier of 1.0 means average risk; 0.9 means 10% lower risk; 1.1 means
#' 10% higher risk.
#'
#' @family regional
#' @seealso [regional_life_expectancy()], [demographic_factors()]
#' @export
#' @examples
#' # Catalonia vs EU average
#' regional_mortality_multiplier("ES51")
#'
#' # Compare to national average
#' regional_mortality_multiplier("ES51", reference = "national")
regional_mortality_multiplier <- function(region_code,
                                          reference = "eu",
                                          year = 2019) {

  checkmate::assert_string(region_code)
  checkmate::assert_choice(reference, c("eu", "national"))
  checkmate::assert_integerish(year, len = 1)

  # Get region data
  region_data <- regional_life_expectancy(year = year, sex = "Total") |>
    dplyr::filter(region_code == !!region_code)

  if (nrow(region_data) == 0) {
    cli::cli_abort("Region code {.val {region_code}} not found for year {year}.")
  }

  # Calculate reference LE
  if (reference == "eu") {
    ref_le <- regional_life_expectancy(year = year, sex = "Total") |>
      dplyr::summarise(ref_le = mean(life_expectancy, na.rm = TRUE)) |>
      dplyr::pull(ref_le)
    ref_name <- "EU average"
  } else {
    country <- substr(region_code, 1, 2)
    ref_le <- regional_life_expectancy(country = country, year = year, sex = "Total") |>
      dplyr::summarise(ref_le = mean(life_expectancy, na.rm = TRUE)) |>
      dplyr::pull(ref_le)
    ref_name <- paste(country, "average")
  }

  # Calculate multiplier
  # Each year LE difference ≈ 2.5% mortality difference
  le_diff <- region_data$life_expectancy - ref_le
  multiplier <- round(1 - (le_diff * 0.025), 3)

  tibble::tibble(
    region_code = region_code,
    region_name = region_data$region_name,
    life_expectancy = region_data$life_expectancy,
    reference = ref_name,
    reference_le = round(ref_le, 2),
    le_difference = round(le_diff, 2),
    mortality_multiplier = multiplier,
    interpretation = dplyr::case_when(
      multiplier < 0.95 ~ "Lower than average mortality risk",
      multiplier > 1.05 ~ "Higher than average mortality risk",
      TRUE ~ "Near average mortality risk"
    )
  )
}
