# Laggard Regions with Stalled Life Expectancy Gains

Convenience function returning regions classified as "laggard" - those
with lower life expectancy or stagnant improvement trends since 2005.

## Usage

``` r
laggard_regions(country = NULL, year = NULL, sex = NULL)
```

## Arguments

- country:

  Character vector. Filter to specific countries using ISO 2-letter
  codes (e.g., "FR", "DE", "ES"). Default `NULL` returns all countries.

- year:

  Integer or vector. Filter to specific years. Default `NULL` returns
  all years (1992-2023).

- sex:

  Character. Filter by sex: "Male", "Female", or "Total". Default `NULL`
  returns all.

## Value

A tibble filtered to laggard regions only.

## See also

[`regional_life_expectancy()`](https://johngavin.github.io/micromort/reference/regional_life_expectancy.md),
[`vanguard_regions()`](https://johngavin.github.io/micromort/reference/vanguard_regions.md)

Other regional:
[`regional_life_expectancy()`](https://johngavin.github.io/micromort/reference/regional_life_expectancy.md),
[`regional_mortality_multiplier()`](https://johngavin.github.io/micromort/reference/regional_mortality_multiplier.md),
[`vanguard_regions()`](https://johngavin.github.io/micromort/reference/vanguard_regions.md)

## Examples

``` r
# Laggard regions in 2019
laggard_regions(year = 2019, sex = "Total")
#> # A tibble: 4 × 9
#>   region_code region_name            country_code  year sex   life_expectancy
#>   <chr>       <chr>                  <chr>        <int> <chr>           <dbl>
#> 1 BE32        Hainaut (Wallonia)     BE            2019 Total            75.9
#> 2 DE80        Mecklenburg-Vorpommern DE            2019 Total            75.9
#> 3 FRE1        Nord (Hauts-de-France) FR            2019 Total            75.9
#> 4 UKC1        Tees Valley and Durham UK            2019 Total            75.9
#> # ℹ 3 more variables: microlives_vs_eu_avg <dbl>, classification <chr>,
#> #   source_url <chr>
```
