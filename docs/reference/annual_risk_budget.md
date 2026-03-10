# Annual Risk Budget

Calculate total annual micromort exposure from a list of activities.

## Usage

``` r
annual_risk_budget(activities, age = NULL)
```

## Arguments

- activities:

  Named numeric vector of activity frequencies per year. Names should
  match activity names in
  [`load_acute_risks()`](https://johngavin.github.io/micromort/reference/load_acute_risks.md).

- age:

  Optional age for baseline risk calculation

## Value

A tibble with risk budget breakdown including:

- activity:

  Activity name

- frequency:

  Times per year

- micromorts_per:

  Micromorts per occurrence

- annual_micromorts:

  Total annual micromorts

- pct_of_total:

  Percentage of total risk budget

## See also

[`daily_hazard_rate()`](https://johngavin.github.io/micromort/reference/daily_hazard_rate.md),
[`load_acute_risks()`](https://johngavin.github.io/micromort/reference/load_acute_risks.md)

Other analysis:
[`compare_interventions()`](https://johngavin.github.io/micromort/reference/compare_interventions.md),
[`daily_hazard_rate()`](https://johngavin.github.io/micromort/reference/daily_hazard_rate.md),
[`lifestyle_tradeoff()`](https://johngavin.github.io/micromort/reference/lifestyle_tradeoff.md)

## Examples

``` r
# Calculate annual risk from recreational activities
annual_risk_budget(c(
  "Skydiving (US)" = 10,
  "Scuba diving, trained" = 20,
  "Running a marathon" = 2
), age = 35)
#> Warning: Activity not found: Skydiving (US)
#> Warning: Activity not found: Scuba diving, trained
#> # A tibble: 5 × 5
#>   activity              frequency micromorts_per annual_micromorts pct_of_total
#>   <chr>                     <dbl>          <dbl>             <dbl>        <dbl>
#> 1 Baseline (age 35)           365              3              1095         98.7
#> 2 Skydiving (US)               10             NA                NA         NA  
#> 3 Scuba diving, trained        20             NA                NA         NA  
#> 4 Running a marathon            2              7                14          1.3
#> 5 TOTAL                        NA             NA              1109        100  
```
