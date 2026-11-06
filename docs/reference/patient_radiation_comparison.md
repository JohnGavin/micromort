# Patient vs Occupational Radiation Comparison

Cross-tabulates patient X-ray exposure against occupational career
radiation to reveal equivalences. Both sides are converted to micromorts
with the same dose-to-risk factor, so `ratio` equals the ratio of the
two cumulative doses in mSv. Values come from
[`atomic_risks()`](https://johngavin.github.io/micromort/reference/atomic_risks.md);
none are hand-typed here.

## Usage

``` r
patient_radiation_comparison(
  xray_counts = c(1, 10, 100),
  career_years = c(10, 20, 40)
)
```

## Arguments

- xray_counts:

  Integer vector of patient X-ray counts to compare. Default
  `c(1, 10, 100)`.

- career_years:

  Integer vector of occupational career durations. Default
  `c(10, 20, 40)`.

## Value

A tibble with columns: occupation, xray_count, career_years,
patient_micromorts, occupational_micromorts, ratio.

## See also

[`radiation_profiles()`](https://johngavin.github.io/micromort/reference/radiation_profiles.md),
[`atomic_risks()`](https://johngavin.github.io/micromort/reference/atomic_risks.md)

## Examples

``` r
patient_radiation_comparison()
#> # A tibble: 45 × 6
#>    occupation  xray_count career_years patient_micromorts occupational_micromo…¹
#>    <chr>            <dbl>        <dbl>              <dbl>                  <dbl>
#>  1 Airline pi…          1           10                  1                   2450
#>  2 X-ray tech…          1           10                  1                    500
#>  3 Dental rad…          1           10                  1                    100
#>  4 Nuclear pl…          1           10                  1                   1000
#>  5 Interventi…          1           10                  1                   1750
#>  6 Airline pi…         10           10                 10                   2450
#>  7 X-ray tech…         10           10                 10                    500
#>  8 Dental rad…         10           10                 10                    100
#>  9 Nuclear pl…         10           10                 10                   1000
#> 10 Interventi…         10           10                 10                   1750
#> # ℹ 35 more rows
#> # ℹ abbreviated name: ¹​occupational_micromorts
#> # ℹ 1 more variable: ratio <dbl>
patient_radiation_comparison(xray_counts = c(50, 200), career_years = c(5, 30))
#> # A tibble: 20 × 6
#>    occupation  xray_count career_years patient_micromorts occupational_micromo…¹
#>    <chr>            <dbl>        <dbl>              <dbl>                  <dbl>
#>  1 Airline pi…         50            5                 50                   1225
#>  2 X-ray tech…         50            5                 50                    250
#>  3 Dental rad…         50            5                 50                     50
#>  4 Nuclear pl…         50            5                 50                    500
#>  5 Interventi…         50            5                 50                    875
#>  6 Airline pi…        200            5                200                   1225
#>  7 X-ray tech…        200            5                200                    250
#>  8 Dental rad…        200            5                200                     50
#>  9 Nuclear pl…        200            5                200                    500
#> 10 Interventi…        200            5                200                    875
#> 11 Airline pi…         50           30                 50                   7350
#> 12 X-ray tech…         50           30                 50                   1500
#> 13 Dental rad…         50           30                 50                    300
#> 14 Nuclear pl…         50           30                 50                   3000
#> 15 Interventi…         50           30                 50                   5250
#> 16 Airline pi…        200           30                200                   7350
#> 17 X-ray tech…        200           30                200                   1500
#> 18 Dental rad…        200           30                200                    300
#> 19 Nuclear pl…        200           30                200                   3000
#> 20 Interventi…        200           30                200                   5250
#> # ℹ abbreviated name: ¹​occupational_micromorts
#> # ℹ 1 more variable: ratio <dbl>
```
