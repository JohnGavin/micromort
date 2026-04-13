# Daily Hazard Rate by Age

Calculates the daily probability of death based on age using a
simplified Gompertz-Makeham mortality model.

## Usage

``` r
daily_hazard_rate(age, sex = "male")
```

## Arguments

- age:

  Age in years

- sex:

  "male" or "female" (default: "male")

## Value

A tibble with:

- age:

  Input age

- sex:

  Input sex

- daily_prob:

  Daily probability of death

- micromorts:

  Daily baseline risk in micromorts

- microlives_consumed:

  Estimated microlives consumed per day

- interpretation:

  Human-readable summary

## References

Gompertz B (1825). "On the Nature of the Function Expressive of the Law
of Human Mortality." Philosophical Transactions of the Royal Society.

## See also

[`annual_risk_budget()`](https://johngavin.github.io/micromort/reference/annual_risk_budget.md),
[`compare_interventions()`](https://johngavin.github.io/micromort/reference/compare_interventions.md)

Other analysis:
[`annual_risk_budget()`](https://johngavin.github.io/micromort/reference/annual_risk_budget.md),
[`compare_interventions()`](https://johngavin.github.io/micromort/reference/compare_interventions.md),
[`lifestyle_tradeoff()`](https://johngavin.github.io/micromort/reference/lifestyle_tradeoff.md)

## Examples

``` r
# Baseline risk at age 30
daily_hazard_rate(30)
#> # A tibble: 1 × 7
#>     age sex   daily_prob micromorts microlives_consumed precision_note          
#>   <dbl> <chr>      <dbl>      <dbl>               <dbl> <chr>                   
#> 1    30 male  0.00000203          2                   0 Gompertz-Makeham approx…
#> # ℹ 1 more variable: interpretation <chr>

# Compare male vs female at age 65
daily_hazard_rate(65, "male")
#> # A tibble: 1 × 7
#>     age sex   daily_prob micromorts microlives_consumed precision_note          
#>   <dbl> <chr>      <dbl>      <dbl>               <dbl> <chr>                   
#> 1    65 male   0.0000346       34.6                 0.3 Gompertz-Makeham approx…
#> # ℹ 1 more variable: interpretation <chr>
daily_hazard_rate(65, "female")
#> # A tibble: 1 × 7
#>     age sex    daily_prob micromorts microlives_consumed precision_note         
#>   <dbl> <chr>       <dbl>      <dbl>               <dbl> <chr>                  
#> 1    65 female  0.0000151       15.1                 0.1 Gompertz-Makeham appro…
#> # ℹ 1 more variable: interpretation <chr>
```
