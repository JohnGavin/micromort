# COVID-19 Vaccine Relative Risks

Mortality risk comparison between vaccinated and unvaccinated
populations during the Omicron BA.4/BA.5 period (Sep-Dec 2022).

## Usage

``` r
covid_vaccine_rr()
```

## Value

A tibble with vaccination status, death rates, micromorts, microlives,
and relative risk compared to bivalent booster recipients.

## Details

Data source: CDC MMWR Vol. 72, No. 6 (Feb 2023).

## References

Link SC, et al. COVID-19 Incidence and Death Rates Among Unvaccinated
and Fully Vaccinated Adults with and Without Booster Doses During
Periods of Delta and Omicron Variant Emergence. MMWR 2023;72:132-138.
<https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm>

## Examples

``` r
covid_vaccine_rr()
#> # A tibble: 15 × 8
#>    age_group vaccination_status deaths_per_100k micromorts microlives
#>    <chr>     <chr>                        <dbl>      <dbl>      <dbl>
#>  1 All ages  Unvaccinated                 2          20          14  
#>  2 All ages  Monovalent only              0.4         4           2.8
#>  3 All ages  Bivalent booster             0.1         1           0.7
#>  4 18-49     Unvaccinated                 0.1         1           0.7
#>  5 18-49     Monovalent only              0.02        0.2         0.1
#>  6 18-49     Bivalent booster             0.005       0.05        0  
#>  7 50-64     Unvaccinated                 0.8         8           5.6
#>  8 50-64     Monovalent only              0.2         2           1.4
#>  9 50-64     Bivalent booster             0.1         1           0.7
#> 10 65-79     Unvaccinated                 7.6        76          53.2
#> 11 65-79     Monovalent only              0.9         9           6.3
#> 12 65-79     Bivalent booster             0.3         3           2.1
#> 13 80+       Unvaccinated                23.4       234         164. 
#> 14 80+       Monovalent only              5.5        55          38.5
#> 15 80+       Bivalent booster             2.3        23          16.1
#> # ℹ 3 more variables: relative_risk <dbl>, period <chr>, source_url <chr>
covid_vaccine_rr() |> dplyr::filter(age_group == "All ages")
#> # A tibble: 3 × 8
#>   age_group vaccination_status deaths_per_100k micromorts microlives
#>   <chr>     <chr>                        <dbl>      <dbl>      <dbl>
#> 1 All ages  Unvaccinated                   2           20       14  
#> 2 All ages  Monovalent only                0.4          4        2.8
#> 3 All ages  Bivalent booster               0.1          1        0.7
#> # ℹ 3 more variables: relative_risk <dbl>, period <chr>, source_url <chr>
```
