# Acute Risks Dataset

A curated dataset of acute mortality risks measured in micromorts. One
micromort equals a one-in-a-million chance of death.

## Format

A tibble with 62 rows and 15 columns:

- record_id:

  Unique record identifier (source_id + sequence)

- activity:

  Human-readable activity name

- activity_normalized:

  Standardized activity name for grouping

- micromorts:

  Risk in micromorts (1 = one-in-a-million death risk)

- microlives:

  Equivalent in microlives (micromorts × 0.7)

- category:

  Activity category (Sport, Travel, Medical, etc.)

- period:

  Time period for risk (per event, per day, per year)

- period_normalized:

  Standardized period (event, day, week, month, year)

- age_group:

  Applicable age group (all, 18-49, 65+, etc.)

- geography:

  Geographic scope (global, US, UK, etc.)

- year:

  Year of data collection

- source_id:

  Source identifier (foreign key to risk_sources)

- source_url:

  Direct URL to source

- confidence:

  Data quality level (high, medium, low)

- last_accessed:

  Date data was retrieved

## Source

- Wikipedia: <https://en.wikipedia.org/wiki/Micromort>

- micromorts.rip: <https://micromorts.rip/>

- CDC MMWR: <https://www.cdc.gov/mmwr/>

## Details

Data is compiled from multiple sources including Wikipedia,
micromorts.rip, and CDC MMWR reports. Multiple estimates for the same
activity may exist from different sources.

## References

Howard RA (1980). "On Making Life and Death Decisions." In Schwing &
Albers (eds), Societal Risk Assessment.

## See also

Other datasets:
[`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md),
[`risk_sources`](https://johngavin.github.io/micromort/reference/risk_sources.md)

## Examples

``` r
# Load the acute risks dataset
acute <- load_acute_risks()
head(acute)
#> # A tibble: 6 × 15
#>   record_id   activity activity_normalized micromorts microlives category period
#>   <chr>       <chr>    <chr>                    <dbl>      <dbl> <chr>    <chr> 
#> 1 micromorts… Mt. Eve… mt. everest ascent       37932     26552. Mountai… per a…
#> 2 micromorts… Himalay… himalayan mountain…      12000      8400  Mountai… per e…
#> 3 micromorts… COVID-1… covid-19 infection       10000      7000  Disease  per i…
#> 4 micromorts… Spanish… spanish flu infect…       3000      2100  Disease  per i…
#> 5 micromorts… Matterh… matterhorn ascent         2840      1988  Mountai… per a…
#> 6 micromorts… Living … living in us durin…        500       350  Disease  per m…
#> # ℹ 8 more variables: period_normalized <chr>, age_group <chr>,
#> #   geography <chr>, year <dbl>, source_id <chr>, source_url <chr>,
#> #   confidence <chr>, last_accessed <date>

# Filter by category
acute |> dplyr::filter(category == "Sport")
#> # A tibble: 13 × 15
#>    record_id  activity activity_normalized micromorts microlives category period
#>    <chr>      <chr>    <chr>                    <dbl>      <dbl> <chr>    <chr> 
#>  1 micromort… Base ju… base jumping             430        301   Sport    per e…
#>  2 micromort… Scuba d… scuba diving             164        115.  Sport    per y…
#>  3 micromort… America… american football         20         14   Sport    per g…
#>  4 micromort… Swimmin… swimming                  12          8.4 Sport    per s…
#>  5 micromort… Skydivi… skydiving                 10          7   Sport    per e…
#>  6 micromort… Skydivi… skydiving                  8          5.6 Sport    per e…
#>  7 micromort… Skydivi… skydiving                  8          5.6 Sport    per e…
#>  8 micromort… Hang gl… hang gliding               8          5.6 Sport    per e…
#>  9 wikipedia… Running… running a marathon         7          4.9 Sport    per e…
#> 10 wikipedia… Scuba d… scuba diving               5          3.5 Sport    per e…
#> 11 micromort… Rock cl… rock climbing              3          2.1 Sport    per e…
#> 12 micromort… Skiing … skiing                     0.7        0.5 Sport    per d…
#> 13 micromort… Horseba… horseback riding           0.5        0.3 Sport    per r…
#> # ℹ 8 more variables: period_normalized <chr>, age_group <chr>,
#> #   geography <chr>, year <dbl>, source_id <chr>, source_url <chr>,
#> #   confidence <chr>, last_accessed <date>

# Top 10 riskiest activities
acute |> dplyr::slice_max(micromorts, n = 10)
#> # A tibble: 10 × 15
#>    record_id  activity activity_normalized micromorts microlives category period
#>    <chr>      <chr>    <chr>                    <dbl>      <dbl> <chr>    <chr> 
#>  1 micromort… Mt. Eve… mt. everest ascent       37932     26552. Mountai… per a…
#>  2 micromort… Himalay… himalayan mountain…      12000      8400  Mountai… per e…
#>  3 micromort… COVID-1… covid-19 infection       10000      7000  Disease  per i…
#>  4 micromort… Spanish… spanish flu infect…       3000      2100  Disease  per i…
#>  5 micromort… Matterh… matterhorn ascent         2840      1988  Mountai… per a…
#>  6 micromort… Living … living in us durin…        500       350  Disease  per m…
#>  7 micromort… Living … living                     463       324. Daily L… per d…
#>  8 micromort… Base ju… base jumping               430       301  Sport    per e…
#>  9 micromort… First d… first day of life          430       301  Daily L… per d…
#> 10 cdc_mmwr_… COVID-1… covid-19 unvaccina…        234       164. COVID-19 11 we…
#> # ℹ 8 more variables: period_normalized <chr>, age_group <chr>,
#> #   geography <chr>, year <dbl>, source_id <chr>, source_url <chr>,
#> #   confidence <chr>, last_accessed <date>
```
