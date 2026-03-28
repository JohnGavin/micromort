# micromort — Medical Risk Metrics Package

## ctx.yaml Package Context

**Central cache:** `~/docs_gh/proj/data/llm/content/inst/ctx/external/`

All ctx.yaml files are version-stamped (`{pkg}@{version}.ctx.yaml`) and stored centrally. To check coverage:

```r
source("~/docs_gh/llm/R/tar_plans/plan_pkgctx.R")
ctx_audit("DESCRIPTION")   # report gaps
ctx_sync("DESCRIPTION")    # generate missing
```

To read a package's API before using it:
```bash
cat ~/docs_gh/proj/data/llm/content/inst/ctx/external/{pkg}@{version}.ctx.yaml
```

**DO NOT** look for ctx files in `.claude/context/` or `inst/ctx/` — they don't exist there. Use the central cache only.

## Project Rules

- PHI/patient data: NEVER commit without anonymization (see `medical-data-anonymization` global rule)
- DuckDB: use `connect_duckdb_secure()` pattern (see `duckdb-security` global rule)
- Risk values: must come from data/targets, never hardcoded
- Vignettes: zero inline computation, all via `safe_tar_read()`

## Key Packages

Imports: checkmate, cli, DBI, dplyr, duckdb, htmltools, rlang
Suggests: 28 packages (see DESCRIPTION)
