# Format Activity Name with Line Break Before Parenthetical

Inserts an HTML `<br>` before the first opening parenthesis in an
activity name, making quiz buttons more readable by separating the
qualifier.

## Usage

``` r
format_activity_name(name)
```

## Arguments

- name:

  Character string. The activity name to format.

## Value

A [`shiny::HTML()`](https://rdrr.io/pkg/shiny/man/reexports.html) object
with `<br>` inserted before `(`, or the original string wrapped in
`HTML()` if no parenthesis is present.

## Examples

``` r
format_activity_name("airline pilot (annual radiation)")
#> airline pilot<br>(annual radiation)
format_activity_name("Skydiving")
#> Skydiving
```
