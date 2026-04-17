# Chronic Factor Descriptions and Help URLs

Returns a tibble of human-readable descriptions and authoritative help
URLs for all factors in
[`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md).
Useful for quiz tooltips, API responses, and dashboards.

## Usage

``` r
factor_descriptions()
```

## Value

A tibble with columns:

- `factor`: Factor name (matches
  [`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md)
  exactly)

- `description`: 1-2 sentence explanation of the factor

- `help_url`: Authoritative source URL

## Examples

``` r
factor_descriptions()
#> # A tibble: 39 × 3
#>    factor                         description                           help_url
#>    <chr>                          <chr>                                 <chr>   
#>  1 Smoking 20 cigarettes          A pack-a-day habit accelerates aging… https:/…
#>  2 Smoking 10 cigarettes          Half-a-pack daily. Dose-response is … https:/…
#>  3 Smoking 2 cigarettes           Even light smoking (2 cigarettes/day… https:/…
#>  4 Being 5 kg overweight          Each 5 kg above optimum BMI increase… https:/…
#>  5 Being 10 kg overweight         Cumulative metabolic and cardiovascu… https:/…
#>  6 Being 15 kg overweight         Significant obesity (BMI ~30+) with … https:/…
#>  7 2nd-3rd alcoholic drink        After the first drink's potential pr… https:/…
#>  8 4th-5th alcoholic drink        Heavy daily drinking (4-5 drinks) dr… https:/…
#>  9 Red meat (1 portion/day)       Daily red meat consumption is associ… https:/…
#> 10 Processed meat (1 portion/day) Bacon, sausages, ham, etc. classifie… https:/…
#> # ℹ 29 more rows
factor_descriptions() |> dplyr::filter(grepl("exercise", factor, ignore.case = TRUE))
#> # A tibble: 2 × 3
#>   factor                   description                                  help_url
#>   <chr>                    <chr>                                        <chr>   
#> 1 20 min moderate exercise Daily brisk walking or equivalent moderate … https:/…
#> 2 150 min weekly exercise  Meeting WHO physical activity guidelines re… https:/…
```
