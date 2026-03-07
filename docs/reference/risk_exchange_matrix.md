# Risk Exchange Matrix

Creates a cross-comparison matrix showing how many of activity B equal
one of activity A, for a selected set of activities.

## Usage

``` r
risk_exchange_matrix(activities = NULL, risks = NULL)
```

## Arguments

- activities:

  Character vector of activity names to include. Defaults to a curated
  set of 10 diverse activities.

- risks:

  A tibble with at least `activity` and `micromorts` columns. Defaults
  to
  [`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md).

## Value

A tibble where rows are activities and columns are exchange rates. Cell
(i, j) = "how many of activity j equal one of activity i".

## See also

[`risk_equivalence()`](https://johngavin.github.io/micromort/reference/risk_equivalence.md)

## Examples

``` r
risk_exchange_matrix()
#> # A tibble: 10 × 11
#>    activity   General anesthesia (…¹ Skydiving (per jump,…² `Running a marathon`
#>    <chr>                       <dbl>                  <dbl>                <dbl>
#>  1 General a…                    1                      1.2                  1.4
#>  2 Skydiving…                    0.8                    1                    1.1
#>  3 Running a…                    0.7                    0.9                  1  
#>  4 Scuba div…                    0.5                    0.6                  0.7
#>  5 Driving (…                    0.1                    0.1                  0.1
#>  6 Skiing (p…                    0.1                    0.1                  0.1
#>  7 Flying (8…                    0.5                    0.6                  0.7
#>  8 Chest X-r…                    0                      0                    0  
#>  9 Cup of co…                    0                      0                    0  
#> 10 Crossing …                    0                      0                    0  
#> # ℹ abbreviated names: ¹​`General anesthesia (emergency)`,
#> #   ²​`Skydiving (per jump, US)`
#> # ℹ 7 more variables: `Scuba diving (per dive, trained)` <dbl>,
#> #   `Driving (230 miles)` <dbl>, `Skiing (per day)` <dbl>,
#> #   `Flying (8h long-haul)` <dbl>, `Chest X-ray (radiation)` <dbl>,
#> #   `Cup of coffee` <dbl>, `Crossing a road` <dbl>
```
