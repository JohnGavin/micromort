# Current Work

## Session: 2026-04-24

### Branch: main

### Completed
- OWID/GBD gap analysis vs micromort package
- Discovered OWID catalog URLs all return 404 (licensing change)
- Created 5 issues: #90 (GBD update), #91 (injuries), #92 (trends), #93 (treemap), #94 (OWID→IHME migration)
- Updated CHANGELOG.md

### Pending (from prior sessions)
- Glossary on reference page: check acronym coverage, add hover popups
- Text selectability: `user-select: none` preventing copy/paste in tables
- "Click to expand" broken on reference page
- Rebuild confounding, data_reliability, introduction articles (acronym link fixes)
- #84 CSS changes need visual browser verification
- #89 CI template for all pkgdown projects

### Blocked
- #90, #91, #92 all blocked by #94 (need IHME account + manual download)
- #93 (treemap vignette) can start with existing data

### Known Limitations
- Bundled disease data frozen at GBD 2019
- OWID catalog defunct — `data-raw/owid_chronic_deaths.R` download script non-functional
