# Introduction to Micromorts and Risk Visualization

``` r
library(micromort)
library(targets)
library(DT)

# Safe tar_read with graceful fallback
safe_tar_read <- function(name) {
  tryCatch(
    targets::tar_read_raw(name),
    error = function(e) {
      message("Target '", name, "' not found. Run tar_make() first.")
      NULL
    }
  )
}
```

This vignette introduces the **micromort** package, which provides tools
for understanding and visualizing risks.

## 1. Micromorts (Acute Risk)

A **micromort** is a unit of risk representing a one-in-a-million chance
of death. More precisely, it’s a **microprobability** of death — a
one-in-a-million chance of a specific event (death) occurring.

### Definition

| Term | Definition | Example |
|----|----|----|
| **Microprobability** | 1-in-a-million chance of any event | 1 micromort = microprobability of death |
| **Micromort** | 1-in-a-million chance of death, per event | Skydiving: 8 micromorts per jump |

### Comparing Risks: Period Matters!

**CRITICAL:** When comparing micromort values, ensure the **period is
the same**. For example:

| Activity     | Micromorts | Period   | Comparable?                       |
|--------------|------------|----------|-----------------------------------|
| Scuba diving | 5          | per dive | Per-event                         |
| Scuba diving | 164        | per year | Per-year (assumes ~33 dives/year) |
| Skydiving    | 8          | per jump | Per-event                         |

The “per year” figure (164) conflates frequency with risk-per-event. A
diver doing 5 dives/year vs 50 dives/year faces very different annual
risk.

### Conditional Risks

Many activities have **selection effects**. For example:

- **Marathon running (7 micromorts):** Runners are self-selected for
  fitness. This low figure reflects the health of participants, not the
  risk to an average person attempting a marathon.
- **Motorcycle riding (10 micromorts/60 miles):** Experienced riders
  face lower risk than novices, but the quoted figure is an average.

These figures answer: “Given that someone completed this activity, what
was their death risk?” Not: “What would happen if a random person
attempted this?”

### Converting Probabilities to Micromorts

``` r
# 1 in 10,000 chance of death = 100 micromorts
as_micromort(1/10000)
#> [1] 100
```

### Common Risks Table

    #> Target 'vig_intro_common_risks' not found. Run tar_make() first.

### Visualizing Risks

Using
[`plot_risks()`](https://johngavin.github.io/micromort/reference/plot_risks.md),
we can see the relative magnitude of different activities on a
logarithmic scale. The plot is split into COVID-19 and Other risks to
make comparisons easier:

    #> Target 'vig_intro_risk_plot' not found. Run tar_make() first.
    #> NULL

#### Interactive Version

For interactive exploration with hover details and category filtering,
use
[`plot_risks_interactive()`](https://johngavin.github.io/micromort/reference/plot_risks_interactive.md):

    #> Target 'vig_intro_risk_plot_interactive' not found. Run tar_make() first.
    #> NULL

## 2. Microlives (Chronic Risk)

While micromorts measure sudden death, **microlives** measure the impact
of chronic habits on your life expectancy. A microlife represents a
30-minute change in life expectancy.

### Living at Different Speeds

A useful way to think about microlives: we all “use up” **48 microlives
per day** just by living (24 hours = 48 × 30 minutes). Unhealthy habits
accelerate this consumption, while healthy habits slow it down.

A smoker who smokes 20 cigarettes per day uses up an additional 10
microlives, which can be interpreted as **rushing towards death at 29
hours per day** instead of 24. Conversely, someone with excellent
lifestyle habits might effectively live at only 22 hours per day.

**Healthcare bonus:** Modern healthcare and healthier lifestyles give us
a “payback” of approximately **12 microlives per day** — our expected
death is moving away from us even as we age.

### Common Chronic Risks

| Factor                   | Microlives/day | Interpretation              |
|--------------------------|----------------|-----------------------------|
| Smoking 1 cigarette      | -1             | Lose 30 min life expectancy |
| Being 5kg overweight     | -1             | Lose 30 min/day             |
| 20 min moderate exercise | +2             | Gain 60 min life expectancy |
| 2+ hours TV daily        | -1             | Sedentary behavior          |
| 5+ servings fruit/veg    | +2             | Healthy diet                |

### Converting Life Expectancy to Microlives

``` r
# as_microlife() converts minutes of life expectancy change to microlives
# Unit: 1 microlife = 30 minutes of life expectancy change PER DAY
# Sign: negative = loss, positive = gain

# Heavy smoker: 20 cigarettes/day, each costs ~30 mins
as_microlife(-20 * 30)  # = -20 microlives/day (life lost)
#> [1] -20

# Moderate exercise: 20 mins → ~60 mins life gained
as_microlife(60)        # = +2 microlives/day (life gained)
#> [1] 2

# Being 5kg overweight costs 30 mins per day
as_microlife(-30)       # = -1 microlife/day (life lost)
#> [1] -1
```

## 3. Relationship Between Micromorts and Microlives

### Theoretical Conversion

Micromorts (acute, per-event risk) and microlives (chronic, per-day
attrition) measure different phenomena, but can be approximately
converted using expected value theory.

**Key relationship:** 1 micromort ≈ 0.7 microlives

**Assumptions for this conversion:** 1. Remaining life expectancy = 40
years (adjust for actual age) 2. Death occurs immediately upon the event
(worst case) 3. Linear approximation (valid for small probabilities)

**Mathematical derivation:**

- 1 micromort = 1/1,000,000 probability of death
- Expected life lost = probability × remaining life
- = 1e-6 × 40 years = 4e-5 years
- = 4e-5 × 525,960 minutes/year ≈ 21 minutes
- 1 microlife = 30 minutes, so 21 minutes ≈ 0.7 microlives

**Why
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)
uses microlives = micromorts × 0.7:**

The conversion allows comparing a single risky event (like one skydive
at 8 micromorts) to chronic daily habits (like smoking at -10
microlives/day). However, **the approximation breaks down when:**

1.  **Remaining life expectancy differs** from 40 years (a 20-year-old
    loses more per micromort than an 80-year-old)
2.  **The risk is not immediate death** (injuries, disabilities are not
    captured)
3.  **Repeated exposures** compound non-linearly

### Unit Definitions (Summary)

| Metric | Unit Definition | Scope | Sign |
|----|----|----|----|
| **Micromort** | 1-in-a-million probability of death | Per discrete event (1 surgery, 1 flight) | Always ≥ 0 |
| **Microlife** | 30 minutes of life expectancy change | Per day of exposure/habit | \+ = gain, − = loss |

### When to Use Each

- **Use micromorts** for discrete, short-duration events with binary
  outcomes (death or survival): surgery, skydiving, a single car trip
- **Use microlives** for chronic, daily habits that accumulate over a
  lifetime: smoking, exercise, diet
- **Convert between them** for policy decisions, but state your
  assumptions (age, remaining life expectancy)

## 4. Value of Statistical Life (VSL)

The **Value of a Statistical Life (VSL)** is the monetary value used to
justify safety spending. It is NOT the value of an individual life, but
the aggregate willingness to pay for small risk reductions.

### US Valuation

Example: If a safety feature costs \$50 and saves 1 life in 100,000
people (10 micromorts), is it worth it? Cost per micromort saved = \$50
/ 10 = \$5. If VSL = \$10M, then 1 micromort = \$10. Since \$5 \< \$10,
it is cost-effective.

``` r
# Standard US VSL of $10M implies $10 per micromort
value_of_micromort(vsl = 10000000)
#> [1] 10
```

### UK Valuation: Micromorts ≈ Microlives

Interestingly, two UK government agencies arrive at similar valuations
for micromorts and microlives:

| Agency | Metric | Value | Per Unit |
|----|----|----|----|
| **NICE** (NHS) | 1 QALY | ~£30,000 | **£1.70 per microlife** |
| **Dept of Transport** | Value of Statistical Life | £1,600,000 | **£1.60 per micromort** |

This near-equivalence (£1.60 ≈ £1.70) provides empirical support for the
theoretical conversion: **1 micromort ≈ 1 microlife** in policy terms.

``` r
# UK Department of Transport VSL: £1.6M → £1.60 per micromort
value_of_micromort(vsl = 1600000)
#> [1] 1.6
```

This consistency suggests that policy decisions affecting acute risks
(transport safety) and chronic risks (healthcare interventions) can be
compared on a common scale.

## 5. Loss of Life Expectancy (LLE)

**LLE** estimates the average time lost from a lifespan due to a
specific risk. For a 1-in-a-million risk (1 micromort), the LLE is
approximately 21 minutes (assuming 40 years remaining life).

``` r
# Loss of life expectancy from 1 micromort (assuming 40 years remaining)
lle(prob = 1/1e6, life_expectancy = 40)
#> [1] 21.0384
#> attr(,"class")
#> [1] "micromort_lle" "numeric"      
#> attr(,"units")
#> [1] "minutes"
```

## 6. Complementary Metrics: QALY, DALY, and Morbidity

Micromorts and microlives focus on mortality. But many conditions (like
the common cold) cause significant quality of life loss without being
fatal. Complementary metrics capture this morbidity burden.

### QALY (Quality-Adjusted Life Year)

Measures years of life adjusted for quality. **1 QALY = 1 year of
perfect health.**

- Health states are weighted 0 (death) to 1 (perfect health)
- A year with chronic pain at 0.7 quality = 0.7 QALYs
- Used to assess cost-effectiveness of medical interventions (e.g.,
  £20,000-30,000 per QALY threshold in UK)

### DALY (Disability-Adjusted Life Years)

Measures disease burden as the sum of:

- **YLL (Years of Life Lost):** From premature mortality
- **YLD (Years Lived with Disability):** From morbidity, weighted by
  disability severity

**Formula:** `DALY = YLL + YLD`

For fatal diseases like COVID-19, YLL dominates. For non-fatal
conditions like the common cold, YLD dominates.

### Comparing Metrics

| Metric | Unit Definition | Scope | Sign | Best For |
|----|----|----|----|----|
| **Micromort** | 1/1,000,000 death probability | Per discrete event (surgery, flight, climb) | ≥ 0 (probability) | Comparing single risky activities |
| **Microlife** | 30 min life expectancy change | Per day of chronic exposure | \+ gain / − loss | Daily lifestyle interventions |
| **QALY** | 1 year at perfect health (quality=1.0) | Per treatment/intervention | ≥ 0 | Cost-effectiveness in healthcare |
| **DALY** | 1 year lost to disease (YLL + YLD) | Per condition/population | ≥ 0 (burden) | Global health prioritization |
| **QALD** | 1 day at perfect health | Per illness episode | ≥ 0 | Short-term morbidity (colds, flu) |

### References

- Spiegelhalter D (2012). “Using speed of ageing and ‘microlives’.” BMJ
  2012;345:e8223.
  [doi:10.1136/bmj.e8223](https://doi.org/10.1136/bmj.e8223)
- Spiegelhalter D (2012). “Understanding uncertainty: Microlives.” Plus
  Magazine.
  [plus.maths.org](https://plus.maths.org/content/understanding-uncertainty-microlives)
- WHO Global Burden of Disease:
  [ghdx.healthdata.org](https://ghdx.healthdata.org/)
- NICE Methods Guide:
  [nice.org.uk](https://www.nice.org.uk/process/pmg9/chapter/the-reference-case)

## 7. Conditional Risks: Cancer, Vaccination, and Risk Hedging

### Cancer Risks by Type and Sex

The
[`cancer_risks()`](https://johngavin.github.io/micromort/reference/cancer_risks.md)
function provides mortality data stratified by cancer type, sex, and age
group:

    #> Target 'vig_intro_cancer_top3' not found. Run tar_make() first.

**Family history impact:** The `family_history_rr` column shows relative
risk increase with a first-degree relative’s diagnosis. For example,
prostate cancer risk increases 2.5× with family history.

    #> Target 'vig_intro_cancer_family_history' not found. Run tar_make() first.

### Vaccination Risk Reduction

The
[`vaccination_risks()`](https://johngavin.github.io/micromort/reference/vaccination_risks.md)
function quantifies micromorts avoided through vaccination:

    #> Target 'vig_intro_vaccination_childhood' not found. Run tar_make() first.

    #> Target 'vig_intro_vaccination_adult' not found. Run tar_make() first.

### Hedged vs Unhedged: Optimal Lifestyle Comparison

The
[`conditional_risk()`](https://johngavin.github.io/micromort/reference/conditional_risk.md)
function compares risk factors between optimal (“hedged”) and suboptimal
(“unhedged”) states:

    #> Target 'vig_intro_cardiovascular_risk' not found. Run tar_make() first.

### Total Portfolio Effect

The
[`hedged_portfolio()`](https://johngavin.github.io/micromort/reference/hedged_portfolio.md)
function calculates total life expectancy gain from adopting all optimal
lifestyle choices:

    #> Target 'vig_intro_hedged_portfolio' not found. Run tar_make() first.

**Interpretation:** A fully “hedged” individual (non-smoker, regular
exercise, healthy diet, vaccinated, etc.) can expect to gain significant
additional life expectancy compared to an “unhedged” baseline.

## 8. Conclusion

The `micromort` package helps translate abstract probabilities into
concrete units for better decision-making. By comparing acute risks
(micromorts), chronic risks (microlives), and quality-of-life metrics
(QALYs, DALYs), individuals and policymakers can make more informed
choices about risk trade-offs.

The new conditional risk functions enable:

- **Cancer risk assessment:** Compare baseline risk to family history
  scenarios
- **Vaccination value:** Quantify micromorts avoided through vaccination
  schedules
- **Lifestyle optimization:** Calculate total life expectancy gain from
  adopting optimal “hedged” behaviors
