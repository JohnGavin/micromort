# Current Work — micromort

_Ephemeral session-state file. Overwritten each session end._

## Last session: 2026-09-05 through 2026-09-07 (multiple /bye rounds)

### Status: session complete, quiz data-capture pipeline fully shipped and verified live

Everything from this multi-day session shipped and is live on
https://johngavin.github.io/micromort/ — see the four dated CHANGELOG
entries (2026-09-05 x3, 2026-09-06/07) for full detail. Headline items:

- Reopened and correctly fixed #142/#132 across all 6 quizzes, confidence-
  before-reveal correctness fix, Next-button highlight, title font-size.
- Retired the 3 Shinylive quizzes (PR #180) in favor of JS-only, after an
  architecture review found no remaining exclusive capability worth the
  2x-maintenance cost. Archived at `archive/shinylive-quizzes-2026-09-05`
  (and a fix-included `-fixed` tag once #179 was verified). Documented the
  general decision framework as a new global rule in the `llm` project.
- Analyzed the Google Sheets submission pipeline (#182), found it only
  captured attempt-level aggregates with no user identification, and
  shipped the fix: a local "My Progress" view + real per-question
  answer/difficulty/confidence + anonymous device-ID now submit live
  (PRs #186, #188) — required the user to manually add 2 fields to the
  Google Form, which I could not do myself (no Forms API access).
- Triaged and cleaned up the open-issue/PR backlog: closed 2 stale PRs
  found to be moot/superseded, merged 1 valid one.

### Next session should

1. Nothing urgent on the quiz work — site is stable, JS-only, and now
   capturing real per-question + anonymous-ID data going forward.
2. [#187](https://github.com/JohnGavin/micromort/issues/187) — chronic
   quiz's question pool has no per-pair difficulty field at the data
   source; low-priority, unfixed.
3. Once enough new per-question submissions accumulate in the Sheet
   (`17HLtIdV3r55dIh06cSaWT8kFXzNrkR-Fu2ZJkjszG8k`), consider building the
   downstream analytics that #182's original question was really asking
   for (per-question calibration, not just attempt-level) — the data now
   exists; nothing consumes it yet.
4. If direct programmatic Google Sheets/Forms access becomes worth the
   setup cost (service account + Cloud project + credential storage), see
   this session's answer to that question in the CHANGELOG/transcript.
5. roborev backlog note: `verdicts.failed=28` vs `verdicts.addressed=12`
   at last check — pre-existing, unrelated to this session's changes, not
   actioned. Worth a sweep if it keeps growing.
6. `roborev_consistency_check.sh --json` threw a jq parse error at session
   end (line 37, invalid numeric literal) despite crash=0/quota=0 being
   visible in the partial output — worth a quick look if it recurs, not
   investigated this session (didn't block anything, informational only).

### Branch state

This session's own branch (`feat/cc-20260903-092557`) carries only
documentation commits (CHANGELOG/CURRENT_WORK appends, 3 rounds) — all
real code changes landed via separate dispatched-agent branches, each
merged to `main` (PRs #172-#180, #186, #188, #153) or, for #179, pushed as
a standalone archive-tag branch with no `main` target. This branch
required a real rebase (not just fast-forward) this round since its own
doc commits had diverged from `origin/main` — resolved cleanly, no code
conflicts, only CHANGELOG.md append-point conflicts.
