# Load Risk Sources Registry

Loads the risk sources parquet dataset from inst/extdata/.

## Usage

``` r
load_sources()
```

## Value

A tibble with source metadata

## Examples

``` r
sources <- load_sources()
nrow(sources)
#> [1] 14
```
