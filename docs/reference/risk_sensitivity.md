# Sensitivity Analysis for Activity Risk Estimates

Computes how activity micromort rankings shift when the base estimate is
varied by ±`pct`%. Useful for communicating uncertainty around point
estimates derived from sparse epidemiological data.

## Usage

``` r
risk_sensitivity(activity = NULL, pct = 20)
```

## Arguments

- activity:

  Character scalar — activity name matching a row in
  [`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md).
  Pass `NULL` (default) to return sensitivity for all activities.

- pct:

  Numeric scalar — percentage variation applied symmetrically around the
  base estimate. Default `20` (i.e., ±20%). Must be in (0, 100).

## Value

A tibble with columns:

- activity:

  Activity name

- micromorts_base:

  Base micromort estimate from
  [`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)

- micromorts_low:

  Low estimate: `base * (1 - pct/100)`

- micromorts_high:

  High estimate: `base * (1 + pct/100)`

- rank_base:

  Rank of the activity at the base estimate (1 = highest risk)

- rank_change:

  Absolute rank positions shifted between low and high estimates

## Details

Activities are sourced from
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md).
The `rank_change` column reports the absolute number of ranking
positions an activity moves between its low and high estimate when all
activities are re-ranked.

## See also

[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md),
[`daily_hazard_rate()`](https://johngavin.github.io/micromort/reference/daily_hazard_rate.md)

Other analysis:
[`annual_risk_budget()`](https://johngavin.github.io/micromort/reference/annual_risk_budget.md),
[`compare_interventions()`](https://johngavin.github.io/micromort/reference/compare_interventions.md),
[`daily_hazard_rate()`](https://johngavin.github.io/micromort/reference/daily_hazard_rate.md),
[`lifestyle_tradeoff()`](https://johngavin.github.io/micromort/reference/lifestyle_tradeoff.md),
[`toxicological_risk()`](https://johngavin.github.io/micromort/reference/toxicological_risk.md)

## Examples

``` r
# Sensitivity for a single activity
risk_sensitivity("Skydiving (US)")
#> # A tibble: 1 × 6
#>   activity  micromorts_base micromorts_low micromorts_high rank_base rank_change
#>   <chr>               <dbl>          <dbl>           <dbl>     <int>       <int>
#> 1 Skydivin…               8            6.4             9.6        32           9

# Sensitivity for all activities at ±10%
risk_sensitivity(pct = 10)
#> # A tibble: 107 × 6
#>    activity micromorts_base micromorts_low micromorts_high rank_base rank_change
#>    <chr>              <dbl>          <dbl>           <dbl>     <int>       <int>
#>  1 Mt. Eve…           37932         34139.          41725.         1           0
#>  2 Himalay…           12000         10800           13200          2           0
#>  3 COVID-1…           10000          9000           11000          3           0
#>  4 Spanish…            3000          2700            3300          4           1
#>  5 Matterh…            2840          2556            3124          5           1
#>  6 Living …             500           450             550          6           1
#>  7 Living …             463           417.            509.         7           3
#>  8 Base ju…             430           387             473          8           2
#>  9 First d…             430           387             473          8           2
#> 10 COVID-1…             234           211.            257.        10           0
#> # ℹ 97 more rows

# Activities with the largest rank uncertainty
risk_sensitivity() |> dplyr::arrange(dplyr::desc(rank_change))
#> # A tibble: 107 × 6
#>    activity micromorts_base micromorts_low micromorts_high rank_base rank_change
#>    <chr>              <dbl>          <dbl>           <dbl>     <int>       <int>
#>  1 COVID-1…               1            0.8             1.2        60          15
#>  2 Living …               1            0.8             1.2        60          15
#>  3 Walking…               1            0.8             1.2        60          15
#>  4 Driving…               1            0.8             1.2        60          15
#>  5 Train (…               1            0.8             1.2        60          15
#>  6 Eating …               1            0.8             1.2        60          15
#>  7 1 hour …               1            0.8             1.2        60          15
#>  8 Eating …               1            0.8             1.2        60          15
#>  9 Eating …               1            0.8             1.2        60          15
#> 10 Living …               1            0.8             1.2        60          15
#> # ℹ 97 more rows
```
