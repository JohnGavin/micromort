# Plan: Regional Longevity Data from Nature Communications Study

## Source

**Paper:** Bonnet F. et al. (2026). "Potential and challenges for sustainable progress in human longevity."
*Nature Communications* 17, 996. [DOI: 10.1038/s41467-026-68828-z](https://www.nature.com/articles/s41467-026-68828-z)

**Summary:** [Mapping Ignorance](https://mappingignorance.org/2026/02/11/regional-diversity-in-longevity-trends-in-western-europe/)

**Interactive Tool:** ReLoG_Europe platform (region-by-region results)

## Data Overview

| Metric | Value |
|--------|-------|
| Coverage | 450 regions in 13 Western European countries |
| Population | ~400 million inhabitants |
| Time span | 1992–2019 (pre-COVID) |
| Granularity | Sub-national regions (departments, cantons, etc.) |

### Key Findings

1. **Vanguard regions** (Northern Italy, Switzerland, Spanish provinces): +2.5 months/year (men), +1.5 months/year (women)
2. **Laggard regions** (East Germany, Wallonia, UK, Hauts-de-France): Stalled progress post-2005
3. **Critical age bracket**: Mortality changes at ages 55–74 drive divergence
4. **Champion life expectancy** (2019): Paris region achieved 83 years (men), 87 years (women)

## Relevance to micromort Package

### Direct Connections

| micromort Concept | Regional Longevity Link |
|-------------------|------------------------|
| `chronic_risks()` | Regional lifestyle factors (smoking, alcohol, diet, exercise) |
| `demographic_factors()` | Geographic mortality multipliers |
| `conditional_risk()` | Regional vs national baseline comparison |
| Microlife calculations | Regional life expectancy differences → microlives/day delta |

### Potential New Functions

```r
# Proposed: regional_life_expectancy()
regional_life_expectancy <- function(region = NULL, country = NULL, year = 2019) {

  # Returns life expectancy by region with:
  # - LE at birth (male, female)
  # - Annual gain trend (months/year)
  # - Vanguard/laggard classification
  # - Microlives/day vs European average
}

# Proposed: regional_mortality_multiplier()
regional_mortality_multiplier <- function(region, age_group = "55-74") {
  # Returns relative mortality risk vs national/European average
  # Useful for adjusting micromort estimates by location
}
```

## Pros of Including

| Pro | Rationale |
|-----|-----------|
| **Geographic granularity** | 450 regions vs current country-level data |
| **Authoritative source** | Nature Communications, peer-reviewed |
| **Time series** | 27-year trends (1992-2019) enable projections |
| **Pre-COVID baseline** | Clean data without pandemic distortions |
| **Actionable insights** | Identifies modifiable factors (lifestyle, healthcare access) |
| **Complements existing data** | Adds WHERE dimension to existing WHAT (risk type) data |
| **Policy relevance** | Supports regional health intervention targeting |

### Quantitative Value

- Convert regional LE differences to microlives:
  - Paris (83y male) vs Hauts-de-France (~79y): 4-year gap
  - 4 years × 365 days × 48 microlives/day = **70,080 microlives lifetime difference**
  - Daily equivalent: ~4.8 microlives/day from living in optimal vs suboptimal region

## Cons of Including

| Con | Mitigation |
|-----|------------|
| **Data size** | 450 regions × 27 years × 2 sexes = ~24,000 rows. Use parquet, lazy loading |
| **Scope creep** | Package focuses on risk *activities*, not *locations*. Keep regional data as supplementary |
| **Maintenance burden** | Static 1992-2019 snapshot; no ongoing updates needed |
| **European-only** | Clearly document geographic limitation; US/global data would require separate sources |
| **Complexity** | Regional codes (NUTS) may confuse users. Provide lookup helpers |
| **Attribution** | Ensure proper citation; CC-BY license from Nature Communications |

### Risk: Misinterpretation

Users might incorrectly conclude "move to Switzerland to live longer" when the data reflects:
- Selection effects (healthy/wealthy people cluster in vanguard regions)
- Confounding (healthcare access, education, income)
- Not individual-level causation

**Mitigation:** Add clear documentation warnings about ecological fallacy.

## Implementation Options

### Option A: Full Integration (Recommended)

Add as core dataset family with:
- `regional_life_expectancy()` - Main accessor
- `regional_mortality_trend()` - Time series
- `vanguard_regions()` / `laggard_regions()` - Convenience filters
- Parquet storage in `inst/extdata/`

**Effort:** ~2-3 days

### Option B: Companion Package

Create separate `micromort.geo` package for geographic extensions.

**Effort:** ~1 week (new package setup)

### Option C: Vignette Only

Document the study in a vignette with links, no data integration.

**Effort:** ~2 hours

## Recommendation

**Option A: Full Integration** because:

1. Data is static (1992-2019), no maintenance needed
2. Directly supports existing `demographic_factors()` pattern
3. Enables powerful analyses: "How does my regional baseline compare to lifestyle choices?"
4. ~24k rows is small for parquet

## Data Schema (Proposed)

```r
regional_life_expectancy <- function() {

  tibble::tribble(
    ~region_code,    # NUTS code (e.g., "FR10" = Île-de-France)
    ~region_name,    # Human-readable name
    ~country,        # ISO country code
    ~year,           # 1992-2019
    ~sex,            # "Male", "Female"
    ~life_expectancy, # Years at birth
    ~annual_gain_months, # Trend (months/year)
    ~classification, # "vanguard", "average", "laggard"
    ~microlives_vs_eu_avg, # Daily microlives vs European mean
    ~source_url      # DOI link
  )
}
```

## Next Steps

1. [ ] Download supplementary data from Nature Communications
2. [ ] Extract regional life expectancy tables
3. [ ] Create `regional_life_expectancy()` function
4. [ ] Add parquet export for cross-language access
5. [ ] Write vignette: "Regional Variation in Life Expectancy"
6. [ ] Add warnings about ecological fallacy
7. [ ] Update pkgdown reference index

## References

- Bonnet F. et al. (2026). Nature Communications 17, 996. https://doi.org/10.1038/s41467-026-68828-z
- INED summary: https://www.ined.fr/en/everything_about_population/demographic-facts-sheets/focus-on/life-expectancy-europe/
- ReLoG_Europe interactive tool (for validation)
