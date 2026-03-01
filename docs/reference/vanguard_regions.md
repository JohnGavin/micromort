# Vanguard Regions with Highest Life Expectancy

Convenience function returning regions classified as "vanguard" - those
with the highest life expectancy and sustained improvement trends.

## Usage

``` r
vanguard_regions(country = NULL, year = NULL, sex = NULL)
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

A tibble filtered to vanguard regions only.

## See also

[`regional_life_expectancy()`](https://johngavin.github.io/micromort/reference/regional_life_expectancy.md),
[`laggard_regions()`](https://johngavin.github.io/micromort/reference/laggard_regions.md)

Other regional:
[`laggard_regions()`](https://johngavin.github.io/micromort/reference/laggard_regions.md),
[`regional_life_expectancy()`](https://johngavin.github.io/micromort/reference/regional_life_expectancy.md),
[`regional_mortality_multiplier()`](https://johngavin.github.io/micromort/reference/regional_mortality_multiplier.md)

## Examples

``` r
# Vanguard regions in 2019
vanguard_regions(year = 2019, sex = "Total")
#> # A tibble: 4 × 9
#>   region_code region_name               country_code  year sex   life_expectancy
#>   <chr>       <chr>                     <chr>        <int> <chr>           <dbl>
#> 1 CH03        Northwestern Switzerland  CH            2019 Total              83
#> 2 ES51        Catalonia                 ES            2019 Total              83
#> 3 FR10        Île-de-France (Paris reg… FR            2019 Total              83
#> 4 ITC4        Lombardy                  IT            2019 Total              83
#> # ℹ 3 more variables: microlives_vs_eu_avg <dbl>, classification <chr>,
#> #   source_url <chr>
```
