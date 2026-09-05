# Current Work — micromort

_Ephemeral session-state file. Overwritten each session end._

## Last session: 2026-09-05 (two /bye rounds)

### Status: session complete, all planned work merged, verified, and housekeeping cleaned up

Everything from this session is live on https://johngavin.github.io/micromort/
(quiz correctness fixes, Shinylive retirement — see the two 2026-09-05
CHANGELOG entries for the full list). Second round, after the first /bye,
added:

- Merged `llm#1165` (the new `shinylive-vs-js-duplication` global rule) and
  filed `llm#1167` (a real bug: `generate_ctx()` swallows stderr, hiding
  `ctx_sync()` failure causes).
- Diagnosed both failures flagged at the first `/bye`: `ctx_sync` fails due
  to crates.io blocking this sandbox's network (not a code bug); the
  telemetry export failure was a transient DB-lock plus a real `tail -5`
  truncation bug in the wrapper script — retried successfully.
- Interactively verified the #179 fix (real rebuild + Puppeteer, not just
  static checks) — 6/6 reproductions pre-fix, 6/6 clean post-fix. Pushed
  `archive/shinylive-quizzes-2026-09-05-fixed` as the recommended
  resurrection point. Left #179 open (no live surface to close against).
- Filed #181 (separate low-priority archived-page bug found during that
  verification).
- Found and cleaned up a real incident: `export_and_deploy_data.sh` left
  ~5.2MB of llmtelemetry data as stray untracked files in this worktree
  (no data lost — correct copies also landed in `llmtelemetry`). Removed
  them, filed `llmtelemetry#361` (private repo) with evidence pointing at a
  likely concurrent-invocation race, not a simple bug.

### Next session should

1. Nothing urgent on the quiz work — site is stable, JS-only, live.
2. If `llmtelemetry#361` (private repo — stray write during concurrent
   script invocations) recurs, that issue has the diagnostic next-step
   (instrument `pkg_root` resolution in `export_dashboard_data.R`).
3. `llm#1167` (generate_ctx stderr swallowing) and #181 (archived-page
   desync bug) are both filed, low-priority, unfixed — pick up if ever
   relevant again.
4. roborev backlog note (unchanged from first /bye check): 17 outstanding
   unaddressed verdict failures, 0 crash, 0 quota — not actioned, not
   related to this session's changes. Worth a sweep if it keeps growing.

### Branch state

This session's own branch (`feat/cc-20260903-092557`) carries only
documentation commits (CHANGELOG/CURRENT_WORK appends) — all real code
changes landed via separate dispatched-agent branches, each merged to
`main` (PRs #172-#180) or, for #179, pushed as a standalone archive-tag
branch with no `main` target. This branch is fast-forwarded to
`origin/main` as of this update.
