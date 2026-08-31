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
#> # A tibble: 14 × 9
#>    region_code region_name              country_code  year sex   life_expectancy
#>    <chr>       <chr>                    <chr>        <int> <chr>           <dbl>
#>  1 CH01        Région lémanique         CH            2019 Total            84.6
#>  2 CH03        Nordwestschweiz          CH            2019 Total            84  
#>  3 CH06        Zentralschweiz           CH            2019 Total            84.4
#>  4 ES13        Cantabria                ES            2019 Total            83.9
#>  5 ES22        Comunidad Foral de Nava… ES            2019 Total            85  
#>  6 ES24        Aragón                   ES            2019 Total            84.4
#>  7 ES30        Comunidad de Madrid      ES            2019 Total            85.8
#>  8 ES51        Cataluña                 ES            2019 Total            84.3
#>  9 ES53        Illes Balears            ES            2019 Total            84.2
#> 10 FI20        Åland                    FI            2019 Total            83.9
#> 11 FRM0        Corse                    FR            2019 Total            84  
#> 12 ITI4        Lazio                    IT            2019 Total            83.8
#> 13 NO01        Oslo og Akershus (stati… NO            2019 Total            83.8
#> 14 SE11        Stockholm                SE            2019 Total            83.9
#> # ℹ 3 more variables: microlives_vs_eu_avg <dbl>, classification <chr>,
#> #   source_url <chr>
```
