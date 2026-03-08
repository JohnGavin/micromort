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
#   Quiz pairs are pre-computed from quiz_pairs(seed=42) and embedded
#   as CSV inline — micromort cannot be loaded in WebR because the
#   arrow package (in Imports) has no WASM binary.
#   Quiz UI/server code is inlined (internal helpers not exported).
#
# Files changed:
#   - vignettes/quiz_shinylive.qmd (NEW)
#   - vignettes/_extensions/quarto-ext/shinylive/ (NEW, Quarto extension)
#   - _pkgdown.yml (add navbar link)
#   - docs/articles/quiz_shinylive.html + _files/ + shinylive-sw.js (rendered)
#   - R/dev/issues/fix_31_shinylive_quiz.R (this file)
#
# Build & deploy:
#   quarto add quarto-ext/shinylive  # install extension (in vignettes/)
#   quarto render vignettes/quiz_shinylive.qmd
#   cp vignettes/quiz_shinylive.html docs/articles/
#   cp -r vignettes/quiz_shinylive_files docs/articles/
#   cp vignettes/shinylive-sw.js docs/articles/
#
# Verification:
#   1. quarto render vignettes/quiz_shinylive.qmd -- no errors
#   2. Open in browser, wait 30-60s for WASM load
#   3. F12 console: no package-not-found errors
#   4. Play quiz: instructions -> questions (back/skip) -> results
#   5. After deploy: URL returns 200
