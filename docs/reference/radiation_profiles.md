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
#>    activity_id     activity category annual_msv annual_micromorts  mm_10y mm_20y
#>    <chr>           <chr>    <chr>         <dbl>             <dbl>   <dbl>  <dbl>
#>  1 airline_pilot_… Airline… Occupat…     4.9              245     2450    4900  
#>  2 xray_tech_annu… X-ray t… Occupat…     0.001              0.05     0.5     1  
#>  3 dental_radiogr… Dental … Occupat…     0.0002             0.01     0.1     0.2
#>  4 nuclear_worker… Nuclear… Occupat…     0.002              0.1      1       2  
#>  5 interventional… Interve… Occupat…     0.0035             0.175    1.75    3.5
#>  6 executive_flye… Frequen… Travel       2.1              105     1050    2100  
#>  7 business_trave… Busines… Travel       0.56              28      280     560  
#>  8 annual_tourist… Annual … Travel       0.084              4.2     42      84  
#>  9 granite_reside… Granite… Environ…     0.002              0.1      1       2  
#> 10 high_altitude_… High-al… Environ…     0.8               40      400     800  
#> 11 background_rad… Normal … Environ…     3.11             156.    1555    3110  
#> # ℹ 3 more variables: mm_40y <dbl>, regulatory_limit_msv <dbl>,
#> #   xray_equivalents_per_year <dbl>
radiation_profiles(milestones = c(5, 25, 50))
#> # A tibble: 11 × 10
#>    activity_id    activity category annual_msv annual_micromorts   mm_5y  mm_25y
#>    <chr>          <chr>    <chr>         <dbl>             <dbl>   <dbl>   <dbl>
#>  1 airline_pilot… Airline… Occupat…     4.9              245     1.23e+3 6125   
#>  2 xray_tech_ann… X-ray t… Occupat…     0.001              0.05  2.5 e-1    1.25
#>  3 dental_radiog… Dental … Occupat…     0.0002             0.01  5   e-2    0.25
#>  4 nuclear_worke… Nuclear… Occupat…     0.002              0.1   5   e-1    2.5 
#>  5 interventiona… Interve… Occupat…     0.0035             0.175 8.75e-1    4.38
#>  6 executive_fly… Frequen… Travel       2.1              105     5.25e+2 2625   
#>  7 business_trav… Busines… Travel       0.56              28     1.4 e+2  700   
#>  8 annual_touris… Annual … Travel       0.084              4.2   2.1 e+1  105   
#>  9 granite_resid… Granite… Environ…     0.002              0.1   5   e-1    2.5 
#> 10 high_altitude… High-al… Environ…     0.8               40     2   e+2 1000   
#> 11 background_ra… Normal … Environ…     3.11             156.    7.77e+2 3888.  
#> # ℹ 3 more variables: mm_50y <dbl>, regulatory_limit_msv <dbl>,
#> #   xray_equivalents_per_year <dbl>
```
