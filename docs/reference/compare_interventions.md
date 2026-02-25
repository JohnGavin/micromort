# Compare Lifestyle Interventions

Compare the impact of multiple lifestyle changes in microlives. Uses the
chronic risks dataset to calculate daily, annual, and lifetime effects
of interventions.

## Usage

``` r
compare_interventions(interventions)
```

## Arguments

- interventions:

  Named list of interventions. Each element should have:

  factor

  :   Name of the chronic risk factor (must match chronic_risks)

  change

  :   Numeric change multiplier (e.g., -1 to remove the factor)

## Value

A tibble comparing effects of each intervention:

- intervention:

  Name of the intervention

- factor:

  Original factor name

- original_ml_per_day:

  Original microlives per day

- change:

  Change multiplier applied

- net_ml_per_day:

  Net microlives gained/lost per day

- annual_days:

  Days of life gained/lost per year

- lifetime_years:

  Years of life gained/lost over 57 years

## Examples

``` r
# Compare quitting smoking vs losing weight
compare_interventions(list(
  "Quit 10 cigarettes/day" = list(factor = "Smoking 10 cigarettes", change = -1),
  "Lose 5kg" = list(factor = "Being 5 kg overweight", change = -1)
))
#> # A tibble: 2 × 7
#>   intervention      factor original_ml_per_day change net_ml_per_day annual_days
#>   <chr>             <chr>                <dbl>  <dbl>          <dbl>       <dbl>
#> 1 Quit 10 cigarett… Smoki…                  -5     -1             -5       -38  
#> 2 Lose 5kg          Being…                  -1     -1             -1        -7.6
#> # ℹ 1 more variable: lifetime_years <dbl>
```
