# Load Chronic Risks Dataset

Loads the chronic risks parquet dataset from inst/extdata/.

## Usage

``` r
load_chronic_risks()
```

## Value

A tibble with chronic risk data

## Examples

``` r
chronic <- load_chronic_risks()
nrow(chronic)
#> [1] 22
```
