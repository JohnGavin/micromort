# Convert Minutes to Microlives

A microlife represents a 30-minute change in life expectancy per day.
This function converts minutes of life expectancy change to microlives.

## Usage

``` r
as_microlife(minutes)
```

## Arguments

- minutes:

  Numeric. Life expectancy change in minutes.

  - Positive values = life gained (e.g., from exercise)

  - Negative values = life lost (e.g., from smoking)

## Value

Numeric. Value in microlives (same sign as input).

## Details

**Unit definition:** 1 microlife = 30 minutes of life expectancy change
per day.

**Sign convention:**

- Negative microlives = life expectancy loss (harmful)

- Positive microlives = life expectancy gain (beneficial)

## See also

[`as_micromort()`](https://johngavin.github.io/micromort/reference/as_micromort.md),
[`lle()`](https://johngavin.github.io/micromort/reference/lle.md),
[`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md)

Other conversion:
[`as_micromort()`](https://johngavin.github.io/micromort/reference/as_micromort.md),
[`as_probability()`](https://johngavin.github.io/micromort/reference/as_probability.md),
[`lle()`](https://johngavin.github.io/micromort/reference/lle.md),
[`value_of_micromort()`](https://johngavin.github.io/micromort/reference/value_of_micromort.md)

## Examples

``` r
# Smoking 20 cigarettes/day: each costs ~30 mins = -600 mins total
as_microlife(-20 * 30)  # -20 microlives (life lost)
#> [1] -20

# Exercise 20 mins/day: gains ~60 mins life expectancy
as_microlife(60)        # +2 microlives (life gained)
#> [1] 2

# Being 5kg overweight: costs ~30 mins/day
as_microlife(-30)       # -1 microlife (life lost)
#> [1] -1
```
