# micromort

A **data package** providing curated, cross-sectional snapshots of
micromort (acute risk) and microlife (chronic risk) values from
authoritative sources including
[Wikipedia](https://en.wikipedia.org/wiki/Micromort), [CDC
MMWR](https://www.cdc.gov/mmwr/), [IHME GBD
2023](https://www.healthdata.org/research-analysis/gbd) via
[OWID](https://ourworldindata.org/), and academic literature.

**120 activity IDs** across 193 atomic risk rows. **35+ chronic
factors.** **6-country disease mortality** + risk factors from GBD 2023.
**3 interactive quizzes.** [Closeread
scrollytelling.](https://johngavin.github.io/micromort/articles/chronic_vs_acute.html)
[REST
API.](https://johngavin.github.io/micromort/articles/rest_api.html)

## Explore

### Load the Datasets

``` r
library(micromort)

# Load acute risks (micromorts per event)
acute <- load_acute_risks()
nrow(acute)
#> [1] 104

# Load chronic risks (microlives per day)
chronic <- load_chronic_risks()
nrow(chronic)
#> [1] 38
```

### Acute Risks (Micromorts per Event)

``` r
# Top 10 riskiest activities
acute |>
  dplyr::select(activity, micromorts, category, period) |>
  head(10)
#> # A tibble: 10 × 4
#>    activity                                micromorts category       period     
#>    <chr>                                        <dbl> <chr>          <chr>      
#>  1 Mt. Everest ascent                           37932 Mountaineering per ascent 
#>  2 Himalayan mountaineering                     12000 Mountaineering per expedi…
#>  3 COVID-19 infection (unvaccinated)            10000 COVID-19       per infect…
#>  4 Spanish flu infection                         3000 Disease        per infect…
#>  5 Matterhorn ascent                             2840 Mountaineering per ascent 
#>  6 Living in US during COVID-19 (Jul 2020)        500 COVID-19       per month  
#>  7 Living (one day, age 90)                       463 Daily Life     per day    
#>  8 Base jumping (per jump)                        430 Sport          per jump   
#>  9 First day of life (newborn)                    430 Daily Life     per day    
#> 10 COVID-19 unvaccinated (age 80+)                234 COVID-19       11 weeks (…
```

### Chronic Risks (Microlives per Day)

``` r
# Factors that reduce life expectancy
chronic |>
  dplyr::filter(direction == "loss") |>
  dplyr::select(factor, microlives_per_day, category) |>
  head(10)
#> # A tibble: 10 × 3
#>    factor                              microlives_per_day category      
#>    <chr>                                            <dbl> <chr>         
#>  1 Smoking 20 cigarettes                              -10 Smoking       
#>  2 Smoking 10 cigarettes                               -5 Smoking       
#>  3 Untreated hypertension                              -4 Cardiovascular
#>  4 Being male (vs female)                              -4 Demographics  
#>  5 Being 15 kg overweight                              -3 Weight        
#>  6 Type 2 diabetes (poorly controlled)                 -3 Cardiovascular
#>  7 Being 10 kg overweight                              -2 Weight        
#>  8 4th-5th alcoholic drink                             -2 Alcohol       
#>  9 Sitting 8+ hours/day                                -2 Sedentary     
#> 10 High LDL cholesterol (untreated)                    -2 Cardiovascular
```

## Visualize

``` r
plot_risks(common_risks() |> dplyr::filter(micromorts >= 1))
```

![Risk comparison in micromorts (log scale). Bars show death probability
per event. COVID-19 and other risks shown in separate panels for
clarity.](reference/figures/README-plot-1.png)

Risk comparison in micromorts (log scale). Bars show death probability
per event. COVID-19 and other risks shown in separate panels for
clarity.

## Analyse

### Compare Lifestyle Interventions

``` r
compare_interventions(list(
  "Quit 10 cigarettes/day" = list(factor = "Smoking 10 cigarettes", change = -1),
  "Lose 5kg" = list(factor = "Being 5 kg overweight", change = -1)
))
#> # A tibble: 2 × 7
#>   intervention      factor original_ml_per_day change net_ml_per_day annual_days
#>   <chr>             <chr>                <dbl>  <dbl>          <dbl>       <dbl>
#> 1 Quit 10 cigarett… Smoki…                  -5     -1             -5       -38  
#> 2 Lose 5kg          Being…                  -1     -1             -1        -7.6
#> # ℹ 1 more variable: lifetime_years <dbl>
```

### Calculate Baseline Risk by Age

``` r
daily_hazard_rate(35)
#> # A tibble: 1 × 7
#>     age sex   daily_prob micromorts microlives_consumed precision_note          
#>   <dbl> <chr>      <dbl>      <dbl>               <dbl> <chr>                   
#> 1    35 male  0.00000296          3                 0.1 Gompertz-Makeham approx…
#> # ℹ 1 more variable: interpretation <chr>
```

### Lifestyle Tradeoffs

``` r
lifestyle_tradeoff("Smoking 2 cigarettes", "20 min moderate exercise")
#> # A tibble: 1 × 6
#>   bad_habit            bad_ml_per_day good_habit    good_ml_per_day units_needed
#>   <chr>                         <dbl> <chr>                   <dbl>        <dbl>
#> 1 Smoking 2 cigarettes             -1 20 min moder…               2          0.5
#> # ℹ 1 more variable: interpretation <chr>
```

### Country-Level Disease Risk

``` r
# Compare disease burden: UK vs Nigeria
common_risks(profile = list(country = "NG")) |>
  dplyr::filter(grepl("mortality risk", activity)) |>
  dplyr::select(activity, micromorts)
#> # A tibble: 4 × 2
#>   activity                                 micromorts
#>   <chr>                                         <dbl>
#> 1 Daily CVD mortality risk (Nigeria)             7.33
#> 2 Daily cancer mortality risk (Nigeria)          2.79
#> 3 Daily LRI mortality risk (Nigeria)             1.77
#> 4 Daily diarrheal mortality risk (Nigeria)       0.88
```

## Quizzes

| Quiz | Instant (static JS) | Shinylive (30-60s load) | Local |
|----|:--:|:--:|:--:|
| Which Is Riskier? | [Play](https://johngavin.github.io/micromort/articles/micromort-quiz.html) | [Play](https://johngavin.github.io/micromort/articles/quiz_shinylive.html) | [`launch_quiz()`](https://johngavin.github.io/micromort/reference/launch_quiz.md) |
| Microlife Quiz | [Play](https://johngavin.github.io/micromort/articles/microlife-quiz.html) | [Play](https://johngavin.github.io/micromort/articles/chronic_quiz_shinylive.html) | [`launch_chronic_quiz()`](https://johngavin.github.io/micromort/reference/launch_chronic_quiz.md) |
| Rank the Risks | [Play](https://johngavin.github.io/micromort/articles/risk-ranking-quiz.html) | [Play](https://johngavin.github.io/micromort/articles/ranking_quiz_shinylive.html) | [`ranking_quiz_questions()`](https://johngavin.github.io/micromort/reference/ranking_quiz_questions.md) |

All quizzes have score submission + percentile ranking via Google Forms.
Static JS versions load instantly; Shinylive versions use WebR (30-60s
load).

``` r
# Generate geography-specific quiz pairs
geography_quiz_pairs(countries = c("UK", "NG"), seed = 42)
```

## Install

### R-Universe (Recommended)

``` r
install.packages("micromort", repos = "https://johngavin.r-universe.dev")
```

### GitHub

``` r
devtools::install_github("JohnGavin/micromort")
```

### Nix Users

``` bash
./default.sh   # Reproducible R env with cachix cache
R
```

Using with rix

``` r
library(rix)
rix(
  r_pkgs = c("dplyr", "ggplot2"),
  git_pkgs = list(list(
    package_name = "micromort",
    repo_url = "https://github.com/JohnGavin/micromort",
    commit = "main"
  )),
  project_path = ".",
  overwrite = TRUE
)
```

## API

Launch the REST API for programmatic access:

``` r
launch_api()
# Swagger docs at http://localhost:8080/__docs__/
```

**Core endpoints** (30 total — [full
reference](https://johngavin.github.io/micromort/articles/rest_api.html)):

| Endpoint                             | Returns                          |
|--------------------------------------|----------------------------------|
| `GET /v1/risks/acute`                | Acute risks (micromorts)         |
| `GET /v1/risks/chronic`              | Chronic risks (microlives)       |
| `GET /v1/risks/cancer`               | Cancer mortality by type/sex/age |
| `GET /v1/analysis/equivalence`       | Risk equivalence lookup          |
| `GET /v1/convert/hazard-rate?age=35` | Daily hazard rate                |

## Concepts

### Micromort (Acute Risk)

A **micromort** = one-in-a-million probability of death per event.
Skydiving: ~8 micromorts per jump.

### Microlife (Chronic Risk)

A **microlife** = 30 minutes of life expectancy change per day. Smoking
2 cigarettes: -1 microlife/day.

### Conversion

**1 micromort ≈ 0.7 microlives** (at 40 years remaining life
expectancy).

## Architecture

See the [Architecture
vignette](https://johngavin.github.io/micromort/articles/architecture.html).

See the [Architecture
vignette](https://johngavin.github.io/micromort/articles/architecture.html)
for detailed diagrams.

## Data Sources

| Source | Type | Data |
|----|----|----|
| [Wikipedia: Micromort](https://en.wikipedia.org/wiki/Micromort) | Encyclopedia | ~50 acute risks |
| [Wikipedia: Microlife](https://en.wikipedia.org/wiki/Microlife) | Encyclopedia | ~20 chronic risks |
| [micromorts.rip](https://micromorts.rip/) | Database | ~45 acute risks |
| [CDC MMWR](https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm) | Government | COVID vaccine data |
| [Spiegelhalter (2012) BMJ](https://pubmed.ncbi.nlm.nih.gov/23247978/) | Academic | Microlife framework |
| [SEER Cancer Statistics](https://seer.cancer.gov/) | Government | Cancer mortality by type/sex |
| [IHME GBD 2023](https://www.healthdata.org/research-analysis/gbd) via [OWID](https://ourworldindata.org/) | Academic | Disease + risk-factor mortality by country |

## Glossary

| Acronym | Definition |
|----|----|
| [DALY](https://en.wikipedia.org/wiki/Disability-adjusted_life_year) | Disability-Adjusted Life Year (YLL + YLD) |
| [LLE](https://en.wikipedia.org/wiki/Loss_of_life_expectancy) | Loss of Life Expectancy (minutes) |
| [QALY](https://en.wikipedia.org/wiki/Quality-adjusted_life_year) | Quality-Adjusted Life Year |
| [VSL](https://en.wikipedia.org/wiki/Value_of_life#Value_of_a_statistical_life) | Value of Statistical Life (~\$10M USD) |

## References

- Howard RA (1980). “On Making Life and Death Decisions.” *Societal Risk
  Assessment*.
- Spiegelhalter D (2012). “Using speed of ageing and ‘microlives’.” BMJ
  345:e8223.
- Blastland M, Spiegelhalter D (2013). *The Norm Chronicles*.

## License

MIT. See [LICENSE](https://johngavin.github.io/micromort/LICENSE).
