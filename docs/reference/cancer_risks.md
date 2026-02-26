# Cancer Risks by Type, Sex, and Age

Mortality rates for major cancers stratified by sex and age group,
expressed in micromorts per year and daily microlives.

## Usage

``` r
cancer_risks()
```

## Value

A tibble with columns: cancer_type, sex, age_group, deaths_per_100k,
micromorts_per_year, microlives_per_day, family_history_rr, rank_by_sex,
source_url.

## Details

Data from SEER Cancer Statistics (NCI) and American Cancer Society
2024-2026.

## References

SEER Cancer Statistics Factsheets. National Cancer Institute.
<https://seer.cancer.gov/statfacts/>

Siegel RL, et al. Cancer statistics, 2024. CA Cancer J Clin.
2024;74:12-49.

## See also

[`vaccination_risks()`](https://johngavin.github.io/micromort/reference/vaccination_risks.md),
[`conditional_risk()`](https://johngavin.github.io/micromort/reference/conditional_risk.md),
[`hedged_portfolio()`](https://johngavin.github.io/micromort/reference/hedged_portfolio.md)

Other conditional-risk:
[`conditional_risk()`](https://johngavin.github.io/micromort/reference/conditional_risk.md),
[`hedged_portfolio()`](https://johngavin.github.io/micromort/reference/hedged_portfolio.md),
[`vaccination_risks()`](https://johngavin.github.io/micromort/reference/vaccination_risks.md)

## Examples

``` r
cancer_risks()
#> # A tibble: 37 × 10
#>    cancer_type     sex    age_group deaths_per_100k micromorts_per_year
#>    <chr>           <chr>  <chr>               <dbl>               <dbl>
#>  1 Lung & Bronchus Male   All ages             37.2                 372
#>  2 Prostate        Male   All ages             19.2                 192
#>  3 Colon & Rectum  Male   All ages             15.3                 153
#>  4 Pancreas        Male   All ages             12.9                 129
#>  5 Liver           Male   All ages             10.2                 102
#>  6 Leukemia        Male   All ages              7.8                  78
#>  7 Esophagus       Male   All ages              7.1                  71
#>  8 Bladder         Male   All ages              6.5                  65
#>  9 All cancers     Male   All ages            184.                 1835
#> 10 Lung & Bronchus Female All ages             27.1                 271
#> # ℹ 27 more rows
#> # ℹ 5 more variables: microlives_per_day <dbl>, family_history_rr <dbl>,
#> #   micromorts_with_family_history <dbl>, rank_by_sex <int>, source_url <chr>
cancer_risks() |> dplyr::filter(sex == "Female")
#> # A tibble: 15 × 10
#>    cancer_type     sex    age_group deaths_per_100k micromorts_per_year
#>    <chr>           <chr>  <chr>               <dbl>               <dbl>
#>  1 Lung & Bronchus Female All ages             27.1                 271
#>  2 Breast          Female All ages             19.2                 192
#>  3 Colon & Rectum  Female All ages             10.8                 108
#>  4 Pancreas        Female All ages              9.9                  99
#>  5 Ovary           Female All ages              6.1                  61
#>  6 Uterus          Female All ages              5.3                  53
#>  7 Leukemia        Female All ages              4.8                  48
#>  8 Liver           Female All ages              4.2                  42
#>  9 All cancers     Female All ages            128.                 1281
#> 10 Lung & Bronchus Female 50-64                35                   350
#> 11 Breast          Female 50-64                25                   250
#> 12 Colon & Rectum  Female 50-64                12                   120
#> 13 Lung & Bronchus Female 65-74                95                   950
#> 14 Breast          Female 65-74                45                   450
#> 15 Colon & Rectum  Female 65-74                28                   280
#> # ℹ 5 more variables: microlives_per_day <dbl>, family_history_rr <dbl>,
#> #   micromorts_with_family_history <dbl>, rank_by_sex <int>, source_url <chr>
cancer_risks() |> dplyr::filter(age_group == "50-64")
#> # A tibble: 7 × 10
#>   cancer_type     sex    age_group deaths_per_100k micromorts_per_year
#>   <chr>           <chr>  <chr>               <dbl>               <dbl>
#> 1 All cancers     Both   50-64                 125                1250
#> 2 Lung & Bronchus Male   50-64                  45                 450
#> 3 Prostate        Male   50-64                   8                  80
#> 4 Colon & Rectum  Male   50-64                  18                 180
#> 5 Lung & Bronchus Female 50-64                  35                 350
#> 6 Breast          Female 50-64                  25                 250
#> 7 Colon & Rectum  Female 50-64                  12                 120
#> # ℹ 5 more variables: microlives_per_day <dbl>, family_history_rr <dbl>,
#> #   micromorts_with_family_history <dbl>, rank_by_sex <int>, source_url <chr>
```
