# Current Work — micromort

**Branch:** `feat/cc-20260520-113729`
**PR:** https://github.com/JohnGavin/micromort/pull/120 (open, awaiting CI + roborev re-review)
**Last session:** 2026-05-20 (Phase 1+2+3 of roborev #3523 follow-up)

## Status — Roborev

- #3523 closed (consolidated 3 findings — all fixed; comment trail on the review)
- #3515 closed (superseded by #3523)
- 0 open jobs against `micromort`
- 0 unkillable orphans (prior #1084/#733 are gone from the DB)

## What just shipped (PR #120)

Eight commits, pushed to `origin/feat/cc-20260520-113729`:

| SHA | Scope |
|---|---|
| `3a35b16` | B1: `combined_quiz_pairs()` period-row fix + regression tests + regen CSV |
| `964550a` | B2: PM2.5 dedup — `chronic_risks()` reads from parquet |
| `d5e3b29` | GH #97: QR/URL CSS across 6 quiz vignettes |
| `43f6b98` | GH #84: chronic_vs_acute closeread fixes (5 sub-issues) |
| `97c9036` | A1: `vig_pipeline_dependency_graph` RDS rebuilt (70 edges) |
| `046bd9d` | Rd refresh post-roxygen edits |
| `7e6c2e0` | A2: pkgdown rebuild + 3 shinylive direct-renders + RDS refresh |
| `9f7cdbd` | Cleanup: 217 stale `vignettes/*_files/` artifacts + QA snapshot |

## Next session — priorities

**Highest leverage (one PR each):**

1. **Strengthen the freshness guard** (root-cause fix for roborev #3523 finding 3). Currently `test-vignette-outputs.R::test_that("rendered articles fresh")` only compares timestamps. Add a content-hash check: hash each `vig_*` RDS plus `chronic_risks()` / `common_risks()` output, write to `inst/extdata/freshness_hashes.json`, fail the test when a hash in a rendered HTML doesn't match the current source-side hash. ~50 LOC; would catch the next "Air pollution (high)" cascade pre-merge.

2. **Verify deploy on live site.** Open https://johngavin.github.io/micromort/articles/palatable_units.html after GH Pages action completes and confirm:
   - PM2.5 4-row ladder shown (not `Air pollution (high)`)
   - chronic_vs_acute: skydiving in opener, no `#>` heading leaks, table font 1.15rem
   - quiz pages: QR <= 110px, URL 1.2rem monospace, selectable

3. **Carried May-3 issues** (one session each, all `enhancement` label):
   - **#99** evidence review for chronic risk factors (research-heavy — needs lit search before code)
   - **#98** life expectancy offset calculator (new feature, needs design pass)
   - **#89** CI content-grep template (cross-project; best tackled in `llm` repo)

## Open questions / decisions deferred

- Should `chronic_risks()` fully migrate to reading from parquet (instead of the partial bind-rows approach used in B2)? Cleaner architecturally but bigger blast radius — keep the partial fix until the `data-raw -> inst/extdata` build chain is itself targets-tracked rather than ad-hoc.
- Do we want a CI job that runs `pkgdown::build_site()` instead of trusting the committed `docs/`? The current `deploy-pages.yml` is "ship pre-built `docs/`" — saved 30s in CI but means every developer must remember to rebuild. The freshness guard makes the missing-rebuild detectable; a CI-side render would make it preventable.

## Local state

- `_targets/` does NOT exist in this worktree (created some RDS by hand-ported tar code in one-shot Rscripts). Main repo `_targets/` was not touched this session.
- `/tmp/palatable_units_freeze_backup_20260520/` holds the moved-aside Quarto freeze cache — safe to delete next session if no rollback needed.

## Verification cheat-sheet for next session

```bash
# Confirm PR #120 CI + roborev
gh pr checks 120 --repo JohnGavin/micromort
/usr/local/bin/roborev list 2>&1 | grep micromort

# Check live deployed labels (after merge)
curl -s https://johngavin.github.io/micromort/articles/palatable_units.html | grep -c "Air pollution (PM2.5"
curl -s https://johngavin.github.io/micromort/articles/palatable_units.html | grep -c "Air pollution (high)"   # MUST be 0
```
