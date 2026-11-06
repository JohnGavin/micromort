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
#> # A tibble: 105 × 6
#>    activity          micromorts reference reference_micromorts ratio equivalence
#>    <chr>                  <dbl> <chr>                    <dbl> <dbl> <chr>      
#>  1 Mt. Everest asce…      37932 Chest X-…                    1 37932 1 Mt. Ever…
#>  2 Himalayan mounta…      12000 Chest X-…                    1 12000 1 Himalaya…
#>  3 COVID-19 infecti…      10000 Chest X-…                    1 10000 1 COVID-19…
#>  4 Spanish flu infe…       3000 Chest X-…                    1  3000 1 Spanish …
#>  5 Matterhorn ascent       2840 Chest X-…                    1  2840 1 Matterho…
#>  6 Living in US dur…        500 Chest X-…                    1   500 1 Living i…
#>  7 Living (one day,…        463 Chest X-…                    1   463 1 Living (…
#>  8 Base jumping (pe…        430 Chest X-…                    1   430 1 Base jum…
#>  9 First day of lif…        430 Chest X-…                    1   430 1 First da…
#> 10 CT scan abdomen …        400 Chest X-…                    1   400 1 CT scan …
#> # ℹ 95 more rows
risk_equivalence("Skydiving (US)")
#> # A tibble: 101 × 6
#>    activity         micromorts reference reference_micromorts  ratio equivalence
#>    <chr>                 <dbl> <chr>                    <dbl>  <dbl> <chr>      
#>  1 Mt. Everest asc…      37932 Skydivin…                    8 4742.  1 Mt. Ever…
#>  2 Himalayan mount…      12000 Skydivin…                    8 1500   1 Himalaya…
#>  3 COVID-19 infect…      10000 Skydivin…                    8 1250   1 COVID-19…
#>  4 Spanish flu inf…       3000 Skydivin…                    8  375   1 Spanish …
#>  5 Matterhorn asce…       2840 Skydivin…                    8  355   1 Matterho…
#>  6 Living in US du…        500 Skydivin…                    8   62.5 1 Living i…
#>  7 Living (one day…        463 Skydivin…                    8   57.9 1 Living (…
#>  8 Base jumping (p…        430 Skydivin…                    8   53.8 1 Base jum…
#>  9 First day of li…        430 Skydivin…                    8   53.8 1 First da…
#> 10 CT scan abdomen…        400 Skydivin…                    8   50   1 CT scan …
#> # ℹ 91 more rows
```
