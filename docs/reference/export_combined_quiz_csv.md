# Export combined quiz pairs to CSV for Shinylive

Generates a representative set of combined quiz pairs and writes them to
`inst/extdata/combined_quiz_pairs.csv`. The Shinylive combined quiz can
read this CSV directly without requiring R computation in the browser.

## Usage

``` r
export_combined_quiz_csv(
  n = 50L,
  time_period_days = 365,
  seed = 42L,
  path = NULL
)
```

## Arguments

- n:

  Integer. Number of pairs to export. Default `50`.

- time_period_days:

  Numeric. Time period for chronic risk accumulation. Default `365` (1
  year).

- seed:

  Integer. Random seed for reproducibility. Default `42`.

- path:

  Character. Output file path. Default writes to
  `inst/extdata/combined_quiz_pairs.csv` under the package root.

## Value

Path to the written CSV (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
export_combined_quiz_csv()
} # }
```
