# Chronic Disease Risks by Country and Year

Returns daily micromorts from chronic diseases for one or more
countries, using a bundled snapshot of IHME Global Burden of Disease
data sourced via Our World in Data.

## Usage

``` r
chronic_disease_risks(country = "GBR", year = NULL)
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

The bundled CSV (`inst/extdata/owid_chronic_deaths.csv`) covers seven
chronic cause categories across ~20 countries. To refresh the snapshot
from the live OWID catalog, run `data-raw/owid_chronic_deaths.R`.

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

[`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md)
for microlife-based chronic lifestyle factors.

## Examples

``` r
# Default: UK, latest year
chronic_disease_risks()
#> # A tibble: 7 × 7
#>   cause   country iso3   year deaths_per_100k daily_micromorts annual_micromorts
#>   <chr>   <chr>   <chr> <int>           <dbl>            <dbl>             <dbl>
#> 1 Cardio… United… GBR    2019           120.             3.30               1205
#> 2 Chroni… United… GBR    2019             8.4            0.230                84
#> 3 Chroni… United… GBR    2019            12.1            0.332               121
#> 4 Chroni… United… GBR    2019            35.8            0.981               358
#> 5 Diabet… United… GBR    2019            10.2            0.280               102
#> 6 Digest… United… GBR    2019            15.6            0.427               156
#> 7 Neopla… United… GBR    2019           136.             3.73               1362

# Specific country
chronic_disease_risks("USA")
#> # A tibble: 7 × 7
#>   cause   country iso3   year deaths_per_100k daily_micromorts annual_micromorts
#>   <chr>   <chr>   <chr> <int>           <dbl>            <dbl>             <dbl>
#> 1 Cardio… United… USA    2019           151.             4.13               1508
#> 2 Chroni… United… USA    2019            14.2            0.389               142
#> 3 Chroni… United… USA    2019            15.8            0.433               158
#> 4 Chroni… United… USA    2019            42.3            1.16                423
#> 5 Diabet… United… USA    2019            18.6            0.510               186
#> 6 Digest… United… USA    2019            18.4            0.504               184
#> 7 Neopla… United… USA    2019           120.             3.30               1205

# Multiple countries
chronic_disease_risks(c("GBR", "USA", "JPN"))
#> # A tibble: 21 × 7
#>    cause  country iso3   year deaths_per_100k daily_micromorts annual_micromorts
#>    <chr>  <chr>   <chr> <int>           <dbl>            <dbl>             <dbl>
#>  1 Cardi… Japan   JPN    2019            75.4            2.07                754
#>  2 Chron… Japan   JPN    2019             4.2            0.115                42
#>  3 Chron… Japan   JPN    2019             9.8            0.268                98
#>  4 Chron… Japan   JPN    2019            18.2            0.499               182
#>  5 Diabe… Japan   JPN    2019             6.8            0.186                68
#>  6 Diges… Japan   JPN    2019            11.4            0.312               114
#>  7 Neopl… Japan   JPN    2019           118.             3.24               1182
#>  8 Cardi… United… GBR    2019           120.             3.30               1205
#>  9 Chron… United… GBR    2019             8.4            0.230                84
#> 10 Chron… United… GBR    2019            12.1            0.332               121
#> # ℹ 11 more rows

# All countries in bundled dataset
chronic_disease_risks("all")
#> # A tibble: 182 × 7
#>    cause  country iso3   year deaths_per_100k daily_micromorts annual_micromorts
#>    <chr>  <chr>   <chr> <int>           <dbl>            <dbl>             <dbl>
#>  1 Cardi… Argent… ARG    2019           179.             4.89               1786
#>  2 Chron… Argent… ARG    2019            12.8            0.351               128
#>  3 Chron… Argent… ARG    2019            14.2            0.389               142
#>  4 Chron… Argent… ARG    2019            38.6            1.06                386
#>  5 Diabe… Argent… ARG    2019            18.4            0.504               184
#>  6 Diges… Argent… ARG    2019            16.8            0.460               168
#>  7 Neopl… Argent… ARG    2019           124.             3.40               1242
#>  8 Cardi… Austra… AUS    2019            98.6            2.70                986
#>  9 Chron… Austra… AUS    2019             9.2            0.252                92
#> 10 Chron… Austra… AUS    2019            10.4            0.285               104
#> # ℹ 172 more rows

# Filter by cause after calling
chronic_disease_risks("GBR") |>
  dplyr::filter(cause == "Cardiovascular diseases")
#> # A tibble: 1 × 7
#>   cause   country iso3   year deaths_per_100k daily_micromorts annual_micromorts
#>   <chr>   <chr>   <chr> <int>           <dbl>            <dbl>             <dbl>
#> 1 Cardio… United… GBR    2019            120.             3.30              1205
```
