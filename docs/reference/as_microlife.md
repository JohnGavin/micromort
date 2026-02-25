# Convert to Microlives

A microlife represents a 30-minute change in life expectancy. This
function estimates the impact of a chronic risk in microlives.

## Usage

``` r
as_microlife(minutes_lost)
```

## Arguments

- minutes_lost:

  Numeric. Life expectancy lost in minutes.

## Value

Numeric. Value in microlives.

## Examples

``` r
as_microlife(30) # 1 microlife
#> [1] 1
```
