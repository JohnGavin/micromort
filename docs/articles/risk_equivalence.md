# Risk Equivalence Dashboard

Micromorts provide a **common currency** for comparing risks that
otherwise seem incommensurable. How dangerous is a CT scan compared to a
skydive? How many chest X-rays equal a long-haul flight?

This dashboard explores these questions using **atomic risk
decomposition** — breaking composite activities into their individual
risk components so you can see exactly what you’re exposed to, and what
you can mitigate.

## Everyday Risk Budget

- Table
- Chart

How risky are the mundane things we do every day?

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

Everyday activities expressed in chest X-ray equivalents:

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

## Flight Risk Decomposition

Flying is a composite risk: crash + deep vein thrombosis (DVT) + cosmic
radiation. The **atomic decomposition** reveals which components
dominate at each duration, and which you can mitigate.

- By Duration
- By Health Status
- Components

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

Key observations:

- **Crash risk** is roughly constant per flight (~1 mm) regardless of
  duration — dominated by takeoff and landing phases (~80% of fatal
  accidents per Boeing Statistical Summary) — and is NOT hedgeable
- **DVT risk** is zero below 4 hours, then grows nonlinearly — and IS
  hedgeable (compression socks reduce risk ~65%)
- **Cosmic radiation** is linear (~0.05 mm/hour) and NOT hedgeable
- For an 8-hour flight, DVT is the dominant hedgeable component

How does DVT risk status change the total?

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

- Surprise Table
- Interactive Explorer

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

Full risk equivalence table with every activity expressed relative to a
chest X-ray:

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

- Comparison Table
- Exchange Chart

Medical imaging procedures vary enormously in radiation dose:

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

How many chest X-rays equal one CT scan?

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

## Hedgeability Analysis

- By Activity
- Stacked Components

Which activities have hedgeable risk components?

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

Flight risk decomposition showing hedgeable vs non-hedgeable portions:

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

## Radiation Exposure Profiles

How does occupational radiation exposure compare across careers, and how
do patient X-ray doses stack up? This section uses annual dose data from
UNSCEAR and the LNT model (0.05 micromorts per mSv) to answer these
questions.

- Occupational Comparison
- Patient vs Occupational
- Timeline
- Regulatory Context

Annual and cumulative radiation exposure across 11 profiles —
occupational, passenger, and environmental:

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

How many patient X-rays equal a career of occupational exposure?

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

Cumulative radiation exposure over a 40-year career:

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

How do actual doses compare to ICRP regulatory limits?

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
alternatives.

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
