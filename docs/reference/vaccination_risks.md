# Vaccination Risk Reduction

Mortality risk reduction from vaccination schedules compared to
unvaccinated baseline, expressed in micromorts avoided per year.

## Usage

``` r
vaccination_risks()
```

## Value

A tibble with vaccination schedules and their risk reduction metrics.

## Details

Data from CDC, WHO, and Lancet 2024 Global Vaccine Impact Study.

## References

CDC. Health and Economic Benefits of Routine Childhood Immunizations.
MMWR 2024;73:1-8. <https://www.cdc.gov/mmwr/>

Lancet 2024. Contribution of vaccination to improved survival: 50 years
of EPI.
<https://www.thelancet.com/journals/lancet/article/PIIS0140-6736(24)00850-X/fulltext>

## See also

[`cancer_risks()`](https://johngavin.github.io/micromort/reference/cancer_risks.md),
[`conditional_risk()`](https://johngavin.github.io/micromort/reference/conditional_risk.md),
[`hedged_portfolio()`](https://johngavin.github.io/micromort/reference/hedged_portfolio.md)

Other conditional-risk:
[`cancer_risks()`](https://johngavin.github.io/micromort/reference/cancer_risks.md),
[`conditional_risk()`](https://johngavin.github.io/micromort/reference/conditional_risk.md),
[`hedged_portfolio()`](https://johngavin.github.io/micromort/reference/hedged_portfolio.md)

## Examples

``` r
vaccination_risks()
#> # A tibble: 17 × 9
#>    vaccine_schedule            age_group country        mortality_reduction_pct
#>    <chr>                       <chr>     <chr>                            <dbl>
#>  1 Complete childhood schedule 0-5       US                                  27
#>  2 Complete childhood schedule 0-5       UK                                  27
#>  3 Complete childhood schedule 0-5       Australia                           27
#>  4 Complete childhood schedule 0-5       Global average                      24
#>  5 Measles vaccine             0-5       US                                  15
#>  6 DTP vaccine                 0-5       US                                  10
#>  7 Rotavirus vaccine           0-5       US                                   4
#>  8 Hib vaccine                 0-5       US                                   3
#>  9 Pneumococcal vaccine        0-5       US                                   2
#> 10 Annual influenza vaccine    65+       US                                   4
#> 11 Annual influenza vaccine    65+       UK                                   4
#> 12 Pneumococcal vaccine        65+       US                                   2
#> 13 Shingles vaccine            50+       US                                   1
#> 14 COVID-19 vaccine (annual)   65+       US                                  15
#> 15 COVID-19 vaccine (annual)   18-64     US                                   3
#> 16 Unvaccinated baseline       0-5       US                                   0
#> 17 Unvaccinated baseline       65+       US                                   0
#> # ℹ 5 more variables: micromorts_avoided_per_year <dbl>, description <chr>,
#> #   microlives_gained_per_day <dbl>, annual_life_days_gained <dbl>,
#> #   source_url <chr>
vaccination_risks() |> dplyr::filter(country == "US")
#> # A tibble: 13 × 9
#>    vaccine_schedule            age_group country mortality_reduction_pct
#>    <chr>                       <chr>     <chr>                     <dbl>
#>  1 Complete childhood schedule 0-5       US                           27
#>  2 Measles vaccine             0-5       US                           15
#>  3 DTP vaccine                 0-5       US                           10
#>  4 Rotavirus vaccine           0-5       US                            4
#>  5 Hib vaccine                 0-5       US                            3
#>  6 Pneumococcal vaccine        0-5       US                            2
#>  7 Annual influenza vaccine    65+       US                            4
#>  8 Pneumococcal vaccine        65+       US                            2
#>  9 Shingles vaccine            50+       US                            1
#> 10 COVID-19 vaccine (annual)   65+       US                           15
#> 11 COVID-19 vaccine (annual)   18-64     US                            3
#> 12 Unvaccinated baseline       0-5       US                            0
#> 13 Unvaccinated baseline       65+       US                            0
#> # ℹ 5 more variables: micromorts_avoided_per_year <dbl>, description <chr>,
#> #   microlives_gained_per_day <dbl>, annual_life_days_gained <dbl>,
#> #   source_url <chr>
vaccination_risks() |> dplyr::filter(age_group == "0-5")  # Childhood vaccines
#> # A tibble: 10 × 9
#>    vaccine_schedule            age_group country        mortality_reduction_pct
#>    <chr>                       <chr>     <chr>                            <dbl>
#>  1 Complete childhood schedule 0-5       US                                  27
#>  2 Complete childhood schedule 0-5       UK                                  27
#>  3 Complete childhood schedule 0-5       Australia                           27
#>  4 Complete childhood schedule 0-5       Global average                      24
#>  5 Measles vaccine             0-5       US                                  15
#>  6 DTP vaccine                 0-5       US                                  10
#>  7 Rotavirus vaccine           0-5       US                                   4
#>  8 Hib vaccine                 0-5       US                                   3
#>  9 Pneumococcal vaccine        0-5       US                                   2
#> 10 Unvaccinated baseline       0-5       US                                   0
#> # ℹ 5 more variables: micromorts_avoided_per_year <dbl>, description <chr>,
#> #   microlives_gained_per_day <dbl>, annual_life_days_gained <dbl>,
#> #   source_url <chr>
```
