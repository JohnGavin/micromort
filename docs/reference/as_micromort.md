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

## See also

[`as_probability()`](https://johngavin.github.io/micromort/reference/as_probability.md),
[`as_microlife()`](https://johngavin.github.io/micromort/reference/as_microlife.md),
[`value_of_micromort()`](https://johngavin.github.io/micromort/reference/value_of_micromort.md)

Other conversion:
[`as_microlife()`](https://johngavin.github.io/micromort/reference/as_microlife.md),
[`as_probability()`](https://johngavin.github.io/micromort/reference/as_probability.md),
[`lle()`](https://johngavin.github.io/micromort/reference/lle.md),
[`value_of_micromort()`](https://johngavin.github.io/micromort/reference/value_of_micromort.md)

## Examples

``` r
as_micromort(1/1000000) # 1 micromort
#> [1] 1
as_micromort(1/10000)   # 100 micromorts
#> [1] 100
```
