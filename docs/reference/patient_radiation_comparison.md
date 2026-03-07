# Patient vs Occupational Radiation Comparison

Cross-tabulates patient X-ray exposure against occupational career
radiation to reveal surprising equivalences. For example, 100 lifetime
chest X-rays (10 micromorts) exceeds a 40-year X-ray technician career
(2 micromorts).

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
#>  1 Airline pi…          1           10                0.1                   1.5 
#>  2 X-ray tech…          1           10                0.1                   0.5 
#>  3 Dental rad…          1           10                0.1                   0.1 
#>  4 Nuclear pl…          1           10                0.1                   1   
#>  5 Interventi…          1           10                0.1                   1.75
#>  6 Airline pi…         10           10                1                     1.5 
#>  7 X-ray tech…         10           10                1                     0.5 
#>  8 Dental rad…         10           10                1                     0.1 
#>  9 Nuclear pl…         10           10                1                     1   
#> 10 Interventi…         10           10                1                     1.75
#> # ℹ 35 more rows
#> # ℹ abbreviated name: ¹​occupational_micromorts
#> # ℹ 1 more variable: ratio <dbl>
patient_radiation_comparison(xray_counts = c(50, 200), career_years = c(5, 30))
#> # A tibble: 20 × 6
#>    occupation  xray_count career_years patient_micromorts occupational_micromo…¹
#>    <chr>            <dbl>        <dbl>              <dbl>                  <dbl>
#>  1 Airline pi…         50            5                  5                  0.75 
#>  2 X-ray tech…         50            5                  5                  0.25 
#>  3 Dental rad…         50            5                  5                  0.05 
#>  4 Nuclear pl…         50            5                  5                  0.5  
#>  5 Interventi…         50            5                  5                  0.875
#>  6 Airline pi…        200            5                 20                  0.75 
#>  7 X-ray tech…        200            5                 20                  0.25 
#>  8 Dental rad…        200            5                 20                  0.05 
#>  9 Nuclear pl…        200            5                 20                  0.5  
#> 10 Interventi…        200            5                 20                  0.875
#> 11 Airline pi…         50           30                  5                  4.5  
#> 12 X-ray tech…         50           30                  5                  1.5  
#> 13 Dental rad…         50           30                  5                  0.3  
#> 14 Nuclear pl…         50           30                  5                  3    
#> 15 Interventi…         50           30                  5                  5.25 
#> 16 Airline pi…        200           30                 20                  4.5  
#> 17 X-ray tech…        200           30                 20                  1.5  
#> 18 Dental rad…        200           30                 20                  0.3  
#> 19 Nuclear pl…        200           30                 20                  3    
#> 20 Interventi…        200           30                 20                  5.25 
#> # ℹ abbreviated name: ¹​occupational_micromorts
#> # ℹ 1 more variable: ratio <dbl>
```
