# Current Work — micromort

_Ephemeral session-state file. Overwritten each session end._

## Last session: 2026-09-05

### Status: session complete, all planned work merged and live-verified

Everything from this session's task list shipped and is live on
https://johngavin.github.io/micromort/:

- Reopened and correctly fixed #142 (quiz-page banner/footer/Source-line
  clutter) and #132 (per-question confidence capture) across all 6 quiz
  vignettes, after prior sessions had incorrectly claimed these fixed.
- Next-button green highlight after submit, all 6 quizzes.
- Confidence-before-reveal correctness fix (confidence must be captured
  BEFORE the answer is revealed, not simultaneously) — PRs #172-#177, all
  merged.
- Page-title font-size shrink on all 6 quiz pages — PR #178, merged.
- Confirmed no historical confidence data was lost (a user-raised concern);
  root-caused to a 1-day-old full rollout, working as designed.
- Filed #179 (tag-selection race condition in `ranking_quiz_shinylive.qmd`
  — now moot, page just redirects, kept open at low priority).
- Architecture review of the 6-quiz JS/Shinylive duplication -> retired the
  3 Shinylive quizzes (PR #180, merged). ~181MB recovered from `docs/`.
  Archived, not deleted — full old content at git tag
  `archive/shinylive-quizzes-2026-09-05`.
- Documented the general decision framework in a new global rule
  (`shinylive-vs-js-duplication.md` in the `llm` project) for future
  projects choosing between Shinylive and JS-only implementations.

### Next session should

1. If continuing quiz work: nothing urgent — the 3-quiz site is stable and
   JS-only now. Population-confidence panels will start showing content
   once >=5 rated attempts land per topic (currently accumulating).
2. Optional housekeeping (not urgent): commit the new
   `shinylive-vs-js-duplication.md` rule to the `llm` repo via its own PR
   (currently only local on this machine) and add its RULES.md index
   pointer.
3. #179 (ranking-quiz tag-selection race) is low priority now that the page
   redirects to JS — only worth fixing if the archived Shinylive version is
   ever resurrected from the `archive/shinylive-quizzes-2026-09-05` tag.
4. roborev backlog note: at session-end check, `verdicts.failed=27` vs.
   `verdicts.addressed=10` (17 outstanding, unrelated to this session's own
   changes — 0 crash, 0 quota). Not actioned this session; worth a backlog
   sweep if it keeps growing.

### Branch state

This session's own branch (`feat/cc-20260903-092557`) carries no unique
commits of its own beyond this CHANGELOG/CURRENT_WORK append — all real
code changes landed via separate dispatched-agent branches, each already
merged to `main` (PRs #172-#180). This branch was fast-forwarded to
`origin/main` before this update.
