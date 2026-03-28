# Current Work

## Session: 2026-03-24 to 2026-03-28

### Branch: main

### Completed

#### Ranking Quiz (Issue #65)
1. R backend: `ranking_quiz_questions()`, `kendall_tau_score()`, `ranking_tag_mapping()` — 67 tests
2. Shinylive version with SortableJS drag-and-drop
3. Tie prevention: min 1.1x LLE ratio between adjacent items
4. Tag selection: 8 tags, Select All/Deselect All, validation
5. Direction labels: green "gain" / red "lose" badges + arrows on reveal
6. Bootstrap tooltips for LLE, Kendall tau link to Wikipedia
7. Tap-to-show LLE help for mobile (hover doesn't work on touch)

#### Pure JS Quiz Migration (98% size reduction)
8. Ported all 3 quizzes from Shinylive (61MB each) to pure JS (<1MB each)
   - `micromort-quiz.qmd` — acute pairwise A-vs-B
   - `microlife-quiz.qmd` — chronic pairwise A-vs-B
   - `risk-ranking-quiz.qmd` — cross-domain drag-and-drop ranking
9. Same features: leaderboard, percentile, share, cross-round dedup, QR codes

#### UX Improvements (all quizzes)
10. Default 5 questions (was 10)
11. Human-readable numbers: `fmtMM()` — 2,840 not 2840.00
12. Side-by-side layout with flexbox, 800px max-width centered
13. Mobile-responsive CSS (stack vertically below 600px)
14. QR codes on instructions + results pages
15. WCAG contrast audit: fixed 3 failing combinations (medium badge, period badge, selected button)
16. Flatly theme workaround: fully inline styles bypass theme `!important` overrides

#### Data Quality
17. Activity unit standardisation: Rock climbing (per day), Base jumping (per jump), etc.
18. Construction (all trades, per work day) clarified
19. Charbroiled steaks (cumulative benzopyrene) clarified
20. Cross-round dedup: no repeat questions across Try Again rounds

#### Config & Infrastructure
21. Shiny module data-sharing rule + skill added to global config
22. WCAG contrast audit methodology documented
23. Plus Maths references added to introduction + data_reliability vignettes
24. Vignette chunks migrated to targets: 76% → 93% coverage

### Pipeline
- 116 targets, 615 tests, all pass

### Quiz URLs (pure JS — instant load)
- https://johngavin.github.io/micromort/articles/micromort-quiz.html
- https://johngavin.github.io/micromort/articles/microlife-quiz.html
- https://johngavin.github.io/micromort/articles/risk-ranking-quiz.html

### Next Session
- Shinylive versions can be removed once pure JS versions are stable
- Monitor leaderboard (quiz_type: acute/chronic/ranking)
- Weekly email runs Mondays 06:00 UTC
