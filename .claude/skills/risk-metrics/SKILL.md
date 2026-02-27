# Risk Metrics for Micromort Package

## Description

Domain-specific knowledge for working with micromort and microlife risk metrics. Covers definitions, CDC MMWR data format, provenance schema, and calculation conventions.

## Purpose

Use this skill when:
- Adding new risk data to the package
- Interpreting CDC MMWR mortality data
- Converting between micromorts and microlives
- Validating data provenance
- Ensuring period normalization

## Core Definitions

### Micromort (μmort)

> **One-in-a-million probability of death from a single exposure or event**

| Property | Value |
|----------|-------|
| Symbol | μmort |
| Definition | 10⁻⁶ probability of death |
| Type | **Acute risk** (per event) |
| Sign | Always ≥ 0 |
| Origin | Howard (1980) |

```r
# Example: Skydiving is 8 micromorts per jump
# = 8-in-a-million chance of death per jump
# = 0.000008 probability
```

### Microlife (μlife)

> **30 minutes of life expectancy gained or lost due to chronic exposure**

| Property | Value |
|----------|-------|
| Symbol | μlife |
| Definition | 30 minutes life expectancy change |
| Type | **Chronic risk** (per day) |
| Sign | Positive = gain, Negative = loss |
| Origin | Spiegelhalter (2012) |

```r
# Example: Smoking 2 cigarettes costs -1 microlife per day
# = 30 minutes life expectancy lost per day
# = 182.5 hours lost per year
# = 7.6 days lost per year
```

### Microprobability

> **Generic term for one-in-a-million probability of any event**

- Micromort is a specific microprobability (death)
- Other microprobabilities exist (injury, disease, etc.)
- Package focuses on mortality risks only

## Conversion Formula

```r
# Micromort to Microlife (approximate)
# Assumes 40 years remaining life expectancy
microlife <- micromort * 0.7

# Derivation:
# 1 μmort = 10⁻⁶ death probability
# Expected life lost = 10⁻⁶ × 40 years = 21.075 minutes
# 21.075 min / 30 min per μlife ≈ 0.7 μlife
```

### Sign Convention (CRITICAL)

```r
#' @param minutes Life expectancy change in minutes.
#'   - **Positive** = life GAINED (good: exercise, vegetables)
#'   - **Negative** = life LOST (bad: smoking, obesity)

as_microlife <- function(minutes) {
  minutes / 30
}

# Examples:
as_microlife(30)   #  1 microlife gained (30 min exercise)
as_microlife(-30)  # -1 microlife lost (2 cigarettes)
```

## Data Schema

### acute_risks (parquet)

| Column | Type | Description |
|--------|------|-------------|
| `record_id` | chr | Unique ID: `{source_id}_{seq}` |
| `activity` | chr | Human-readable name |
| `activity_normalized` | chr | Standardized grouping key |
| `micromorts` | dbl | Risk value (always ≥ 0) |
| `microlives` | dbl | Calculated: micromorts × 0.7 |
| `category` | chr | Activity category |
| `period` | chr | Human-readable period |
| `period_normalized` | chr | One of: event, day, week, month, year |
| `age_group` | chr | all, 18-49, 50-64, 65-79, 80+ |
| `geography` | chr | global, US, UK, etc. |
| `year` | int | Data collection year |
| `source_id` | chr | Foreign key to risk_sources |
| `source_url` | chr | Direct URL |
| `confidence` | chr | high, medium, low |
| `last_accessed` | date | Retrieval date |

### chronic_risks (parquet)

| Column | Type | Description |
|--------|------|-------------|
| `record_id` | chr | Unique identifier |
| `factor` | chr | Human-readable factor name |
| `factor_normalized` | chr | Standardized grouping key |
| `microlives_per_day` | dbl | Daily impact (+/-) |
| `direction` | chr | "gain" or "loss" |
| `category` | chr | Diet, Exercise, Smoking, etc. |
| `description` | chr | Detailed description |
| `annual_effect_days` | dbl | Days gained/lost per year |
| `source_id` | chr | Foreign key to risk_sources |
| `source_url` | chr | Direct URL |
| `confidence` | chr | high, medium, low |
| `last_accessed` | date | Retrieval date |

### risk_sources (parquet)

| Column | Type | Description |
|--------|------|-------------|
| `source_id` | chr | Primary key (e.g., "cdc_mmwr_2023") |
| `citation` | chr | Full citation |
| `primary_url` | chr | Main URL |
| `type` | chr | academic, government, database, book, encyclopedia |
| `description` | chr | Brief description |
| `data_types` | chr | acute, chronic, or both |
| `last_accessed` | date | Retrieval date |

## CDC MMWR Format

### Period Convention

CDC MMWR reports use **11-week observation periods**:

```r
# CDC MMWR (2022) vaccination effectiveness study
# Period: 11 weeks ending 2022-10-22

# Example entries:
"COVID-19 unvaccinated (age 80+)"      # 234 μmort per 11 weeks
"COVID-19 bivalent booster (age 80+)"  # 23 μmort per 11 weeks
```

### Age Group Stratification

| CDC Age Group | period_normalized | Notes |
|---------------|-------------------|-------|
| 18-49 | "11 weeks" | Working age |
| 50-64 | "11 weeks" | Pre-retirement |
| 65-79 | "11 weeks" | Senior |
| 80+ | "11 weeks" | Elderly |
| All ages | "11 weeks" | Weighted average |

### Vaccination Status Categories

```r
# CDC categories (as of 2022)
vaccination_status <- c(
  "unvaccinated",           # No COVID vaccine
  "monovalent_vaccine",     # Original vaccine only
  "bivalent_booster"        # Updated booster
)
```

## Period Normalization

### The Problem

**Micromort values with different periods are NOT directly comparable!**

```r
# WRONG comparison:
# Scuba diving (trained): 5 micromorts per dive
# Scuba diving (per year): 164 micromorts per year
# These are NOT the same activity at different scales!
```

### Period Types

| Type | period_normalized | Example |
|------|-------------------|---------|
| Per-event | "event" | "per jump", "per dive" |
| Per-day | "day" | "per day", "per night" |
| Per-week | "week" | "per week" |
| Per-month | "month" | "per month" |
| Per-year | "year" | "per year" |
| Specific period | "period" | "11 weeks (2022)" |

### Normalization Helper

```r
parse_period <- function(period) {
  period_type <- case_when(
    grepl("per day|per night", period) ~ "day",
    grepl("per hour", period) ~ "hour",
    grepl("per year", period) ~ "year",
    grepl("per month", period) ~ "month",
    grepl("weeks", period) ~ "period",
    grepl("per event|per jump|per dive", period) ~ "event",
    TRUE ~ "event"
  )

  period_type
}
```

### Daily Rate Calculation

```r
# Convert to daily rate for comparison
micromorts_per_day <- case_when(
  period_normalized == "day" ~ micromorts,
  period_normalized == "year" ~ micromorts / 365,
  period_normalized == "month" ~ micromorts / 30,
  period_normalized == "event" ~ micromorts / period_days,
  TRUE ~ NA_real_
)
```

## Conditional Risk Warning

### The Problem

Many risk estimates are **conditional** on the exposed population:

```r
# Marathon running: 7 micromorts per event
# BUT: This is for MARATHON RUNNERS, not the general population
# Marathon runners are self-selected for fitness

# The risk for an AVERAGE person attempting a marathon
# would be MUCH HIGHER
```

### Documentation Pattern

Always document the conditional nature:

```r
#' @details
#' **Conditional Risk Warning:** This estimate applies to the typical
#' participant population, which may be self-selected for fitness,
#' training, or other protective factors. The risk for the general
#' population attempting this activity would likely be higher.
```

### Vignette Warning Text

```markdown
### Conditional Risks

**Important:** Some risk estimates are *conditional* on the characteristics
of people who actually do the activity:

* **Marathon running (7 micromorts):** Runners are self-selected for fitness.
  An untrained person attempting a marathon faces much higher risk.

* **Scuba diving (5 micromorts per dive):** Assumes trained, certified divers.
  Untrained diving has significantly higher risk.
```

## UK Government Valuations

### NICE (NHS)

```r
# National Institute for Health and Care Excellence
# Quality-Adjusted Life Year (QALY) valuation

qaly_value_gbp <- 30000  # £30,000 per QALY
microlife_value_gbp <- 30000 / (365 * 48)  # ≈ £1.70 per microlife

# 1 QALY = 1 year of perfect health
# 1 year = 365 days × 48 microlives/day = 17,520 microlives
```
### Department for Transport

```r
# Value of Statistical Life (VSL)
vsl_gbp <- 1600000  # £1,600,000 per statistical life

micromort_value_gbp <- vsl_gbp / 1e6  # = £1.60 per micromort
```

### Key Insight

> **£1.70 per microlife ≈ £1.60 per micromort**
>
> UK government valuations imply micromorts and microlives have similar
> economic value, supporting the 0.7 conversion factor.

## Source References

### Primary Sources

| Source ID | Type | URL |
|-----------|------|-----|
| `wikipedia_micromort` | encyclopedia | https://en.wikipedia.org/wiki/Micromort |
| `micromorts_rip` | database | https://micromorts.rip/ |
| `cdc_mmwr_2023` | government | https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm |
| `spiegelhalter_2012` | academic | https://doi.org/10.1136/bmj.e8223 |
| `howard_1980` | academic | Societal Risk Assessment (book chapter) |

### Citation Format

```r
#' @source
#' CDC MMWR: \url{https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm}
#'
#' @references
#' Spiegelhalter D (2012). "Using speed of ageing and 'microlives' to
#' communicate the effects of lifetime habits and environment."
#' BMJ 2012;345:e8223. \doi{10.1136/bmj.e8223}
```

## Checklist for Adding New Data

- [ ] Source URL is valid and accessible
- [ ] Period is explicitly stated
- [ ] Age group is documented (or "all" if not stratified)
- [ ] Geography is documented (or "global" if not specified)
- [ ] Micromorts value is ≥ 0
- [ ] Microlives calculated as micromorts × 0.7
- [ ] Conditional risk warning added if applicable
- [ ] source_id links to risk_sources table
- [ ] last_accessed date is current

## Related Functions

| Function | Family | Purpose |
|----------|--------|---------|
| `common_risks()` | datasets | Load acute risks |
| `chronic_risks()` | datasets | Load chronic risks |
| `as_micromort()` | conversion | Convert to micromorts |
| `as_microlife()` | conversion | Convert to microlives |
| `cancer_risks()` | conditional-risk | Cancer risk with family history |
| `vaccination_risks()` | conditional-risk | Vaccine effectiveness |
| `conditional_risk()` | conditional-risk | Generic hedging calculator |

## Resources

- [Plus Maths: Living at Different Speeds](https://plus.maths.org/content/understanding-uncertainty-microlives)
- [Wikipedia: Micromort](https://en.wikipedia.org/wiki/Micromort)
- [Wikipedia: Microlife](https://en.wikipedia.org/wiki/Microlife)
- [CDC MMWR Vaccination Study](https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm)
- [Spiegelhalter BMJ Paper](https://doi.org/10.1136/bmj.e8223)
