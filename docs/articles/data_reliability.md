# How Reliable Are These Numbers?

Risk numbers disagree. The WHO and the Institute for Health Metrics and
Evaluation (IHME) report malaria deaths as 550,000 and 760,000
respectively — a 38% gap from the *same underlying deaths*. Our World in
Data’s [Deadliest Animals](https://ourworldindata.org/deadliest-animals)
chart is visually compelling, but converting annual death counts to
per-encounter micromorts is non-trivial. This vignette documents how we
handle that uncertainty.

## 1. Why Risk Numbers Disagree

Three factors drive disagreement between sources:

1.  **Numerator uncertainty**: Death attribution varies by coding system
    (ICD-10 codes, verbal autopsy, hospital records)
2.  **Denominator uncertainty**: How many people were *exposed*? A
    “deaths per year” figure means nothing without knowing the exposure
    population
3.  **Temporal and geographic aggregation**: A global annual average
    hides enormous regional and seasonal variation

Our inclusion criteria: **traceable numerator** + **defined
denominator** + **reproducible calculation**. We reject risks where we
cannot identify both the death count *and* the population at risk.

## 2. The Confidence System

Every entry in
[`atomic_risks()`](https://johngavin.github.io/micromort/reference/atomic_risks.md)
carries a `confidence` tier:

| Tier | Criteria | Example | Source type |
|:---|:---|:---|:---|
| **high** | Peer-reviewed, large-N studies with defined denominators | Medical radiation (NRC dosimetry) | Regulatory agency |
| **medium** | Reputable sources, reasonable denominators, some extrapolation | Wikipedia micromort list, CDC injury data | Secondary compilation |
| **low** | Limited sources, regional uncertainty, or extrapolated denominators | Snake bite in rural Africa (WHO estimate) | Expert estimate |
| **estimated** | Derived by calculation from a model (e.g., LNT for radiation) | Annual cosmic radiation from LNT model | Model-derived |

Confidence tiers with examples from the micromort dataset

### Validation status (new)

Within each confidence tier, we now track how thoroughly the estimate
has been cross-checked:

| Status | Definition | Source count | Example |
|:---|:---|:---|:---|
| `single_source` | One citation, no cross-check | 1 | Most legacy entries from Wikipedia/micromorts.rip |
| `corroborated` | 2+ sources agree within 2x | 2+ | Flight risks (Boeing + NCRP + medical literature) |
| `cross_validated` | 3+ sources, range documented, outliers explained | 3+ | (Future: entries with systematic literature review) |

Validation status levels

| confidence | corroborated | single_source |
|:-----------|-------------:|--------------:|
| high       |           29 |             9 |
| low        |            3 |             0 |
| medium     |           12 |            76 |
| estimated  |            0 |             2 |

Current validation status across all entries

## 3. Geographic and Health Profile Conditioning

Geography is the biggest source of variation in risk data — the same
snake bite ranges from 0.5 mm (US, with antivenom) to 18.5 mm (rural
sub-Saharan Africa) �� a 37x difference. Health profile conditioning
shows similar magnitude: a bee sting is 0.03 mm for the general
population but 31 mm for someone with a known allergy (1,000x).

For the full analysis of how geography and demographics reshuffle risk
rankings, including disease mortality by country
([IHME](https://www.healthdata.org/)
[GBD](https://www.healthdata.org/research-analysis/gbd) data) and
age-conditioned confounders (bed falls, anaesthesia), see the
[Confounding
Variables](https://johngavin.github.io/micromort/articles/confounding.md)
vignette.

The
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)
function supports profile-based filtering:

``` r
# Default: returns high-income, all-ages estimates
common_risks()

# Geographic and health profile conditioning
common_risks(profile = list(country = "NG"))
common_risks(profile = list(health_profile = "allergic"))
```

## 4. Cross-Validation Methods

We use five methods to assess data reliability:

### Source triangulation

Compare the same risk across independent sources. For wildlife risks, we
cross-reference:

- **[OWID](https://ourworldindata.org/)** (Our World in Data) annual
  death counts (numerator)
- **[CDC](https://www.cdc.gov/)** (Centers for Disease Control and
  Prevention) injury surveillance (US denominator)
- **[WHO](https://www.who.int/)** (World Health Organization) fact
  sheets (global denominator)
- **[ISAF](https://www.floridamuseum.ufl.edu/shark-attacks/)**
  (International Shark Attack File) species-specific data

### Denominator audit

The most common failure mode. Does the source report **both** a
numerator (deaths) **and** a denominator (exposures)?

| Animal    | Numerator available? | Denominator available? | Included? |
|-----------|----------------------|------------------------|-----------|
| Shark     | Yes (ISAF)           | Yes (~100M swims/yr)   | Yes       |
| Dog       | Yes (CDC, WHO)       | Yes (4.5M bites US)    | Yes       |
| Mosquito  | Yes (WHO: 600k+)     | No per-encounter rate  | **No**    |
| Crocodile | Yes (CrocBITE)       | No exposure estimate   | **No**    |

### Temporal stability

Has the number changed significantly across editions of the source?
Stable estimates across 5+ years increase confidence.

### Geographic consistency

Do US, UK, and global estimates agree within an order of magnitude?
Large discrepancies suggest unmeasured confounders (see [Confounding
Variables](https://johngavin.github.io/micromort/articles/confounding.md)).

### Order-of-magnitude test

Is the number physically plausible? A micromort value that implies more
deaths than the population can support is a red flag.

## 5. Worked Example: Animal Risks from [OWID](https://ourworldindata.org/)

Our World in Data reports annual deaths by animal. Converting to
per-encounter micromorts requires:

``` math
\text{micromorts} = \frac{\text{deaths per year}}{\text{encounters per year}} \times 10^6
```

| Animal | Annual deaths (approx) | Encounters/yr (approx) | Micromorts | Source for denominator | In dataset? |
|:---|:---|:---|:---|:---|:---|
| Shark | ~6 (US) | ~100M ocean swims | 0.06 | ISAF | Yes |
| Dog (US) | ~30 | ~4.5M bites | 6.7 | CDC | Yes |
| Bee/wasp (US) | ~62 | ~2M stings | 0.03 | CDC | Yes |
| Snake (US) | ~5 | ~10,000 bites | 0.5 | CDC | Yes |
| Snake (Africa) | ~100,000 | ~5.4M bites | 18.5 | WHO/Lancet | Yes |
| Mosquito | ~600,000+ | Unknown per-bite | — | — | **No** |
| Crocodile | ~1,000 | Unknown | — | — | **No** |
| Elephant | ~500 | Unknown | — | — | **No** |

Converting Our World in Data (OWID) annual counts to per-encounter
micromorts

Mosquito, crocodile, and elephant fail our inclusion criteria: there is
no defensible per-encounter denominator. Mosquito bites are ubiquitous
in endemic regions, making a per-bite risk meaningless. We cite
[OWID](https://ourworldindata.org/) for context but do not include these
as micromort entries.

## 6. Estimate Ranges

For wildlife entries, we document plausible ranges reflecting source
disagreement:

| activity | micromorts | estimate_range | source_count | validation_status |
|:---|---:|:---|---:|:---|
| Shark encounter (ocean swim) | 0.06 | 0.03-0.10 | 2 | corroborated |
| Dog bite (US) | 6.70 | 5-10 | 2 | corroborated |
| Dog bite (rabies-endemic) | 160.00 | 100-250 | 2 | corroborated |
| Bee/wasp sting (general) | 0.03 | 0.02-0.05 | 2 | corroborated |
| Bee/wasp sting (allergic) | 31.00 | 20-50 | 2 | corroborated |
| Snake bite (US, with antivenom) | 0.50 | 0.3-1.0 | 2 | corroborated |
| Snake bite (rural sub-Saharan Africa) | 18.50 | 10-30 | 2 | corroborated |

Estimate ranges for wildlife entries

The range reflects uncertainty in both the numerator (death counts vary
by year and reporting) and denominator (exposure estimates are often
rough). The point estimate is our best central value; the range brackets
the plausible minimum and maximum.

## 7. What You Can Contribute

If you find a better source for an existing entry, or want to propose a
new risk: open an issue at
[github.com/johngavin/micromort](https://github.com/johngavin/micromort/issues)
with:

1.  **Numerator**: Death count and source citation
2.  **Denominator**: Exposure count and source citation
3.  **Geography/condition**: Does the estimate apply globally, or to a
    specific population?
4.  **Time period**: When was the data collected?

Entries start at `validation_status = "single_source"` and get upgraded
as more sources confirm them.

### References

- Spiegelhalter D (2009). “Micromorts.” Plus Magazine.
  [plus.maths.org](https://plus.maths.org/os/issue55/features/risk/index)
- Spiegelhalter D (2012). “Microlives.” Plus Magazine.
  [plus.maths.org](https://plus.maths.org/content/understanding-uncertainty-microlives)
- [micromorts.rip](https://micromorts.rip/) — curated micromort database
- [Wikipedia: Micromort](https://en.wikipedia.org/wiki/Micromort)

## Reproducibility

Show code

``` r
sessionInfo()
R version 4.5.2 (2025-10-31)
Platform: aarch64-apple-darwin24.6.0
Running under: macOS Tahoe 26.6.2

Matrix products: default
BLAS:   /nix/store/gf17x1bj3m732n39jznn6kz69szbr5rb-blas-3/lib/libblas.dylib 
LAPACK: /nix/store/5kg4z5bffhr8nry8bl8l5wlxvpy54dm2-openblas-0.3.30/lib/libopenblasp-r0.3.30.dylib;  LAPACK version 3.12.0

locale:
[1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

time zone: Europe/Belfast
tzcode source: internal

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] dplyr_1.1.4     micromort_0.2.0 testthat_3.3.1 

loaded via a namespace (and not attached):
 [1] generics_0.1.4     digest_0.6.39      magrittr_2.0.4     evaluate_1.0.5    
 [5] grid_4.5.2         RColorBrewer_1.1-3 pkgload_1.4.1      fastmap_1.2.0     
 [9] rprojroot_2.1.1    jsonlite_2.0.0     processx_3.8.6     pkgbuild_1.4.8    
[13] backports_1.5.0    brio_1.1.5         secretbase_1.0.5   ps_1.9.1          
[17] purrr_1.2.0        scales_1.4.0       codetools_0.2-20   cli_3.6.5         
[21] rlang_1.1.6        units_1.0-0        bit64_4.6.0-1      withr_3.0.2       
[25] yaml_2.3.12        otel_0.2.0         tools_4.5.2        checkmate_2.3.3   
[29] base64url_1.4      ggplot2_4.0.1      credentials_2.0.3  assertthat_0.2.1  
[33] vctrs_0.6.5        R6_2.6.1           lifecycle_1.0.4    fs_1.6.6          
[37] bit_4.6.0          usethis_3.2.1      targets_1.11.4     arrow_22.0.0      
[41] callr_3.7.6        pkgconfig_2.0.3    desc_1.4.3         pillar_1.11.1     
[45] gtable_0.3.6       data.table_1.18.0  glue_1.8.0         Rcpp_1.1.0        
[49] gert_2.2.0         xfun_0.55          tibble_3.3.0       tidyselect_1.2.1  
[53] sys_3.4.3          knitr_1.51         farver_2.1.2       igraph_2.2.1      
[57] htmltools_0.5.9    rmarkdown_2.30     compiler_4.5.2     prettyunits_1.2.0 
[61] S7_0.2.1           askpass_1.2.1      openssl_2.3.4     
```

------------------------------------------------------------------------

**micromort**
[0.1.0](https://github.com/JohnGavin/micromort/releases/tag/v0.1.0) \|
**Git**
[`94d93d2`](https://github.com/JohnGavin/micromort/commit/94d93d29c29c25f1b4833b6c65731ca9411cb15f)
\| **R**
[4.5.2](https://cran.r-project.org/doc/manuals/r-release/NEWS.html) \|
**Built** 2026-04-18 12:20:56
