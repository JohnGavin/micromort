# Changelog

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
