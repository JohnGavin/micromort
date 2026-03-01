# Regional Mortality Multiplier

Calculate a mortality risk multiplier for a region relative to the
national or EU average. Useful for adjusting baseline micromort
estimates by location.

## Usage

``` r
regional_mortality_multiplier(region_code, reference = "eu", year = 2019)
```

## Arguments

- region_code:

  Character. NUTS2 region code (e.g., "FR10").

- reference:

  Character. Compare against "national" average or "eu" average. Default
  is "eu".

- year:

  Integer. Reference year. Default is 2019 (pre-COVID).

## Value

A tibble with the region's mortality multiplier and interpretation.

## Details

The mortality multiplier is derived from life expectancy differences
using the approximation that each year of life expectancy difference
corresponds to approximately 2.5% difference in annual mortality risk.

A multiplier of 1.0 means average risk; 0.9 means 10% lower risk; 1.1
means 10% higher risk.

## See also

[`regional_life_expectancy()`](https://johngavin.github.io/micromort/reference/regional_life_expectancy.md),
[`demographic_factors()`](https://johngavin.github.io/micromort/reference/demographic_factors.md)

Other regional:
[`laggard_regions()`](https://johngavin.github.io/micromort/reference/laggard_regions.md),
[`regional_life_expectancy()`](https://johngavin.github.io/micromort/reference/regional_life_expectancy.md),
[`vanguard_regions()`](https://johngavin.github.io/micromort/reference/vanguard_regions.md)

## Examples

``` r
# Catalonia vs EU average
regional_mortality_multiplier("ES51")
#> # A tibble: 1 × 8
#>   region_code region_name life_expectancy reference  reference_le le_difference
#>   <chr>       <chr>                 <dbl> <chr>             <dbl>         <dbl>
#> 1 ES51        Cataluña               84.3 EU average         82.4          1.86
#> # ℹ 2 more variables: mortality_multiplier <dbl>, interpretation <chr>

# Compare to national average
regional_mortality_multiplier("ES51", reference = "national")
#> # A tibble: 1 × 8
#>   region_code region_name life_expectancy reference  reference_le le_difference
#>   <chr>       <chr>                 <dbl> <chr>             <dbl>         <dbl>
#> 1 ES51        Cataluña               84.3 ES average         83.7          0.59
#> # ℹ 2 more variables: mortality_multiplier <dbl>, interpretation <chr>
```
