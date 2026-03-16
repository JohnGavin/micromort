# Launch Interactive "Which Daily Habit Has a Bigger Effect?" Quiz

A standalone Shiny app where users compare pairs of chronic lifestyle
factors and guess which has the larger absolute effect on life
expectancy (microlives per day). Built with bslib cards for a modern UI.

## Usage

``` r
launch_chronic_quiz(n_pairs = NULL, ...)
```

## Arguments

- n_pairs:

  Number of question pairs. If `NULL` (default), the user chooses on the
  instructions page.

- ...:

  Additional arguments passed to
  [`shiny::shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html).

## Value

A Shiny app object (runs interactively).

## Examples

``` r
if (interactive()) {
  launch_chronic_quiz()
}
```
