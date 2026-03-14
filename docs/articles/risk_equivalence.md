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

Show code

``` r
everyday <- safe_tar_read("vig_equiv_everyday")
if (!is.null(everyday)) {
  DT::datatable(
    everyday,
    caption = "Everyday activities ranked by micromort risk, with chest X-ray equivalents",
    options = list(pageLength = 15, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatRound(c("micromorts", "microlives", "micromorts_per_day"), 2)
}
```

### Chart

Everyday activities expressed in chest X-ray equivalents:

Show code

``` r
everyday <- safe_tar_read("vig_equiv_everyday")
if (!is.null(everyday) && requireNamespace("plotly", quietly = TRUE)) {
  plotly::plot_ly(
    everyday,
    y = ~stats::reorder(activity, xray_equivalents),
    x = ~xray_equivalents,
    type = "bar",
    orientation = "h",
    marker = list(color = "#1976D2")
  ) |>
    plotly::layout(
      title = "Everyday Activities in Chest X-ray Equivalents",
      xaxis = list(title = "Chest X-ray equivalents"),
      yaxis = list(title = ""),
      margin = list(l = 200),
      paper_bgcolor = "white",
      plot_bgcolor = "white",
      font = list(color = "#1a1a1a")
    ) |>
    plotly::config(scrollZoom = TRUE)
}
```

Everyday activities expressed in chest X-ray equivalents, showing that a
long-haul flight equals ~50 chest X-rays while a banana is negligible.

## Flight Risk Decomposition

Flying is a composite risk: crash + deep vein thrombosis (DVT) + cosmic
radiation. The **atomic decomposition** reveals which components
dominate at each duration, and which you can mitigate.

### By Duration

Show code

``` r
flight_data <- safe_tar_read("vig_equiv_flight_duration")
if (!is.null(flight_data) && requireNamespace("plotly", quietly = TRUE)) {
  plotly::plot_ly(
    flight_data,
    x = ~activity,
    y = ~micromorts,
    color = ~component_label,
    type = "bar"
  ) |>
    plotly::layout(
      barmode = "stack",
      title = "Flight Risk by Duration and Component (Healthy Profile)",
      xaxis = list(title = ""),
      yaxis = list(title = "Micromorts"),
      legend = list(orientation = "h", y = -0.2, font = list(color = "#1a1a1a"),
                    bgcolor = "rgba(255,255,255,0.9)"),
      paper_bgcolor = "white",
      plot_bgcolor = "white",
      font = list(color = "#1a1a1a")
    ) |>
    plotly::config(scrollZoom = TRUE)
}
```

Stacked bar chart decomposing flight risk into crash, DVT, and cosmic
radiation components across 2h, 5h, 8h, and 12h flights.

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

Show code

``` r
components <- safe_tar_read("vig_equiv_flight_components")
if (!is.null(components)) {
  DT::datatable(
    components,
    caption = "Flying (8h long-haul): Healthy vs DVT risk factors",
    options = list(pageLength = 10, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatRound("micromorts", 1)
}
```

### Components

Show code

``` r
# Show all flight components across durations
flight_data <- safe_tar_read("vig_equiv_flight_duration")
if (!is.null(flight_data)) {
  DT::datatable(
    flight_data,
    caption = "All flight risk components by duration (healthy profile)",
    options = list(pageLength = 20, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatRound("micromorts", 2)
}
```

## Landmark Equivalences

### Surprise Table

Show code

``` r
landmarks <- safe_tar_read("vig_equiv_landmarks")
if (!is.null(landmarks)) {
  DT::datatable(
    landmarks |>
      dplyr::select(activity, micromorts, category, xray_equivalents),
    caption = "Landmark activities from coffee to Everest, in chest X-ray equivalents",
    options = list(pageLength = 20, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatRound("micromorts", 2)
}
```

### Interactive Explorer

Full risk equivalence table with every activity expressed relative to a
chest X-ray:

Show code

``` r
explorer <- safe_tar_read("vig_equiv_explorer")
if (!is.null(explorer)) {
  DT::datatable(
    explorer,
    caption = "All activities as multiples of one chest X-ray (0.1 micromorts)",
    options = list(pageLength = 15, dom = "ftip", scrollX = TRUE),
    filter = "top",
    rownames = FALSE
  ) |>
    DT::formatRound(c("micromorts", "ratio"), 2)
}
```

## Medical Radiation

### Comparison Table

Medical imaging procedures vary enormously in radiation dose:

Show code

``` r
med <- safe_tar_read("vig_equiv_medical_focus")
if (!is.null(med)) {
  DT::datatable(
    med |> dplyr::select(activity, micromorts, microlives, period),
    caption = "Medical radiation procedures ranked by micromort risk",
    options = list(pageLength = 10, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatRound(c("micromorts", "microlives"), 2)
}
```

### Exchange Chart

How many chest X-rays equal one CT scan?

Show code

``` r
med <- safe_tar_read("vig_equiv_medical_focus")
if (!is.null(med) && requireNamespace("plotly", quietly = TRUE)) {
  med <- med |>
    dplyr::mutate(xray_equiv = round(micromorts / 0.1, 0))

  plotly::plot_ly(
    med,
    y = ~stats::reorder(activity, xray_equiv),
    x = ~xray_equiv,
    type = "bar",
    orientation = "h",
    marker = list(color = "#C62828")
  ) |>
    plotly::layout(
      title = "Medical Procedures in Chest X-ray Equivalents",
      xaxis = list(title = "Number of chest X-rays"),
      yaxis = list(title = ""),
      margin = list(l = 200),
      paper_bgcolor = "white",
      plot_bgcolor = "white",
      font = list(color = "#1a1a1a")
    ) |>
    plotly::config(scrollZoom = TRUE)
}
```

Medical procedures ranked by chest X-ray equivalents, showing that a CT
abdomen equals ~200 chest X-rays.

## Hedgeability Analysis

### By Activity

Which activities have hedgeable risk components?

Show code

``` r
hedgeable <- safe_tar_read("vig_equiv_hedgeable_summary")
if (!is.null(hedgeable)) {
  DT::datatable(
    hedgeable,
    caption = "Activities with hedgeable risk components (sorted by hedgeable %)",
    options = list(pageLength = 10, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatRound("hedgeable_pct", 1)
}
```

### Stacked Components

Flight risk decomposition showing hedgeable vs non-hedgeable portions:

Show code

``` r
flight_data <- safe_tar_read("vig_equiv_flight_duration")
if (!is.null(flight_data) && requireNamespace("plotly", quietly = TRUE)) {
  flight_data <- flight_data |>
    dplyr::mutate(
      hedge_status = ifelse(hedgeable, "Hedgeable", "Not hedgeable")
    )

  plotly::plot_ly(
    flight_data,
    x = ~activity,
    y = ~micromorts,
    color = ~hedge_status,
    colors = c("Hedgeable" = "#2E7D32", "Not hedgeable" = "#C62828"),
    type = "bar"
  ) |>
    plotly::layout(
      barmode = "stack",
      title = "Hedgeable vs Non-hedgeable Risk by Flight Duration",
      xaxis = list(title = ""),
      yaxis = list(title = "Micromorts"),
      legend = list(orientation = "h", y = -0.2, font = list(color = "#1a1a1a"),
                    bgcolor = "rgba(255,255,255,0.9)"),
      paper_bgcolor = "white",
      plot_bgcolor = "white",
      font = list(color = "#1a1a1a")
    ) |>
    plotly::config(scrollZoom = TRUE)
}
```

Flight risk decomposition by hedgeability: DVT risk (green, hedgeable
via compression socks) vs crash and radiation (red, not hedgeable).

## Radiation Exposure Profiles

How does occupational radiation exposure compare across careers, and how
do patient X-ray doses stack up? This section uses annual dose data from
UNSCEAR and the LNT model (0.05 micromorts per mSv) to answer these
questions.

### Occupational Comparison

Annual and cumulative radiation exposure across 11 profiles —
occupational, passenger, and environmental:

Show code

``` r
rad_profiles <- safe_tar_read("vig_radiation_profiles")
if (!is.null(rad_profiles)) {
  DT::datatable(
    rad_profiles,
    caption = "Radiation exposure profiles: annual dose and cumulative micromorts at career milestones",
    options = list(pageLength = 15, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatRound(c("annual_msv", "annual_micromorts",
                       "mm_10y", "mm_20y", "mm_40y",
                       "xray_equivalents_per_year"), 3)
}
```

Key insight: A 40-year airline pilot career accumulates ~6 micromorts of
radiation — equivalent to just 60 chest X-rays.

### Patient vs Occupational

How many patient X-rays equal a career of occupational exposure?

Show code

``` r
prc <- safe_tar_read("vig_radiation_patient_vs_occ")
if (!is.null(prc)) {
  DT::datatable(
    prc,
    caption = "Patient X-ray exposure vs occupational career radiation (ratio > 1 means patient exceeds worker)",
    options = list(pageLength = 15, dom = "tip", scrollX = TRUE),
    filter = "top",
    rownames = FALSE
  ) |>
    DT::formatRound(c("patient_micromorts", "occupational_micromorts", "ratio"), 3)
}
```

Key insight: 100 lifetime chest X-rays (10 micromorts) exceeds a 40-year
X-ray technician career (2 micromorts) by 5x.

### Timeline

Cumulative radiation exposure over a 40-year career:

Show code

``` r
timeline <- safe_tar_read("vig_radiation_timeline_data")
if (!is.null(timeline) && requireNamespace("plotly", quietly = TRUE)) {
  plotly::plot_ly(
    timeline,
    x = ~year,
    y = ~cumulative_micromorts,
    color = ~activity,
    type = "scatter",
    mode = "lines"
  ) |>
    plotly::layout(
      title = "Cumulative Radiation Micromorts Over Career",
      xaxis = list(title = "Years of Exposure"),
      yaxis = list(title = "Cumulative Micromorts"),
      legend = list(orientation = "v", x = 1.02, y = 1, font = list(color = "#1a1a1a"),
                    bgcolor = "rgba(255,255,255,0.9)"),
      paper_bgcolor = "white",
      plot_bgcolor = "white",
      font = list(color = "#1a1a1a")
    ) |>
    plotly::config(scrollZoom = TRUE)
}
#> Warning in RColorBrewer::brewer.pal(max(N, 3L), "Set2"): n too large, allowed maximum for palette Set2 is 8
#> Returning the palette you asked for with that many colors
#> Warning in RColorBrewer::brewer.pal(max(N, 3L), "Set2"): n too large, allowed maximum for palette Set2 is 8
#> Returning the palette you asked for with that many colors
```

Cumulative radiation micromorts over a 40-year career for different
exposure profiles, showing that 100 lifetime chest X-rays exceeds
occupational exposure.

### Regulatory Context

How do actual doses compare to ICRP regulatory limits?

Show code

``` r
regulatory <- safe_tar_read("vig_radiation_regulatory")
if (!is.null(regulatory)) {
  DT::datatable(
    regulatory,
    caption = "Actual annual doses vs ICRP limits (occupational: 20 mSv/yr, public: 1 mSv/yr)",
    options = list(pageLength = 15, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatRound(c("annual_msv", "pct_of_limit"), 1)
}
```

Key insight: Actual doses are typically 5-20x below regulatory limits.

## Cross-Activity Matrix

Exchange rates between 10 diverse activities. Read as: “one row-activity
equals X column-activities.”

Show code

``` r
mat <- safe_tar_read("vig_equiv_matrix")
if (!is.null(mat)) {
  DT::datatable(
    mat,
    caption = "Risk exchange matrix: cell(i,j) = how many of column j equal one of row i",
    options = list(
      pageLength = 10,
      dom = "t",
      scrollX = TRUE
    ),
    rownames = FALSE
  ) |>
    DT::formatRound(names(mat)[-1], 1)
}
```

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
#> [31] sys_3.4.3           usethis_3.2.1       lazyeval_0.2.2     
#> [34] yaml_2.3.12         plotly_4.12.0       tidyr_1.3.2        
#> [37] jquerylib_0.1.4     pillar_1.11.1       openssl_2.3.4      
#> [40] cachem_1.1.0        tidyselect_1.2.1    digest_0.6.39      
#> [43] dplyr_1.1.4         purrr_1.2.1         arrow_22.0.0       
#> [46] rprojroot_2.1.1     fastmap_1.2.0       grid_4.5.2         
#> [49] cli_3.6.5           magrittr_2.0.4      pkgbuild_1.4.8     
#> [52] withr_3.0.2         prettyunits_1.2.0   scales_1.4.0       
#> [55] backports_1.5.0     bit64_4.6.0-1       httr_1.4.7         
#> [58] rmarkdown_2.30      igraph_2.2.1        bit_4.6.0          
#> [61] otel_0.2.0          askpass_1.2.1       evaluate_1.0.5     
#> [64] knitr_1.51          viridisLite_0.4.2   rlang_1.1.7        
#> [67] gert_2.3.1          glue_1.8.0          pkgload_1.4.1      
#> [70] jsonlite_2.0.0      R6_2.6.1            fs_1.6.6
```
