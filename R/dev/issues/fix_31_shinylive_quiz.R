# Fix script for issue #31: Shinylive/WebR quiz vignette
# https://github.com/JohnGavin/micromort/issues/31
#
# Problem:
#   launch_quiz() is a Shiny app that only runs locally.
#   Users visiting the pkgdown site cannot play the quiz.
#
# Solution:
#   Create a Shinylive vignette (quiz_shinylive.qmd) that runs
#   the quiz directly in the browser using WebR + Shinylive.
#   Uses the existing micromort WASM binary from R-Universe.
#   Quiz UI/server code is inlined (internal helpers not exported).
#   quiz_pairs() (exported) provides the data generation.
#
# Files changed:
#   - vignettes/quiz_shinylive.qmd (NEW)
#   - _pkgdown.yml (add navbar link)
#   - R/dev/issues/fix_31_shinylive_quiz.R (this file)
#
# Build & deploy:
#   quarto add quarto-ext/shinylive
#   quarto render vignettes/quiz_shinylive.qmd --output-dir docs/articles/
#   # Then commit docs/articles/quiz_shinylive.html + supporting files
#
# Verification:
#   1. quarto render vignettes/quiz_shinylive.qmd -- no errors
#   2. Open in browser, wait 60s for WASM load
#   3. F12 console: no package-not-found errors
#   4. Play quiz: instructions -> questions (back/skip) -> results
#   5. After deploy: URL returns 200
