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
#> # A tibble: 924 × 9
#>    region_code region_name             country_code  year sex    life_expectancy
#>  * <chr>       <chr>                   <chr>        <int> <chr>            <dbl>
#>  1 BE10        Brussels-Capital Region BE            1992 Female            80.5
#>  2 BE10        Brussels-Capital Region BE            1992 Male              74  
#>  3 BE10        Brussels-Capital Region BE            1992 Total             77  
#>  4 BE10        Brussels-Capital Region BE            1993 Female            80.6
#>  5 BE10        Brussels-Capital Region BE            1993 Male              74.1
#>  6 BE10        Brussels-Capital Region BE            1993 Total             77.1
#>  7 BE10        Brussels-Capital Region BE            1994 Female            80.7
#>  8 BE10        Brussels-Capital Region BE            1994 Male              74.2
#>  9 BE10        Brussels-Capital Region BE            1994 Total             77.2
#> 10 BE10        Brussels-Capital Region BE            1995 Female            80.8
#> # ℹ 914 more rows
#> # ℹ 3 more variables: microlives_vs_eu_avg <dbl>, classification <chr>,
#> #   source_url <chr>

# French regions in 2019
regional_life_expectancy(country = "FR", year = 2019)
#> # A tibble: 6 × 9
#>   region_code region_name               country_code  year sex   life_expectancy
#>   <chr>       <chr>                     <chr>        <int> <chr>           <dbl>
#> 1 FR10        Île-de-France (Paris reg… FR            2019 Fema…            85.4
#> 2 FR10        Île-de-France (Paris reg… FR            2019 Male             81.1
#> 3 FR10        Île-de-France (Paris reg… FR            2019 Total            83  
#> 4 FRE1        Nord (Hauts-de-France)    FR            2019 Fema…            79.7
#> 5 FRE1        Nord (Hauts-de-France)    FR            2019 Male             73.1
#> 6 FRE1        Nord (Hauts-de-France)    FR            2019 Total            75.9
#> # ℹ 3 more variables: microlives_vs_eu_avg <dbl>, classification <chr>,
#> #   source_url <chr>

# Compare vanguard vs laggard regions
regional_life_expectancy(year = 2019, sex = "Total") |>
  dplyr::group_by(classification) |>
  dplyr::summarise(mean_le = mean(life_expectancy))
#> # A tibble: 3 × 2
#>   classification mean_le
#>   <chr>            <dbl>
#> 1 average           79.8
#> 2 laggard           75.9
#> 3 vanguard          83  

# Top 10 regions by life expectancy (2019, Total)
regional_life_expectancy(year = 2019, sex = "Total") |>
  dplyr::slice_max(life_expectancy, n = 10)
#> # A tibble: 11 × 9
#>    region_code region_name              country_code  year sex   life_expectancy
#>    <chr>       <chr>                    <chr>        <int> <chr>           <dbl>
#>  1 CH03        Northwestern Switzerland CH            2019 Total            83  
#>  2 ES51        Catalonia                ES            2019 Total            83  
#>  3 FR10        Île-de-France (Paris re… FR            2019 Total            83  
#>  4 ITC4        Lombardy                 IT            2019 Total            83  
#>  5 BE10        Brussels-Capital Region  BE            2019 Total            79.8
#>  6 DE21        Upper Bavaria            DE            2019 Total            79.8
#>  7 NL32        North Holland            NL            2019 Total            79.8
#>  8 BE32        Hainaut (Wallonia)       BE            2019 Total            75.9
#>  9 DE80        Mecklenburg-Vorpommern   DE            2019 Total            75.9
#> 10 FRE1        Nord (Hauts-de-France)   FR            2019 Total            75.9
#> 11 UKC1        Tees Valley and Durham   UK            2019 Total            75.9
#> # ℹ 3 more variables: microlives_vs_eu_avg <dbl>, classification <chr>,
#> #   source_url <chr>

# Microlives advantage of Catalonia vs EU average
regional_life_expectancy(country = "ES", year = 2019, sex = "Total") |>
  dplyr::filter(grepl("Catalonia", region_name))
#> # A tibble: 1 × 9
#>   region_code region_name country_code  year sex   life_expectancy
#>   <chr>       <chr>       <chr>        <int> <chr>           <dbl>
#> 1 ES51        Catalonia   ES            2019 Total              83
#> # ℹ 3 more variables: microlives_vs_eu_avg <dbl>, classification <chr>,
#> #   source_url <chr>
```
