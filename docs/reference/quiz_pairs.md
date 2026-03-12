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

- `description_a`, `help_url_a`, `description_b`, `help_url_b`

- `ratio` (max/min of the two micromort values)

- `answer` ("a" or "b" — whichever activity is riskier)

## Examples

``` r
pairs <- quiz_pairs(seed = 42)
head(pairs)
#> # A tibble: 6 × 16
#>   activity_b         activity_a micromorts_a category_a hedgeable_pct_a period_a
#>   <chr>              <chr>             <dbl> <chr>                <dbl> <chr>   
#> 1 Airline pilot (an… Commuting…         0.13 Travel                   0 per trip
#> 2 American football  COVID-19 …        23    COVID-19                 0 11 week…
#> 3 American football  US milita…        25    Military                 0 per day 
#> 4 Base jumping       Living in…       500    COVID-19                 0 per mon…
#> 5 Business travelle… Working i…         0.03 Daily Life               0 per day 
#> 6 COVID-19 infectio… Himalayan…     12000    Mountaine…               0 per exp…
#> # ℹ 10 more variables: micromorts_b <dbl>, category_b <chr>,
#> #   hedgeable_pct_b <dbl>, period_b <chr>, ratio <dbl>, answer <chr>,
#> #   description_a <chr>, help_url_a <chr>, description_b <chr>,
#> #   help_url_b <chr>
```
