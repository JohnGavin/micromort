---
title: "micromort: Curated Micromort and Microlife Risk Datasets"
format: gfm
---

<!-- README.md is generated from README.qmd. Please edit that file -->



# micromort

A **data package** providing curated datasets of micromort (acute risk) and microlife (chronic risk) values from authoritative sources including Wikipedia, CDC MMWR, and academic literature.
## Features

- **62 acute risks** measured in micromorts (one-in-a-million death probability per event)
- **35+ chronic factors** measured in microlives (30-minute life expectancy change per day)
- **14 authoritative sources** with full provenance tracking
- **Parquet datasets** for cross-language compatibility (R, Python, Arrow)
- **Plumber REST API** for programmatic access
- **Interactive dashboard** for data exploration
- **targets pipeline** for reproducible data updates

## Architecture

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': {'primaryColor': '#2d5f8a', 'primaryTextColor': '#e0e0e0', 'primaryBorderColor': '#4a9eda', 'lineColor': '#4a9eda', 'secondaryColor': '#3d3d5c', 'tertiaryColor': '#1a1a2e', 'background': '#1a1a1a', 'mainBkg': '#1a1a2e', 'nodeBorder': '#4a9eda', 'clusterBkg': '#2a2a3e', 'clusterBorder': '#4a9eda', 'titleColor': '#e0e0e0', 'edgeLabelBackground': '#1a1a2e'}}}%%
graph LR

  Conversion["Unit Conversion<br>5 functions"]
  Data["Risk Datasets<br>21 functions"]
  Analysis["Risk Analysis<br>6 functions"]
  Viz["Visualization<br>5 functions"]
  Apps["Interactive Apps<br>4 functions"]

  Conversion --> Data --> Analysis --> Viz --> Apps

  style Conversion fill:#1a2d4a,stroke:#1976D2
  style Data fill:#1a3d1a,stroke:#2E7D32
  style Analysis fill:#3d1a2a,stroke:#C62828
  style Viz fill:#2d1a3d,stroke:#7B1FA2
  style Apps fill:#1a3d3d,stroke:#00897B
```

See the [Architecture vignette](https://johngavin.github.io/micromort/articles/architecture.html)
for detailed diagrams of the data pipeline, function hierarchy, and user journey.

## Installation

### R-Universe (Recommended)

```r
# Install from r-universe (pre-built binaries, fast)
install.packages("micromort", repos = "https://johngavin.r-universe.dev")
```

### GitHub

```r
# Install from GitHub (source)
# install.packages("devtools")
devtools::install_github("JohnGavin/micromort")
```

### Nix Users

This project provides a reproducible Nix environment with pre-built binaries from the `johngavin` cachix cache:

```bash
# Enter project shell (uses cachix cache for fast builds)
./default.sh

# Start R
R
```

#### Using with rix

To include micromort in your own Nix-based R project:

```r
library(rix)

rix(
  r_pkgs = c("dplyr", "ggplot2"),
  git_pkgs = list(
    list(
      package_name = "micromort",
      repo_url = "https://github.com/JohnGavin/micromort",
      commit = "main"  # Or specific SHA for reproducibility
    )
  ),
  project_path = ".",
  overwrite = TRUE
)
```

## Concepts

### Micromort (Acute Risk)
A **micromort** is a unit of mortality risk equal to a **one-in-a-million probability of death per specific event**.

- **Unit:** 1 micromort = 1/1,000,000 = 0.0001% death probability
- **Scope:** Per discrete event (e.g., one skydive, one surgery, one flight)
- **Sign:** Always non-negative (it's a probability)
- **Example:** Skydiving has ~8 micromorts per jump (8-in-a-million death chance per jump)

### Microlife (Chronic Risk)

A **microlife** is a unit of life expectancy change equal to **30 minutes of expected lifespan, measured per day** of exposure.

- **Unit:** 1 microlife = 30 minutes of life expectancy
- **Scope:** Per day of maintaining a habit or exposure
- **Sign:** Positive (life gained) or negative (life lost)
- **Example:** Smoking 2 cigarettes daily costs -1 microlife/day (losing 30 mins of life expectancy each day you smoke)

### Conversion {#conversion}

**1 micromort ≈ 0.7 microlives** (assuming 40 years remaining life expectancy).
The conversion scales linearly with remaining life expectancy:

| Remaining life expectancy | 1 micromort ≈ |
|---------------------------|---------------|
| 10 years | 0.18 microlives |
| 20 years | 0.35 microlives |
| 40 years (default) | 0.70 microlives |
| 60 years | 1.05 microlives |

Use `lle(prob, life_expectancy = ...)` and `as_microlife()` to convert at any age.
See the [Age-Based Hazard Rates](#calculate-baseline-risk-by-age) section for daily micromort exposure by age.

### Morbidity Metrics

Micromorts and microlives focus on mortality. For quality-of-life impacts:

- **QALY (Quality-Adjusted Life Year):** 1 year of perfect health. Used in healthcare economics.
- **DALY (Disability-Adjusted Life Years):** Disease burden combining:
    - **YLL (Years of Life Lost):** Premature mortality component
    - **YLD (Years Lived with Disability):** Morbidity component
- **QALD (Quality-Adjusted Life Days):** 1 day of perfect health. For common illnesses.

See the [Introduction vignette](https://johngavin.github.io/micromort/articles/introduction.html) for detailed examples and the [Glossary](#glossary) for all acronym definitions.

## Quick Start

### Load the Datasets


``` r
library(micromort)

# Load acute risks (micromorts per event)
acute <- load_acute_risks()
nrow(acute)
#> [1] 62

# Load chronic risks (microlives per day)
chronic <- load_chronic_risks()
nrow(chronic)
#> [1] 22

# Load source registry
sources <- load_sources()
nrow(sources)
#> [1] 14
```

### Acute Risks (Micromorts per Event)


``` r
# Convert a probability to micromorts
# Example: 1 in 10,000 chance = 100 micromorts
as_micromort(1/10000)
#> [1] 100

# Top 10 riskiest activities (micromorts per event/period)
acute |>
  dplyr::select(activity, micromorts, category, period) |>
  head(10)
#> [90m# A tibble: 10 × 4[39m
#>    activity                                micromorts category       period     
#>    [3m[90m<chr>[39m[23m                                        [3m[90m<dbl>[39m[23m [3m[90m<chr>[39m[23m          [3m[90m<chr>[39m[23m      
#> [90m 1[39m Mt. Everest ascent                           [4m3[24m[4m7[24m932 Mountaineering per ascent 
#> [90m 2[39m Himalayan mountaineering                     [4m1[24m[4m2[24m000 Mountaineering per expedi…
#> [90m 3[39m COVID-19 infection (unvaccinated)            [4m1[24m[4m0[24m000 Disease        per infect…
#> [90m 4[39m Spanish flu infection                         [4m3[24m000 Disease        per infect…
#> [90m 5[39m Matterhorn ascent                             [4m2[24m840 Mountaineering per ascent 
#> [90m 6[39m Living in US during COVID-19 (Jul 2020)        500 Disease        per month  
#> [90m 7[39m Living (one day, age 90)                       463 Daily Life     per day    
#> [90m 8[39m Base jumping (per jump)                        430 Sport          per event  
#> [90m 9[39m First day of life (newborn)                    430 Daily Life     per day    
#> [90m10[39m COVID-19 unvaccinated (age 80+)                234 COVID-19       11 weeks (…
```

**Caption:** Micromorts represent probability of death per event. Higher values = higher risk per occurrence.

### Chronic Risks (Microlives per Day)


``` r
# Factors that reduce life expectancy (microlives lost per day)
chronic |>
  dplyr::filter(direction == "loss") |>
  dplyr::select(factor, microlives_per_day, category) |>
  head(10)
#> [90m# A tibble: 10 × 3[39m
#>    factor                   microlives_per_day category    
#>    [3m[90m<chr>[39m[23m                                 [3m[90m<dbl>[39m[23m [3m[90m<chr>[39m[23m       
#> [90m 1[39m Smoking 20 cigarettes                   -[31m10[39m Smoking     
#> [90m 2[39m Smoking 10 cigarettes                    -[31m5[39m Smoking     
#> [90m 3[39m Being male (vs female)                   -[31m4[39m Demographics
#> [90m 4[39m Being 15 kg overweight                   -[31m3[39m Weight      
#> [90m 5[39m Being 10 kg overweight                   -[31m2[39m Weight      
#> [90m 6[39m 4th-5th alcoholic drink                  -[31m2[39m Alcohol     
#> [90m 7[39m Smoking 2 cigarettes                     -[31m1[39m Smoking     
#> [90m 8[39m Being 5 kg overweight                    -[31m1[39m Weight      
#> [90m 9[39m 2nd-3rd alcoholic drink                  -[31m1[39m Alcohol     
#> [90m10[39m Red meat (1 portion/day)                 -[31m1[39m Diet
```

**Caption:** Microlives per day. Negative values = life expectancy loss; positive = gain. Effects accumulate daily.

### Visualize Risks


``` r
# Filter to show only activities with micromorts >= 1 for clarity on log scale
plot_risks(common_risks() |> dplyr::filter(micromorts >= 1))
#> Warning in ggplot2::scale_y_log10(labels = scales::comma, limits = c(0.01, : [1m[22m[32mlog-10[39m transformation introduced infinite values.
#> [1m[22m[32mlog-10[39m transformation introduced infinite values.
#> [1m[22m[32mlog-10[39m transformation introduced infinite values.
#> [1m[22m[32mlog-10[39m transformation introduced infinite values.
#> [1m[22m[32mlog-10[39m transformation introduced infinite values.
#> [1m[22m[32mlog-10[39m transformation introduced infinite values.
#> [1m[22m[32mlog-10[39m transformation introduced infinite values.
#> [1m[22m[32mlog-10[39m transformation introduced infinite values.
#> [1m[22m[32mlog-10[39m transformation introduced infinite values.
#> [1m[22m[32mlog-10[39m transformation introduced infinite values.
#> [1m[22m[32mlog-10[39m transformation introduced infinite values.
#> [1m[22m[32mlog-10[39m transformation introduced infinite values.
```

<div class="figure">
<img src="man/figures/README-plot-1.png" alt="Risk comparison in micromorts (log scale). Bars show death probability per event. COVID-19 and other risks shown in separate panels for clarity." width="100%" />
<p class="caption">Risk comparison in micromorts (log scale). Bars show death probability per event. COVID-19 and other risks shown in separate panels for clarity.</p>
</div>

## Analysis Functions

### Compare Lifestyle Interventions


``` r
# Compare quitting smoking vs losing weight (microlives gained per day)
compare_interventions(list(
  "Quit 10 cigarettes/day" = list(factor = "Smoking 10 cigarettes", change = -1),
  "Lose 5kg" = list(factor = "Being 5 kg overweight", change = -1)
))
#> [90m# A tibble: 2 × 7[39m
#>   intervention      factor original_ml_per_day change net_ml_per_day annual_days
#>   [3m[90m<chr>[39m[23m             [3m[90m<chr>[39m[23m                [3m[90m<dbl>[39m[23m  [3m[90m<dbl>[39m[23m          [3m[90m<dbl>[39m[23m       [3m[90m<dbl>[39m[23m
#> [90m1[39m Quit 10 cigarett… Smoki…                  -[31m5[39m     -[31m1[39m             -[31m5[39m       -[31m38[39m  
#> [90m2[39m Lose 5kg          Being…                  -[31m1[39m     -[31m1[39m             -[31m1[39m        -[31m7[39m[31m.[39m[31m6[39m
#> [90m# ℹ 1 more variable: lifetime_years <dbl>[39m
```

### Calculate Baseline Risk by Age


``` r
# Daily baseline mortality risk at age 35 (micromorts per day just from being alive)
daily_hazard_rate(35)
#> [90m# A tibble: 1 × 6[39m
#>     age sex   daily_prob micromorts microlives_consumed interpretation          
#>   [3m[90m<dbl>[39m[23m [3m[90m<chr>[39m[23m      [3m[90m<dbl>[39m[23m      [3m[90m<dbl>[39m[23m               [3m[90m<dbl>[39m[23m [3m[90m<chr>[39m[23m                   
#> [90m1[39m    35 male  0.000[4m0[24m[4m0[24m[4m2[24m96          3                0.05 At age 35 (male): 3.0 m…
```

### Lifestyle Tradeoffs


``` r
# How much exercise offsets smoking? (in microlives per day)
lifestyle_tradeoff("Smoking 2 cigarettes", "20 min moderate exercise")
#> [90m# A tibble: 1 × 6[39m
#>   bad_habit            bad_ml_per_day good_habit    good_ml_per_day units_needed
#>   [3m[90m<chr>[39m[23m                         [3m[90m<dbl>[39m[23m [3m[90m<chr>[39m[23m                   [3m[90m<dbl>[39m[23m        [3m[90m<dbl>[39m[23m
#> [90m1[39m Smoking 2 cigarettes             -[31m1[39m 20 min moder…               2          0.5
#> [90m# ℹ 1 more variable: interpretation <chr>[39m
```

## API Access

Launch the REST API for programmatic access:

```r
launch_api()
# API available at http://localhost:8080
# Swagger docs at http://localhost:8080/__docs__/
```

**Core endpoints** (30 total — see [REST API vignette](https://johngavin.github.io/micromort/articles/rest_api.html) for full reference):

- `GET /v1/risks/acute` — Acute risks (micromorts per event)
- `GET /v1/risks/chronic` — Chronic risks (microlives per day)
- `GET /v1/risks/cancer` — Cancer mortality by type/sex/age
- `GET /v1/analysis/equivalence` — Risk equivalence lookup
- `GET /v1/convert/hazard-rate?age=35` — Daily hazard rate
- `GET /v1/sources` — Source registry
- `GET /health` — Health check

## Interactive Dashboard

Launch the Shiny dashboard:

```r
launch_dashboard()
```

## Risk Quiz

[Play in browser](https://johngavin.github.io/micromort/articles/quiz_shinylive.html)
— runs via WebR/Shinylive (30-60s initial load). Or locally:

```r
micromort::launch_quiz()
```

## Data Sources

| Source | Type | Data |
|--------|------|------|
| Wikipedia: Micromort | Encyclopedia | ~50 acute risks |
| Wikipedia: Microlife | Encyclopedia | ~20 chronic risks |
| micromorts.rip | Database | ~45 acute risks |
| CDC MMWR | Government | COVID vaccine data |
| Spiegelhalter (2012) BMJ | Academic | Microlife framework |
| SEER Cancer Statistics | Government | Cancer mortality by type/sex |

## Project Structure

<details>
<summary>Click to expand project tree</summary>


```
#> [1;36m.[0m
#> ├── DESCRIPTION
#> ├── LICENSE
#> ├── LICENSE.md
#> ├── NAMESPACE
#> ├── [1;36mR[0m
#> │   ├── api.R
#> │   ├── atomic_risks.R
#> │   ├── dashboard.R
#> │   ├── data.R
#> │   ├── [1;36mdev[0m
#> │   │   ├── [1;36missues[0m
#> │   │   └── verify_pkgdown_urls.R
#> │   ├── diagrams.R
#> │   ├── micromort.R
#> │   ├── models.R
#> │   ├── quiz.R
#> │   ├── radiation_profiles.R
#> │   ├── regional.R
#> │   ├── risk_equivalence.R
#> │   ├── risks.R
#> │   ├── [1;36mtar_plans[0m
#> │   │   ├── plan_data_acquisition.R
#> │   │   ├── plan_documentation.R
#> │   │   ├── plan_export.R
#> │   │   ├── plan_logging.R
#> │   │   ├── plan_normalization.R
#> │   │   ├── plan_validation.R
#> │   │   └── plan_vignette_outputs.R
#> │   └── visualization.R
#> ├── README.md
#> ├── README.qmd
#> ├── [1;36mREADME_files[0m
#> │   └── [1;36mlibs[0m
#> │       ├── [1;36mbootstrap[0m
#> │       ├── [1;36mclipboard[0m
#> │       └── [1;36mquarto-html[0m
#> ├── [1;36mbox[0m
#> │   ├── [1;36mapi[0m
#> │   │   ├── __init__.R
#> │   │   └── endpoints.R
#> │   ├── [1;36mdashboard[0m
#> │   │   ├── __init__.R
#> │   │   ├── server.R
#> │   │   └── ui.R
#> │   ├── [1;36mdata[0m
#> │   │   ├── __init__.R
#> │   │   ├── loaders.R
#> │   │   ├── parsers.R
#> │   │   └── schemas.R
#> │   └── [1;36mmodels[0m
#> │       ├── __init__.R
#> │       ├── compare.R
#> │       └── hazard.R
#> ├── [1;36mdata-raw[0m
#> │   ├── 01_extract_current_data.R
#> │   ├── 02_regional_life_expectancy.R
#> │   ├── 02_regional_life_expectancy_sample.R
#> │   ├── README_regional_data.md
#> │   └── [1;36msources[0m
#> │       ├── acute_risks_base.csv
#> │       ├── chronic_risks_base.csv
#> │       ├── covid_vaccine_rr.csv
#> │       ├── demographic_factors.csv
#> │       └── risk_sources.csv
#> ├── default.R
#> ├── default.nix
#> ├── [31mdefault.sh[0m
#> ├── [1;36mdocs[0m
#> │   ├── 404.html
#> │   ├── 404.md
#> │   ├── LICENSE-text.html
#> │   ├── LICENSE-text.md
#> │   ├── LICENSE.html
#> │   ├── LICENSE.md
#> │   ├── [1;36marticles[0m
#> │   │   ├── architecture.html
#> │   │   ├── architecture.md
#> │   │   ├── [1;36marchitecture_files[0m
#> │   │   ├── confounding.html
#> │   │   ├── confounding.md
#> │   │   ├── index.html
#> │   │   ├── index.md
#> │   │   ├── introduction.html
#> │   │   ├── introduction.md
#> │   │   ├── [1;36mintroduction_files[0m
#> │   │   ├── palatable_units.html
#> │   │   ├── palatable_units.md
#> │   │   ├── [1;36mpalatable_units_files[0m
#> │   │   ├── quiz_shinylive.html
#> │   │   ├── quiz_shinylive.md
#> │   │   ├── [1;36mquiz_shinylive_files[0m
#> │   │   ├── regional_variation.html
#> │   │   ├── regional_variation.md
#> │   │   ├── [1;36mregional_variation_files[0m
#> │   │   ├── rest_api.html
#> │   │   ├── rest_api.md
#> │   │   ├── [1;36mrest_api_files[0m
#> │   │   ├── risk_equivalence.html
#> │   │   ├── risk_equivalence.md
#> │   │   ├── [1;36mrisk_equivalence_files[0m
#> │   │   └── shinylive-sw.js
#> │   ├── authors.html
#> │   ├── authors.md
#> │   ├── [1;36mdeps[0m
#> │   │   ├── [1;36mbootstrap-5.3.1[0m
#> │   │   ├── [1;36mbootstrap-toc-1.0.1[0m
#> │   │   ├── [1;36mclipboard.js-2.0.11[0m
#> │   │   ├── data-deps.txt
#> │   │   ├── [1;36mfont-awesome-6.5.2[0m
#> │   │   ├── [1;36mheadroom-0.11.0[0m
#> │   │   ├── [1;36mjquery-3.6.0[0m
#> │   │   └── [1;36msearch-1.0.0[0m
#> │   ├── extra.css
#> │   ├── extra.js
#> │   ├── index.html
#> │   ├── index.md
#> │   ├── katex-auto.js
#> │   ├── lightswitch.js
#> │   ├── link.svg
#> │   ├── llms.txt
#> │   ├── [1;36mnews[0m
#> │   ├── pkgdown.js
#> │   ├── pkgdown.yml
#> │   ├── [1;36mreference[0m
#> │   │   ├── acute_risks.html
#> │   │   ├── acute_risks.md
#> │   │   ├── annual_risk_budget.html
#> │   │   ├── annual_risk_budget.md
#> │   │   ├── as_microlife.html
#> │   │   ├── as_microlife.md
#> │   │   ├── as_micromort.html
#> │   │   ├── as_micromort.md
#> │   │   ├── as_probability.html
#> │   │   ├── as_probability.md
#> │   │   ├── atomic_risks.html
#> │   │   ├── atomic_risks.md
#> │   │   ├── cancer_risks.html
#> │   │   ├── cancer_risks.md
#> │   │   ├── chronic_risks.html
#> │   │   ├── chronic_risks.md
#> │   │   ├── common_risks.html
#> │   │   ├── common_risks.md
#> │   │   ├── compare_interventions.html
#> │   │   ├── compare_interventions.md
#> │   │   ├── conditional_risk.html
#> │   │   ├── conditional_risk.md
#> │   │   ├── covid_vaccine_rr.html
#> │   │   ├── covid_vaccine_rr.md
#> │   │   ├── daily_hazard_rate.html
#> │   │   ├── daily_hazard_rate.md
#> │   │   ├── demographic_factors.html
#> │   │   ├── demographic_factors.md
#> │   │   ├── [1;36mfigures[0m
#> │   │   ├── hedged_portfolio.html
#> │   │   ├── hedged_portfolio.md
#> │   │   ├── index.html
#> │   │   ├── index.md
#> │   │   ├── laggard_regions.html
#> │   │   ├── laggard_regions.md
#> │   │   ├── launch_api.html
#> │   │   ├── launch_api.md
#> │   │   ├── launch_dashboard.html
#> │   │   ├── launch_dashboard.md
#> │   │   ├── launch_quiz.html
#> │   │   ├── launch_quiz.md
#> │   │   ├── [1;36mlibs[0m
#> │   │   ├── lifestyle_tradeoff.html
#> │   │   ├── lifestyle_tradeoff.md
#> │   │   ├── lle.html
#> │   │   ├── lle.md
#> │   │   ├── load_acute_risks.html
#> │   │   ├── load_acute_risks.md
#> │   │   ├── load_chronic_risks.html
#> │   │   ├── load_chronic_risks.md
#> │   │   ├── load_sources.html
#> │   │   ├── load_sources.md
#> │   │   ├── patient_radiation_comparison.html
#> │   │   ├── patient_radiation_comparison.md
#> │   │   ├── plot_risk_components-1.png
#> │   │   ├── plot_risk_components.html
#> │   │   ├── plot_risk_components.md
#> │   │   ├── plot_risks-1.png
#> │   │   ├── plot_risks-2.png
#> │   │   ├── plot_risks-3.png
#> │   │   ├── plot_risks-4.png
#> │   │   ├── plot_risks-5.png
#> │   │   ├── plot_risks.html
#> │   │   ├── plot_risks.md
#> │   │   ├── plot_risks_interactive.html
#> │   │   ├── plot_risks_interactive.md
#> │   │   ├── prepare_risks_plot-1.png
#> │   │   ├── prepare_risks_plot.html
#> │   │   ├── prepare_risks_plot.md
#> │   │   ├── quiz_pairs.html
#> │   │   ├── quiz_pairs.md
#> │   │   ├── radiation_profiles.html
#> │   │   ├── radiation_profiles.md
#> │   │   ├── regional_life_expectancy.html
#> │   │   ├── regional_life_expectancy.md
#> │   │   ├── regional_mortality_multiplier.html
#> │   │   ├── regional_mortality_multiplier.md
#> │   │   ├── risk_components.html
#> │   │   ├── risk_components.md
#> │   │   ├── risk_data_sources.html
#> │   │   ├── risk_data_sources.md
#> │   │   ├── risk_equivalence.html
#> │   │   ├── risk_equivalence.md
#> │   │   ├── risk_exchange_matrix.html
#> │   │   ├── risk_exchange_matrix.md
#> │   │   ├── risk_for_duration.html
#> │   │   ├── risk_for_duration.md
#> │   │   ├── risk_sources.html
#> │   │   ├── risk_sources.md
#> │   │   ├── theme_micromort_dark-1.png
#> │   │   ├── theme_micromort_dark.html
#> │   │   ├── theme_micromort_dark.md
#> │   │   ├── vaccination_risks.html
#> │   │   ├── vaccination_risks.md
#> │   │   ├── value_of_micromort.html
#> │   │   ├── value_of_micromort.md
#> │   │   ├── vanguard_regions.html
#> │   │   └── vanguard_regions.md
#> │   ├── search.json
#> │   ├── sitemap.xml
#> │   └── [1;36mtutorials[0m
#> ├── [1;36minst[0m
#> │   ├── [1;36mdashboard[0m
#> │   │   └── about.md
#> │   ├── [1;36mextdata[0m
#> │   │   ├── acute_risks.parquet
#> │   │   ├── chronic_risks.parquet
#> │   │   ├── [1;36mlogs[0m
#> │   │   ├── regional_life_expectancy.parquet
#> │   │   └── risk_sources.parquet
#> │   └── [1;36mplumber[0m
#> │       └── api.R
#> ├── [1;36mman[0m
#> │   ├── acute_risks.Rd
#> │   ├── annual_risk_budget.Rd
#> │   ├── as_microlife.Rd
#> │   ├── as_micromort.Rd
#> │   ├── as_probability.Rd
#> │   ├── atomic_risks.Rd
#> │   ├── cancer_risks.Rd
#> │   ├── chronic_risks.Rd
#> │   ├── common_risks.Rd
#> │   ├── compare_interventions.Rd
#> │   ├── conditional_risk.Rd
#> │   ├── covid_vaccine_rr.Rd
#> │   ├── daily_hazard_rate.Rd
#> │   ├── demographic_factors.Rd
#> │   ├── [1;36mfigures[0m
#> │   │   └── README-plot-1.png
#> │   ├── hedged_portfolio.Rd
#> │   ├── laggard_regions.Rd
#> │   ├── launch_api.Rd
#> │   ├── launch_dashboard.Rd
#> │   ├── launch_quiz.Rd
#> │   ├── lifestyle_tradeoff.Rd
#> │   ├── lle.Rd
#> │   ├── load_acute_risks.Rd
#> │   ├── load_chronic_risks.Rd
#> │   ├── load_sources.Rd
#> │   ├── patient_radiation_comparison.Rd
#> │   ├── plot_risk_components.Rd
#> │   ├── plot_risks.Rd
#> │   ├── plot_risks_interactive.Rd
#> │   ├── prepare_risks_plot.Rd
#> │   ├── quiz_pairs.Rd
#> │   ├── radiation_profiles.Rd
#> │   ├── regional_life_expectancy.Rd
#> │   ├── regional_mortality_multiplier.Rd
#> │   ├── risk_components.Rd
#> │   ├── risk_data_sources.Rd
#> │   ├── risk_equivalence.Rd
#> │   ├── risk_exchange_matrix.Rd
#> │   ├── risk_for_duration.Rd
#> │   ├── risk_sources.Rd
#> │   ├── theme_micromort_dark.Rd
#> │   ├── vaccination_risks.Rd
#> │   ├── value_of_micromort.Rd
#> │   └── vanguard_regions.Rd
#> ├── [35mnix-shell-root[0m
#> ├── package.nix
#> ├── [1;36mpkgdown[0m
#> │   ├── extra.css
#> │   └── extra.js
#> ├── [1;36mplans[0m
#> │   ├── PLAN_consistency_refactor.md
#> │   ├── PLAN_regional_longevity.md
#> │   ├── PLAN_risk_equivalence_dashboard.md
#> │   └── PLAN_vignette_targets_refactor.md
#> ├── [31mpush_to_cachix.sh[0m
#> ├── [1;36mtests[0m
#> │   └── [1;36mtestthat[0m
#> │       ├── [1;36m_snaps[0m
#> │       ├── test-adversarial.R
#> │       ├── test-api.R
#> │       ├── test-atomic-risks.R
#> │       ├── test-diagrams.R
#> │       ├── test-quiz.R
#> │       ├── test-radiation-profiles.R
#> │       ├── test-risk-components.R
#> │       ├── test-risk-equivalence.R
#> │       └── test-visualization.R
#> └── [1;36mvignettes[0m
#>     ├── [1;36m_extensions[0m
#>     │   └── [1;36mquarto-ext[0m
#>     ├── architecture.qmd
#>     ├── confounding.Rmd
#>     ├── introduction.Rmd
#>     ├── palatable_units.Rmd
#>     ├── quiz_shinylive.qmd
#>     ├── [1;36mquiz_shinylive_files[0m
#>     ├── regional_variation.Rmd
#>     ├── rest_api.Rmd
#>     ├── risk_equivalence.Rmd
#>     └── shinylive-sw.js
```

</details>

## Contributing

Contributions are welcome! Please:

1. **Report issues** at [GitHub Issues](https://github.com/JohnGavin/micromort/issues)
2. **Submit PRs** following the [tidyverse style guide](https://style.tidyverse.org/)
3. **Add data** - New risk sources welcome! Include:
   - Source URL with citation
   - Units (micromorts per event OR microlives per day)
   - Period specification (per jump, per day, per year, etc.)

### Development Setup

Requires [Nix](https://nixos.org/) (the `./default.sh` script builds a reproducible R environment via Nix):

```bash
# Clone and enter Nix environment
git clone https://github.com/JohnGavin/micromort.git
cd micromort
./default.sh   # Requires Nix — builds reproducible R env with all dependencies

# Run tests
Rscript -e "devtools::test()"

# Check package
Rscript -e "devtools::check()"
```

## Glossary {#glossary}

| Acronym | Full Name | Definition |
|---------|-----------|------------|
| DALY | Disability-Adjusted Life Year | Disease burden = [YLL](#glossary) + [YLD](#glossary). 1 DALY = 1 year of healthy life lost. |
| LLE | Loss of Life Expectancy | Expected lifespan reduction from a risk, in minutes. See `lle()`. |
| QALD | Quality-Adjusted Life Day | 1 day of perfect health. Useful for short-duration conditions. |
| QALY | Quality-Adjusted Life Year | 1 year of perfect health. Used in healthcare cost-effectiveness. |
| VSL | Value of Statistical Life | Monetary value society places on preventing one death (~$10M USD). See `value_of_micromort()`. |
| YLD | Years Lived with Disability | Morbidity component of [DALY](#glossary). Time spent in impaired health. |
| YLL | Years of Life Lost | Mortality component of [DALY](#glossary). Premature death relative to standard life expectancy. |

## References

- Howard RA (1980). "On Making Life and Death Decisions." *Societal Risk Assessment*.
- Spiegelhalter D (2012). "Using speed of ageing and 'microlives'." BMJ 345:e8223. [DOI: 10.1136/bmj.e8223](https://doi.org/10.1136/bmj.e8223)
- Blastland M, Spiegelhalter D (2013). *The Norm Chronicles: Stories and Numbers About Danger*.

## License

MIT © [John Gavin](https://github.com/JohnGavin)

See [LICENSE](LICENSE) for details.
