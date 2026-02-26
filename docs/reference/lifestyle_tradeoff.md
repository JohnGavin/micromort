# Calculate Lifestyle Tradeoff

Calculate how much of one good habit compensates for a bad habit.

## Usage

``` r
lifestyle_tradeoff(bad_habit, good_habit)
```

## Arguments

- bad_habit:

  Factor name of the bad habit (from
  [`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md))

- good_habit:

  Factor name of the compensating behavior (from
  [`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md))

## Value

A tibble showing the tradeoff ratio

## See also

[`compare_interventions()`](https://johngavin.github.io/micromort/reference/compare_interventions.md),
[`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md)

Other analysis:
[`annual_risk_budget()`](https://johngavin.github.io/micromort/reference/annual_risk_budget.md),
[`compare_interventions()`](https://johngavin.github.io/micromort/reference/compare_interventions.md),
[`daily_hazard_rate()`](https://johngavin.github.io/micromort/reference/daily_hazard_rate.md)

## Examples

``` r
# How much exercise offsets 2 cigarettes?
lifestyle_tradeoff("Smoking 2 cigarettes", "20 min moderate exercise")
#> # A tibble: 1 × 6
#>   bad_habit            bad_ml_per_day good_habit    good_ml_per_day units_needed
#>   <chr>                         <dbl> <chr>                   <dbl>        <dbl>
#> 1 Smoking 2 cigarettes             -1 20 min moder…               2          0.5
#> # ℹ 1 more variable: interpretation <chr>
```
