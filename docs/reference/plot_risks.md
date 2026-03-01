# Plot Risk Comparison

Visualizes the risk of different activities in micromorts. For filtering
by category, use
[`prepare_risks_plot()`](https://johngavin.github.io/micromort/reference/prepare_risks_plot.md)
first.

## Usage

``` r
plot_risks(risks = common_risks(), facet = TRUE, height = 12, label_size = 9)
```

## Arguments

- risks:

  Tibble. Dataframe of risks from
  [`prepare_risks_plot()`](https://johngavin.github.io/micromort/reference/prepare_risks_plot.md)
  or
  [`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md).
  If not pre-filtered, applies default filtering.

- facet:

  Logical. If TRUE, splits plot into COVID-19 and Other panels. Default
  is TRUE.

- height:

  Numeric. Plot height in inches. Default is 12 (doubled from previous
  default of 6) to prevent label overlap.

- label_size:

  Numeric. Y-axis label font size. Default is 9.

## Value

A ggplot2 object.

## See also

[`prepare_risks_plot()`](https://johngavin.github.io/micromort/reference/prepare_risks_plot.md),
[`plot_risks_interactive()`](https://johngavin.github.io/micromort/reference/plot_risks_interactive.md),
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)

Other visualization:
[`plot_risks_interactive()`](https://johngavin.github.io/micromort/reference/plot_risks_interactive.md),
[`prepare_risks_plot()`](https://johngavin.github.io/micromort/reference/prepare_risks_plot.md)

## Examples

``` r
# Default plot (all risks)
plot_risks()


# Without faceting
plot_risks(facet = FALSE)


# Filter then plot
prepare_risks_plot(categories = "Sport") |> plot_risks()


# Exclude COVID-19 and show top 20
prepare_risks_plot(exclude_categories = "COVID-19", top_n = 20) |>
  plot_risks(facet = FALSE)


# Custom height for many categories
prepare_risks_plot(top_n = 50) |> plot_risks(height = 16)
```
