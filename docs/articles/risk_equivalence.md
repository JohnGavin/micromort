# Risk Equivalence Dashboard

Micromorts provide a **common currency** for comparing risks that
otherwise seem incommensurable. How dangerous is a CT scan compared to a
skydive? How many chest X-rays equal a long-haul flight?

This dashboard explores these questions using **atomic risk
decomposition** — breaking composite activities into their individual
risk components so you can see exactly what you’re exposed to, and what
you can mitigate.

## Everyday Risk Budget

### Table

How risky are the mundane things we do every day?

### Chart

Everyday activities expressed in chest X-ray equivalents:

    #> Target 'vig_equiv_everyday_chart' not found in targets store or RDS fallback.

*Target ‘vig_equiv_everyday_chart’ not available.*

## Flight Risk Decomposition

Flying is a composite risk: crash + deep vein thrombosis (DVT) + cosmic
radiation. The **atomic decomposition** reveals which components
dominate at each duration, and which you can mitigate.

### By Duration

    #> Target 'vig_equiv_flight_duration_chart' not found in targets store or RDS fallback.

*Target ‘vig_equiv_flight_duration_chart’ not available.*

Key observations:

- **Crash risk** is roughly constant per flight (~1 mm) regardless of
  duration — dominated by takeoff and landing phases (~80% of fatal
  accidents per Boeing Statistical Summary) — and is NOT hedgeable
- **DVT risk** is zero below 4 hours, then grows nonlinearly — and IS
  hedgeable (compression socks reduce risk ~65%)
- **Cosmic radiation** is linear (~0.05 mm/hour) and NOT hedgeable
- For an 8-hour flight, DVT is the dominant hedgeable component

### By Health Status

How does DVT risk status change the total?

### Components

## Landmark Equivalences

### Surprise Table

### Interactive Explorer

Full risk equivalence table with every activity expressed relative to a
chest X-ray:

## Medical Radiation

### Comparison Table

Medical imaging procedures vary enormously in radiation dose:

### Exchange Chart

How many chest X-rays equal one CT scan?

    #> Target 'vig_equiv_medical_exchange_chart' not found in targets store or RDS fallback.

*Target ‘vig_equiv_medical_exchange_chart’ not available.*

## Hedgeability Analysis

### By Activity

Which activities have hedgeable risk components?

### Stacked Components

Flight risk decomposition showing hedgeable vs non-hedgeable portions:

    #> Target 'vig_equiv_hedgeable_chart' not found in targets store or RDS fallback.

*Target ‘vig_equiv_hedgeable_chart’ not available.*

## Radiation Exposure Profiles

How does occupational radiation exposure compare across careers, and how
do patient X-ray doses stack up? This section uses annual dose data from
UNSCEAR and the LNT model (0.05 micromorts per mSv) to answer these
questions.

### Occupational Comparison

Annual and cumulative radiation exposure across 11 profiles —
occupational, passenger, and environmental:

Key insight: A 40-year airline pilot career accumulates ~6 micromorts of
radiation — equivalent to just 60 chest X-rays.

### Patient vs Occupational

How many patient X-rays equal a career of occupational exposure?

Key insight: 100 lifetime chest X-rays (10 micromorts) exceeds a 40-year
X-ray technician career (2 micromorts) by 5x.

### Timeline

Cumulative radiation exposure over a 40-year career:

    #> Target 'vig_equiv_radiation_timeline_chart' not found in targets store or RDS fallback.

*Target ‘vig_equiv_radiation_timeline_chart’ not available.*

### Regulatory Context

How do actual doses compare to ICRP regulatory limits?

Key insight: Actual doses are typically 5-20x below regulatory limits.

## Cross-Activity Matrix

Exchange rates between 10 diverse activities. Read as: “one row-activity
equals X column-activities.”

## Methodology & Caveats

**Atomic vs composite risks.** The
[`atomic_risks()`](https://johngavin.github.io/micromort/reference/atomic_risks.md)
function returns ONE row per risk component per activity. Activities not
yet decomposed use `component = "all_causes"` (an honest placeholder
indicating the breakdown is unknown).

**Conditional risks.** Some components depend on health profile (e.g.,
DVT risk varies by whether you have risk factors). The default profile
assumes “healthy” values; use
`common_risks(profile = list(health_profile = "dvt_risk_factors"))` for
alternatives. Geographic conditioning can change equivalences
dramatically: a snake bite is 0.5 mm in the US but 18.5 mm in rural
Africa (37x). See the [Data
Reliability](https://johngavin.github.io/micromort/articles/data_reliability.md)
vignette for details.

**Duration bucketing.** Rather than encoding rate functions, flight
risks are pre-computed at standard duration buckets (2h, 5h, 8h, 12h).
Every number is directly citable — no hidden formulas.

**DVT literature.** DVT risk below 4 hours is negligible. Above 4 hours,
risk rises nonlinearly. Compression socks + hydration + movement reduce
DVT risk by approximately 60–70%. Sources: Lancet Haematology, Cochrane
Reviews.

**Medical radiation.** The “(radiation)” label indicates that the
radiation dose IS the risk. For invasive procedures (e.g., coronary
angiogram), procedural risks (infection, bleeding) are separate
components not yet decomposed.

**Confidence levels.** Each component carries a confidence rating:
“high” (published meta-analyses), “medium” (single studies or expert
consensus), “low” (extrapolated), “estimated” (order-of-magnitude).

## Reproducibility

Show code

``` r
sessionInfo()
#> R version 4.5.2 (2025-10-31)
#> Platform: aarch64-apple-darwin25.2.0
#> Running under: macOS Tahoe 26.3.1
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
#> [1] DT_0.34.0       targets_1.11.4  micromort_0.1.0 testthat_3.3.2 
#> 
#> loaded via a namespace (and not attached):
#>  [1] gtable_0.3.6        xfun_0.56           bslib_0.10.0       
#>  [4] ggplot2_4.0.1       htmlwidgets_1.6.4   processx_3.8.6     
#>  [7] callr_3.7.6         vctrs_0.7.1         tools_4.5.2        
#> [10] crosstalk_1.2.2     ps_1.9.1            generics_0.1.4     
#> [13] base64url_1.4       tibble_3.3.1        pkgconfig_2.0.3    
#> [16] data.table_1.18.2.1 checkmate_2.3.3     secretbase_1.1.1   
#> [19] RColorBrewer_1.1-3  S7_0.2.1            desc_1.4.3         
#> [22] assertthat_0.2.1    lifecycle_1.0.5     compiler_4.5.2     
#> [25] farver_2.1.2        credentials_2.0.3   brio_1.1.5         
#> [28] codetools_0.2-20    sass_0.4.10         htmltools_0.5.9    
#> [31] sys_3.4.3           usethis_3.2.1       yaml_2.3.12        
#> [34] jquerylib_0.1.4     pillar_1.11.1       openssl_2.3.4      
#> [37] cachem_1.1.0        tidyselect_1.2.1    digest_0.6.39      
#> [40] dplyr_1.1.4         purrr_1.2.1         arrow_22.0.0       
#> [43] rprojroot_2.1.1     fastmap_1.2.0       grid_4.5.2         
#> [46] cli_3.6.5           magrittr_2.0.4      pkgbuild_1.4.8     
#> [49] withr_3.0.2         prettyunits_1.2.0   scales_1.4.0       
#> [52] backports_1.5.0     bit64_4.6.0-1       rmarkdown_2.30     
#> [55] igraph_2.2.1        bit_4.6.0           otel_0.2.0         
#> [58] askpass_1.2.1       evaluate_1.0.5      knitr_1.51         
#> [61] rlang_1.1.7         gert_2.3.1          glue_1.8.0         
#> [64] pkgload_1.4.1       jsonlite_2.0.0      R6_2.6.1           
#> [67] fs_1.6.6
```

------------------------------------------------------------------------

**micromort**
[0.1.0](https://github.com/JohnGavin/micromort/releases/tag/v0.1.0) \|
**Git**
[`94d93d2`](https://github.com/JohnGavin/micromort/commit/94d93d29c29c25f1b4833b6c65731ca9411cb15f)
\| **R**
[4.5.2](https://cran.r-project.org/doc/manuals/r-release/NEWS.html) \|
**Built** 2026-04-18 12:20:56
