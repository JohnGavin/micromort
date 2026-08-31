# Daily Hazard Rate by Age

Calculates the daily probability of death based on age using a
simplified Gompertz-Makeham mortality model. Returns a central estimate
plus credible bounds derived from ±10% sensitivity on the Gompertz
parameters `a` (background mortality) and `b` (initial mortality).

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

  Daily probability of death (central estimate)

- micromorts:

  Daily baseline risk in micromorts (central estimate)

- micromorts_lower:

  Lower credible bound (micromorts) from ±10% parameter sensitivity

- micromorts_upper:

  Upper credible bound (micromorts) from ±10% parameter sensitivity

- microlives_consumed:

  Estimated microlives consumed per day

- precision_note:

  Reminder that Gompertz parameters are approximate

- interpretation:

  Human-readable summary

## Details

The Gompertz hazard is `h(x) = a + b * exp(c * x)`. Bounds are computed
by varying `a` and `b` independently by ±10% (four combinations) and
taking the min/max across those combinations.

## References

Gompertz B (1825). "On the Nature of the Function Expressive of the Law
of Human Mortality." Philosophical Transactions of the Royal Society.

## See also

[`annual_risk_budget()`](https://johngavin.github.io/micromort/reference/annual_risk_budget.md),
[`compare_interventions()`](https://johngavin.github.io/micromort/reference/compare_interventions.md)

Other analysis:
[`annual_risk_budget()`](https://johngavin.github.io/micromort/reference/annual_risk_budget.md),
[`compare_interventions()`](https://johngavin.github.io/micromort/reference/compare_interventions.md),
[`lifestyle_tradeoff()`](https://johngavin.github.io/micromort/reference/lifestyle_tradeoff.md),
[`risk_sensitivity()`](https://johngavin.github.io/micromort/reference/risk_sensitivity.md),
[`toxicological_risk()`](https://johngavin.github.io/micromort/reference/toxicological_risk.md)

## Examples

``` r
# Baseline risk at age 30 with credible bounds
daily_hazard_rate(30)
#> # A tibble: 1 × 9
#>     age sex   daily_prob micromorts micromorts_lower micromorts_upper
#>   <dbl> <chr>      <dbl>      <dbl>            <dbl>            <dbl>
#> 1    30 male  0.00000203          2              1.8              2.2
#> # ℹ 3 more variables: microlives_consumed <dbl>, precision_note <chr>,
#> #   interpretation <chr>

# Compare male vs female at age 65
daily_hazard_rate(65, "male")
#> # A tibble: 1 × 9
#>     age sex   daily_prob micromorts micromorts_lower micromorts_upper
#>   <dbl> <chr>      <dbl>      <dbl>            <dbl>            <dbl>
#> 1    65 male   0.0000346       34.6             31.2             38.1
#> # ℹ 3 more variables: microlives_consumed <dbl>, precision_note <chr>,
#> #   interpretation <chr>
daily_hazard_rate(65, "female")
#> # A tibble: 1 × 9
#>     age sex    daily_prob micromorts micromorts_lower micromorts_upper
#>   <dbl> <chr>       <dbl>      <dbl>            <dbl>            <dbl>
#> 1    65 female  0.0000151       15.1             13.6             16.6
#> # ℹ 3 more variables: microlives_consumed <dbl>, precision_note <chr>,
#> #   interpretation <chr>
```
