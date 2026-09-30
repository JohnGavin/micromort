# Current Work — micromort

**Branch:** `feat/cc-20260926-134325` (own worktree had no unique commits this session — all real work landed via dispatched agents' branches, merged to main directly, then fast-forwarded into this branch)
**Last session:** 2026-09-26/30 — quiz leaderboard-stats deploy fix (#132) → radiation-conversion-factor audit and fix (#196)

## Status

Main is at `423f865` — PRs #195 (leaderboard stats/deploy fix, merged last, after a conflict resolution), #197, #198, #199 all merged. A separate cross-repo fix, `llm` PR #1289 (private_repo_detail_guard.sh word-boundary bug), also merged.

## What just shipped

- **Quiz leaderboard stats — percent-scale bug + stale deploy**: the Google Sheet's confidence column returns a *fraction* (0.75) via gviz, but `plan_leaderboard_stats.R` treated it as already-0-100. Fixed with a `confidence_fraction_to_pct()` helper that also rejects out-of-range values loudly. Separately, the refresh workflow committed with `GITHUB_TOKEN`, which doesn't trigger the Pages deploy workflow — added an explicit `gh workflow run pkgdown.yaml` step, and moved the refresh from weekly-only to daily. PR #195, opened, **not yet merged** — pending review.
- **Radiation-to-micromort conversion was 1000x too low**: `msv_to_micromorts()` used 0.05 micromorts/mSv; two independent primary sources (FDA's CT-risk guidance, ICRP 103 via the NRC synopsis) agree on 50/mSv. Fixed in PR #197 (6 rows), then PR #199 (9 more rows, 4 medical-scan doses + 5 flight/altitude rows derived self-consistently from the file's own already-fixed cosmic-dose-per-hour constant). Both merged.
- **Added a new data point**: "Accidental drowning, Japan age 75+ (annual)" — 330 micromorts/year, Satoh et al. 2013, JP-conditioned, does not touch/replace the existing general-population "Taking a bath" row. PR #198, merged.
- **Fixed a real guard false-positive in `llm`**: `private_repo_detail_guard.sh`'s candidate-name match was a bare substring (`grep -F`), so a 6-char private repo name matched inside an unrelated longer English word. Fixed with `-w` (whole-word). **Live-disclosure incident during the fix**: a dispatched agent's first commit named the actual private repo in its own commit message before self-correcting in a second commit — which does NOT remove it from pushed history. Caught, history rewritten (squashed to one clean commit), force-pushed before merge. `llm` PR #1289, merged.
- **Split #196 into per-row issues**: the 5 rows PR #199 couldn't source (genuinely conflicting/too-variable literature, not a research gap) are now individually tracked as #200 (nuclear plant worker), #201 (dental radiographer), #202 (interventional cardiologist), #203 (granite resident/radon), #204 (X-ray technician). #196 itself is narrowed to just the separate legacy `acute_risks_base.csv` pipeline bug (stale snapshot + a wine-row CSV parsing bug).

## Roborev finding — NOT actioned this session (deferred, tracked)

A roborev review on PR #197 (job 13730, verdict FAIL) was never addressed and is still accurate as of today:

1. **The quiz currently ships internally-inconsistent comparisons.** 5 of the 14 originally-wrong rows (#200-#204) are still at ~1000x-too-low values, mixed into the same `common_risks()`/quiz output as the 9 now-fixed rows. Concretely: "Granite resident (annual radon)" (0.10) vs "Normal background radiation" (155.5) — backwards by construction.
2. **A second, independent duplicate**: `R/radiation_profiles.R:89` hardcodes `xray_mm <- 0.1` separately from the now-corrected `med_rad` chest X-ray row (`1`).

User was asked to choose a stopgap (scale-by-1000 or exclude-from-quiz) vs. defer; re-ran `/bye` without picking, so this was logged as [#205](https://github.com/JohnGavin/micromort/issues/205) rather than fixed. **This needs a decision next session**, not silent deferral again.

## Next session — priorities

1. **Decide and fix [#205](https://github.com/JohnGavin/micromort/issues/205)** (the interim-inconsistency issue).
2. **Dispatch "Leaderboard Stats Refresh" once** (`workflow_dispatch`) — #195 changed that workflow and it has never run; confirm stats regenerate and Pages deploys. Also tidy the two leftover agent worktrees (`agent-a64c4e12df0c34abb`, `agent-ac56acae76cbf4429`).
3. **Work #200-#204** (the 5 genuinely-unresourced radiation rows) as real research tasks — each has a clear "what done looks like" bar already written.
4. **#196** (narrowed) — fix the wine-row CSV parsing bug in the legacy `acute_risks_base.csv` pipeline, then decide whether that dataset should be re-derived from `R/atomic_risks.R` or kept independently sourced.
5. **Network on this machine was intermittently dropping ALL outbound HTTPS** (not just GitHub) for extended periods this session — worth checking if it recurs.
