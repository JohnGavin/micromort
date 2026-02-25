# Load Acute Risks Dataset

Loads the acute risks parquet dataset from inst/extdata/.

## Usage

``` r
load_acute_risks()
```

## Value

A tibble with acute risk data

## Examples

``` r
acute <- load_acute_risks()
nrow(acute)
#> [1] 62
```
