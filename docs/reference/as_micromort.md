# Convert Probability to Micromorts

A micromort represents a one-in-a-million chance of death. This function
converts a raw probability of death into micromorts.

## Usage

``` r
as_micromort(prob)
```

## Arguments

- prob:

  Numeric. Probability of death (0 to 1).

## Value

Numeric value in micromorts.

## Examples

``` r
as_micromort(1/1000000) # 1 micromort
#> [1] 1
as_micromort(1/10000)   # 100 micromorts
#> [1] 100
```
