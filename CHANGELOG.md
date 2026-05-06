# Changelog

## 2026-05-03 to 2026-05-06

### Completed

**Issues closed: 1** (#96)
**Issues created: 2** (#98, #99)

#### Rankings bump chart (#96)
- 5th tab on Causes of Death page: SVG bump chart showing cause rankings across 26 countries
- Countries sorted by World Bank income group (High → Upper-middle → Lower-middle → Low)
- 14 cause lines with hover-to-highlight interaction
- White cause labels at 0.8rem bold (fixed from gray/small)

#### Merged comparison table
- Table tab in comparison mode: single table grouped by cause (was two separate tables)
- Columns: Cause, Category, Country1 /100k, Country2 /100k, Average, Difference
- Difference column colour-coded; sortable by average and difference

#### Air pollution dose-response (#99)
- Replaced single "Air pollution (high) = -1 ml/day" with 4 PM2.5 level entries
- Based on WHO 2020 meta-analysis (RR=1.08 per 10μg/m³, 107 studies)
- Levels: 10/25/50/100 μg/m³ at -0.5/-1/-2/-4 ml/day
- Confidence tiers: high/high/medium/low

#### Issues raised
- #98: Life expectancy offset calculator (select harmful habits → see offset options)
- #99: Evidence review for 12 missing chronic risk factors (GLP-1, vaping, sleep, social connection, diets)

### Accuracy / Metrics
- Tests: 923 passing, 0 failures
- CI: passing (green)

### Known Limitations
- 12 chronic risk factors still missing from #99 (GLP-1, vaping, sleep dose-response, social connection, DASH/MIND diets, nuts, coffee, aspirin, sauna, dancing, HRT)
- docs_qa_precommit.sh hook still buggy
- Quarto 1.8.26 strips scripts — requires Python post-injection for causes_of_death

## 2026-04-25 to 2026-05-03

### Completed

**Version bump: 0.1.0 → 0.2.0**
**Issues closed: 2** (#93, #95)
**Issues created: 3** (#95, #96, #97)

#### Causes of Death by Country vignette (#93, #95)
- Pure JS interactive page (instant load, no Shinylive WASM)
- 4 tabs: Chart (CSS treemap), Table (sortable), All Countries (#95), Notes
- 26 countries, 14 causes, GBD 2019 data
- Display labels (Cancer not Neoplasms), darkened colours, dynamic captions
- Hover tooltips, clickable cause links to WHO, sortable columns
- All Countries tab: dropdown to select cause, all 26 countries ranked

#### CI QA fixes
- Resolved 29 CI errors: target name mismatches + missing RDS files
- Tightened CI pattern from broad "not available" to exact "not found in targets store or RDS fallback"
- Excluded Closeread/Shinylive articles from CI content check (can't be rebuilt by pkgdown)
- CI now passes (green as of 2026-05-01)

#### Full site rebuild
- All 14 non-Shinylive articles rebuilt with updated navbar
- Exported 84 vignette targets to RDS fallback files
- Footer updated: "micromort 0.2.0 | SHA | Built date"
- TOC sidebar removed from causes_of_death page

### Failed Approaches
- **Quarto `{=html}` blocks strip `<script>` tags** (Quarto 1.8.26). Tried: multiple `{=html}` blocks, `include-after-body`, `resources` + `<script src>`, extra.js dynamic loader. All failed. Workaround: Python post-processing injects JS+JSON directly into the pkgdown-built HTML before committing to docs/.
- **extra.js dynamic script loader** failed due to timing (IIFE ran before DOM ready → #cod-app not found) then caused double-load when combined with include-after-body. Removed in favour of inline injection.
- **`function renderTable(data, label)`** — parameter `label` shadowed the global `label()` display-name function. Chart worked but table crashed. Fix: renamed to `groupLabel`.
- **Full `build_site()`** crashed on Closeread article (quarto render error). Individual `build_article()` calls work for all except chronic_vs_acute (pkgdown skips it).

### Accuracy / Metrics
- CI: passing (0 HTML content errors in checked articles)
- Version: 0.2.0
- New vignette: causes_of_death (pure JS, 80KB deployed)

### Known Limitations
- chronic_vs_acute still has 4 "not found in targets" in deployed HTML (Closeread, pkgdown can't rebuild — quarto direct render is clean)
- docs_qa_precommit.sh hook has a bug (exits non-zero even with 0 errors) — requires python workaround to stage docs/ files
- OWID catalog URLs defunct (#94 blocks #90-92)
- Ireland missing from death shares data
- No temporal data (#92), no injury data (#91)

## 2026-04-24

### Completed

**Issues created: 5** (#90, #91, #92, #93, #94)

#### OWID/GBD gap analysis
- Compared OWID "What do people die from in different countries?" against micromort package coverage
- Found strong overlap (same IHME/GBD source, same disease categories, ~54 countries)
- Identified 4 gaps: GBD version (2019→2023), injuries as population cause, temporal trends, proportional death-share visualization

#### Data source investigation
- Discovered OWID catalog URLs now return 404 (all dates from 2024-05-20 through 2026-02-11)
- OWID restricted GBD redistribution due to IHME licensing changes
- Existing bundled CSVs still work (local snapshots) but download scripts cannot refresh
- Mapped new data access path: IHME GBD Results Tool (free account, 100k row limit)
- Identified additional OWID datasets: risk-attributable deaths, cancer-specific, HALE, DALYs

#### Issues raised
- #90: Update OWID data to GBD 2023
- #91: Add injuries as population-level cause of death
- #92: Add temporal trends (1990-2023)
- #93: Proportional death-share treemap vignette
- #94: OWID catalog URLs return 404 — migrate to IHME direct download (blocks #90-92)

### Failed Approaches
- Tried probing 15 OWID catalog date variants (2024-05-20 through 2026-02-11) — all return 404. The entire catalog.ourworldindata.org/garden/ihme_gbd/ path is defunct.
- OWID grapher CSV download pattern also returns 404 for GBD charts specifically (licensing restriction, not general breakage)

### Known Limitations
- #94 blocks #90, #91, #92 — all need manual IHME account creation + download
- Existing bundled data frozen at GBD 2019 (via 2024-05-20 OWID snapshot)
- Pending from prior sessions: glossary/reference page fixes, text selectability, "click to expand" broken, article rebuilds for acronym link fixes

## 2026-04-21

### Completed

**Issues closed: 3** (#30, #63, #82)
**Issues created: 4** (#84, #85, #86, #87)

#### Portfolio Risk Builder (#30, #63 merged)
- New Shinylive vignette: `portfolio_shinylive.qmd` — users select acute activities (with frequency) and chronic factors to build cumulative annual risk portfolio
- Exact survival multiplication: `1 - prod(1 - p_i)` with additive approximation error displayed
- Synergy detection for alcohol+smoking (SI 3.78) and alcohol+obesity (SI 1.55)
- Gompertz baseline comparison by age and sex
- Cleveland dot chart (pure HTML/CSS, no plotly)
- 105 acute activities + 40 chronic factors from `atomic_risks()` and `chronic_risks()`
- CSV generation: `data-raw/generate_portfolio_csv.R`

#### Risk Perception (#82)
- Added Ropeik framework sections (The Perception Gap, Calibrating Intuition) to introduction vignette
- 5th "Risk Perception" dashboard tab in extra.js
- Cites Ropeik 2002/2010, Slovic 2000, Fischhoff 1978

#### Vignette quality
- Added captions to 13 uncaptioned plots and tables (confounding: 5, chronic_vs_acute: 4, what-is-a-micromort: 3, introduction: 1)
- Merged telemetry.qmd into architecture.qmd (-109 lines, -1 vignette)
- Trimmed introduction §8 to 4-line pointer to data_reliability (-51 lines)
- Trimmed data_reliability §3 to 10-line pointer to confounding (-30 lines)
- Built 6 missing reference pages (chronic_disease_risks, infectious_disease_risks, toxicological_risk, combined_quiz_pairs, export_combined_quiz_csv, risk_sensitivity)

#### Infrastructure
- Added `shinylive` to DESCRIPTION Suggests + regenerated `default.nix`
- Added `units` to `default.nix` (was in DESCRIPTION but missing from nix)
- Fixed CI: built missing `quiz_analytics.html`

### Known Issues (raised)
- #84: chronic_vs_acute rendering — heading/content mismatch, vertical gaps, raw `#>` output, font size mismatch
- #85: global rule needed for acronym expansion (CVD, LRI, etc.) with hover tooltip + external link
- #86: raw R console output (`#>`) leaking into all 10 narrative vignettes (42-65 occurrences each)
- #87: font sizing inconsistency between Closeread narrative text and embedded tables

### Lessons Learned
- **Closeread CSS specificity**: pkgdown Bootstrap 5 + Closeread CSS + extra.css creates 3-layer specificity. Must test in deployed context, not local render. Previous font-size fixes failed because local render doesn't load pkgdown's Bootstrap.
- **`show_target()` caption parameter**: can pass `caption = "..."` to add DT captions at render time without modifying targets. Compliant with "targets return data.frame, not DT" rule.
- **`shinylive` R package**: required in nix shell for quarto to render Shinylive vignettes. The quarto extension alone is insufficient — the R package bridges quarto filter → R session.
- **`knitr::opts_chunk$set(comment = "#>")` in setup chunks**: causes ALL R output to get `#>` prefix, including `show_target()` output that should render as DT. Likely root cause of #86.

## 2026-04-20

### Completed

**Issues closed: 13** (#47, #58, #59, #61, #64, #71, #72, #75, #78, #79, #81, #83)
**Issues created: 2** (#82, #83)

#### New exported functions (7)
- `risk_sensitivity(activity, pct)` — ranking stability under estimate variation (#72)
- `chronic_disease_risks(country, year)` — daily micromorts from 7 chronic diseases, 25 countries (#75)
- `infectious_disease_risks(country, year)` — daily micromorts from 7 infectious diseases, 26 countries (#75)
- `toxicological_risk(substance, dose_mg, body_weight_kg)` — micromorts from LD50 data, 16 substances (#83)
- `combined_quiz_pairs(n, time_period_days)` — cross-domain acute vs chronic quiz pairs (#61)
- `export_combined_quiz_csv()` — bundled CSV generation for Shinylive (#61)
- `daily_hazard_rate()` — now returns micromorts_lower/upper credible bounds (#71)

#### Units package foundation (#64)
- Custom "micromort" and "microlife" units registered in .onLoad
- `as_micromort(prob, use_units=TRUE)` / `as_microlife(mins, use_units=TRUE)`
- Backwards-compatible (default `use_units=FALSE`)

#### Introduction vignette dashboard
- Client-side JS converts 10 H2 sections into 4-page dashboard (Risk Units, Valuation & Metrics, Applied Risks, Notes)
- Plain `<button>` elements with inline CSS (no Bootstrap tab dependency)
- TOC hidden, main content expanded to full width

#### DT dark mode fix (root cause: CDN CSS)
- DataTables CDN CSS loaded AFTER extra.css, overriding dark theme
- Fix: removed CDN CSS from _pkgdown.yml, kept JS only
- Updated global rules to prevent recurrence

#### Vignette content
- LLE section expanded with worked examples and age sensitivity table
- External links for QALY (NICE), DALY (WHO), disability weights
- Portfolio sub-targets exported as separate RDS files
- show_target() fig-cap removed from htmlwidget chunks

#### Quiz features
- localStorage streak tracking with 24h window (#79)
- Star rating (1-5) + sanitized text feedback (#47)
- Enriched metadata: timer, difficulty, skipped, language, device, referrer (#58)
- Per-question localStorage stats with djb2 hash keys (#78)
- Quiz analytics dashboard (pure HTML/JS, no Shinylive) (#59)
- Score history recording in all 3 quiz vignettes

#### QA/validation rules
- Post-build gate expanded: now checks "not available", "not found in targets", "Error in", "#> NULL"
- Global rule updated: CDN CSS forbidden for DT (JS only)

### Failed Approaches
- Bootstrap `data-bs-toggle` tabs: BS5 JS intercepted clicks on dynamically created nav elements, causing anchor navigation instead of tab switching. Fixed by switching to plain `<button>` elements with custom click handlers.
- Bootstrap `.tab-pane` CSS: `display:none` hid content even with `show active` classes. Fixed by using inline `style.display` toggling.
- Moving sections into tab panes via `appendChild`: sections rendered above nav because `parentContainer` reference became stale after DOM moves. Fixed by capturing parent before moves.

### Accuracy / Metrics
- Tests: 914 passing, 0 failures
- New tests this session: ~112
- New exported functions: 7
- New bundled datasets: 4 CSVs (chronic diseases, infectious diseases, LD50, combined quiz pairs)

### Known Limitations
- Introduction page build-info shows stale date (2026-04-18) — vig_build_info target needs rebuild
- `noUiSlider` JS error in DT filter widgets (cosmetic, doesn't affect functionality)
- Google Form fields for enriched quiz metadata not yet created (TODO comments in code)
- Per-question stats are localStorage-only (not shared across devices)
- Quiz analytics page needs pkgdown site rebuild to deploy
