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

Distribution of validation status in the dataset

## 3. Geographic Conditioning: The Biggest Source of Variation

The same animal encounter can produce dramatically different micromort
values depending on location and healthcare access:

| activity | micromorts | condition_value | confidence | notes |
|:---|---:|:---|:---|:---|
| Dog bite (US) | 6.7 | high_income | medium | CDC: ~30 deaths/yr among ~4.5M bites requiring medical attention |
| Dog bite (rabies-endemic) | 160.0 | low_income | low | WHO: ~40k rabies deaths/yr, mostly dog-mediated |
| Snake bite (US, with antivenom) | 0.5 | high_income | medium | CDC: ~5 deaths/yr among ~10k bites |
| Snake bite (rural sub-Saharan Africa) | 18.5 | low_income | low | WHO/Lancet: ~100k deaths/yr among ~5.4M bites in sub-Saharan Africa |

Geographic conditioning: same encounter, different risk

Snake bite: **0.5 mm** (US, with antivenom) vs **18.5 mm** (rural
Africa) — a **37x difference**. Dog bite: **6.7 mm** (US, with rabies
PEP) vs **160 mm** (rabies-endemic, no treatment) — a **24x
difference**.

### The hedgeability asymmetry

Geography is a **hedgeable conditional risk** — but only for some
people:

- A **tourist** can hedge: choose destination, get travel vaccines,
  carry antivenom kit, buy travel insurance
- A **resident** cannot hedge: they live there, and may lack healthcare
  infrastructure, vaccines, or economic choice

This parallels the existing health profile conditioning. A bee sting is
0.03 mm for someone who is not allergic, but **31 mm** for someone with
a known allergy — a 1,000x difference. The allergic person can hedge
(carry an epinephrine auto-injector), but they cannot eliminate the
underlying vulnerability.

| activity | micromorts | condition_value | hedge_description | hedge_reduction_pct |
|:---|---:|:---|:---|---:|
| Bee/wasp sting (general) | 0.03 | healthy | Avoid nests, wear shoes outdoors | 30 |
| Bee/wasp sting (allergic) | 31.00 | allergic | Carry epinephrine auto-injector, immunotherapy | 95 |

Health profile conditioning: same sting, different risk

### Using geographic filtering

``` r
# Default: returns high-income estimates
common_risks() |> filter(category == "Wildlife")

# Explicitly request low-income geography
common_risks(profile = list(geography = "low_income")) |> filter(category == "Wildlife")

# Combine with health profile
common_risks(profile = list(geography = "low_income", health_profile = "allergic"))
```

## 4. Cross-Validation Methods

We use five methods to assess data reliability:

### Source triangulation

Compare the same risk across independent sources. For wildlife risks, we
cross-reference:

- **OWID** annual death counts (numerator)
- **CDC** injury surveillance (US denominator)
- **WHO** fact sheets (global denominator)
- **ISAF** shark attack database (species-specific data)

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

## 5. Worked Example: Animal Risks from OWID

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

Converting OWID annual counts to per-encounter micromorts

Mosquito, crocodile, and elephant fail our inclusion criteria: there is
no defensible per-encounter denominator. Mosquito bites are ubiquitous
in endemic regions, making a per-bite risk meaningless. We cite OWID for
context but do not include these as micromort entries.

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
