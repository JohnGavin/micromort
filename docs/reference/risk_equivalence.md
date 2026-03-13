# Risk Equivalence Table

Compares a reference activity to all other activities by computing the
ratio of micromorts. "How many X-rays equal one skydive?"

## Usage

``` r
risk_equivalence(reference, risks = NULL, min_ratio = 0.01, max_ratio = Inf)
```

## Arguments

- reference:

  Character. Activity name to use as the reference (denominator). Must
  match an `activity` value in `risks`.

- risks:

  A tibble with at least `activity` and `micromorts` columns. Defaults
  to
  [`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md).

- min_ratio:

  Numeric. Minimum ratio to include (default 0.01).

- max_ratio:

  Numeric. Maximum ratio to include (default `Inf`).

## Value

A tibble with columns: `activity`, `micromorts`, `reference`,
`reference_micromorts`, `ratio`, `equivalence`.

## See also

[`risk_exchange_matrix()`](https://johngavin.github.io/micromort/reference/risk_exchange_matrix.md)

## Examples

``` r
risk_equivalence("Chest X-ray (radiation per scan)")
#> # A tibble: 94 × 6
#>    activity         micromorts reference reference_micromorts  ratio equivalence
#>    <chr>                 <dbl> <chr>                    <dbl>  <dbl> <chr>      
#>  1 Mt. Everest asc…      37932 Chest X-…                  0.1 379320 1 Mt. Ever…
#>  2 Himalayan mount…      12000 Chest X-…                  0.1 120000 1 Himalaya…
#>  3 COVID-19 infect…      10000 Chest X-…                  0.1 100000 1 COVID-19…
#>  4 Spanish flu inf…       3000 Chest X-…                  0.1  30000 1 Spanish …
#>  5 Matterhorn asce…       2840 Chest X-…                  0.1  28400 1 Matterho…
#>  6 Living in US du…        500 Chest X-…                  0.1   5000 1 Living i…
#>  7 Living (one day…        463 Chest X-…                  0.1   4630 1 Living (…
#>  8 Base jumping            430 Chest X-…                  0.1   4300 1 Base jum…
#>  9 First day of li…        430 Chest X-…                  0.1   4300 1 First da…
#> 10 COVID-19 unvacc…        234 Chest X-…                  0.1   2340 1 COVID-19…
#> # ℹ 84 more rows
risk_equivalence("Skydiving (US)")
#> # A tibble: 86 × 6
#>    activity         micromorts reference reference_micromorts  ratio equivalence
#>    <chr>                 <dbl> <chr>                    <dbl>  <dbl> <chr>      
#>  1 Mt. Everest asc…      37932 Skydivin…                    8 4742.  1 Mt. Ever…
#>  2 Himalayan mount…      12000 Skydivin…                    8 1500   1 Himalaya…
#>  3 COVID-19 infect…      10000 Skydivin…                    8 1250   1 COVID-19…
#>  4 Spanish flu inf…       3000 Skydivin…                    8  375   1 Spanish …
#>  5 Matterhorn asce…       2840 Skydivin…                    8  355   1 Matterho…
#>  6 Living in US du…        500 Skydivin…                    8   62.5 1 Living i…
#>  7 Living (one day…        463 Skydivin…                    8   57.9 1 Living (…
#>  8 Base jumping            430 Skydivin…                    8   53.8 1 Base jum…
#>  9 First day of li…        430 Skydivin…                    8   53.8 1 First da…
#> 10 COVID-19 unvacc…        234 Skydivin…                    8   29.2 1 COVID-19…
#> # ℹ 76 more rows
```
