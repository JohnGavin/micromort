# Plan: Function Naming Consistency and Cardiovascular Risks

## Problem Analysis

### Issue 1: Duplicate Data Systems
Currently TWO parallel systems exist for the same data:

| Location | Function | Returns | Problem |
|----------|----------|---------|---------|
| R/risks.R | `common_risks()` | Inline tribble | Named "common" but titled "Acute Risks" |
| R/data.R | `load_acute_risks()` | Parquet file | Different schema, `load_` prefix |
| R/risks.R | `chronic_risks()` | Inline tribble | Consistent name |
| R/data.R | `load_chronic_risks()` | Parquet file | `load_` prefix inconsistent |

### Issue 2: Naming Inconsistency
- `common_risks()` ≠ "acute" - misleading name
- `load_*` prefix used inconsistently
- Users confused about which function to use

### Issue 3: Schema Differences
- `common_risks()` has 9 columns (simplified)
- `load_acute_risks()` has 15 columns (full provenance)

## Proposed Solution

### Option A: Rename to Consistent Pattern (RECOMMENDED)

| Old Function | New Function | Rationale |
|--------------|--------------|-----------|
| `common_risks()` | `acute_risks()` | Matches title, parallels `chronic_risks()` |
| `load_acute_risks()` | `acute_risks_full()` | Full schema with provenance |
| `load_chronic_risks()` | `chronic_risks_full()` | Full schema with provenance |
| `load_sources()` | `risk_sources()` | Remove `load_` prefix |

### Option B: Keep Both, Add Soft Deprecation
- Keep `common_risks()` as alias with deprecation warning
- Point users to `acute_risks()`

## Implementation Steps

### Step 1: Create New Functions with Correct Names
```r
# R/risks.R
#' Acute Risks in Micromorts
acute_risks <- function() {
  # ... existing common_risks() code
}

#' @rdname acute_risks
#' @export
common_risks <- function() {

  lifecycle::deprecate_soft("0.2.0", "common_risks()", "acute_risks()")
  acute_risks()
}
```

### Step 2: Rename Parquet Loaders
```r
# R/data.R
#' Load Full Acute Risks Dataset
#' @description
#' Returns the full acute risks dataset with all provenance columns.
#' For a simplified view, use [acute_risks()].
acute_risks_full <- function() {
  # ... existing load_acute_risks() code
}

#' @rdname acute_risks_full
#' @export
load_acute_risks <- function() {
  lifecycle::deprecate_soft("0.2.0", "load_acute_risks()", "acute_risks_full()")
  acute_risks_full()
}
```

### Step 3: Update All Internal References
Files to update:
- `R/visualization.R`: `common_risks()` → `acute_risks()`
- `R/models.R`: `load_chronic_risks()` → `chronic_risks_full()`
- `R/dashboard.R`: Update both
- Tests: Update all references

### Step 4: Update Documentation
- Add `@family datasets` to all risk functions
- Cross-reference between simplified and full versions
- Update vignettes

## New Function: cardiovascular_risks()

### Rationale
Analogous to `cancer_risks()`, provide cardiovascular disease mortality by:
- Condition type (heart disease, stroke, etc.)
- Sex
- Age group
- Risk factors (hypertension, diabetes, smoking)

### Data Sources
- CDC WONDER: https://wonder.cdc.gov/
- AHA Heart Disease Statistics: https://www.heart.org/en/about-us/heart-and-stroke-association-statistics
- WHO Cardiovascular Diseases: https://www.who.int/health-topics/cardiovascular-diseases

### Proposed Schema
```r
cardiovascular_risks <- function() {
  tibble::tribble(
    ~condition, ~sex, ~age_group, ~deaths_per_100k, ~risk_factor_rr,

    # Heart Disease - All ages
    "Heart Disease", "Male", "All ages", 208.0, 1.0,
    "Heart Disease", "Female", "All ages", 130.0, 1.0,

    # Stroke - All ages
    "Stroke", "Male", "All ages", 38.0, 1.0,
    "Stroke", "Female", "All ages", 36.0, 1.0,

    # Hypertensive Heart Disease
    "Hypertensive Heart Disease", "Male", "All ages", 15.0, 1.0,
    "Hypertensive Heart Disease", "Female", "All ages", 12.0, 1.0,

    # Heart Failure
    "Heart Failure", "Male", "All ages", 12.5, 1.0,
    "Heart Failure", "Female", "All ages", 10.0, 1.0,

    # Age-stratified (both sexes)
    "Heart Disease", "Both", "35-44", 15.0, 1.0,
    "Heart Disease", "Both", "45-54", 45.0, 1.0,
    "Heart Disease", "Both", "55-64", 105.0, 1.0,
    "Heart Disease", "Both", "65-74", 230.0, 1.0,
    "Heart Disease", "Both", "75-84", 550.0, 1.0,
    "Heart Disease", "Both", "85+", 1500.0, 1.0,

    # Risk factor multipliers (relative risk)
    "Heart Disease + Smoking", "Both", "All ages", NA, 2.0,
    "Heart Disease + Diabetes", "Both", "All ages", NA, 2.5,
    "Heart Disease + Hypertension", "Both", "All ages", NA, 2.0,
    "Heart Disease + Obesity", "Both", "All ages", NA, 1.5,
    "Heart Disease + Family History", "Both", "All ages", NA, 1.8
  ) |>
    dplyr::mutate(
      micromorts_per_year = deaths_per_100k * 10,
      microlives_per_day = round(micromorts_per_year / 365 * 0.7, 2),
      source_url = "https://www.cdc.gov/nchs/fastats/heart-disease.htm"
    )
}
```

## Migration Timeline

### Phase 1: Add New Functions (v0.2.0)
- Add `acute_risks()` as primary function
- Add `cardiovascular_risks()`
- Soft deprecate old names

### Phase 2: Update Internals (v0.2.1)
- Update all internal uses to new names
- Update vignettes and examples

### Phase 3: Remove Deprecated Functions (v0.3.0)
- Remove `common_risks()` alias
- Remove `load_*` functions
- Breaking change with clear NEWS entry

## Files to Modify

| File | Changes |
|------|---------|
| R/risks.R | Add `acute_risks()`, rename, add `cardiovascular_risks()` |
| R/data.R | Rename `load_*` to `*_full()` |
| R/visualization.R | Update defaults |
| R/models.R | Update references |
| R/dashboard.R | Update references |
| tests/ | Update all tests |
| man/ | Regenerate |
| vignettes/ | Update examples |
| NEWS.md | Document changes |

## Testing Checklist

- [ ] All new functions have tests
- [ ] Deprecated functions still work with warning
- [ ] Cross-references in documentation work
- [ ] Vignettes render correctly
- [ ] pkgdown site builds
- [ ] R CMD check passes

## Open Questions

1. Should `acute_risks()` and `acute_risks_full()` be unified into one function with a `full = FALSE` parameter?
2. Should we add `lifecycle` as a dependency for deprecation warnings?
3. What risk factors should be included in `cardiovascular_risks()`?
