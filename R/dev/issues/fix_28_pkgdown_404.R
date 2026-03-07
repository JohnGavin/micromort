# Fix #28: Add micromort to johngavin.github.io + fix pkgdown 404
#
# Problem:
#   - risk_equivalence.html was listed in _pkgdown.yml navbar but never built
#   - docs/articles/ was missing risk_equivalence.html -> 404 on live site
#   - No CI validation caught the mismatch between _pkgdown.yml and docs/
#   - micromort not listed on personal site johngavin.github.io
#
# Root cause:
#   pkgdown::build_site() was not re-run after adding the vignette.
#   The pkgdown.yaml CI workflow only checked docs/index.html existed,
#   not individual articles. R-CMD-check had no URL validation.
#
# Fix:
#   1. Rebuilt full pkgdown site: pkgdown::build_site(devel = FALSE)
#   2. Added pre-deploy navbar article check to pkgdown.yaml
#   3. Added post-deploy curl -I URL verification to pkgdown.yaml
#   4. Added urlchecker::url_check() step to R-CMD-check.yml
#   5. Added navbar-vs-docs consistency check to R-CMD-check.yml
#   6. Added urlchecker to DESCRIPTION Suggests
#   7. Added micromort to johngavin.github.io index.md
#
# Verification:
#   curl -s -o /dev/null -w "%{http_code}" \
#     "https://johngavin.github.io/micromort/articles/risk_equivalence.html"
#   # Should return 200
#
# Files changed:
#   - .github/workflows/pkgdown.yaml (2 new steps)
#   - .github/workflows/R-CMD-check.yml (2 new steps)
#   - DESCRIPTION (urlchecker in Suggests)
#   - docs/ (full site rebuild)
