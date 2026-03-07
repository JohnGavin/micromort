# Launch Interactive "Which Is Riskier?" Quiz

A standalone Shiny app where users compare pairs of risky activities and
guess which carries more micromort risk. Built with bslib cards for a
modern UI.

## Usage

``` r
launch_quiz(n_pairs = NULL, ...)
```

## Arguments

- n_pairs:

  Number of question pairs to offer as options (5 or 10). If `NULL`
  (default), the user chooses on the instructions page.

- ...:

  Additional arguments passed to
  [`shiny::shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html).

## Value

A Shiny app object (runs interactively).

## Examples

``` r
if (interactive()) {
  launch_quiz()
}
```
