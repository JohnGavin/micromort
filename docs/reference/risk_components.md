# View Risk Components for an Activity

Returns the atomic risk components for a specified activity, optionally
filtered by health profile. Useful for understanding what contributes to
a composite risk value.

## Usage

``` r
risk_components(activity_id, profile = list(), risks = NULL)
```

## Arguments

- activity_id:

  Character. The activity ID (e.g., `"flying_8h"`). Use
  `atomic_risks()$activity_id` to see available IDs.

- profile:

  A named list of condition variables, e.g.
  `list(health_profile = "dvt_risk_factors")`.

- risks:

  Optional pre-computed
  [`atomic_risks()`](https://johngavin.github.io/micromort/reference/atomic_risks.md)
  tibble.

## Value

A tibble of atomic components for the requested activity.

## See also

[`atomic_risks()`](https://johngavin.github.io/micromort/reference/atomic_risks.md),
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)

## Examples

``` r
risk_components("flying_8h")
#> # A tibble: 3 × 19
#>   component_id      activity_id activity component risk_category component_label
#>   <chr>             <chr>       <chr>    <chr>     <chr>         <chr>          
#> 1 flying_8h_8h_cra… flying_8h   Flying … crash     physical      Aircraft crash 
#> 2 flying_8h_8h_dvt… flying_8h   Flying … dvt       medical       Deep vein thro…
#> 3 flying_8h_8h_rad… flying_8h   Flying … radiation radiation     Cosmic radiati…
#> # ℹ 13 more variables: micromorts <dbl>, duration_hours <dbl>, category <chr>,
#> #   period <chr>, period_type <chr>, hedgeable <lgl>, hedge_description <chr>,
#> #   hedge_reduction_pct <dbl>, condition_variable <chr>, condition_value <chr>,
#> #   confidence <chr>, source_url <chr>, notes <chr>
risk_components("flying_8h", profile = list(health_profile = "dvt_risk_factors"))
#> # A tibble: 3 × 19
#>   component_id      activity_id activity component risk_category component_label
#>   <chr>             <chr>       <chr>    <chr>     <chr>         <chr>          
#> 1 flying_8h_8h_cra… flying_8h   Flying … crash     physical      Aircraft crash 
#> 2 flying_8h_8h_dvt… flying_8h   Flying … dvt       medical       Deep vein thro…
#> 3 flying_8h_8h_rad… flying_8h   Flying … radiation radiation     Cosmic radiati…
#> # ℹ 13 more variables: micromorts <dbl>, duration_hours <dbl>, category <chr>,
#> #   period <chr>, period_type <chr>, hedgeable <lgl>, hedge_description <chr>,
#> #   hedge_reduction_pct <dbl>, condition_variable <chr>, condition_value <chr>,
#> #   confidence <chr>, source_url <chr>, notes <chr>
```
