# Current Work

## Session: 2026-05-03 to 2026-05-06

### Branch: main

### Completed
- Rankings bump chart tab (#96 closed)
- Merged comparison table in Table tab
- Air pollution PM2.5 dose-response ladder (4 levels, WHO meta-analysis)
- Issues created: #98 (offset calculator), #99 (evidence review)

### Pending (prioritised)
- #99: Evidence review — 12 missing chronic risk factors:
  - High: GLP-1 drugs, vaping vs smoking, sleep dose-response
  - Medium: social connection, DASH diet, MIND diet, nuts, coffee
  - Low: aspirin, sauna, dancing, HRT
- #98: Offset calculator (depends on #99 data)
- #97: QR code smaller, URL text larger on quiz results
- Glossary on reference page: acronym coverage, hover popups
- Text selectability: `user-select: none` in tables
- #84 CSS browser verification
- #89 CI template for all pkgdown projects

### Blocked
- #90, #91, #92 blocked by #94 (IHME account needed)

### Known Limitations
- docs_qa_precommit.sh hook buggy — use python subprocess for git add docs/
- Quarto 1.8.26 strips <script> from {=html} blocks — requires Python post-injection
- chronic_vs_acute (Closeread) can't be rebuilt by pkgdown
