# Value of a Statistical Life (VSL) to Micromort Value

Calculates the monetary value of one micromort based on the Value of a
Statistical Life (VSL).

## Usage

``` r
value_of_micromort(vsl = 1e+07)
```

## Arguments

- vsl:

  Numeric. Value of a Statistical Life (default \$10,000,000).

## Value

Numeric value of one micromort.

## See also

[`as_micromort()`](https://johngavin.github.io/micromort/reference/as_micromort.md),
[`lle()`](https://johngavin.github.io/micromort/reference/lle.md)

Other conversion:
[`as_microlife()`](https://johngavin.github.io/micromort/reference/as_microlife.md),
[`as_micromort()`](https://johngavin.github.io/micromort/reference/as_micromort.md),
[`as_probability()`](https://johngavin.github.io/micromort/reference/as_probability.md),
[`lle()`](https://johngavin.github.io/micromort/reference/lle.md)

## Examples

``` r
value_of_micromort(10000000) # $10
#> [1] 10
```
