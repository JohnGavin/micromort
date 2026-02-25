# Risk Sources Registry

A registry of data sources used to compile the risk datasets. Each
source has a unique identifier that links to records in acute_risks and
chronic_risks.

## Format

A tibble with 14 rows and 7 columns:

- source_id:

  Unique source identifier (e.g., "spiegelhalter_2012")

- citation:

  Full citation or source name

- primary_url:

  Primary URL

- type:

  Source type: academic, government, database, book, encyclopedia

- description:

  Brief description

- data_types:

  Types of data: acute, chronic, or both

- last_accessed:

  Date data was retrieved

## See also

Other datasets:
[`acute_risks`](https://johngavin.github.io/micromort/reference/acute_risks.md),
[`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md)

## Examples

``` r
# Load the source registry
sources <- load_sources()
sources
#> # A tibble: 14 × 7
#>    source_id     citation primary_url type  description data_types last_accessed
#>    <chr>         <chr>    <chr>       <chr> <chr>       <chr>      <date>       
#>  1 howard_1980   Howard … https://br… Acad… Original m… acute      2026-02-25   
#>  2 spiegelhalte… Spiegel… https://pu… Acad… Introduced… chronic    2026-02-25   
#>  3 norm_chronic… The Nor… https://ww… Book  Comprehens… both       2026-02-25   
#>  4 wikipedia_mi… Wikiped… https://en… Ency… Comprehens… acute      2026-02-25   
#>  5 wikipedia_mi… Wikiped… https://en… Ency… Chronic ri… chronic    2026-02-25   
#>  6 micromorts_r… micromo… https://mi… Data… Crowdsourc… acute      2026-02-25   
#>  7 understandin… Underst… https://pl… Educ… Cambridge … both       2026-02-25   
#>  8 cdc_mmwr      CDC MMWR https://ww… Gove… US mortali… acute      2026-02-25   
#>  9 cdc_life_exp… CDC Lif… https://cd… Gove… US life ex… both       2026-02-25   
#> 10 who_ghe       WHO Glo… https://ww… Gove… Global mor… both       2026-02-25   
#> 11 uk_ons        UK ONS   https://ww… Gove… UK death s… both       2026-02-25   
#> 12 nhtsa         NHTSA    https://ww… Gove… US traffic… both       2026-02-25   
#> 13 pmc_covid_ov… COVID-1… https://pm… Acad… Micromort … both       2026-02-25   
#> 14 cdc_vaccine_… CDC COV… https://ww… Gove… Vaccinated… both       2026-02-25   

# Academic sources
sources |> dplyr::filter(type == "Academic")
#> # A tibble: 3 × 7
#>   source_id      citation primary_url type  description data_types last_accessed
#>   <chr>          <chr>    <chr>       <chr> <chr>       <chr>      <date>       
#> 1 howard_1980    Howard … https://br… Acad… Original m… acute      2026-02-25   
#> 2 spiegelhalter… Spiegel… https://pu… Acad… Introduced… chronic    2026-02-25   
#> 3 pmc_covid_ove… COVID-1… https://pm… Acad… Micromort … both       2026-02-25   
```
