# Confounding Variables in Risk Data

Population-average risk statistics can be dangerously misleading when
**confounding variables** — unmeasured or ignored factors that correlate
with both exposure and outcome — drive most of the variation. This
vignette illustrates how conditioning on the right variable can change a
risk estimate by orders of magnitude.

For data quality criteria and denominator problems that motivate this
analysis, see the [Data Quality
section](https://johngavin.github.io/micromort/articles/introduction.html#data-quality-the-denominator-problem)
of the introduction. For the conditional risk functions used throughout
this package, see [Conditional
Risks](https://johngavin.github.io/micromort/articles/introduction.html#conditional-risks-cancer-vaccination-and-risk-hedging).

## 1. Simpson’s Paradox in Risk Data

**Simpson’s paradox** occurs when a trend that appears in aggregated
data reverses or disappears when the data is split by a confounding
variable. Risk data is especially vulnerable because:

- **Exposure varies by subgroup**: Not everyone faces the same hazard
  equally
- **Susceptibility varies by subgroup**: Age, genetics, and occupation
  change vulnerability
- **Reporting conflates subgroups**: A single “micromorts per year”
  figure averages across vastly different populations

The result: a population-average micromort value may describe *nobody*
accurately.

## 2. Flagship Example: Bed Falls (Age as Confounder)

Falling out of bed kills ~450 Americans per year
([CPSC](https://www.cpsc.gov/Newsroom/News-Releases/2022/Older-Americans-Are-More-Likely-to-Suffer-Fatalities-from-Falls-and-Fire-CPSC-Report-Highlights-Hidden-Hazards-Around-the-Home)).
The population average is **1.36 micromorts/year**. But age is a massive
confounder — the [CDC age-stratified
data](https://www.cdc.gov/nchs/products/databriefs/db532.htm) reveals a
**2,500-fold** difference:

| Age group | Sex    | Fall deaths per 100,000/year | Micromorts per night |
|-----------|--------|------------------------------|----------------------|
| Under 65  | Both   | ~0.4                         | **0.004**            |
| 65–74     | Male   | 24.7                         | **0.68**             |
| 65–74     | Female | 14.2                         | **0.39**             |
| 85+       | Male   | 373.3                        | **10.2**             |
| 85+       | Female | 319.7                        | **8.8**              |

### What 10 micromorts per night means

For an 85-year-old man, going to bed carries ~10 micromorts — comparable
to:

- Riding a motorcycle 60 miles (10 micromorts/trip)
- A single ecstasy dose (13 micromorts/dose)
- A day of skiing (0.7 micromorts/day) repeated **14 times**

For someone under 65, the same activity carries 0.004 micromorts per
night — essentially zero. The population average of 1.36/year describes
neither group accurately.

### The confounding mechanism

Age confounds the bed fall risk through two pathways:

1.  **Fragility**: Older adults have lower bone density, slower
    reflexes, and higher complication rates from identical falls
2.  **Bed type and environment**: Hospital beds, care home beds, and
    medication-induced drowsiness increase fall frequency in older
    populations

Neither pathway is captured by the aggregate statistic.

## 3. Further Examples

### 3.1 Bee and wasp stings (allergy as confounder)

Bee and wasp stings kill 72 Americans per year ([CDC
MMWR](https://www.cdc.gov/mmwr/volumes/68/wr/mm6829a5.htm)). The
population rate is 0.22 micromorts/year. But nearly all fatalities are
among the ~1% with venom allergy ([JACI,
2015](https://doi.org/10.1016/j.jaci.2015.07.017)):

| Subgroup            | Prevalence  | Risk per sting           |
|---------------------|-------------|--------------------------|
| No allergy (~99%)   | 327M people | **~0 micromorts**        |
| Venom allergy (~1%) | 3.3M people | **~22 micromorts/sting** |

The confounder (allergy status) is binary and creates an extreme bimodal
distribution. The population average — 0.22 micromorts/year — is
meaningless for both groups.

### 3.2 Cow trampling (occupation as confounder)

Cattle kill 22 Americans per year ([CDC
MMWR](https://www.cdc.gov/mmwr/volumes/64/wr/mm6446a8.htm)). Population
rate: 0.07 micromorts/year. But exposure is concentrated among ~2.9
million cattle workers:

| Subgroup       | Population | Micromorts/year |
|----------------|------------|-----------------|
| General public | ~328M      | **~0**          |
| Cattle farmers | ~2.9M      | **~7.5**        |

That’s a **100-fold** difference. Occupation is the confounder: it
determines both exposure frequency (daily cattle handling vs never) and
risk magnitude (confined spaces, agitated animals, kick zones).

### 3.3 Lightning strike (outdoor work as confounder)

Lightning kills 28 Americans per year
([NOAA](https://www.weather.gov/safety/lightning-fatalities)).
Population rate: 0.08 micromorts/year. But outdoor agricultural workers
face ~15x the risk:

| Subgroup                    | Micromorts/year |
|-----------------------------|-----------------|
| Indoor worker               | **~0.02**       |
| Outdoor recreational        | **~0.3**        |
| Outdoor agricultural worker | **~1.2**        |

The confounders are occupation and behaviour: time spent outdoors, in
open fields, near tall objects, and during storm season.

### 3.4 Drowning (age and setting as confounders)

Drowning kills ~4,000 Americans per year
([CDC](https://www.cdc.gov/drowning/data/index.html)). The population
rate is ~12 micromorts/year. But the risk distribution is bimodal:

| Subgroup           | Drowning rate per 100,000/year |
|--------------------|--------------------------------|
| Children 1–4       | **7.6**                        |
| Adults 25–64       | **1.2**                        |
| Males (all ages)   | **3.5**                        |
| Females (all ages) | **0.8**                        |

Age and sex are strong confounders. Setting matters too: swimming pools
(children), natural water (adults), and bathtubs (elderly,
alcohol-related) each have distinct risk profiles that the aggregate
hides.

## 4. Recognising Confounders in Risk Data

A confounding variable must satisfy two conditions:

1.  **Correlated with exposure**: The confounder determines who is
    exposed (e.g., farmers are exposed to cattle; office workers are
    not)
2.  **Correlated with outcome**: The confounder affects the probability
    of death given exposure (e.g., age affects fall mortality; allergy
    affects sting mortality)

### Warning signs of confounded risk data

| Warning sign | Example |
|----|----|
| Risk applies to “general population” | Cow trampling at 0.07 micromorts/year |
| Denominator is “per year” for an activity not everyone does | Horse riding at 0.5 micromorts/ride conflated with per-year |
| No age stratification | Bed fall deaths without age breakdown |
| No occupational stratification | Lightning deaths without indoor/outdoor split |
| Dramatic differences between sources | Different studies report 10x different values for the same activity |

### What to do

When you encounter a population-average risk:

1.  **Ask “conditional on what?”** — identify the most likely
    confounders (age, sex, occupation, geography, pre-existing
    conditions)
2.  **Seek stratified data** — government agencies (CDC, CPSC, NOAA)
    often publish age- and sex-stratified breakdowns
3.  **Calculate conditional rates** — use
    [`conditional_risk()`](https://johngavin.github.io/micromort/reference/conditional_risk.md)
    from this package to compare hedged vs unhedged scenarios
4.  **Report the range, not the average** — a range like “0.004–10.2
    micromorts/night depending on age” is more informative than “1.36
    micromorts/year”

## 5. Geographic Confounding: Snake Bites

Geography is arguably the most powerful confounder in risk data. The
same encounter — a snake bite — has vastly different outcomes depending
on location:

Show code

``` r
ar <- atomic_risks()
ar |>
  dplyr::filter(grepl("snake_bite", activity_id, ignore.case = TRUE)) |>
  dplyr::select(activity, micromorts, condition_value, hedge_description, confidence) |>
  knitr::kable(digits = 1)
```

| activity | micromorts | condition_value | hedge_description | confidence |
|:---|---:|:---|:---|:---|
| Snake bite (US, with antivenom) | 0.5 | high_income | Wear boots in snake habitat, carry pressure bandage | medium |
| Snake bite (rural sub-Saharan Africa) | 18.5 | low_income | Footwear, torch at night, proximity to clinic | low |

Snake bite micromorts by geography

The 37x difference between the US and rural sub-Saharan Africa reflects
differences in antivenom availability, hospital proximity, and emergency
transport infrastructure — not differences in snake venom potency. A
population-average snake bite risk that blends these geographies would
be misleading for everyone: too high for Americans, too low for rural
Africans.

The same pattern applies to dog bites (24x difference driven by rabies
PEP availability). For more on the systematic framework behind these
geographic estimates, see the [Data
Reliability](https://johngavin.github.io/micromort/articles/data_reliability.md)
vignette.

## 6. Implications for the Micromort Package

This package addresses confounding in several ways:

- **Geographic conditioning** via
  `filter_by_profile(list(geography = "low_income"))` compares high- and
  low-income variants of the same risk

- **[`conditional_risk()`](https://johngavin.github.io/micromort/reference/conditional_risk.md)**
  and
  **[`hedged_portfolio()`](https://johngavin.github.io/micromort/reference/hedged_portfolio.md)**
  explicitly compare conditioned subgroups
  ([documentation](https://johngavin.github.io/micromort/reference/conditional_risk.md))

- **[`cancer_risks()`](https://johngavin.github.io/micromort/reference/cancer_risks.md)**
  stratifies by sex, age group, and family history

- **[`vaccination_risks()`](https://johngavin.github.io/micromort/reference/vaccination_risks.md)**
  stratifies by age group and vaccine type

- **[`regional_life_expectancy()`](https://johngavin.github.io/micromort/reference/regional_life_expectancy.md)**
  stratifies by geography, capturing regional confounders

- **Data quality criteria** in the
  [Introduction](https://johngavin.github.io/micromort/articles/introduction.html#data-quality-the-denominator-problem)
  exclude risks with unknown denominators that would mask confounding

The general principle: **a micromort value is only as good as its
denominator and conditioning variables**.

## References

- Spiegelhalter D (2012). “Using speed of ageing and ‘microlives’ to
  communicate the effects of lifetime habits and environment.” *BMJ*
  345:e8223. [doi:10.1136/bmj.e8223](https://doi.org/10.1136/bmj.e8223)
- CDC MMWR (2019). “Hymenoptera stings.”
  [cdc.gov/mmwr/volumes/68/wr/mm6829a5.htm](https://www.cdc.gov/mmwr/volumes/68/wr/mm6829a5.htm)
- CDC Data Brief 532. “Deaths from unintentional falls.”
  [cdc.gov/nchs/products/databriefs/db532.htm](https://www.cdc.gov/nchs/products/databriefs/db532.htm)
- CPSC (2022). “Older Americans Are More Likely to Suffer Fatalities
  from Falls.”
  [cpsc.gov](https://www.cpsc.gov/Newsroom/News-Releases/2022/Older-Americans-Are-More-Likely-to-Suffer-Fatalities-from-Falls-and-Fire-CPSC-Report-Highlights-Hidden-Hazards-Around-the-Home)
- NOAA. “Lightning fatalities.”
  [weather.gov/safety/lightning-fatalities](https://www.weather.gov/safety/lightning-fatalities)
- CDC. “Drowning data.”
  [cdc.gov/drowning/data](https://www.cdc.gov/drowning/data/index.html)
- Golden DB et al. (2015). “Stinging insect hypersensitivity.” *JACI*
  135(6):1429–35.
  [doi:10.1016/j.jaci.2015.07.017](https://doi.org/10.1016/j.jaci.2015.07.017)

## Reproducibility

Show code

``` r
sessionInfo()
#> R version 4.5.2 (2025-10-31)
#> Platform: aarch64-apple-darwin25.2.0
#> Running under: macOS Tahoe 26.3
#> 
#> Matrix products: default
#> BLAS:   /nix/store/ab8sq4g14lg45192ykfqcklgw6fvaswh-blas-3/lib/libblas.dylib 
#> LAPACK: /nix/store/ssl6kfm7w37gz5pn57jn2x7xzw3bss24-openblas-0.3.30/lib/libopenblasp-r0.3.30.dylib;  LAPACK version 3.12.0
#> 
#> locale:
#> [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
#> 
#> time zone: Europe/Belfast
#> tzcode source: internal
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] micromort_0.1.0 testthat_3.3.2 
#> 
#> loaded via a namespace (and not attached):
#>  [1] bit_4.6.0          gtable_0.3.6       jsonlite_2.0.0     dplyr_1.1.4       
#>  [5] compiler_4.5.2     brio_1.1.5         tidyselect_1.2.1   assertthat_0.2.1  
#>  [9] scales_1.4.0       arrow_22.0.0       credentials_2.0.3  yaml_2.3.12       
#> [13] fastmap_1.2.0      ggplot2_4.0.1      R6_2.6.1           generics_0.1.4    
#> [17] knitr_1.51         backports_1.5.0    tibble_3.3.1       checkmate_2.3.3   
#> [21] desc_1.4.3         rprojroot_2.1.1    openssl_2.3.4      RColorBrewer_1.1-3
#> [25] pillar_1.11.1      rlang_1.1.7        xfun_0.56          S7_0.2.1          
#> [29] fs_1.6.6           sys_3.4.3          bit64_4.6.0-1      pkgload_1.4.1     
#> [33] otel_0.2.0         cli_3.6.5          withr_3.0.2        magrittr_2.0.4    
#> [37] grid_4.5.2         digest_0.6.39      askpass_1.2.1      gert_2.3.1        
#> [41] lifecycle_1.0.5    vctrs_0.7.1        evaluate_1.0.5     glue_1.8.0        
#> [45] farver_2.1.2       pkgbuild_1.4.8     rmarkdown_2.30     purrr_1.2.1       
#> [49] pkgconfig_2.0.3    tools_4.5.2        usethis_3.2.1      htmltools_0.5.9
```
