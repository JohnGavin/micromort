# Fix script for Issue #22: Atomic Risk Schema + Risk Equivalence Dashboard
# PR #23: feature/atomic-risk-schema
# Date: 2026-03-06
#
# Summary:
# - Phase 1: Created atomic_risks() with 92 rows (19 columns), each row = ONE
#   risk component of ONE activity. Refactored common_risks() to aggregate from
#   atomic_risks() with full backward compatibility.
# - Phase 2: Decomposed flights (16 rows: crash/DVT/radiation x 4 durations x
#   health profiles). Added 8 medical radiation + 7 mundane everyday activities.
#   New functions: risk_equivalence(), risk_exchange_matrix(), risk_components(),
#   risk_for_duration(), plot_risk_components().
# - Phase 3: Risk Equivalence Dashboard vignette with 7 tabset sections, 10
#   pre-computed targets, zero-computation compliance.
#
# Adversarial QA fixes (75 -> ~92/100):
# - FAIL-1: risk_for_duration() rewritten to accept activity_prefix
# - FAIL-2: Added flying_2h dvt_risk_factors row (0.0 mm)
# - FAIL-3: format(scientific=FALSE) in equivalence strings
# - FAIL-4: .row_order assigned after filter_to_duration()
# - WARN-2: category=="Medical" filter in vig_equiv_medical_focus target
# - Added zero-micromort guard in risk_exchange_matrix()
#
# Files changed:
# - R/atomic_risks.R (CREATE)
# - R/risk_equivalence.R (CREATE)
# - R/risks.R (MODIFY - common_risks aggregates from atomic_risks)
# - R/visualization.R (APPEND - plot_risk_components)
# - R/tar_plans/plan_vignette_outputs.R (APPEND - 10 vig_equiv_* targets)
# - vignettes/risk_equivalence.Rmd (CREATE)
# - _pkgdown.yml (MODIFY)
# - tests/testthat/test-atomic-risks.R (CREATE)
# - tests/testthat/test-risk-components.R (CREATE)
# - tests/testthat/test-risk-equivalence.R (CREATE)
#
# Verification:
# 154 tests pass, R CMD check 0 errors

# Quick smoke test
if (FALSE) {
  library(micromort)

  # Phase 1: atomic schema
  ar <- atomic_risks()
  stopifnot(nrow(ar) == 92, ncol(ar) == 19)

  # Phase 1: backward compat
  cr <- common_risks()
  stopifnot(nrow(cr) == 80)
  stopifnot(cr$micromorts[cr$activity == "Mt. Everest ascent"] == 37932)

  # Phase 2: flight decomposition
  rc <- risk_components("flying_8h")
  stopifnot(nrow(rc) == 3, sum(rc$micromorts) == 4.9)

  # Phase 2: risk equivalence
  re <- risk_equivalence("Chest X-ray (radiation per scan)")
  stopifnot(re$ratio[re$activity == "Skydiving (US)"] == 80)

  # Phase 2: duration lookup

  rd <- risk_for_duration("flying", duration_hours = 7)
  stopifnot(rd$duration_hours == 8)

  # Exchange matrix
  m <- risk_exchange_matrix()
  stopifnot(nrow(m) == 10, ncol(m) == 11)
}
