# Generate Quiz Pairs for "Which Is Riskier?" Game

Creates candidate question pairs from
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)
for use in an interactive risk comparison quiz. Each pair contains two
activities with similar micromort values, making the comparison
challenging and educational.

## Usage

``` r
quiz_pairs(
  min_ratio = 1.1,
  max_ratio = 2,
  prefer_cross_category = TRUE,
  seed = NULL
)
```

## Arguments

- min_ratio:

  Minimum ratio between micromort values in a pair. Values above 1.0
  exclude identical-risk pairs that are unanswerable. Default 1.1.

- max_ratio:

  Maximum ratio between micromort values in a pair. Lower values produce
  harder questions. Default 2.0.

- prefer_cross_category:

  If `TRUE` (default), pairs from different risk categories are
  prioritised over same-category pairs.

- seed:

  Optional random seed for reproducibility.

## Value

A tibble with columns:

- `activity_a`, `micromorts_a`, `category_a`, `hedgeable_pct_a`,
  `period_a`

- `activity_b`, `micromorts_b`, `category_b`, `hedgeable_pct_b`,
  `period_b`

- `ratio` (max/min of the two micromort values)

- `answer` ("a" or "b" — whichever activity is riskier)

## Examples

``` r
pairs <- quiz_pairs(seed = 42)
head(pairs)
#> # A tibble: 6 × 12
#>   activity_a         micromorts_a category_a hedgeable_pct_a period_a activity_b
#>   <chr>                     <dbl> <chr>                <dbl> <chr>    <chr>     
#> 1 Ecstasy/MDMA (per…       13     Drugs                    0 per dose CT scan a…
#> 2 Skydiving (UK)            8     Sport                    0 per eve… Flying (1…
#> 3 COVID-19 unvaccin…        1     COVID-19                 0 11 week… Flying (2…
#> 4 Interventional ca…        0.175 Occupation             100 per year Frequent …
#> 5 Skydiving (UK)            8     Sport                    0 per eve… Living in…
#> 6 Skydiving (US)            8     Sport                    0 per eve… Flying (1…
#> # ℹ 6 more variables: micromorts_b <dbl>, category_b <chr>,
#> #   hedgeable_pct_b <dbl>, period_b <chr>, ratio <dbl>, answer <chr>
```
