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
#> # A tibble: 81 × 9
#>    region_code region_name           country_code  year sex   life_expectancy
#>    <chr>       <chr>                 <chr>        <int> <chr>           <dbl>
#>  1 AT13        Wien                  AT            2019 Total            81.1
#>  2 AT22        Steiermark            AT            2019 Total            82.2
#>  3 AT32        Salzburg              AT            2019 Total            82.8
#>  4 AT33        Tirol                 AT            2019 Total            83  
#>  5 AT34        Vorarlberg            AT            2019 Total            83.3
#>  6 BE32        Prov. Hainaut         BE            2019 Total            79.6
#>  7 BE33        Prov. Liège           BE            2019 Total            80.6
#>  8 BE34        Prov. Luxembourg (BE) BE            2019 Total            80.6
#>  9 BE35        Prov. Namur           BE            2019 Total            80.3
#> 10 DE11        Stuttgart             DE            2019 Total            82.6
#> # ℹ 71 more rows
#> # ℹ 3 more variables: microlives_vs_eu_avg <dbl>, classification <chr>,
#> #   source_url <chr>
```
