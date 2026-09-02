# Current Work — micromort

**Branch:** `main` (session worktree `feat/cc-20260830-194708` had no local commits — all work landed via merged PRs)
**Last session:** 2026-08-30/09-01 — worktree cleanup, quiz-confidence feature (#132), site layout fixes

## Status

Main is fully current at `4b892b3` — all 9 PRs from this session merged and deployed (#133, #120, #135, #136, #137, #139, #134, #140, #143). Live: https://johngavin.github.io/micromort/articles/micromort-quiz.html

## What just shipped

- **Quiz confidence, Phase 1+2, `micromort-quiz.qmd` only**: per-question confidence capture, self-only Brier score, population comparison wired to the shared Google Form (`entry.1681143871`) — see [issue #132](https://github.com/JohnGavin/micromort/issues/132).
- **Site layout fix**: Shinylive banner / Source line / footer moved off the quiz scroll path into a new `vignettes/details.qmd` tabset page; toolbar (A−/A+/theme) root-cause fixed to actually render `position:fixed` top-right (was silently losing its CSS via a pkgdown/quarto `include-in-header` content-drop bug); 20 WCAG-AA contrast failures fixed. See [issue #142](https://github.com/JohnGavin/micromort/issues/142) for why this took 3 attempts.
- **PR #120 unstuck**: 101-day-stale branch had a real rounding bug (`combined_quiz_pairs()` period-row scaling) plus a frozen merge-base from prior squash-merges — both fixed, merged.

## Next session — priorities

1. **Replicate quiz-confidence Phase 2 to the other 2 quizzes** (`microlife-quiz.qmd`, `risk-ranking-quiz.qmd`) — per `project_quiz-confidence-phase2-definition-of-done` memory, the pattern is now proven on `micromort-quiz.qmd`; copy it rather than rebuilding from scratch.
2. **Watch for real population confidence data** to start flowing into `docs/api/quiz_stats.json`'s `calibration` block (currently `n: 0`) — once it does, sanity-check the attempt-level Brier approximation against real submissions.
3. Fix the `docs/pkgdown.yml`-sentinel-after-`git rm -rf docs` workaround properly (hit 4 times this session) — maybe a `site_pre_check`/`site_verify` target that seeds it automatically.
4. `worktree-agent-a57cb96f` branch/worktree still un-triaged (deferred, ambiguous salvage signal).
5. Any new UI/layout claim about the quiz pages MUST be verified with real puppeteer-core browser interaction (proven working this session) before being reported as fixed — static grep/curl checks have been wrong twice.

## Roborev

- 16 reviews since 2026-08-26: 12 failed verdicts, 6 addressed (6 open, all `gemini`, no crash/quota).
- 3 phantom "High severity" findings (#9962/#9963/#9968, all "couldn't read my own diff snapshot") closed as invalid — root cause tracked in [llm#1127](https://github.com/JohnGavin/llm/issues/1127).
