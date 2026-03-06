# Plan: Risk Equivalence Dashboard Vignette

**Status**: PLANNING
**Created**: 2026-03-06
**Branch**: `feature/risk-equivalence-dashboard`
**Issue**: TBD (create as Step 1 of 9-step workflow)

## Problem Statement

Users want intuitive "A = N x B" risk comparisons (e.g., "a transatlantic flight = 10 chest X-rays in radiation risk"). The package has 62 acute risks in `common_risks()` but:

1. No medical radiation activities (chest X-ray, CT scan, mammogram) exist in the data
2. No `risk_equivalence()` function to compute cross-activity ratios
3. No dedicated vignette for interactive equivalence exploration

## Scope

### In Scope
- Add ~10 medical radiation activities to `acute_risks_base.csv` and `common_risks()`
- New exported function: `risk_equivalence()`
- New vignette: `vignettes/risk_equivalence.Rmd`
- New targets in `plan_vignette_outputs.R` for all dashboard data
- Tests for `risk_equivalence()`
- Registration in `_pkgdown.yml`

### Out of Scope
- flexdashboard format (not in Suggests; use standard Rmd with DT/plotly)
- Shiny interactivity (use DT filtering and plotly hover instead)
- Changes to chronic_risks() data

---

## Design

### 1. New Data: Medical Radiation Activities

#### 1a. Add rows to `data-raw/sources/acute_risks_base.csv`

Add these 8 activities to the CSV with a new `"Medical Radiation"` category. All values from peer-reviewed literature (Wall et al. 2011 BJR, Mettler et al. 2008 Radiology, NCRP Report 184).

| activity | micromorts | category | period | source_id |
|----------|-----------|----------|--------|-----------|
| Dental X-ray | 0.01 | Medical Radiation | per event | radiation_literature |
| Chest X-ray | 0.1 | Medical Radiation | per event | radiation_literature |
| Mammogram | 0.1 | Medical Radiation | per event | radiation_literature |
| Living near nuclear plant (1 year) | 0.1 | Medical Radiation | per year | radiation_literature |
| Transatlantic flight (radiation dose) | 1 | Medical Radiation | per flight | radiation_literature |
| CT scan (head) | 2 | Medical Radiation | per event | radiation_literature |
| CT scan (abdomen) | 5 | Medical Radiation | per event | radiation_literature |
| CT scan (chest) | 7 | Medical Radiation | per event | radiation_literature |

**CSV columns** (matching existing schema):
`activity,micromorts,microlives,category,period,source_url,source_id,confidence,year,geography,age_group,last_accessed`

- `microlives`: computed as `micromorts * 0.7`
- `source_url`: `https://pubmed.ncbi.nlm.nih.gov/21969028/` (Wall et al. 2011)
- `source_id`: `radiation_literature` (new source_id)
- `confidence`: `high` (peer-reviewed radiology literature)
- `year`: 2025
- `geography`: global
- `age_group`: all
- `last_accessed`: 2026-03-06

#### 1b. Add source to `data-raw/sources/risk_sources.csv`

Add one new row:

```
Wall et al. (2011),https://pubmed.ncbi.nlm.nih.gov/21969028/,Academic,Radiation doses in diagnostic radiology from national surveys,radiation_literature,acute,2026-03-06
```

#### 1c. Update `common_risks()` in `R/risks.R`

Add the same 8 activities to the `tibble::tribble()` inside `common_risks()`, under a new comment block `# Medical Radiation`. Use a new variable:

```r
rad_lit <- "https://pubmed.ncbi.nlm.nih.gov/21969028/"
```

Also add `"Medical Radiation"` to the `parse_period()` helper:
- `per flight` should map to `period_type = "event"` and `period_days = 0.33` (~8 hours)
- All other "per event" entries already handled

#### 1d. Update globalVariables in `R/visualization.R`

No new global variables needed -- existing `activity`, `micromorts`, `category` declarations cover the new data.

### 2. New Function: `risk_equivalence()`

#### Location: `R/risks.R` (alongside `common_risks()`, `compare_interventions()`)

#### API Design

```r
#' Risk Equivalence Table
#'
#' Given a reference activity, compute how many units of every other activity
#' carry the same micromort risk. The function answers questions like
#' "a transatlantic flight = how many chest X-rays?"
#'
#' @param activity Character. Name of the reference activity. Must match an
#'   activity name in [common_risks()] exactly. Use `common_risks()$activity`
#'   to see valid names.
#' @param risks Tibble. Risk dataset to use. Default [common_risks()].
#'   Must have columns `activity` and `micromorts`.
#' @param min_ratio Numeric. Minimum equivalence ratio to include in results.
#'   Default 0.001 (exclude comparisons where ratio < 0.001). Set to 0 for all.
#' @param digits Integer. Number of decimal places for rounding ratios.
#'   Default 2.
#'
#' @return A tibble with columns:
#' \describe{
#'   \item{reference}{The reference activity name}
#'   \item{reference_micromorts}{Micromorts for the reference activity}
#'   \item{comparison}{The comparison activity name}
#'   \item{comparison_micromorts}{Micromorts for the comparison activity}
#'   \item{comparison_category}{Category of the comparison activity}
#'   \item{equivalence}{How many of the comparison activity equal the reference
#'     (reference_micromorts / comparison_micromorts)}
#'   \item{interpretation}{Human-readable equivalence string, e.g.
#'     "1 Transatlantic flight = 10.0 Chest X-rays"}
#' }
#'
#' @family analysis
#' @seealso [common_risks()], [compare_interventions()], [annual_risk_budget()]
#' @export
#' @examples
#' # "A transatlantic flight = how many chest X-rays?"
#' risk_equivalence("Transatlantic flight (radiation dose)")
#'
#' # "Skydiving = how many days of living at age 20?"
#' risk_equivalence("Skydiving (per jump, US)")
#'
#' # Mt Everest compared to everything
#' risk_equivalence("Mt. Everest ascent") |> head(10)
risk_equivalence <- function(activity,
                             risks = common_risks(),
                             min_ratio = 0.001,
                             digits = 2) {
```

#### Implementation Logic

```r
risk_equivalence <- function(activity,
                             risks = common_risks(),
                             min_ratio = 0.001,
                             digits = 2) {
  checkmate::assert_string(activity)
  checkmate::assert_data_frame(risks)
  checkmate::assert_subset(c("activity", "micromorts"), names(risks))
  checkmate::assert_number(min_ratio, lower = 0)
  checkmate::assert_int(digits, lower = 0)

  # Validate activity exists
 ref_row <- risks |> dplyr::filter(activity == !!activity)
  if (nrow(ref_row) == 0) {
    cli::cli_abort(c(
      "x" = "Activity {.val {activity}} not found in risks dataset.",
      "i" = "Use {.code common_risks()$activity} to see valid names."
    ))
  }

  ref_mm <- ref_row$micromorts[1]

  # Compute equivalences against all other activities
  risks |>
    dplyr::filter(activity != !!activity) |>
    dplyr::mutate(
      reference = !!activity,
      reference_micromorts = ref_mm,
      comparison = activity,
      comparison_micromorts = micromorts,
      comparison_category = category,
      equivalence = round(ref_mm / micromorts, digits),
      interpretation = sprintf(
        "1 %s = %s %s",
        !!activity,
        format(round(ref_mm / micromorts, digits), big.mark = ","),
        activity
      )
    ) |>
    dplyr::filter(equivalence >= min_ratio) |>
    dplyr::select(
      reference, reference_micromorts,
      comparison, comparison_micromorts, comparison_category,
      equivalence, interpretation
    ) |>
    dplyr::arrange(dplyr::desc(equivalence))
}
```

#### Key Design Decisions

1. **Single reference activity** (not pairwise matrix): Simpler API, users call it once per activity of interest. A pairwise matrix of 70x70 = 4,900 rows is overwhelming; the vignette can pre-compute a curated subset.

2. **Returns tibble, not htmlwidget**: The function is data-first. The vignette wraps it in `DT::datatable()` for interactivity.

3. **`min_ratio` filter**: Avoids absurd comparisons like "1 Everest = 0.0000013 chest X-rays" which add noise.

4. **`interpretation` column**: Pre-formatted human-readable string for display. This is the "London to New York = N chest X-rays" phrasing.

5. **Reuses `common_risks()`**: No new data structure needed; the function operates on any tibble with `activity` and `micromorts` columns.

### 3. Vignette Structure: `vignettes/risk_equivalence.Rmd`

Standard `.Rmd` with DT/plotly content (NOT flexdashboard -- not in Suggests).

#### YAML Header

```yaml
---
title: "Risk Equivalence Dashboard"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Risk Equivalence Dashboard}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---
```

#### Section Outline

```
## Setup chunk (safe_tar_read definition)

## 1. The Common Currency of Risk
   Brief intro: micromorts as universal exchange rate.
   "How many chest X-rays = 1 skydive?" is answerable because both
   have micromort values.

## 2. Everyday Equivalences: Landmark Comparisons
   DT::datatable of curated "headline" equivalences.
   Pre-computed target: vig_equiv_landmarks
   ~15-20 carefully chosen comparisons that tell a story:
   - "1 transatlantic flight = 10 chest X-rays (radiation)"
   - "1 skydive = 80 chest X-rays"
   - "1 day at age 90 = 46,300 dental X-rays"
   - "Living a day at age 20 = driving 230 miles"

## 3. Interactive Equivalence Explorer
   DT::datatable with full risk_equivalence() output for a
   user-selected reference activity.
   Pre-computed target: vig_equiv_flight (transatlantic flight)
   Caption explains: "Sort by equivalence column to find how many
   of each activity equal one transatlantic flight."

## 4. The Risk Exchange Rate Chart
   plotly horizontal bar chart showing equivalence ratios on log scale.
   Pre-computed target: vig_equiv_plot
   Reference: transatlantic flight = 1.0x (vertical line).
   All other activities shown as multiples.
   Caption: Tufte comparison -- "compared to what?" answered by
   the reference line.

## 5. Medical Radiation Comparisons
   Focused DT::datatable for medical radiation activities only.
   Pre-computed target: vig_equiv_medical_radiation
   Key comparisons: CT scans vs flights vs X-rays.
   Context: "Your doctor orders a chest CT. In micromort terms,
   that's equivalent to 7 transatlantic flights or 70 chest X-rays."

## 6. Cross-Category Matrix: Key Activities
   plotly heatmap or DT::datatable showing a curated NxN matrix
   of equivalences between ~12 "landmark" activities spanning all
   categories.
   Pre-computed target: vig_equiv_matrix
   Activities: Chest X-ray, Driving 230mi, Flying 1000mi,
   Transatlantic flight (radiation), Skydiving, Running a marathon,
   Scuba dive, General anesthesia, CT scan (chest),
   Night in hospital, Base jumping, Motorcycling 60mi.

## 7. Methodology and Caveats
   - Period mismatches: comparing "per event" to "per day" requires care
   - Conditional risks: these are population averages, not individual
   - Medical radiation: dose depends on machine, protocol, patient size
   - Source references with hyperlinks

## References
```

#### Vignette Rules Compliance

Every `{r}` chunk (except setup) is exactly one expression:
```r
safe_tar_read("vig_equiv_landmarks") |>
  DT::datatable(caption = "...", ...)
```

Zero assignments, zero computation, zero ggplot construction.

### 4. Targets: Additions to `plan_vignette_outputs.R`

Add a new section `# RISK EQUIVALENCE DASHBOARD VIGNETTE` with these targets:

```r
  # ==========================================================================
  # RISK EQUIVALENCE DASHBOARD VIGNETTE
  # ==========================================================================

  # Landmark equivalences: curated headline comparisons
  targets::tar_target(
    vig_equiv_landmarks,
    {
      # Curated list of reference activities for "headline" comparisons
      refs <- c(
        "Transatlantic flight (radiation dose)",
        "Skydiving (per jump, US)",
        "Running a marathon",
        "General anesthesia (emergency)",
        "Driving (230 miles)",
        "CT scan (chest)"
      )

      # For each reference, pick the most illuminating comparisons
      purrr::map_dfr(refs, function(ref) {
        risk_equivalence(ref) |>
          # Pick comparisons from different categories for variety
          dplyr::slice_head(n = 3)
      }) |>
        dplyr::select(reference, comparison, comparison_category,
                      equivalence, interpretation)
    }
  ),


  # Full equivalence table for transatlantic flight (interactive explorer)
  targets::tar_target(
    vig_equiv_flight,
    risk_equivalence("Transatlantic flight (radiation dose)")
  ),


  # Risk exchange rate chart (plotly)
  targets::tar_target(
    vig_equiv_plot,
    {
      flight_equiv <- risk_equivalence("Transatlantic flight (radiation dose)")

      # Filter to event-based activities for clean comparison, top 25
      plot_data <- flight_equiv |>
        dplyr::slice_max(equivalence, n = 25) |>
        dplyr::bind_rows(
          flight_equiv |> dplyr::slice_min(equivalence, n = 10)
        ) |>
        dplyr::distinct(comparison, .keep_all = TRUE)

      plotly::plot_ly(
        data = plot_data,
        x = ~equivalence,
        y = ~reorder(comparison, equivalence),
        type = "bar",
        orientation = "h",
        color = ~comparison_category,
        text = ~interpretation,
        hoverinfo = "text"
      ) |>
        plotly::layout(
          title = list(
            text = paste0(
              "Risk Equivalence: How Many of Each Activity = 1 Transatlantic Flight?",
              "<br><sup>",
              "Ratio of micromorts. Values >1 mean the activity is less risky ",
              "(you need more of them to match). Log scale. ",
              "Source: common_risks() + Wall et al. (2011) BJR.",
              "</sup>"
            )
          ),
          xaxis = list(title = "Equivalence Ratio (log scale)", type = "log"),
          yaxis = list(title = ""),
          shapes = list(
            list(
              type = "line", x0 = 1, x1 = 1,
              y0 = 0, y1 = 1, yref = "paper",
              line = list(color = "red", dash = "dash", width = 2)
            )
          ),
          annotations = list(
            list(
              x = log10(1), y = 1.02, yref = "paper",
              text = "1 transatlantic flight", showarrow = FALSE,
              font = list(color = "red", size = 10)
            )
          ),
          margin = list(l = 250),
          legend = list(orientation = "h", y = -0.15)
        )
    }
  ),


  # Medical radiation focused comparison
  targets::tar_target(
    vig_equiv_medical_radiation,
    {
      med_rad <- common_risks() |>
        dplyr::filter(category == "Medical Radiation") |>
        dplyr::arrange(micromorts)

      # Cross-compare all medical radiation activities
      purrr::map_dfr(med_rad$activity, function(act) {
        risk_equivalence(act) |>
          dplyr::filter(comparison_category == "Medical Radiation" |
                          comparison %in% c(
                            "Flying (1000 miles)",
                            "Driving (230 miles)",
                            "Eating 1000 bananas (radiation)"
                          ))
      }) |>
        dplyr::select(reference, comparison, equivalence, interpretation)
    }
  ),


  # Cross-category equivalence matrix (12 landmark activities)
  targets::tar_target(
    vig_equiv_matrix,
    {
      landmarks <- c(
        "Chest X-ray", "Driving (230 miles)", "Flying (1000 miles)",
        "Transatlantic flight (radiation dose)",
        "Skydiving (per jump, US)", "Running a marathon",
        "Scuba diving (per dive, trained)", "General anesthesia (emergency)",
        "CT scan (chest)", "Night in hospital",
        "Base jumping (per jump)", "Motorcycling (60 miles)"
      )

      risks <- common_risks() |>
        dplyr::filter(activity %in% landmarks)

      # Build NxN matrix
      matrix_data <- tidyr::expand_grid(
        ref_activity = landmarks,
        comp_activity = landmarks
      ) |>
        dplyr::filter(ref_activity != comp_activity) |>
        dplyr::left_join(
          risks |> dplyr::select(activity, micromorts),
          by = c("ref_activity" = "activity")
        ) |>
        dplyr::rename(ref_mm = micromorts) |>
        dplyr::left_join(
          risks |> dplyr::select(activity, micromorts),
          by = c("comp_activity" = "activity")
        ) |>
        dplyr::rename(comp_mm = micromorts) |>
        dplyr::mutate(
          ratio = round(ref_mm / comp_mm, 2),
          label = sprintf("1 %s = %s %s",
                          ref_activity,
                          format(ratio, big.mark = ","),
                          comp_activity)
        )

      matrix_data
    }
  )
```

### 5. Tests: `tests/testthat/test-risk-equivalence.R`

```r
test_that("risk_equivalence returns correct structure", {
  result <- risk_equivalence("Driving (230 miles)")
  expect_s3_class(result, "tbl_df")
  expect_named(result, c("reference", "reference_micromorts", "comparison",
                          "comparison_micromorts", "comparison_category",
                          "equivalence", "interpretation"))
  # Driving = 1 mm, so chest X-ray (0.1 mm) should give equivalence = 10
  chest_row <- result |> dplyr::filter(comparison == "Chest X-ray")
  expect_equal(chest_row$equivalence, 10)
})

test_that("risk_equivalence validates inputs", {
  expect_error(risk_equivalence("NONEXISTENT"), "not found")
  expect_error(risk_equivalence(123))
  expect_error(risk_equivalence("Driving (230 miles)",
                                risks = data.frame(x = 1)))
})

test_that("risk_equivalence min_ratio filters correctly", {
  full <- risk_equivalence("Mt. Everest ascent", min_ratio = 0)
  filtered <- risk_equivalence("Mt. Everest ascent", min_ratio = 1)
  expect_lt(nrow(filtered), nrow(full))
  expect_true(all(filtered$equivalence >= 1))
})

test_that("risk_equivalence excludes self-comparison", {
  result <- risk_equivalence("Driving (230 miles)")
  expect_false("Driving (230 miles)" %in% result$comparison)
})

test_that("medical radiation activities exist in common_risks", {
  risks <- common_risks()
  expect_true("Chest X-ray" %in% risks$activity)
  expect_true("CT scan (chest)" %in% risks$activity)
  expect_true("Dental X-ray" %in% risks$activity)
  expect_true("Mammogram" %in% risks$activity)
  expect_true("Transatlantic flight (radiation dose)" %in% risks$activity)
  # Verify category
  med_rad <- risks |> dplyr::filter(category == "Medical Radiation")
  expect_gte(nrow(med_rad), 8)
})

test_that("risk_equivalence math is correct", {
  # Transatlantic flight = 1 mm, Chest X-ray = 0.1 mm
  # So 1 flight = 10 chest X-rays
  result <- risk_equivalence("Transatlantic flight (radiation dose)")
  chest <- result |> dplyr::filter(comparison == "Chest X-ray")
  expect_equal(chest$equivalence, 10)

  # CT scan (chest) = 7 mm, Chest X-ray = 0.1 mm
  # So 1 CT = 70 chest X-rays
  result2 <- risk_equivalence("CT scan (chest)")
  chest2 <- result2 |> dplyr::filter(comparison == "Chest X-ray")
  expect_equal(chest2$equivalence, 70)
})
```

### 6. Adversarial Tests: `tests/testthat/test-adversarial-risk-equivalence.R`

```r
test_that("risk_equivalence handles edge cases", {
  # Activity with lowest micromorts (0.05)
  result <- risk_equivalence("COVID-19 bivalent booster (age 18-49)")
  expect_true(all(result$equivalence <= 1))

  # Activity with highest micromorts (37932)
  result <- risk_equivalence("Mt. Everest ascent")
  expect_true(all(result$equivalence >= 1))

  # Custom risks dataset
  custom <- tibble::tibble(
    activity = c("A", "B"),
    micromorts = c(10, 2),
    category = c("X", "Y")
  )
  result <- risk_equivalence("A", risks = custom)
  expect_equal(nrow(result), 1)
  expect_equal(result$equivalence, 5)
})

test_that("risk_equivalence handles zero micromorts gracefully", {
  # Create dataset with zero
  custom <- tibble::tibble(
    activity = c("A", "B"),
    micromorts = c(10, 0),
    category = c("X", "Y")
  )
  # Division by zero should produce Inf, filtered by min_ratio default
  result <- risk_equivalence("A", risks = custom, min_ratio = 0)
  expect_true(is.infinite(result$equivalence[result$comparison == "B"]) ||
              nrow(result |> dplyr::filter(comparison == "B")) == 0)
})
```

### 7. Registration in `_pkgdown.yml`

#### Add to navbar articles menu:

```yaml
      - text: "Risk Equivalence"
        href: articles/risk_equivalence.html
```

#### Add `risk_equivalence` to reference section "Analysis Functions":

```yaml
- title: "Analysis Functions"
  desc: "Risk analysis and modeling"
  contents:
  - compare_interventions
  - lifestyle_tradeoff
  - daily_hazard_rate
  - annual_risk_budget
  - risk_equivalence
```

### 8. NAMESPACE and Documentation

After adding the function with `@export`:

```bash
nix-shell default.nix --run "Rscript -e 'devtools::document()'"
```

This will:
- Generate `man/risk_equivalence.Rd`
- Add `export(risk_equivalence)` to NAMESPACE
- Update any `@family analysis` cross-references

### 9. Update `R/visualization.R` globalVariables

Add new variables used in the targets pipeline:

```r
utils::globalVariables(c(
  # ... existing ...
  # risk_equivalence()
  "reference", "reference_micromorts", "comparison",
  "comparison_micromorts", "comparison_category", "equivalence",
  "interpretation",
  # vig_equiv_matrix
  "ref_activity", "comp_activity", "ref_mm", "comp_mm", "ratio", "label"
))
```

---

## Implementation Sequence (9-Step Workflow)

### Step 0: Plan (this document)

### Step 1: Create GitHub Issue

```r
gh::gh("POST /repos/johngavin/micromort/issues",
  title = "Add risk equivalence dashboard vignette",
  body = "## Summary\n- Add medical radiation data (8 activities)\n- New risk_equivalence() function\n- New vignette with interactive DT/plotly tables\n\nSee plans/PLAN_risk_equivalence_dashboard.md",
  labels = list("enhancement", "vignette")
)
```

### Step 2: Create Branch

```r
usethis::pr_init("feature/risk-equivalence-dashboard")
```

### Step 3: Make Changes (RED-GREEN-REFACTOR)

Order of implementation:

1. **Write tests first** (`test-risk-equivalence.R`, `test-adversarial-risk-equivalence.R`)
   - Tests will FAIL (RED) because function and data don't exist yet

2. **Add data** to `data-raw/sources/acute_risks_base.csv` and `risk_sources.csv`
   - Add 8 medical radiation rows + 1 new source

3. **Add data to `common_risks()`** in `R/risks.R`
   - Add 8 new entries to the tribble
   - Add `rad_lit` URL variable
   - Update `parse_period()` for "per flight"

4. **Implement `risk_equivalence()`** in `R/risks.R`
   - Write function body
   - Add roxygen documentation
   - Handle edge cases (zero micromorts, Inf ratios)

5. **Run tests** -- should now PASS (GREEN)

6. **Add vignette targets** to `R/tar_plans/plan_vignette_outputs.R`
   - 6 new targets: vig_equiv_landmarks, vig_equiv_flight,
     vig_equiv_plot, vig_equiv_medical_radiation, vig_equiv_matrix

7. **Create vignette** `vignettes/risk_equivalence.Rmd`
   - Zero computation; all data from safe_tar_read()

8. **Update `_pkgdown.yml`** -- add navbar entry and reference entry

9. **Update globalVariables** in `R/visualization.R`

### Step 4: Run Checks + QA

```bash
nix-shell default.nix --run "Rscript -e 'devtools::document()'"
nix-shell default.nix --run "Rscript -e 'devtools::test()'"
nix-shell default.nix --run "Rscript -e 'targets::tar_make()'"
nix-shell default.nix --run "Rscript -e 'devtools::check(args = \"--as-cran\")'"
```

Verify:
- [ ] `risk_equivalence()` tests pass (0 failures)
- [ ] Medical radiation data present in `common_risks()` (70 activities total)
- [ ] All `vig_equiv_*` targets build successfully
- [ ] Vignette renders without errors
- [ ] R CMD check: 0 errors, 0 warnings
- [ ] Adversarial tests pass (>= 95%)
- [ ] Quality gate >= Silver (90+)

### Step 5: Push Cachix

```bash
./push_to_cachix.sh
```

### Step 6: Push GitHub

```r
usethis::pr_push()
```

### Step 7: Wait for CI

```bash
gh pr checks
```

### Step 8: Merge PR

```r
usethis::pr_merge_main()
```

### Step 9: Log Everything

Include `R/dev/issues/fix_risk_equivalence.R` script in PR.

---

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| Medical radiation micromort values disputed | Use conservative estimates from peer-reviewed BJR/Radiology; note uncertainty in vignette caveats section |
| Period mismatch confuses users | Vignette Section 7 explicitly addresses "per event" vs "per year" comparisons |
| 70+ activities makes DT tables slow | Use `pageLength = 15` and server-side filtering |
| plotly heatmap for 12x12 matrix too dense | Use DT::datatable instead if heatmap is cluttered; matrix_data target supports both |
| `risk_equivalence()` with zero-micromort activity | Guard with `dplyr::filter(micromorts > 0)` before division, or let Inf through and filter with min_ratio |
| Existing `common_risks()` is hardcoded tribble | Adding rows is straightforward; data also flows through CSV pipeline for parquet export |

## Files Changed

| File | Change |
|------|--------|
| `data-raw/sources/acute_risks_base.csv` | Add 8 medical radiation rows |
| `data-raw/sources/risk_sources.csv` | Add 1 new source (radiation_literature) |
| `R/risks.R` | Add 8 activities to `common_risks()` tribble; add `risk_equivalence()` function |
| `R/tar_plans/plan_vignette_outputs.R` | Add 6 new `vig_equiv_*` targets |
| `R/visualization.R` | Add globalVariables for new columns |
| `vignettes/risk_equivalence.Rmd` | New vignette (zero computation) |
| `_pkgdown.yml` | Add navbar entry + reference entry |
| `tests/testthat/test-risk-equivalence.R` | New test file |
| `tests/testthat/test-adversarial-risk-equivalence.R` | New adversarial test file |
| `NAMESPACE` | Auto-generated: export(risk_equivalence) |
| `man/risk_equivalence.Rd` | Auto-generated roxygen docs |

## Success Criteria

1. `risk_equivalence("Transatlantic flight (radiation dose)")` returns a tibble showing "1 flight = 10 Chest X-rays"
2. `common_risks()` has 70 activities (62 existing + 8 new medical radiation)
3. `devtools::check()` passes with 0 errors, 0 warnings
4. All 6 `vig_equiv_*` targets build successfully
5. Vignette renders with interactive DT tables and plotly chart
6. pkgdown site shows "Risk Equivalence" in navbar Articles menu
7. All tests pass including adversarial edge cases
