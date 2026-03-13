# Activity Descriptions and Help URLs

Returns a tibble of human-readable descriptions and authoritative help
URLs for all activities in
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md).
Useful for quiz tooltips, API responses, and dashboards.

## Usage

``` r
activity_descriptions()
```

## Value

A tibble with columns:

- `activity`: Activity name (matches
  [`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)
  exactly)

- `description`: 1-2 sentence explanation of the risk

- `help_url`: Authoritative source URL (Wikipedia or similar)

## Examples

``` r
activity_descriptions()
#> # A tibble: 119 × 3
#>    activity                                description                  help_url
#>    <chr>                                   <chr>                        <chr>   
#>  1 Mt. Everest ascent                      At 8,849m, extreme altitude… https:/…
#>  2 Himalayan mountaineering                Expeditions to 8,000m+ peak… https:/…
#>  3 COVID-19 infection (unvaccinated)       Unvaccinated COVID-19 infec… https:/…
#>  4 Spanish flu infection                   The 1918 influenza pandemic… https:/…
#>  5 Matterhorn ascent                       One of the Alps' deadliest … https:/…
#>  6 Living in US during COVID-19 (Jul 2020) Peak US COVID-19 mortality … https:/…
#>  7 Living (one day, age 90)                Daily background mortality … https:/…
#>  8 Base jumping                            Parachuting from fixed obje… https:/…
#>  9 First day of life (newborn)             The first 24 hours carry el… https:/…
#> 10 COVID-19 unvaccinated (age 80+)         Unvaccinated elderly face t… https:/…
#> # ℹ 109 more rows
activity_descriptions() |> dplyr::filter(grepl("Skydiving", activity))
#> # A tibble: 3 × 3
#>   activity       description                                            help_url
#>   <chr>          <chr>                                                  <chr>   
#> 1 Skydiving      Risk from parachute malfunction, mid-air collision, a… https:/…
#> 2 Skydiving (US) US skydiving fatality rate based on USPA incident rep… https:/…
#> 3 Skydiving (UK) UK skydiving fatality rate based on British Parachute… https:/…
```
