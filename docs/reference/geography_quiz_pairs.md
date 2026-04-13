# Generate Geography Quiz Pairs Comparing Risk Across Countries

Creates quiz pairs that compare the same disease risk across different
countries, or compare country-specific disease risk against acute
one-off activities. Uses
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)
with country profiles.

## Usage

``` r
geography_quiz_pairs(
  countries = c("UK", "NG"),
  seed = NULL,
  include_acute = TRUE,
  difficulty = NULL
)
```

## Arguments

- countries:

  Character vector of ISO-2 country codes to compare. Default
  `c("UK", "NG")` (UK vs Nigeria — high contrast).

- seed:

  Optional random seed for reproducibility.

- include_acute:

  If `TRUE` (default), also includes cross-domain pairs comparing
  country-specific disease risk vs unconditional acute activities (e.g.,
  "Daily CVD risk (Nigeria) vs Skydiving").

- difficulty:

  Optional difficulty level: `"easy"`, `"medium"`, `"hard"`, or
  `"mixed"`.

## Value

A tibble with the same columns as
[`quiz_pairs()`](https://johngavin.github.io/micromort/reference/quiz_pairs.md),
plus a `pair_type` column indicating `"cross_country"` or
`"disease_vs_acute"`.

## Examples

``` r
geography_quiz_pairs(countries = c("UK", "NG"), seed = 42)
#> # A tibble: 20 × 17
#>    activity_b        activity_a micromorts_a category_a hedgeable_pct_a period_a
#>    <chr>             <chr>             <dbl> <chr>                <dbl> <chr>   
#>  1 Skydiving (US)    Daily dia…         0.88 Disease                  0 per day 
#>  2 Daily LRI mortal… Daily LRI…         0.53 Disease                  0 per day 
#>  3 COVID-19 bivalen… Daily can…         2.79 Disease                  0 per day 
#>  4 Heroin use (per … Daily can…         3.95 Disease                  0 per day 
#>  5 Daily CVD mortal… Daily CVD…         3.24 Disease                  0 per day 
#>  6 COVID-19 monoval… Daily dia…         0.02 Disease                  0 per day 
#>  7 US military in A… Daily can…         2.79 Disease                  0 per day 
#>  8 US military in A… Daily CVD…         3.24 Disease                  0 per day 
#>  9 Ecstasy/MDMA (pe… Daily LRI…         1.77 Disease                  0 per day 
#> 10 Daily diarrheal … Daily dia…         0.02 Disease                  0 per day 
#> 11 Skydiving (UK)    Daily dia…         0.88 Disease                  0 per day 
#> 12 Heroin use (per … Daily CVD…         3.24 Disease                  0 per day 
#> 13 US military in A… Daily can…         3.95 Disease                  0 per day 
#> 14 Daily cancer mor… Daily can…         3.95 Disease                  0 per day 
#> 15 Living in NYC CO… Daily CVD…         7.33 Disease                  0 per day 
#> 16 Scuba diving, tr… Daily LRI…         0.53 Disease                  0 per day 
#> 17 Living (one day,… Daily LRI…         0.53 Disease                  0 per day 
#> 18 COVID-19 monoval… Daily CVD…         7.33 Disease                  0 per day 
#> 19 Living (one day,… Daily LRI…         1.77 Disease                  0 per day 
#> 20 Kangaroo encount… Daily dia…         0.02 Disease                  0 per day 
#> # ℹ 11 more variables: micromorts_b <dbl>, category_b <chr>,
#> #   hedgeable_pct_b <dbl>, period_b <chr>, ratio <dbl>, pair_type <chr>,
#> #   answer <chr>, description_a <chr>, help_url_a <chr>, description_b <chr>,
#> #   help_url_b <chr>
```
