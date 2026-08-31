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
#>  1 airline_pilot_a… Airline… Occupat…       3               0.15    1.5     3   
#>  2 xray_tech_annual X-ray t… Occupat…       1               0.05    0.5     1   
#>  3 dental_radiogra… Dental … Occupat…       0.2             0.01    0.1     0.2 
#>  4 nuclear_worker_… Nuclear… Occupat…       2               0.1     1       2   
#>  5 interventional_… Interve… Occupat…       3.5             0.175   1.75    3.5 
#>  6 executive_flyer… Frequen… Travel         3               0.15    1.5     3   
#>  7 business_travel… Busines… Travel         0.75            0.0375  0.375   0.75
#>  8 annual_tourist_… Annual … Travel         0.12            0.006   0.06    0.12
#>  9 granite_residen… Granite… Environ…       2               0.1     1       2   
#> 10 high_altitude_r… High-al… Environ…       0.7             0.035   0.35    0.7 
#> 11 background_radi… Normal … Environ…       2.4             0.12    1.2     2.4 
#> # ℹ 3 more variables: mm_40y <dbl>, regulatory_limit_msv <dbl>,
#> #   xray_equivalents_per_year <dbl>
radiation_profiles(milestones = c(5, 25, 50))
#> # A tibble: 11 × 10
#>    activity_id       activity category annual_msv annual_micromorts mm_5y mm_25y
#>    <chr>             <chr>    <chr>         <dbl>             <dbl> <dbl>  <dbl>
#>  1 airline_pilot_an… Airline… Occupat…       3               0.15   0.75   3.75 
#>  2 xray_tech_annual  X-ray t… Occupat…       1               0.05   0.25   1.25 
#>  3 dental_radiograp… Dental … Occupat…       0.2             0.01   0.05   0.25 
#>  4 nuclear_worker_a… Nuclear… Occupat…       2               0.1    0.5    2.5  
#>  5 interventional_c… Interve… Occupat…       3.5             0.175  0.875  4.38 
#>  6 executive_flyer_… Frequen… Travel         3               0.15   0.75   3.75 
#>  7 business_travell… Busines… Travel         0.75            0.0375 0.188  0.938
#>  8 annual_tourist_a… Annual … Travel         0.12            0.006  0.03   0.15 
#>  9 granite_resident… Granite… Environ…       2               0.1    0.5    2.5  
#> 10 high_altitude_re… High-al… Environ…       0.7             0.035  0.175  0.875
#> 11 background_radia… Normal … Environ…       2.4             0.12   0.6    3    
#> # ℹ 3 more variables: mm_50y <dbl>, regulatory_limit_msv <dbl>,
#> #   xray_equivalents_per_year <dbl>
```
