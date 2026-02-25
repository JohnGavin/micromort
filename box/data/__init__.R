#' @name box/data
#' @title Data Loading and Schema Validation Module
#' @description Provides functions to load parquet datasets and validate schemas.

box::use(
  ./loaders[load_acute_risks, load_chronic_risks, load_sources],
  ./schemas[validate_acute_schema, validate_chronic_schema, validate_sources_schema],
  ./parsers[parse_acute_csv, parse_chronic_csv, merge_acute_risks, merge_chronic_risks]
)

#' @export
box::export(
  # Loaders
  load_acute_risks,
  load_chronic_risks,
  load_sources,
  # Validators
  validate_acute_schema,
  validate_chronic_schema,
  validate_sources_schema,
  # Parsers
  parse_acute_csv,
  parse_chronic_csv,
  merge_acute_risks,
  merge_chronic_risks
)
