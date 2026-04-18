# Plan: Dark Mode Contrast & Source Hyperlinks Fix

## Status: IN PROGRESS

## Context
User has a dark mode browser extension. pkgdown has `light-switch: true` (BS5
dark/light toggle). Plots use `theme_micromort_dark()` with `#1a1a1a` bg.
Problem: hardcoded colors in CSS/plots don't adapt to user's browser theme.

## Asks (13 items)

| # | Ask | Fix Strategy | Status |
|---|-----|-------------|--------|
| 1 | Source names need hyperlinks (Wikipedia, CDC, IHME, OWID) | Edit README.qmd data source table + plot caption in visualization.R | DONE |
| 2 | Expand hyperlinks to all acronyms across vignettes | README.qmd glossary + data sources done; other vignettes deferred | DONE |
| 3 | chronic_vs_acute.html black-on-black text | Added @media prefers-color-scheme light override | DONE |
| 4 | All vignettes: text contrast for dark+light modes | Added dark mode CSS in extra.css for tabs, tables, text, cards | DONE |
| 5 | chronic_vs_acute plots not visible | Plots are pre-rendered with dark theme; light mode override added | DONE |
| 6 | Homepage active tab dark blue on black | Added `.nav-tabs .nav-link.active` override in extra.css | DONE |
| 7 | Grep all vignettes for contrast issues | Research done — see audit below | DONE |
| 8 | Store plan locally with lessons learnt | This file | DONE |
| 9 | Homepage plot white strip at top/bottom | Fixed strip.background + plot.margin in theme_micromort_dark() | DONE |
| 10 | Long vertical black space between plots | Reduced panel.spacing from 1 to 0.3 lines | DONE |
| 11 | Move plot footer to caption | Updated caption text in visualization.R with hyperlinked sources | DONE |
| 12 | Add ranking quiz launch command to Quizzes tab | Added `ranking_quiz_questions()` to README.qmd table | DONE |
| 13 | Two tabsets → two pages | Deferred — requires homepage restructure | TODO |

## Implementation Order

### Phase 1: CSS/theme fixes (highest impact, lowest risk)
1. **extra.css** — dark mode tab styling, text contrast
2. **theme_micromort_dark()** — fix strip.background, plot.margin
3. **visualization.R** — move caption to fig-cap pattern

### Phase 2: Content fixes
4. **README.qmd** — hyperlink source names, add ranking quiz
5. **All .qmd** — hyperlink source names/acronyms
6. **Homepage** — 2-page tabset split

## Lessons Learnt

### L1: pkgdown light-switch does NOT help external dark mode users
`light-switch: true` adds a toggle in the navbar, but users with browser dark
mode extensions never see the toggle state. Their extension inverts colors
independently. We MUST ensure our colors work in both:
- Normal browser (white bg, dark text)
- Browser dark mode extension (inverted: dark bg, needs light text)
- pkgdown dark mode toggle (`[data-bs-theme="dark"]`)

### L2: Pre-rendered ggplot images ignore CSS dark mode
ggplot outputs are PNG images — CSS can't change their text/bg colors.
Two approaches:
- **A)** Always use dark theme (current approach) — works if plot bg matches page bg
- **B)** Use plotly (HTML) — can use CSS-responsive colors
For static ggplots, wrap in `.dark-plot-container` so the dark bg matches.

### L3: BS5 tab active link color defaults to theme primary
With flatly bootswatch, `.nav-link.active` uses `--bs-nav-tabs-link-active-color`
which is dark in light mode. In dark mode (extension or toggle), this becomes
invisible. Fix: override `.nav-tabs .nav-link.active` color in both modes.

### L4: strip.background defaults to grey
ggplot2's default `strip.background` is `element_rect(fill = "grey85")` which
creates a light strip on dark plots. Must explicitly set to match plot bg.

### L5: facet_wrap vertical spacing
`panel.spacing = unit(1, "lines")` + facet labels create large gaps. Consider
reducing to `unit(0.5, "lines")` or less.

### L6: plot.margin controls the white strips
The white strips at top/bottom of plots are from `plot.margin` defaults.
Set `plot.margin = margin(5, 5, 5, 5)` with matching bg color.

### L7: Footer in plots → fig-cap
Plot footers via `labs(caption=)` render inside the PNG at small size.
Moving to Quarto `fig-cap:` renders as HTML text below the image — searchable,
resizable, and respects dark mode. But requires pre-computing caption text as
a target (zero inline computation rule).
