#' Acute Risks Dataset
#'
#' A curated dataset of acute mortality risks measured in micromorts.
#' One micromort equals a one-in-a-million chance of death.
#'
#' Data is compiled from multiple sources including Wikipedia, micromorts.rip,
#' and CDC MMWR reports. Multiple estimates for the same activity may exist
#' from different sources.
#'
#' @format A tibble with 62 rows and 15 columns:
#' \describe{
#'   \item{record_id}{Unique record identifier (source_id + sequence)}
#'   \item{activity}{Human-readable activity name}
#'   \item{activity_normalized}{Standardized activity name for grouping}
#'   \item{micromorts}{Risk in micromorts (1 = one-in-a-million death risk)}
#'   \item{microlives}{Equivalent in microlives (micromorts × 0.7)}
#'   \item{category}{Activity category (Sport, Travel, Medical, etc.)}
#'   \item{period}{Time period for risk (per event, per day, per year)}
#'   \item{period_normalized}{Standardized period (event, day, week, month, year)}
#'   \item{age_group}{Applicable age group (all, 18-49, 65+, etc.)}
#'   \item{geography}{Geographic scope (global, US, UK, etc.)}
#'   \item{year}{Year of data collection}
#'   \item{source_id}{Source identifier (foreign key to risk_sources)}
#'   \item{source_url}{Direct URL to source}
#'   \item{confidence}{Data quality level (high, medium, low)}
#'   \item{last_accessed}{Date data was retrieved}
#' }
#' @source
#' - Wikipedia: \url{https://en.wikipedia.org/wiki/Micromort}
#' - micromorts.rip: \url{https://micromorts.rip/}
#' - CDC MMWR: \url{https://www.cdc.gov/mmwr/}
#' @references
#' Howard RA (1980). "On Making Life and Death Decisions."
#' In Schwing & Albers (eds), Societal Risk Assessment.
#' @examples
#' # Load the acute risks dataset
#' acute <- load_acute_risks()
#' head(acute)
#'
#' # Filter by category
#' acute |> dplyr::filter(category == "Sport")
#'
#' # Top 10 riskiest activities
#' acute |> dplyr::slice_max(micromorts, n = 10)
#' @name acute_risks
#' @family datasets
NULL

#' Chronic Risks Dataset
#'
#' A curated dataset of chronic lifestyle factors measured in microlives.
#' One microlife equals 30 minutes of life expectancy gained or lost.
#'
#' Positive values indicate life expectancy gains; negative values indicate losses.
#' Based on the framework introduced by David Spiegelhalter (2012).
#'
#' @format A tibble with 22 rows and 12 columns:
#' \describe{
#'   \item{record_id}{Unique record identifier}
#'   \item{factor}{Human-readable factor name}
#'   \item{factor_normalized}{Standardized factor name for grouping}
#'   \item{microlives_per_day}{Daily impact in microlives (+/- 30 min units)}
#'   \item{direction}{Effect direction: "gain" or "loss"}
#'   \item{category}{Factor category (Diet, Exercise, Smoking, etc.)}
#'   \item{description}{Detailed description of the factor}
#'   \item{annual_effect_days}{Days of life gained/lost per year}
#'   \item{source_id}{Source identifier}
#'   \item{source_url}{Direct URL to source}
#'   \item{confidence}{Data quality level}
#'   \item{last_accessed}{Date data was retrieved}
#' }
#' @source
#' Spiegelhalter D (2012). "Using speed of ageing and 'microlives' to
#' communicate the effects of lifetime habits and environment."
#' BMJ 2012;345:e8223. \doi{10.1136/bmj.e8223}
#' @references
#' \url{https://en.wikipedia.org/wiki/Microlife}
#' @examples
#' # Load the chronic risks dataset
#' chronic <- load_chronic_risks()
#' head(chronic)
#'
#' # Factors that reduce life expectancy
#' chronic |> dplyr::filter(direction == "loss")
#'
#' # Factors that increase life expectancy
#' chronic |> dplyr::filter(direction == "gain")
#' @name chronic_risks
#' @family datasets
NULL

#' Risk Sources Registry
#'
#' A registry of data sources used to compile the risk datasets.
#' Each source has a unique identifier that links to records in
#' [acute_risks] and [chronic_risks].
#'
#' @format A tibble with 14 rows and 7 columns:
#' \describe{
#'   \item{source_id}{Unique source identifier (e.g., "spiegelhalter_2012")}
#'   \item{citation}{Full citation or source name}
#'   \item{primary_url}{Primary URL}
#'   \item{type}{Source type: academic, government, database, book, encyclopedia}
#'   \item{description}{Brief description}
#'   \item{data_types}{Types of data: acute, chronic, or both}
#'   \item{last_accessed}{Date data was retrieved}
#' }
#' @examples
#' # Load the source registry
#' sources <- load_sources()
#' sources
#'
#' # Academic sources
#' sources |> dplyr::filter(type == "Academic")
#' @name risk_sources
#' @family datasets
NULL

#' Load Acute Risks Dataset
#'
#' Loads the acute risks parquet dataset from inst/extdata/.
#'
#' @return A tibble with acute risk data
#' @export
#' @examples
#' acute <- load_acute_risks()
#' nrow(acute)
load_acute_risks <- function() {
  path <- system.file("extdata", "acute_risks.parquet", package = "micromort")
  if (path == "") {
    path <- "inst/extdata/acute_risks.parquet"
  }

  if (!file.exists(path)) {
    cli::cli_abort(c(
      "x" = "Acute risks parquet file not found",
      "i" = "Run tar_make() to generate the dataset"
    ))
  }

  arrow::read_parquet(path)
}

#' Load Chronic Risks Dataset
#'
#' Loads the chronic risks parquet dataset from inst/extdata/.
#'
#' @return A tibble with chronic risk data
#' @export
#' @examples
#' chronic <- load_chronic_risks()
#' nrow(chronic)
load_chronic_risks <- function() {
  path <- system.file("extdata", "chronic_risks.parquet", package = "micromort")
  if (path == "") {
    path <- "inst/extdata/chronic_risks.parquet"
  }

  if (!file.exists(path)) {
    cli::cli_abort(c(
      "x" = "Chronic risks parquet file not found",
      "i" = "Run tar_make() to generate the dataset"
    ))
  }

  arrow::read_parquet(path)
}

#' Load Risk Sources Registry
#'
#' Loads the risk sources parquet dataset from inst/extdata/.
#'
#' @return A tibble with source metadata
#' @export
#' @examples
#' sources <- load_sources()
#' nrow(sources)
load_sources <- function() {
  path <- system.file("extdata", "risk_sources.parquet", package = "micromort")
  if (path == "") {
    path <- "inst/extdata/risk_sources.parquet"
  }

  if (!file.exists(path)) {
    cli::cli_abort(c(
      "x" = "Risk sources parquet file not found",
      "i" = "Run tar_make() to generate the dataset"
    ))
  }

  arrow::read_parquet(path)
}
