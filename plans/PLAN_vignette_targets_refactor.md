# Plan: Refactor Vignettes to Use Targets Pipeline

**Status**: PLANNING
**Created**: 2026-03-01
**Issue**: Vignettes compute inline instead of using mandatory targets pipeline

## Problem Statement

The micromort vignettes (`regional_variation.Rmd`, `introduction.Rmd`, `palatable_units.Rmd`) violate the mandatory rule from `quarto-files.md`:

> **MANDATORY: Vignettes contain ZERO computation and ZERO assignments.**
> Every `{r}` chunk is exactly ONE expression: `safe_tar_read("vig_target_name")`

### Current Violations in `regional_variation.Rmd`

| Line | Violation | Code |
|------|-----------|------|
| 54-68 | Inline computation + assignment | `regional_life_expectancy() \|> group_by() \|> summarise()` |
| 76-89 | Assignment + computation | `gap_data <- regional_life_expectancy()...` |
| 118-133 | Data query + processing | `regional_life_expectancy() \|> select() \|> arrange()` |
| 141-162 | Full ggplot construction | `regional_life_expectancy() \|> group_by() \|> ggplot()` |
| 170-176 | Data query | `regional_mortality_multiplier("FR10")` |

## Root Cause Analysis

### Why This Happened

1. **No pre-commit check**: No hook validates vignettes for inline computation
2. **No CI gate**: R CMD check doesn't fail on inline computation
3. **Documentation scattered**: Rules in `quarto-files.md`, skill in `targets-vignettes/`, but no single "vignette checklist" enforced at commit time
4. **Data package context**: micromort exports data via functions, making inline queries feel natural—but this is still a violation

### What the Documentation Says

**quarto-files.md (lines 56-78)**:
```
**MANDATORY**: Vignettes perform NO computation.

**All data must come from:**
- `targets::tar_load()` for targets
- `targets::tar_read()` for inline use
- Pre-saved RDS/parquet files in `inst/extdata/`

**Forbidden in vignettes:**
- Database queries
- API calls
- Heavy computation
- File I/O that computes
```

**targets-vignettes/SKILL.md (lines 18-30)**:
```
Vignettes should NOT:
- Run expensive computations directly
- Process raw data
- Generate complex visualizations from scratch
- Take a long time to build
```

## Implementation Plan

### Phase 1: Create Targets Pipeline for Vignettes

#### 1.1 Create `R/tar_plans/plan_vignette_outputs.R`

```r
# R/tar_plans/plan_vignette_outputs.R
# Pre-computed objects for vignettes

plan_vignette_outputs <- list(
  # Regional Variation vignette objects

  # Table: Classification summary (2019)
  targets::tar_target(
    vig_regional_classification_summary,
    regional_life_expectancy(year = 2019, sex = "Total") |>
      dplyr::group_by(classification) |>
      dplyr::summarise(
        n_regions = dplyr::n(),
        mean_le = round(mean(life_expectancy), 1),
        min_le = round(min(life_expectancy), 1),
        max_le = round(max(life_expectancy), 1),
        mean_microlives_diff = round(mean(microlives_vs_eu_avg), 1)
      )
  ),

  # Gap data for microlives calculation
  targets::tar_target(
    vig_regional_le_gap,
    {
      gap_data <- regional_life_expectancy(year = 2019, sex = "Total") |>
        dplyr::group_by(classification) |>
        dplyr::summarise(mean_le = mean(life_expectancy)) |>
        dplyr::filter(classification %in% c("vanguard", "laggard"))

      le_gap <- diff(gap_data$mean_le)
      lifetime_microlives_gap <- abs(le_gap) * 17520

      list(
        le_gap = round(abs(le_gap), 1),
        lifetime_microlives = format(round(lifetime_microlives_gap), big.mark = ","),
        daily_microlives = round(abs(le_gap) * 1.2, 1)
      )
    }
  ),

  # Full data table for explorer
  targets::tar_target(
    vig_regional_explorer_data,
    regional_life_expectancy(year = 2019, sex = "Total") |>
      dplyr::select(region_name, country_code, life_expectancy,
                    microlives_vs_eu_avg, classification) |>
      dplyr::arrange(dplyr::desc(life_expectancy))
  ),

  # Trends plot
  targets::tar_target(
    vig_regional_trends_plot,
    {
      library(ggplot2)
      regional_life_expectancy(sex = "Total") |>
        dplyr::group_by(year, classification) |>
        dplyr::summarise(mean_le = mean(life_expectancy), .groups = "drop") |>
        ggplot(aes(x = year, y = mean_le, color = classification)) +
        geom_line(linewidth = 1.2) +
        geom_vline(xintercept = 2005, linetype = "dashed", alpha = 0.5) +
        annotate("text", x = 2006, y = 74, label = "Divergence\nbegins", hjust = 0, size = 3) +
        scale_color_manual(
          values = c("vanguard" = "#2E7D32", "average" = "#1976D2", "laggard" = "#C62828"),
          labels = c("vanguard" = "Vanguard", "average" = "Average", "laggard" = "Laggard")
        ) +
        labs(
          title = "Life Expectancy Trends by Region Classification",
          subtitle = "Western Europe, 1992-2019",
          x = "Year",
          y = "Life Expectancy at Birth (years)",
          color = "Classification",
          caption = "Source: Eurostat demo_r_mlifexp; Classification per Bonnet et al. (2026)"
        ) +
        theme_minimal() +
        theme(legend.position = "bottom")
    }
  ),

  # Paris mortality multiplier
  targets::tar_target(
    vig_regional_paris_multiplier,
    regional_mortality_multiplier("FR10")
  )
)
```

#### 1.2 Create/Update `_targets.R`

```r
# _targets.R
library(targets)

# Source package functions
for (file in list.files("R", pattern = "\\.R$", full.names = TRUE)) {
  if (!grepl("R/(dev|tar_plans)/", file)) source(file)
}

# Source plans
plan_files <- list.files("R/tar_plans", pattern = "^plan_.*\\.R$", full.names = TRUE)
for (plan_file in plan_files) source(plan_file)

# Combine all plans
c(
  plan_vignette_outputs
)
```

#### 1.3 Refactor `vignettes/regional_variation.Rmd`

Replace all inline computation with `tar_load()`/`tar_read()`:

```rmd
```{r setup}
library(targets)
library(DT)

# Define safe_tar_read for graceful fallback
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

## Key Finding: A Two-Tiered Europe

```{r}
#| echo: false
safe_tar_read("vig_regional_classification_summary") |>
  DT::datatable(
    caption = "Life expectancy by region classification (2019)",
    options = list(dom = "t", pageLength = 5),
    rownames = FALSE
  )
```
```

### Phase 2: Create Enforcement Mechanisms

#### 2.1 Pre-commit Hook for Vignette Validation

Add to `.claude/hooks/vignette_check.sh`:

```bash
#!/bin/bash
# Hook: Validate vignettes have no inline computation

for file in vignettes/*.Rmd vignettes/*.qmd; do
  [ -f "$file" ] || continue

  # Check for forbidden patterns (excluding setup chunk)
  if grep -q '<-' "$file" | grep -v "setup"; then
    echo "ERROR: $file contains assignments (<-)"
    echo "Vignettes must use tar_load()/tar_read() only"
    exit 1
  fi
done
```

#### 2.2 Add to CLAUDE.md Section on Vignettes

**Proposed addition to CLAUDE.md under "Testing Before Commit":**

```markdown
## Vignette Computation Check (MANDATORY)

Before committing any vignette:

1. **Check for inline computation:**
   ```bash
   grep -c '<-\|print(\|ggplot(' vignettes/*.Rmd
   # Must return 0 (excluding setup chunk)
   ```

2. **Verify targets exist:**
   ```r
   targets::tar_manifest() |> filter(grepl("^vig_", name))
   # All vignette objects must be listed
   ```

3. **Vignette pattern:**
   - Every plot/table is a target prefixed `vig_`
   - Every chunk uses `tar_load()` or `safe_tar_read()`
   - ZERO inline computation outside setup chunk
```

### Phase 3: Documentation Improvements

#### 3.1 Add "Vignette Checklist" to quarto-files.md

The existing checklist doesn't have a numbered, sequential workflow. Add:

```markdown
## Pre-Commit Vignette Workflow (SEQUENTIAL)

1. [ ] Create targets in `R/tar_plans/plan_vignette_outputs.R`
2. [ ] Run `tar_make()` to build all vignette objects
3. [ ] Verify targets exist: `tar_manifest() |> filter(grepl("^vig_", name))`
4. [ ] Refactor vignette to use ONLY `tar_load()`/`tar_read()`
5. [ ] Run check: `grep -c '<-' vignettes/*.Rmd` (must be 0 outside setup)
6. [ ] Build vignette: `devtools::build_vignettes()`
7. [ ] Verify rendering doesn't fail with "target not found"
```

#### 3.2 Make Rule More Prominent in CLAUDE.md

The current CLAUDE.md mentions "pre-compute in targets" but doesn't have a dedicated section. Add:

**Proposed new section:**

```markdown
## Vignettes: Zero Computation (ABSOLUTE RULE)

**CRITICAL**: Vignettes are DISPLAY-ONLY documents.

| Allowed | Forbidden |
|---------|-----------|
| `tar_load()` | `<-` assignments |
| `tar_read()` | `dplyr::*` verbs |
| `safe_tar_read()` | `ggplot()` construction |
| `DT::datatable()` on loaded data | Function calls that compute |
| `print()` on loaded plots | `regional_life_expectancy()` queries |

**Exception**: Setup chunk may define `safe_tar_read()` helper.

**Enforcement**: Run `grep -c '<-' vignettes/*.Rmd` before commit.
```

## Tasks

- [ ] Create `R/tar_plans/plan_vignette_outputs.R`
- [ ] Create/update `_targets.R`
- [ ] Refactor `vignettes/regional_variation.Rmd`
- [ ] Refactor `vignettes/introduction.Rmd`
- [ ] Refactor `vignettes/palatable_units.Rmd`
- [ ] Run `tar_make()` and verify all targets build
- [ ] Run `devtools::check()` to verify vignettes render
- [ ] Propose documentation updates to CLAUDE.md (separate PR to ~/.claude/)

## Success Criteria

1. All vignettes have zero inline computation (verified by grep)
2. All vignette objects exist as targets prefixed `vig_`
3. `tar_make()` builds all vignette dependencies
4. `devtools::check()` passes with no vignette errors
5. pkgdown site renders correctly

## Why This Was Missed

The rule exists and is clear, but:

1. **No automated enforcement**: The rule is documentation-only, no hook/CI validates it
2. **Natural API for data packages**: `regional_life_expectancy()` returns tibbles directly, making inline queries feel appropriate (but they're still violations)
3. **Context loss in long sessions**: After many edits, focus on content over compliance

**Recommendation**: Add a simple grep check to the 9-step workflow's Step 4 or create a pre-commit hook.
