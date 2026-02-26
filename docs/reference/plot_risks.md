# Plot Risk Comparison

Visualizes the risk of different activities in micromorts.

## Usage

``` r
plot_risks(risks = common_risks(), facet = TRUE)
```

## Arguments

- risks:

  Tibble. Dataframe of risks, defaults to common_risks().

- facet:

  Logical. If TRUE, splits plot into COVID-19 and Other panels (2x1
  stacked). Default is TRUE.

## Value

A ggplot2 object.

## Examples

``` r
plot_risks()

plot_risks(facet = FALSE)
```
