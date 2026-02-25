# Loss of Life Expectancy (LLE)

Estimates the average time lost from a lifespan due to a specific risk.

## Usage

``` r
lle(prob, life_expectancy = 40)
```

## Arguments

- prob:

  Numeric. Probability of death.

- life_expectancy:

  Numeric. Remaining life expectancy in years (default 40).

## Value

Numeric. Loss of life expectancy in seconds, minutes, or days
(estimated).

## Examples

``` r
lle(1/1000000, 40) # Loss from 1 micromort
#> [1] 21.0384
#> attr(,"class")
#> [1] "micromort_lle" "numeric"      
#> attr(,"units")
#> [1] "minutes"
```
