# Acute Risks in Micromorts

A comprehensive dataset of activities and their associated acute
mortality risk in micromorts, with calculated microlives and source
references.

## Usage

``` r
common_risks()
```

## Value

A tibble with columns:

- activity:

  Activity name

- micromorts:

  Risk in micromorts (1 = 1-in-a-million death probability)

- microlives:

  Equivalent microlives (micromorts × 0.7)

- category:

  Activity category

- period:

  Human-readable period description

- period_type:

  Normalized period type: "event", "day", "hour", "year", "period"

- period_days:

  Typical duration in days (for cross-activity comparison)

- source_url:

  Data source URL

## Details

Micromort: one-in-a-million chance of death (acute risk). Microlife: 30
minutes of life expectancy lost.

Data sources: Wikipedia, micromorts.rip, CDC MMWR, academic literature.

## References

Howard RA (1980). "On Making Life and Death Decisions." In Schwing &
Albers (eds), Societal Risk Assessment: How Safe Is Safe Enough?

<https://en.wikipedia.org/wiki/Micromort>

<https://micromorts.rip/>

## Examples

``` r
common_risks()
#> # A tibble: 62 × 9
#>    activity        micromorts microlives category period period_type period_days
#>    <chr>                <dbl>      <dbl> <chr>    <chr>  <chr>             <dbl>
#>  1 Mt. Everest as…      37932     26552. Mountai… per a… event                60
#>  2 Himalayan moun…      12000      8400  Mountai… per e… event                45
#>  3 COVID-19 infec…      10000      7000  COVID-19 per i… event                14
#>  4 Spanish flu in…       3000      2100  Disease  per i… event                14
#>  5 Matterhorn asc…       2840      1988  Mountai… per a… event                60
#>  6 Living in US d…        500       350  COVID-19 per m… month                30
#>  7 Living (one da…        463       324. Daily L… per d… day                   1
#>  8 Base jumping (…        430       301  Sport    per e… event                 1
#>  9 First day of l…        430       301  Daily L… per d… day                   1
#> 10 COVID-19 unvac…        234       164. COVID-19 11 we… period               77
#> # ℹ 52 more rows
#> # ℹ 2 more variables: micromorts_per_day <dbl>, source_url <chr>
common_risks() |> dplyr::filter(category == "COVID-19")
#> # A tibble: 19 × 9
#>    activity        micromorts microlives category period period_type period_days
#>    <chr>                <dbl>      <dbl> <chr>    <chr>  <chr>             <dbl>
#>  1 COVID-19 infec…   10000        7000   COVID-19 per i… event                14
#>  2 Living in US d…     500         350   COVID-19 per m… month                30
#>  3 COVID-19 unvac…     234         164.  COVID-19 11 we… period               77
#>  4 COVID-19 unvac…      76          53.2 COVID-19 11 we… period               77
#>  5 COVID-19 monov…      55          38.5 COVID-19 11 we… period               77
#>  6 Living in NYC …      50          35   COVID-19 per 8… period               56
#>  7 COVID-19 bival…      23          16.1 COVID-19 11 we… period               77
#>  8 COVID-19 unvac…      20          14   COVID-19 11 we… period               77
#>  9 COVID-19 monov…       9           6.3 COVID-19 11 we… period               77
#> 10 COVID-19 unvac…       8           5.6 COVID-19 11 we… period               77
#> 11 Living in Mary…       7           4.9 COVID-19 per 8… period               56
#> 12 COVID-19 monov…       4           2.8 COVID-19 11 we… period               77
#> 13 COVID-19 bival…       3           2.1 COVID-19 11 we… period               77
#> 14 COVID-19 monov…       2           1.4 COVID-19 11 we… period               77
#> 15 COVID-19 unvac…       1           0.7 COVID-19 11 we… period               77
#> 16 COVID-19 bival…       1           0.7 COVID-19 11 we… period               77
#> 17 COVID-19 bival…       1           0.7 COVID-19 11 we… period               77
#> 18 COVID-19 monov…       0.2         0.1 COVID-19 11 we… period               77
#> 19 COVID-19 bival…       0.05        0   COVID-19 11 we… period               77
#> # ℹ 2 more variables: micromorts_per_day <dbl>, source_url <chr>
common_risks() |> dplyr::filter(micromorts > 100)
#> # A tibble: 14 × 9
#>    activity        micromorts microlives category period period_type period_days
#>    <chr>                <dbl>      <dbl> <chr>    <chr>  <chr>             <dbl>
#>  1 Mt. Everest as…      37932    26552.  Mountai… per a… event                60
#>  2 Himalayan moun…      12000     8400   Mountai… per e… event                45
#>  3 COVID-19 infec…      10000     7000   COVID-19 per i… event                14
#>  4 Spanish flu in…       3000     2100   Disease  per i… event                14
#>  5 Matterhorn asc…       2840     1988   Mountai… per a… event                60
#>  6 Living in US d…        500      350   COVID-19 per m… month                30
#>  7 Living (one da…        463      324.  Daily L… per d… day                   1
#>  8 Base jumping (…        430      301   Sport    per e… event                 1
#>  9 First day of l…        430      301   Daily L… per d… day                   1
#> 10 COVID-19 unvac…        234      164.  COVID-19 11 we… period               77
#> 11 Caesarean birt…        170      119   Medical  per e… event                 1
#> 12 Scuba diving (…        164      115.  Sport    per y… year                365
#> 13 Vaginal birth …        120       84   Medical  per e… event                 1
#> 14 Living (one da…        105       73.5 Daily L… per d… day                   1
#> # ℹ 2 more variables: micromorts_per_day <dbl>, source_url <chr>
```
