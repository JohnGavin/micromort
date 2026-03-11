# Current Work

## Last Session: 2026-03-11

### Commits (4 this session)
- **`9420a08`**: Issues #43 (tooltips), #44 (explanations), #45 (leaderboard scaffold), #46 (OG image)
- **`96ce8ab`**: Vignette content audit rule (`.claude/rules/vignette-content-audit.md`)
- **`21ecc7e`**: Replaced leaderboard placeholder URLs with real Google Form values — closes #45
- **`68aa5e1`**: Extended `verify_pkgdown_urls.R` from 17 to 55 URLs (all 8 articles + all reference pages)

### Website Validation: 54/55 OK
- 8/8 articles, 2/2 home, 1/1 reference index, 43/44 reference pages
- Single 404: `/reference/activity_descriptions.html` — awaiting pkgdown rebuild

### Google Form Live
- Form URL: `1FAIpQLSc1HX5kPVO6G982zOxH2BLv1FWexiITPnbjfWMN3a1M9yDtvw`
- Entry IDs: `335579146` (score), `2122920576` (total), `621716914` (timestamp)
- Sheet published to web for JSON reads

### Vignette Audit Gaps (separate PR needed)
- ZERO figures have `fig-cap` or `fig-alt` across all 8 vignettes (~12 ggplot figures)
- ZERO mermaid diagrams have captions (5 in architecture.qmd)
- Markdown tables in architecture.qmd have no captions

### Open Issues
- #45: Leaderboard — CLOSED (real URLs committed)
- #47: User rating/text feedback — depends on #45, ready to start

### Next Session
- Rebuild pkgdown site to deploy new `activity_descriptions` reference page
- Vignette fig-cap/fig-alt remediation (separate PR)
- Issue #47: user rating/text feedback implementation
- Triage remaining uncommitted changes (risk equivalence, API fixes)
