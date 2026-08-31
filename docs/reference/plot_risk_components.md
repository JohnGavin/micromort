# Plot Risk Components as Stacked Bar

Creates a stacked bar chart showing the breakdown of atomic risk
components for selected activities. Hedgeable components are visually
distinguished.

## Usage

``` r
plot_risk_components(activity_ids, profile = list(), risks = NULL)
```

## Arguments

- activity_ids:

  Character vector of activity IDs to plot.

- profile:

  A named list of condition variables for filtering.

- risks:

  Optional pre-computed
  [`atomic_risks()`](https://johngavin.github.io/micromort/reference/atomic_risks.md)
  tibble.

## Value

A ggplot2 object.

## See also

[`risk_components()`](https://johngavin.github.io/micromort/reference/risk_components.md),
[`atomic_risks()`](https://johngavin.github.io/micromort/reference/atomic_risks.md)

## Examples

``` r
plot_risk_components(c("flying_2h", "flying_8h", "flying_12h"))
```
