# Plot Risk Comparison

Visualizes the risk of different activities in micromorts. For filtering
by category, use
[`prepare_risks_plot()`](https://johngavin.github.io/micromort/reference/prepare_risks_plot.md)
first.

## Usage

``` r
plot_risks(
  risks = common_risks(),
  facet = TRUE,
  height = 12,
  label_size = 9,
  dark = TRUE,
  guide_lines = TRUE,
  jitter_ones = TRUE,
  cluster_bands = TRUE
)
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

  Numeric. Plot height in inches. Default is 12.

- label_size:

  Numeric. Y-axis label font size. Default is 9.

- dark:

  Logical. If TRUE (default), use
  [`theme_micromort_dark()`](https://johngavin.github.io/micromort/reference/theme_micromort_dark.md).
  If FALSE, use `theme_minimal()`.

- guide_lines:

  Logical. If TRUE (default), add dashed guide lines from y-axis labels
  to bar starts.

- jitter_ones:

  Logical. If TRUE (default), shift 1-micromort values slightly so bars
  are visible on log scale.

- cluster_bands:

  Logical. If TRUE (default), add subtle background bands grouping risks
  with similar micromort values.

## Value

A ggplot2 object.

## See also

[`prepare_risks_plot()`](https://johngavin.github.io/micromort/reference/prepare_risks_plot.md),
[`plot_risks_interactive()`](https://johngavin.github.io/micromort/reference/plot_risks_interactive.md),
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)

Other visualization:
[`plot_risks_interactive()`](https://johngavin.github.io/micromort/reference/plot_risks_interactive.md),
[`prepare_risks_plot()`](https://johngavin.github.io/micromort/reference/prepare_risks_plot.md),
[`theme_micromort_dark()`](https://johngavin.github.io/micromort/reference/theme_micromort_dark.md)

## Examples

``` r
# Default dark plot
plot_risks()
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.


# Light theme
plot_risks(dark = FALSE)
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.


# Filter then plot
prepare_risks_plot(categories = "Sport") |> plot_risks()
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.


# Exclude COVID-19 and show top 20
prepare_risks_plot(exclude_categories = "COVID-19", top_n = 20) |>
  plot_risks(facet = FALSE)
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
#> Warning: log-10 transformation introduced infinite values.
```
