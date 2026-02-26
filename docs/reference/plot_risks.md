# Plot Risk Comparison

Visualizes the risk of different activities in micromorts.

## Usage

``` r
plot_risks(risks = common_risks(), facet = TRUE)
```

## Arguments

- risks:

  Tibble. Dataframe of risks, defaults to
  [`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md).

- facet:

  Logical. If TRUE, splits plot into COVID-19 and Other panels (2x1
  stacked). Default is TRUE.

## Value

A ggplot2 object.

## See also

[`plot_risks_interactive()`](https://johngavin.github.io/micromort/reference/plot_risks_interactive.md),
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)

Other visualization:
[`plot_risks_interactive()`](https://johngavin.github.io/micromort/reference/plot_risks_interactive.md)

## Examples

``` r
plot_risks()

plot_risks(facet = FALSE)
```
