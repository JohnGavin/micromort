# Radiation Exposure Profiles

Compares annual and cumulative radiation exposure across occupational,
passenger, and environmental profiles. Uses the Linear No-Threshold
(LNT) model for dose-to-risk conversion.

## Usage

``` r
radiation_profiles(milestones = c(10, 20, 40))
```

## Arguments

- milestones:

  Integer vector of career/exposure years for cumulative columns.
  Default `c(10, 20, 40)`.

## Value

A tibble with columns: activity_id, activity, category, annual_msv,
annual_micromorts, milestone columns (mm_Ny for each N),
regulatory_limit_msv, xray_equivalents_per_year.

## References

ICRP Publication 103 (2007). Recommendations of the International
Commission on Radiological Protection.

Brenner DJ, Hall EJ (2007). "Computed Tomography — An Increasing Source
of Radiation Exposure." NEJM 357:2277-2284.

UNSCEAR 2020. Sources, Effects and Risks of Ionizing Radiation.

## See also

[`atomic_risks()`](https://johngavin.github.io/micromort/reference/atomic_risks.md),
[`patient_radiation_comparison()`](https://johngavin.github.io/micromort/reference/patient_radiation_comparison.md)

## Examples

``` r
radiation_profiles()
#> # A tibble: 11 × 10
#>    activity_id      activity category annual_msv annual_micromorts mm_10y mm_20y
#>    <chr>            <chr>    <chr>         <dbl>             <dbl>  <dbl>  <dbl>
#>  1 airline_pilot_a… Airline… Occupat…      4.9               245     2450   4900
#>  2 xray_tech_annual X-ray t… Occupat…      1                  50      500   1000
#>  3 dental_radiogra… Dental … Occupat…      0.2                10      100    200
#>  4 nuclear_worker_… Nuclear… Occupat…      2                 100     1000   2000
#>  5 interventional_… Interve… Occupat…      3.5               175     1750   3500
#>  6 executive_flyer… Frequen… Travel        2.1               105     1050   2100
#>  7 business_travel… Busines… Travel        0.56               28      280    560
#>  8 annual_tourist_… Annual … Travel        0.084               4.2     42     84
#>  9 granite_residen… Granite… Environ…      2                 100     1000   2000
#> 10 high_altitude_r… High-al… Environ…      0.8                40      400    800
#> 11 background_radi… Normal … Environ…      3.11              156.    1555   3110
#> # ℹ 3 more variables: mm_40y <dbl>, regulatory_limit_msv <dbl>,
#> #   xray_equivalents_per_year <dbl>
radiation_profiles(milestones = c(5, 25, 50))
#> # A tibble: 11 × 10
#>    activity_id       activity category annual_msv annual_micromorts mm_5y mm_25y
#>    <chr>             <chr>    <chr>         <dbl>             <dbl> <dbl>  <dbl>
#>  1 airline_pilot_an… Airline… Occupat…      4.9               245   1225   6125 
#>  2 xray_tech_annual  X-ray t… Occupat…      1                  50    250   1250 
#>  3 dental_radiograp… Dental … Occupat…      0.2                10     50    250 
#>  4 nuclear_worker_a… Nuclear… Occupat…      2                 100    500   2500 
#>  5 interventional_c… Interve… Occupat…      3.5               175    875   4375 
#>  6 executive_flyer_… Frequen… Travel        2.1               105    525   2625 
#>  7 business_travell… Busines… Travel        0.56               28    140    700 
#>  8 annual_tourist_a… Annual … Travel        0.084               4.2   21    105 
#>  9 granite_resident… Granite… Environ…      2                 100    500   2500 
#> 10 high_altitude_re… High-al… Environ…      0.8                40    200   1000 
#> 11 background_radia… Normal … Environ…      3.11              156.   778.  3888.
#> # ℹ 3 more variables: mm_50y <dbl>, regulatory_limit_msv <dbl>,
#> #   xray_equivalents_per_year <dbl>
```
