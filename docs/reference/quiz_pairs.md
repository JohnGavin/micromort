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
  seed = NULL,
  difficulty = NULL,
  profile = list()
)
```

## Arguments

- min_ratio:

  Minimum ratio between micromort values in a pair. Values above 1.0
  exclude identical-risk pairs that are unanswerable. Default 1.1.
  Ignored when `difficulty` is non-NULL.

- max_ratio:

  Maximum ratio between micromort values in a pair. Lower values produce
  harder questions. Default 2.0. Ignored when `difficulty` is non-NULL.

- prefer_cross_category:

  If `TRUE` (default), pairs from different risk categories are
  prioritised over same-category pairs.

- seed:

  Optional random seed for reproducibility.

- difficulty:

  Optional difficulty level. One of `"easy"`, `"medium"`, `"hard"`, or
  `"mixed"`. When non-NULL, overrides `min_ratio` and `max_ratio` to use
  the full pool (ratios 1.5–10) and assigns difficulty

  based on data-driven terciles:

  - **hard**: lowest third of ratios (hardest to distinguish)

  - **medium**: middle third

  - **easy**: highest third (easiest to distinguish)

  - **mixed**: samples equally from all three tiers

  When `NULL` (default), the original `min_ratio`/`max_ratio` behaviour
  is preserved and no `difficulty` column is added.

- profile:

  A named list of condition variables for filtering conditional risks,
  passed to
  [`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md).
  E.g. `list(country = "US")` to include country-specific disease
  mortality in the quiz pool. Default
  [`list()`](https://rdrr.io/r/base/list.html) uses population-average
  unconditional risks only.

## Value

A tibble with columns:

- `activity_a`, `micromorts_a`, `category_a`, `hedgeable_pct_a`,
  `period_a`

- `activity_b`, `micromorts_b`, `category_b`, `hedgeable_pct_b`,
  `period_b`

- `description_a`, `help_url_a`, `description_b`, `help_url_b`

- `ratio` (max/min of the two micromort values)

- `answer` ("a" or "b" — whichever activity is riskier)

- `difficulty` (only when `difficulty` is non-NULL)

## Examples

``` r
pairs <- quiz_pairs(seed = 42)
head(pairs)
#> # A tibble: 6 × 16
#>   activity_b         activity_a micromorts_a category_a hedgeable_pct_a period_a
#>   <chr>              <chr>             <dbl> <chr>                <dbl> <chr>   
#> 1 All US workers ba… Commuting…         0.13 Travel                   0 per trip
#> 2 American football  COVID-19 …        23    COVID-19                 0 11 week…
#> 3 Annual tourist fl… Scuba div…         5    Sport                    0 per dive
#> 4 Base jumping (per… Living in…       500    COVID-19                 0 per mon…
#> 5 Business travelle… COVID-19 …        23    COVID-19                 0 11 week…
#> 6 Business travelle… US milita…        25    Military                 0 per day 
#> # ℹ 10 more variables: micromorts_b <dbl>, category_b <chr>,
#> #   hedgeable_pct_b <dbl>, period_b <chr>, ratio <dbl>, answer <chr>,
#> #   description_a <chr>, help_url_a <chr>, description_b <chr>,
#> #   help_url_b <chr>

# Easy questions (large ratio differences)
easy <- quiz_pairs(difficulty = "easy", seed = 42)
head(easy)
#> # A tibble: 6 × 17
#>   activity_b         activity_a micromorts_a category_a hedgeable_pct_a period_a
#>   <chr>              <chr>             <dbl> <chr>                <dbl> <chr>   
#> 1 Agriculture (per … Annual to…          4.2 Travel                   0 per year
#> 2 American football  Vaginal b…        120   Medical                  0 per eve…
#> 3 Annual tourist fl… US milita…         25   Military                 0 per day 
#> 4 Annual tourist fl… Skiing              0.7 Sport                    0 per day 
#> 5 Barium enema (rad… Living in…         50   COVID-19                 0 per 8 w…
#> 6 Business travelle… Caesarean…        170   Medical                  0 per eve…
#> # ℹ 11 more variables: micromorts_b <dbl>, category_b <chr>,
#> #   hedgeable_pct_b <dbl>, period_b <chr>, ratio <dbl>, difficulty <chr>,
#> #   answer <chr>, description_a <chr>, help_url_a <chr>, description_b <chr>,
#> #   help_url_b <chr>

# Country-specific quiz with Nigerian disease risk
ng_pairs <- quiz_pairs(profile = list(country = "NG"), seed = 42)
head(ng_pairs)
#> # A tibble: 6 × 16
#>   activity_b         activity_a micromorts_a category_a hedgeable_pct_a period_a
#>   <chr>              <chr>             <dbl> <chr>                <dbl> <chr>   
#> 1 All US workers ba… Commuting…         0.13 Travel                   0 per trip
#> 2 American football  COVID-19 …        23    COVID-19                 0 11 week…
#> 3 Annual tourist fl… Scuba div…         5    Sport                    0 per dive
#> 4 Base jumping (per… Living in…       500    COVID-19                 0 per mon…
#> 5 Business travelle… US milita…        25    Military                 0 per day 
#> 6 COVID-19 infectio… Himalayan…     12000    Mountaine…               0 per exp…
#> # ℹ 10 more variables: micromorts_b <dbl>, category_b <chr>,
#> #   hedgeable_pct_b <dbl>, period_b <chr>, ratio <dbl>, answer <chr>,
#> #   description_a <chr>, help_url_a <chr>, description_b <chr>,
#> #   help_url_b <chr>
```
