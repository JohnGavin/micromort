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

Everyday activities expressed in chest X-ray equivalents, showing that a
long-haul flight equals ~50 chest X-rays while a banana is negligible.

## Flight Risk Decomposition

Flying is a composite risk: crash + deep vein thrombosis (DVT) + cosmic
radiation. The **atomic decomposition** reveals which components
dominate at each duration, and which you can mitigate.

### By Duration

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

Medical procedures ranked by chest X-ray equivalents, showing that a CT
abdomen equals ~200 chest X-rays.

## Hedgeability Analysis

### By Activity

Which activities have hedgeable risk components?

### Stacked Components

Flight risk decomposition showing hedgeable vs non-hedgeable portions:

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

Key insight: A 40-year airline pilot career accumulates ~6 micromorts of
radiation — equivalent to just 60 chest X-rays.

### Patient vs Occupational

How many patient X-rays equal a career of occupational exposure?

Key insight: 100 lifetime chest X-rays (10 micromorts) exceeds a 40-year
X-ray technician career (2 micromorts) by 5x.

### Timeline

Cumulative radiation exposure over a 40-year career:

    #> Warning in RColorBrewer::brewer.pal(max(N, 3L), "Set2"): n too large, allowed maximum for palette Set2 is 8
    #> Returning the palette you asked for with that many colors
    #> Warning in RColorBrewer::brewer.pal(max(N, 3L), "Set2"): n too large, allowed maximum for palette Set2 is 8
    #> Returning the palette you asked for with that many colors

Cumulative radiation micromorts over a 40-year career for different
exposure profiles, showing that 100 lifetime chest X-rays exceeds
occupational exposure.

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
