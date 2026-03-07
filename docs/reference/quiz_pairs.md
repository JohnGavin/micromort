# Generate Quiz Pairs for "Which Is Riskier?" Game

Creates candidate question pairs from
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)
for use in an interactive risk comparison quiz. Each pair contains two
activities with similar micromort values, making the comparison
challenging and educational.

## Usage

``` r
quiz_pairs(max_ratio = 2, prefer_cross_category = TRUE, seed = NULL)
```

## Arguments

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

- `activity_a`, `micromorts_a`, `category_a`, `hedgeable_pct_a`

- `activity_b`, `micromorts_b`, `category_b`, `hedgeable_pct_b`

- `ratio` (max/min of the two micromort values)

- `answer` ("a" or "b" — whichever activity is riskier)

## Examples

``` r
pairs <- quiz_pairs(seed = 42)
head(pairs)
#> # A tibble: 6 × 10
#>   activity_a     micromorts_a category_a hedgeable_pct_a activity_b micromorts_b
#>   <chr>                 <dbl> <chr>                <dbl> <chr>             <dbl>
#> 1 Mammogram (ra…          0.1 Medical                  0 Nuclear p…          0.1
#> 2 Living (one d…          1   Daily Life               0 COVID-19 …          1  
#> 3 Base jumping …        430   Sport                    0 First day…        430  
#> 4 Living 2 mont…          1   Environme…               0 Driving (…          1  
#> 5 COVID-19 unva…          8   COVID-19                 0 Hang glid…          8  
#> 6 Living (one d…          1   Daily Life               0 COVID-19 …          1  
#> # ℹ 4 more variables: category_b <chr>, hedgeable_pct_b <dbl>, ratio <dbl>,
#> #   answer <chr>
```
