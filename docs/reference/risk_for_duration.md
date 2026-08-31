# Calculate Risk for Custom Duration

For duration-dependent activities, finds the nearest pre-computed
duration bucket across all variants of an activity family and returns
the aggregated risk.

## Usage

``` r
risk_for_duration(
  activity_prefix,
  duration_hours,
  profile = list(),
  risks = NULL
)
```

## Arguments

- activity_prefix:

  Character. Activity family prefix (e.g., `"flying"` matches
  `flying_2h`, `flying_5h`, `flying_8h`, `flying_12h`). Also accepts a
  full `activity_id`.

- duration_hours:

  Numeric. Desired duration in hours.

- profile:

  A named list of condition variables.

- risks:

  Optional pre-computed
  [`atomic_risks()`](https://johngavin.github.io/micromort/reference/atomic_risks.md)
  tibble.

## Value

A tibble with one row per component at the nearest duration bucket, plus
summary columns.

## See also

[`risk_components()`](https://johngavin.github.io/micromort/reference/risk_components.md),
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)

## Examples

``` r
risk_for_duration("flying", duration_hours = 7)
#> # A tibble: 1 × 6
#>   activity      activity_id hedgeable_pct micromorts n_components duration_hours
#>   <chr>         <chr>               <dbl>      <dbl>        <int>          <dbl>
#> 1 Flying (8h l… flying_8h            64.1        3.9            3              8
risk_for_duration("flying", duration_hours = 3)
#> # A tibble: 1 × 6
#>   activity      activity_id hedgeable_pct micromorts n_components duration_hours
#>   <chr>         <chr>               <dbl>      <dbl>        <int>          <dbl>
#> 1 Flying (2h s… flying_2h               0        1.1            3              2
```
