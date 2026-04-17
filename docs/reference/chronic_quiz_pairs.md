# Generate Quiz Pairs for "Which Daily Habit Has a Bigger Effect?" Game

Creates candidate question pairs from
[`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md)
for use in an interactive microlife comparison quiz. Each pair contains
two chronic lifestyle factors, and the player guesses which has the
larger absolute effect on life expectancy (in microlives per day).

## Usage

``` r
chronic_quiz_pairs(
  min_ratio = 1.1,
  max_ratio = 2,
  prefer_cross_category = TRUE,
  seed = NULL,
  difficulty = NULL
)
```

## Arguments

- min_ratio:

  Minimum ratio between absolute microlife values in a pair. Default
  1.1. Ignored when `difficulty` is non-NULL.

- max_ratio:

  Maximum ratio. Default 2.0. Ignored when `difficulty` is non-NULL.

- prefer_cross_category:

  If `TRUE` (default), pairs from different categories are prioritised.

- seed:

  Optional random seed for reproducibility.

- difficulty:

  Optional difficulty level. One of `"easy"`, `"medium"`, `"hard"`, or
  `"mixed"`. When non-NULL, overrides `min_ratio`/`max_ratio` to use the
  full pool (ratios 1.5–10) and assigns difficulty via data-driven
  terciles.

## Value

A tibble with columns:

- `factor_a`, `microlives_a`, `direction_a`, `category_a`,
  `description_a`, `help_url_a`, `annual_days_a`

- `factor_b`, `microlives_b`, `direction_b`, `category_b`,
  `description_b`, `help_url_b`, `annual_days_b`

- `ratio` (max/min of absolute microlife values)

- `answer` ("a" or "b" – whichever factor has the larger absolute
  effect)

- `difficulty` (only when `difficulty` is non-NULL)

## Examples

``` r
pairs <- chronic_quiz_pairs(seed = 42)
head(pairs)
#> # A tibble: 6 × 16
#>   factor_b            factor_a microlives_a direction_a category_a annual_days_a
#>   <chr>               <chr>           <dbl> <chr>       <chr>              <dbl>
#> 1 150 min weekly exe… Untreat…           -4 loss        Cardiovas…         -30.4
#> 2 20 min moderate ex… High su…           -1 loss        Diet                -7.6
#> 3 20 min moderate ex… Process…           -1 loss        Diet                -7.6
#> 4 20 min moderate ex… Low fib…           -1 loss        Diet                -7.6
#> 5 2nd-3rd alcoholic … Being 1…           -2 loss        Weight             -15.2
#> 6 4th-5th alcoholic … Smoking…           -1 loss        Smoking             -7.6
#> # ℹ 10 more variables: microlives_b <dbl>, direction_b <chr>, category_b <chr>,
#> #   annual_days_b <dbl>, ratio <dbl>, answer <chr>, description_a <chr>,
#> #   help_url_a <chr>, description_b <chr>, help_url_b <chr>

easy <- chronic_quiz_pairs(difficulty = "easy", seed = 42)
head(easy)
#> # A tibble: 6 × 17
#>   factor_b            factor_a microlives_a direction_a category_a annual_days_a
#>   <chr>               <chr>           <dbl> <chr>       <chr>              <dbl>
#> 1 150 min weekly exe… Smoking…          -10 loss        Smoking            -76  
#> 2 5 servings fruit/v… 2nd-3rd…           -1 loss        Alcohol             -7.6
#> 3 5 servings fruit/v… Being 5…           -1 loss        Weight              -7.6
#> 4 5 servings fruit/v… Smoking…           -1 loss        Smoking             -7.6
#> 5 Average cancer dia… Low fib…           -1 loss        Diet                -7.6
#> 6 Average cancer dia… Process…           -1 loss        Diet                -7.6
#> # ℹ 11 more variables: microlives_b <dbl>, direction_b <chr>, category_b <chr>,
#> #   annual_days_b <dbl>, ratio <dbl>, difficulty <chr>, answer <chr>,
#> #   description_a <chr>, help_url_a <chr>, description_b <chr>,
#> #   help_url_b <chr>
```
