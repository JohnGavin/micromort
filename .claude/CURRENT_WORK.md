# Current Work

## Session: 2026-03-29 to 2026-04-03

### Branch: main

### Completed

#### Closeread "What is a Micromort?" vignette
1. Closeread Quarto extension installed (scroll-triggered sticky panels)
2. 5-act narrative: Morning risks → Full spectrum → Chronic risks → Bridge → Quizzes
3. All plots converted to interactive plotly (dark theme, hover tooltips)
4. Workaround: post-process HTML to inject closeread JS (Quarto 1.8.26 bug)
5. Renamed scrollytelling.qmd → what-is-a-micromort.qmd (SEO-friendly URL)

#### Navbar regrouped into 4 sections
- Start here: What is a Micromort?
- Quizzes: ☠️ Micromort, ⏳ Microlife, 📊 Rank Risks
- Reference: 7 analysis articles
- Developer: Architecture + Telemetry

#### Content fixes (scrollytelling)
6. Axis labels with units: Micromorts (mm), Microlives per day (ml/day)
7. Wine 50x ratio explained: both below 1mm, absolute difference negligible
8. Everest rounded: 37,932 → ~38,000 mm
9. Spectrum plot: all text-referenced items included, plotly hover
10. Smoking arithmetic: 10 × 30 = 300 min = 5 hrs
11. Diet vs exercise verified: both from Spiegelhalter BMJ 2012
12. Bridge table: abbreviations (mm, ml/day) to avoid confusion with millilitres

#### Quiz UX fixes
13. Submit button moved next to Next in ranking quiz nav bar
14. Yellow buttons → burnt orange (#b85c0a) for WCAG contrast
15. Removed middot separator from question count
16. 📊 emoji for ranking quiz share text

### Pipeline: 116 targets, 615 tests

### URLs
- https://johngavin.github.io/micromort/articles/what-is-a-micromort.html
- https://johngavin.github.io/micromort/articles/micromort-quiz.html
- https://johngavin.github.io/micromort/articles/microlife-quiz.html
- https://johngavin.github.io/micromort/articles/risk-ranking-quiz.html

### Next Session
- Closeread scroll effects not working (CSS loads but scroll-trigger layout not activating)
- Consider adding ggiraph to nix env for interactive SVG plots
- Weekly leaderboard email running (Mondays 06:00 UTC)
