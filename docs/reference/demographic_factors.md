# Demographic Life Expectancy Factors

Population-level factors affecting baseline life expectancy, expressed
as microlives per day relative to a reference population.

## Usage

``` r
demographic_factors()
```

## Value

A tibble with demographic factors and their microlife effects.

## Details

Based on actuarial data and epidemiological studies.

## References

Spiegelhalter D (2012). BMJ 2012;345:e8223.

<https://en.wikipedia.org/wiki/Microlife>

## Examples

``` r
demographic_factors()
#> # A tibble: 6 × 5
#>   factor         comparison                 microlives_per_day source source_url
#>   <chr>          <chr>                                   <dbl> <chr>  <chr>     
#> 1 Sex            Female vs Male                              4 BMJ 2… https://e…
#> 2 Era            2010 vs 1910                               15 BMJ 2… https://e…
#> 3 Country (male) Sweden vs Russia                           21 BMJ 2… https://e…
#> 4 Country (male) UK vs Russia                               15 BMJ 2… https://e…
#> 5 Socioeconomic  Professional vs Unskilled…                  4 BMJ 2… https://e…
#> 6 Education      Degree vs No qualificatio…                  4 BMJ 2… https://e…
```
