# Current Work

## Session: 2026-03-17

### Branch: main (post-merge from issue-60-chronic-quiz)

### Completed This Session

1. **Site build pipeline** — `R/tar_plans/plan_site_build.R` (5 targets: `site_pkgdown`, `site_quiz_shinylive`, `site_chronic_shinylive`, `site_deploy_shinylive`, `site_verify`). Zero manual steps: `tar_make()` builds everything.

2. **Navbar reorder** — Interactive quizzes moved to top of Articles dropdown, Architecture/Telemetry moved to bottom.

3. **Quiz button reorder** — Results page: Submit Score | Share | View Details | Try Again (both quizzes).

4. **Encouragement text alignment** — Removed `text-center`, added `padding-left: 1.5em` for consistency with bullet list.

5. **Chronic quiz intro text** — Split microlife definition into two lines with indented example.

6. **Deduplicate quiz pairs** — Added canonical key dedup in `quiz_pairs()` and `chronic_quiz_pairs()` in `R/quiz.R`.

7. **External reference links** — Detail results tables now hyperlink activity/factor names to `help_url` (Wikipedia, CDC, WHO). Both quizzes.

8. **Chronic quiz Submit Score** — Added leaderboard JS (reuses acute quiz Google Form/Sheet), Submit button, percentile text.

9. **quiz_type field** — Both quizzes send `quiz_type` ("acute"/"chronic") to Google Form (entry.268026248). Chronic percentile filters by type.

10. **difficulty + n_questions fields** — Both quizzes send difficulty (entry.232879816) and n_questions (entry.2010782223) to Google Form.

11. **Share button includes percentile** — Clipboard text dynamically includes percentile ranking if available.

12. **Pre-computed leaderboard stats** — `R/tar_plans/plan_leaderboard_stats.R` (2 targets). Fetches Google Sheet, computes quantile summaries, writes `docs/api/quiz_stats.json`. JS two-tier fetch: static JSON first, live Sheet fallback.

13. **Weekly GitHub Action** — `.github/workflows/leaderboard-refresh.yml`. Mondays 06:00 UTC: refresh stats, commit, conditional email report (only if submissions in past week). Tested successfully.

### Google Form Fields (6 total)
| Field | Entry ID | Values |
|-------|----------|--------|
| score | 335579146 | integer |
| total | 2122920576 | integer |
| timestamp | 621716914 | ISO 8601 |
| quiz_type | 268026248 | "acute" / "chronic" |
| difficulty | 232879816 | "easy"/"medium"/"hard"/"mixed" |
| n_questions | 2010782223 | 5 / 10 |

### Pipeline: 91 targets
- `plan_leaderboard_stats` (2 targets) and `plan_site_build` (5 targets) added
- All 548 tests pass

### Still Pending
- Untracked build artifacts in `vignettes/` (quarto render outputs) — consider `.gitignore`
- `check/` directory from R CMD check — should be in `.gitignore`
- `man/figures/logo-candidates/` — decide if to commit or ignore
- Subgroup percentile will activate once enough submissions accumulate (n >= 10 per config)

### Open Issues
- #60: Chronic quiz (merged via PR #62)
