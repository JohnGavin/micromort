# Current Work

## Session: 2026-04-25 to 2026-05-03

### Branch: main

### Completed
- Causes of Death vignette: pure JS, 4 tabs, 26 countries, sortable tables, All Countries tab
- Version bump to 0.2.0
- CI QA: 29 errors → 0 (target name fixes + RDS exports + tightened patterns)
- Full site rebuild with updated navbars
- Issues: #93 closed, #95 closed, #96 created (bump plot), #97 created (QR sizing)

### Pending
- Glossary on reference page: acronym coverage, hover popups
- Text selectability: `user-select: none` in tables
- "Click to expand" broken on reference page
- #84 CSS browser verification
- #89 CI template for all pkgdown projects
- #96 Bump plot (cross-country or temporal)
- #97 QR code smaller, URL text larger on quiz results
- chronic_vs_acute: commit quarto-rendered HTML to fix 4 remaining errors

### Blocked
- #90, #91, #92 blocked by #94 (IHME account needed)

### Known Limitations
- docs_qa_precommit.sh hook buggy — use python subprocess for git add docs/
- Quarto 1.8.26 strips <script> from {=html} blocks — requires Python post-injection
- chronic_vs_acute (Closeread) can't be rebuilt by pkgdown
