# Convert Micromorts to Probability

Convert Micromorts to Probability

## Usage

``` r
as_probability(micromorts)
```

## Arguments

- micromorts:

  Numeric. Risk in micromorts.

## Value

Numeric probability.

## See also

[`as_micromort()`](https://johngavin.github.io/micromort/reference/as_micromort.md),
[`as_microlife()`](https://johngavin.github.io/micromort/reference/as_microlife.md)

Other conversion:
[`as_microlife()`](https://johngavin.github.io/micromort/reference/as_microlife.md),
[`as_micromort()`](https://johngavin.github.io/micromort/reference/as_micromort.md),
[`lle()`](https://johngavin.github.io/micromort/reference/lle.md),
[`value_of_micromort()`](https://johngavin.github.io/micromort/reference/value_of_micromort.md)

## Examples

``` r
as_probability(1) # 1e-6
#> [1] 1e-06
```
