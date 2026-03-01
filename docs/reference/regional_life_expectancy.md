# Regional Life Expectancy in Western Europe

Life expectancy at birth by NUTS2 region for Western European countries,
based on Eurostat data and the methodology from Bonnet et al. (2026).

## Usage

``` r
regional_life_expectancy(
  country = NULL,
  year = NULL,
  sex = NULL,
  classification = NULL
)
```

## Arguments

- country:

  Character vector. Filter to specific countries using ISO 2-letter
  codes (e.g., "FR", "DE", "ES"). Default `NULL` returns all countries.

- year:

  Integer or vector. Filter to specific years. Default `NULL` returns
  all years (1992-2023).

- sex:

  Character. Filter by sex: "Male", "Female", or "Total". Default `NULL`
  returns all.

- classification:

  Character. Filter by region classification: "vanguard", "average", or
  "laggard". Default `NULL` returns all.

## Value

A tibble with columns:

- region_code:

  NUTS2 region code (e.g., "FR10" for Île-de-France)

- region_name:

  Human-readable region name

- country_code:

  ISO 2-letter country code

- year:

  Data year (1992-2023)

- sex:

  Sex category: "Male", "Female", or "Total"

- life_expectancy:

  Life expectancy at birth in years

- microlives_vs_eu_avg:

  Daily microlives difference vs EU average

- classification:

  "vanguard", "average", or "laggard" based on 2019 trends

- source_url:

  DOI link to source publication

## Details

### Data Structure: Aggregated Population Statistics

**Each row represents one region-year-sex combination**, NOT individual
survey responses. For example, a dataset with 450 regions × 28 years × 3
sex categories = 37,800 rows of aggregated statistics.

|  |  |  |  |  |
|----|----|----|----|----|
| region_code | year | sex | life_expectancy | Meaning |
| FR10 | 2019 | Male | 82.5 | Avg LE for all males in Île-de-France in 2019 |
| FR10 | 2019 | Female | 87.1 | Avg LE for all females in Île-de-France in 2019 |
| FR10 | 2019 | Total | 84.8 | Avg LE for entire population of Île-de-France in 2019 |

The underlying Eurostat data represents **~400 million people** across
Western Europe. Life expectancy is calculated from official death
registrations and census population counts—not a sample survey.

### Data Source

Primary data from Eurostat dataset `demo_r_mlifexp`. Regional
classifications based on Bonnet et al. (2026) methodology identifying:

- **Vanguard regions**: Top 20% life expectancy with sustained gains
  (≥1.5 months/year)

- **Laggard regions**: Bottom 20% life expectancy or stagnant gains
  (\<0.5 months/year)

- **Average regions**: All others

### Microlives Interpretation

The `microlives_vs_eu_avg` column converts life expectancy differences
to daily microlives using the approximation: 1 year LE difference ≈ 1.2
microlives/day (assuming 40 years remaining life expectancy).

Example: A region with +2 years above EU average = +2.4 microlives/day,
equivalent to the benefit of 20 minutes daily exercise.

### Ecological Fallacy Warning

**IMPORTANT:** Regional life expectancy reflects population averages,
NOT individual-level causation. High life expectancy in "vanguard"
regions results from multiple factors including:

- Healthcare system quality and access

- Socioeconomic composition (income, education)

- Selection effects (healthy/wealthy people moving to certain regions

- Historical and cultural factors

Moving to a high-LE region does NOT guarantee increased personal
longevity.

## References

Bonnet F, et al. (2026). "Potential and challenges for sustainable
progress in human longevity." Nature Communications 17, 996.
[doi:10.1038/s41467-026-68828-z](https://doi.org/10.1038/s41467-026-68828-z)

Eurostat (2024). Life expectancy by age, sex and NUTS 2 region
(demo_r_mlifexp).
<https://ec.europa.eu/eurostat/databrowser/product/view/demo_r_mlifexp>

## See also

[`demographic_factors()`](https://johngavin.github.io/micromort/reference/demographic_factors.md),
[`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md)

Other regional:
[`laggard_regions()`](https://johngavin.github.io/micromort/reference/laggard_regions.md),
[`regional_mortality_multiplier()`](https://johngavin.github.io/micromort/reference/regional_mortality_multiplier.md),
[`vanguard_regions()`](https://johngavin.github.io/micromort/reference/vanguard_regions.md)

## Examples

``` r
# All data
regional_life_expectancy()
#> # A tibble: 17,221 × 9
#>    region_code region_name country_code  year sex    life_expectancy
#>    <chr>       <chr>       <chr>        <int> <chr>            <dbl>
#>  1 AT11        Burgenland  AT            1992 Female            79  
#>  2 AT11        Burgenland  AT            1992 Male              71.8
#>  3 AT11        Burgenland  AT            1992 Total             75.5
#>  4 AT11        Burgenland  AT            1993 Female            79.6
#>  5 AT11        Burgenland  AT            1993 Male              72.7
#>  6 AT11        Burgenland  AT            1993 Total             76.2
#>  7 AT11        Burgenland  AT            1994 Female            80  
#>  8 AT11        Burgenland  AT            1994 Male              72.5
#>  9 AT11        Burgenland  AT            1994 Total             76.3
#> 10 AT11        Burgenland  AT            1996 Female            79.7
#> # ℹ 17,211 more rows
#> # ℹ 3 more variables: microlives_vs_eu_avg <dbl>, classification <chr>,
#> #   source_url <chr>

# French regions in 2019
regional_life_expectancy(country = "FR", year = 2019)
#> # A tibble: 78 × 9
#>    region_code region_name           country_code  year sex    life_expectancy
#>    <chr>       <chr>                 <chr>        <int> <chr>            <dbl>
#>  1 FR10        Ile de France         FR            2019 Female            87.1
#>  2 FR10        Ile de France         FR            2019 Male              81.8
#>  3 FR10        Ile de France         FR            2019 Total             84.6
#>  4 FRB0        Centre — Val de Loire FR            2019 Female            85.7
#>  5 FRB0        Centre — Val de Loire FR            2019 Male              79.6
#>  6 FRB0        Centre — Val de Loire FR            2019 Total             82.7
#>  7 FRC1        Bourgogne             FR            2019 Female            85.6
#>  8 FRC1        Bourgogne             FR            2019 Male              79.3
#>  9 FRC1        Bourgogne             FR            2019 Total             82.4
#> 10 FRC2        Franche-Comté         FR            2019 Female            85.9
#> # ℹ 68 more rows
#> # ℹ 3 more variables: microlives_vs_eu_avg <dbl>, classification <chr>,
#> #   source_url <chr>

# Compare vanguard vs laggard regions
regional_life_expectancy(year = 2019, sex = "Total") |>
  dplyr::group_by(classification) |>
  dplyr::summarise(mean_le = mean(life_expectancy))
#> # A tibble: 3 × 2
#>   classification mean_le
#>   <chr>            <dbl>
#> 1 average           82.8
#> 2 laggard           81.7
#> 3 vanguard          84.3

# Top 10 regions by life expectancy (2019, Total)
regional_life_expectancy(year = 2019, sex = "Total") |>
  dplyr::slice_max(life_expectancy, n = 10)
#> # A tibble: 10 × 9
#>    region_code region_name              country_code  year sex   life_expectancy
#>    <chr>       <chr>                    <chr>        <int> <chr>           <dbl>
#>  1 ES30        Comunidad de Madrid      ES            2019 Total            85.8
#>  2 CH07        Ticino                   CH            2019 Total            85  
#>  3 ES22        Comunidad Foral de Nava… ES            2019 Total            85  
#>  4 ITH2        Provincia Autonoma di T… IT            2019 Total            84.9
#>  5 ES41        Castilla y León          ES            2019 Total            84.7
#>  6 CH01        Région lémanique         CH            2019 Total            84.6
#>  7 FR10        Ile de France            FR            2019 Total            84.6
#>  8 ES21        País Vasco               ES            2019 Total            84.5
#>  9 ITH1        Provincia Autonoma di B… IT            2019 Total            84.5
#> 10 ITI2        Umbria                   IT            2019 Total            84.5
#> # ℹ 3 more variables: microlives_vs_eu_avg <dbl>, classification <chr>,
#> #   source_url <chr>

# Microlives advantage of Catalonia vs EU average
regional_life_expectancy(country = "ES", year = 2019, sex = "Total") |>
  dplyr::filter(grepl("Catalonia", region_name))
#> # A tibble: 0 × 9
#> # ℹ 9 variables: region_code <chr>, region_name <chr>, country_code <chr>,
#> #   year <int>, sex <chr>, life_expectancy <dbl>, microlives_vs_eu_avg <dbl>,
#> #   classification <chr>, source_url <chr>
```
