# Vignette Content Audit Rule

## When
After any vignette is added or modified, and before publishing the pkgdown site.

## Required Checks

### Content completeness
1. Every ggplot/plotly figure MUST have `fig-cap` and `fig-alt`
2. Every DT::datatable MUST have a caption argument
3. Every mermaid diagram MUST have a fig-cap
4. Markdown tables SHOULD have captions (via `tbl-cap` chunk option)
5. Code chunks: verify echo setting matches intent (hidden for data, shown for API docs)
6. All navbar article URLs must resolve (extend verify_pkgdown_urls.R)

### Staleness check (MANDATORY — validation FAILS if stale)
For each vignette .qmd file:
1. Get the file's last-modified timestamp: `file.mtime("vignettes/X.qmd")`
2. Get the file's last git-committed timestamp: `gert::git_log(path = "vignettes/X.qmd", max = 1)$time`
3. Get the last push timestamp: `gert::git_ahead_behind()` — if ahead > 0, file hasn't been pushed
4. **FAIL** if `file.mtime > last_commit_time` (uncommitted local changes)
5. **FAIL** if branch is ahead of remote (committed but not pushed)
6. Compare last commit timestamp against the deployed pkgdown site's article HTML:
   check `docs/articles/X.html` modification time (if docs/ exists locally) or
   the `Last-Modified` HTTP header from `https://johngavin.github.io/micromort/articles/X.html`
7. **WARN** if the .qmd was committed+pushed more recently than the deployed HTML

### Implementation
Use R code (not bash) via gert/fs packages:
- `fs::file_info("vignettes/*.qmd")$modification_time` for file timestamps
- `gert::git_log(path = file, max = 1)$time` for last commit per file
- `gert::git_ahead_behind()` for push status
- `httr2::request(url) |> req_method("HEAD") |> req_perform()` for deployed HTML timestamps

## Audit Output
Produce a summary table grouped by vignette showing:
- Content: tables (with/without captions), figures (with/without fig-cap, fig-alt),
  diagrams (with/without captions), code chunks (echo true/false)
- Staleness: file_mtime, last_commit, last_push, deployed_html_date, status (OK/STALE/WARN)
