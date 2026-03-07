# Fix script for Issue #25: Lifetime Radiation Exposure Profiles
# Also subsumes Issue #24 (patient vs occupational X-ray comparison)
#
# Changes:
# 1. Added 11 annual radiation rows to atomic_risks() (Part 5):
#    - 5 occupational: airline pilot, X-ray tech, dental radiographer,
#      nuclear worker, interventional cardiologist
#    - 3 passenger: executive flyer, business traveller, tourist
#    - 3 environmental: granite resident, high-altitude, background
# 2. Added msv_to_micromorts() internal helper (LNT: 0.05 mm/mSv)
# 3. Created R/radiation_profiles.R with:
#    - radiation_profiles(): annual + cumulative milestone comparison
#    - patient_radiation_comparison(): cross-tab of patient X-rays vs careers
# 4. Added 5 vig_radiation_* targets for vignette
# 5. Added "Radiation Exposure Profiles" section to risk_equivalence.Rmd
# 6. Updated _pkgdown.yml with new functions
# 7. Updated tests: row count 92->103, activity_id count 80->91
#
# Key insight: 100 lifetime chest X-rays (10 mm) > 40-year X-ray tech career (2 mm)

# ── Verification ──────────────────────────────────────────────────────────
if (FALSE) {
  library(micromort)

  # Check row counts
  ar <- atomic_risks()
  stopifnot(nrow(ar) == 103)
  stopifnot(length(unique(ar$activity_id)) == 91)

  # Check new annual rows
  annual <- ar[grepl("_annual$", ar$activity_id), ]
  stopifnot(nrow(annual) == 11)
  stopifnot(all(annual$component == "radiation"))
  stopifnot(all(annual$period_type == "year"))

  # Check radiation_profiles()
  rp <- radiation_profiles()
  stopifnot(nrow(rp) == 11)
  stopifnot(all(c("mm_10y", "mm_20y", "mm_40y") %in% names(rp)))

  # Key assertion: 100 X-rays > 40-year X-ray tech career
  prc <- patient_radiation_comparison()
  row <- prc[prc$occupation == "X-ray technician (annual radiation)" &
             prc$xray_count == 100 &
             prc$career_years == 40, ]
  stopifnot(row$patient_micromorts > row$occupational_micromorts)

  message("All verification checks passed!")
}
