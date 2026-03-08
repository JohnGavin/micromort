# Fix script for issue #31: Shinylive/WebR quiz vignette UX overhaul
# https://github.com/JohnGavin/micromort/issues/31
#
# Problem:
#   1. ALL 50 quiz pairs had ratio=1.0 (identical micromorts, unanswerable)
#   2. Vague medical radiation labels (e.g. "Chest X-ray (radiation)")
#   3. Redundant intro/outro text, callout note, "How it works" section
#   4. Cramped two-row layout (cards + separate buttons)
#   5. Static results messaging (only 4 phrases)
#
# Solution:
#   A. quiz_pairs(): Add min_ratio param (default 1.1), add period_a/period_b
#   B. atomic_risks.R: "(radiation)" -> "(radiation per scan)" for 8 medical
#   C. Vignette: strip text, add quiz section to README.qmd
#   D. Merged single-row button layout with period badges, 180px min-height
#   E. viewerHeight 700 -> 800
#   F. 8 fun result phrases with Wikipedia links
#   G. Regenerate CSV with min_ratio=1.1, clarified labels, period columns
#
# Files changed:
#   - R/quiz.R (min_ratio param, period columns, quiz_result_phrase helper)
#   - R/atomic_risks.R ("radiation per scan" labels)
#   - vignettes/quiz_shinylive.qmd (stripped text, new layout, CSV, phrases)
#   - README.qmd (Risk Quiz section)
#   - R/dev/issues/fix_31_shinylive_quiz.R (this file)
#
# Build & deploy:
#   quarto render vignettes/quiz_shinylive.qmd
#   cp vignettes/quiz_shinylive.html docs/articles/
#   cp -r vignettes/quiz_shinylive_files docs/articles/
#   cp vignettes/shinylive-sw.js docs/articles/
#
# Verification:
#   1. pkgload::load_all() -- no errors
#   2. quiz_pairs(seed=42, min_ratio=1.1) -- all ratios > 1.0, period cols
#   3. quarto render vignettes/quiz_shinylive.qmd -- clean
#   4. Browser test: merged buttons, period badges, fun phrases, fixed height
#   5. devtools::test() -- all pass
