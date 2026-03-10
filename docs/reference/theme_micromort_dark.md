# Dark Theme for Micromort Risk Plots

A dark-background ggplot2 theme designed for risk comparison plots.
White text on `#1a1a1a` background with subtle grid lines.

## Usage

``` r
theme_micromort_dark(label_size = 9)
```

## Arguments

- label_size:

  Numeric. Y-axis label font size. Default is 9.

## Value

A ggplot2 theme object.

## See also

Other visualization:
[`plot_risks()`](https://johngavin.github.io/micromort/reference/plot_risks.md),
[`plot_risks_interactive()`](https://johngavin.github.io/micromort/reference/plot_risks_interactive.md),
[`prepare_risks_plot()`](https://johngavin.github.io/micromort/reference/prepare_risks_plot.md)

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(mpg, wt)) + geom_point(color = "white") + theme_micromort_dark()
```
