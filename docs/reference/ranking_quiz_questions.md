# Generate Ranking Quiz Questions

Creates questions for the ranking quiz by combining acute (micromort)
and chronic (microlife) risks, converting to a common Loss of Life
Expectancy (LLE) scale, and grouping into rankable sets.

## Usage

``` r
ranking_quiz_questions(
  tags = NULL,
  items_per_question = 3L,
  n_questions = 5L,
  seed = NULL,
  difficulty = NULL,
  profile = list()
)
```

## Arguments

- tags:

  Character vector of tags to include (e.g. "Radiation", "Travel"). Use
  `NULL` for all tags. See
  [`ranking_tag_mapping()`](https://johngavin.github.io/micromort/reference/ranking_tag_mapping.md)
  for available tags.

- items_per_question:

  Integer. Number of items per question (2, 3, or 4). Default 3.

- n_questions:

  Integer. Number of questions to generate. Default 5.

- seed:

  Optional integer seed for reproducibility.

- difficulty:

  Optional difficulty level: "easy", "medium", "hard", or "mixed". Easy
  = large LLE spread within question, hard = small spread.

- profile:

  A named list of condition variables for filtering conditional risks,
  passed to
  [`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md).
  E.g. `list(country = "NG")` to include Nigerian disease mortality in
  the acute risk pool. Default
  [`list()`](https://rdrr.io/r/base/list.html).

## Value

A tibble with columns:

- `question_id`, `tag`, `item_name`, `item_source` ("acute"/"chronic"),
  `lle_minutes`, `micromorts`, `microlives_per_day`, `category`,
  `description`, `help_url`, `correct_rank`, `difficulty`

## Examples

``` r
ranking_quiz_questions(tags = "Travel", n_questions = 3, seed = 42)
#> # A tibble: 9 × 12
#>   question_id tag    item_name                item_source lle_minutes micromorts
#>         <int> <chr>  <chr>                    <chr>             <dbl>      <dbl>
#> 1           1 Travel Flying (12h ultra-long-… acute            139.         6.6 
#> 2           1 Travel Train (1000 miles)       acute             21.0        1   
#> 3           1 Travel Commuting by bicycle (3… acute              2.52       0.12
#> 4           2 Travel Flying (8h long-haul)    acute             82.0        3.9 
#> 5           2 Travel Frequent executive flye… acute              3.16       0.15
#> 6           2 Travel Walking (1 trip, NYC)    acute              1.89       0.09
#> 7           3 Travel Flying (2h short-haul)   acute             23.1        1.1 
#> 8           3 Travel Driving (230 miles)      acute             21.0        1   
#> 9           3 Travel Commuting by car (30 mi… acute              2.73       0.13
#> # ℹ 6 more variables: microlives_per_day <dbl>, category <chr>,
#> #   description <chr>, help_url <chr>, correct_rank <int>, difficulty <chr>
```
