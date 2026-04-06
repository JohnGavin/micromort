# Current Work

## Session: 2026-04-05 to 2026-04-06

### Branch: main

### Completed

#### Data Quality Fixes
1. **Bicycle commuting**: 0.50 → 0.12 mm per 30-min trip (Cycling UK 2024: 9-11M trips per fatality, cross-checked with DfT/NTS)
2. **Wine (glass)**: Relabelled from acute "per event" to "per day (chronic)" — Wikipedia's 0.5 mm figure mixes chronic cancer/liver effects with acute risk. Confidence downgraded to low.

### Failed Approaches
- Searched for DfT RAS30 tables directly — data is in downloadable ODS files not web pages. Used Cycling UK summary statistics instead.

### Accuracy / Metrics
- Tests: 615 passing
- Bicycle micromort corrected from 5x overestimate to evidence-based range (0.09-0.14 mm)

### Known Limitations
- Closeread scroll effects still not activating (CSS loads but layout doesn't trigger)
- Wine entry remains in acute dataset with chronic label — could be moved to chronic_risks() entirely
- Substack article (rootofall) not relevant to project (motivational, not quantitative)

### Pipeline: 116 targets, 615 tests

### Next Session
- Review other "per event" entries for similar chronic/acute conflation
- Consider full audit of Wikipedia-sourced micromort values against primary sources
- Closeread scroll debugging
