# micromort — Medical Risk Metrics Package

## CRITICAL: Package Context (ctx.yaml)

**Central cache:** `~/docs_gh/proj/data/llm/content/inst/ctx/external/`

This cache has 70+ version-stamped ctx files shared across all projects.

**To check ctx coverage, ALWAYS run:**
```r
source("~/docs_gh/llm/R/tar_plans/plan_pkgctx.R")
ctx_audit("DESCRIPTION")
```

**To fix missing ctx:**
```r
source("~/docs_gh/llm/R/tar_plans/plan_pkgctx.R")
ctx_sync("DESCRIPTION")
```

**NEVER** write your own ctx checking code. NEVER look in `.claude/context/` or `inst/ctx/` — those don't exist. ALWAYS use `ctx_audit()` from `plan_pkgctx.R`.

**To read a package API before using it:**
```r
# Find the file
list.files("~/docs_gh/proj/data/llm/content/inst/ctx/external", pattern = "^dplyr@")
# Read it
readLines("~/docs_gh/proj/data/llm/content/inst/ctx/external/dplyr@1.1.4.ctx.yaml")
```

## Project Rules

- PHI/patient data: NEVER commit without anonymization (see `medical-data-anonymization` global rule)
- DuckDB: use `connect_duckdb_secure()` pattern (see `duckdb-security` global rule)
- Risk values: must come from data/targets, never hardcoded
- Vignettes: zero inline computation, all via `safe_tar_read()`
- DBI::dbGetQuery forbidden — use duckplyr instead
- suppressWarnings(as.*) forbidden — see `suppress-warnings-antipattern` rule
- cli::cli_abort() not stop() for errors
