# Daily micromorts from infectious diseases by country

Returns daily micromorts from infectious diseases for one or more
countries, using a bundled snapshot of IHME Global Burden of Disease
data sourced via Our World in Data.

## Usage

``` r
infectious_disease_risks(country = "GBR", year = NULL)
```

## Arguments

- country:

  Character vector of ISO-3 country codes (e.g. `"GBR"`,
  `c("GBR", "USA")`). Default is `"GBR"`. Use `"all"` to return every
  country in the bundled dataset.

- year:

  Integer or `NULL`. If `NULL` (default), the most recent available year
  is returned. If a specific year is supplied, only rows matching that
  year are returned; an error is raised if the year is absent.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns:

- cause:

  Disease cause label (character)

- country:

  Country name (character)

- iso3:

  ISO-3 country code (character)

- year:

  Data year (integer)

- deaths_per_100k:

  Age-standardised deaths per 100,000 per year (double)

- daily_micromorts:

  Daily micromort risk (double)

- annual_micromorts:

  Annual micromort risk (double)

## Details

The bundled CSV (`inst/extdata/owid_infectious_deaths.csv`) covers seven
infectious cause categories across 26 countries. To refresh the
snapshot, run `data-raw/owid_infectious_deaths.R`.

### Conversion formula

`daily_micromorts = (deaths_per_100k / 365) * 10`

Because: annual deaths per 100,000 → divide by 100,000 for annual
probability → divide by 365 for daily probability → multiply by
1,000,000 for micromorts. The 100,000 and 1,000,000 cancel to a factor
of 10: `rate / 100,000 / 365 × 1,000,000 = rate / 365 × 10`.

## References

Institute for Health Metrics and Evaluation (IHME). Global Burden of
Disease Study 2019. Seattle, WA: IHME, 2020.
<https://www.healthdata.org/research-analysis/gbd>

Our World in Data. Cause of Death.
<https://ourworldindata.org/causes-of-death>

## See also

[`chronic_disease_risks()`](https://johngavin.github.io/micromort/reference/chronic_disease_risks.md)
for chronic disease micromort risks by country.

## Examples

``` r
# Default: UK, latest year
infectious_disease_risks()
#> # A tibble: 7 × 7
#>   cause   country iso3   year deaths_per_100k daily_micromorts annual_micromorts
#>   <chr>   <chr>   <chr> <int>           <dbl>            <dbl>             <dbl>
#> 1 Diarrh… United… GBR    2019             0.5           0.0137                 5
#> 2 HIV/AI… United… GBR    2019             0.8           0.0219                 8
#> 3 Hepati… United… GBR    2019             0.4           0.011                  4
#> 4 Lower … United… GBR    2019            20             0.548                200
#> 5 Malaria United… GBR    2019             0             0                      0
#> 6 Mening… United… GBR    2019             0.3           0.0082                 3
#> 7 Tuberc… United… GBR    2019             0.5           0.0137                 5

# Specific country
infectious_disease_risks("USA")
#> # A tibble: 7 × 7
#>   cause   country iso3   year deaths_per_100k daily_micromorts annual_micromorts
#>   <chr>   <chr>   <chr> <int>           <dbl>            <dbl>             <dbl>
#> 1 Diarrh… United… USA    2019             1.2           0.0329                12
#> 2 HIV/AI… United… USA    2019             1.5           0.0411                15
#> 3 Hepati… United… USA    2019             0.5           0.0137                 5
#> 4 Lower … United… USA    2019            15             0.411                150
#> 5 Malaria United… USA    2019             0             0                      0
#> 6 Mening… United… USA    2019             0.2           0.0055                 2
#> 7 Tuberc… United… USA    2019             0.1           0.0027                 1

# Multiple countries
infectious_disease_risks(c("GBR", "USA", "IND"))
#> # A tibble: 21 × 7
#>    cause  country iso3   year deaths_per_100k daily_micromorts annual_micromorts
#>    <chr>  <chr>   <chr> <int>           <dbl>            <dbl>             <dbl>
#>  1 Diarr… India   IND    2019            30             0.822                300
#>  2 HIV/A… India   IND    2019             1.5           0.0411                15
#>  3 Hepat… India   IND    2019             8             0.219                 80
#>  4 Lower… India   IND    2019            65             1.78                 650
#>  5 Malar… India   IND    2019             3             0.0822                30
#>  6 Menin… India   IND    2019             5             0.137                 50
#>  7 Tuber… India   IND    2019            30             0.822                300
#>  8 Diarr… United… GBR    2019             0.5           0.0137                 5
#>  9 HIV/A… United… GBR    2019             0.8           0.0219                 8
#> 10 Hepat… United… GBR    2019             0.4           0.011                  4
#> # ℹ 11 more rows

# All countries in bundled dataset
infectious_disease_risks("all")
#> # A tibble: 189 × 7
#>    cause  country iso3   year deaths_per_100k daily_micromorts annual_micromorts
#>    <chr>  <chr>   <chr> <int>           <dbl>            <dbl>             <dbl>
#>  1 Diarr… Argent… ARG    2019             3.2           0.0877                32
#>  2 HIV/A… Argent… ARG    2019             4.1           0.112                 41
#>  3 Hepat… Argent… ARG    2019             1.2           0.0329                12
#>  4 Lower… Argent… ARG    2019            18.5           0.507                185
#>  5 Malar… Argent… ARG    2019             0             0                      0
#>  6 Menin… Argent… ARG    2019             0.8           0.0219                 8
#>  7 Tuber… Argent… ARG    2019             2.8           0.0767                28
#>  8 Diarr… Austra… AUS    2019             0.6           0.0164                 6
#>  9 HIV/A… Austra… AUS    2019             0.4           0.011                  4
#> 10 Hepat… Austra… AUS    2019             0.5           0.0137                 5
#> # ℹ 179 more rows

# Filter by cause after calling
infectious_disease_risks("GBR") |>
  dplyr::filter(cause == "Tuberculosis")
#> # A tibble: 1 × 7
#>   cause   country iso3   year deaths_per_100k daily_micromorts annual_micromorts
#>   <chr>   <chr>   <chr> <int>           <dbl>            <dbl>             <dbl>
#> 1 Tuberc… United… GBR    2019             0.5           0.0137                 5
```
