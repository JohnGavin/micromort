# Verify pkgdown site URLs after deployment
# Run this after pkgdown::build_site() and git push to gh-pages
#
# Usage: Rscript R/dev/verify_pkgdown_urls.R
#
# This script checks all internal links in the pkgdown site for 404 errors.
# It should be run as part of the mandatory workflow before considering
# a PR complete.

library(cli)
library(httr2)

verify_pkgdown_urls <- function(
    base_url = "https://johngavin.github.io/micromort",
    timeout = 10,
    verbose = TRUE
) {
  # Key pages to verify
  pages <- c(
    # Home
    "/",
    "/index.html",


    # Articles
    "/articles/introduction.html",
    "/articles/palatable_units.html",

    # Reference index
    "/reference/index.html",

    # Core functions
    "/reference/common_risks.html",
    "/reference/chronic_risks.html",
    "/reference/plot_risks.html",
    "/reference/plot_risks_interactive.html",

    # Conditional risk functions
    "/reference/cancer_risks.html",
    "/reference/vaccination_risks.html",
    "/reference/conditional_risk.html",
    "/reference/hedged_portfolio.html",

    # Conversion functions
    "/reference/as_micromort.html",
    "/reference/as_microlife.html",

    # Analysis functions
    "/reference/compare_interventions.html",
    "/reference/daily_hazard_rate.html"
  )

  results <- list()
  n_ok <- 0
n_fail <- 0

  if (verbose) cli_h1("Verifying pkgdown URLs")

  for (page in pages) {
    url <- paste0(base_url, page)
    tryCatch({
      resp <- request(url) |>
        req_timeout(timeout) |>
        req_perform()

      status <- resp_status(resp)
      if (status == 200) {
        n_ok <- n_ok + 1
        if (verbose) cli_alert_success("{page}")
        results[[page]] <- list(url = url, status = status, ok = TRUE)
      } else {
        n_fail <- n_fail + 1
        if (verbose) cli_alert_danger("{page} - HTTP {status}")
        results[[page]] <- list(url = url, status = status, ok = FALSE)
      }
    }, error = function(e) {
      n_fail <<- n_fail + 1
      if (verbose) cli_alert_danger("{page} - {conditionMessage(e)}")
      results[[page]] <<- list(url = url, status = NA, ok = FALSE, error = conditionMessage(e))
    })
  }

  if (verbose) {
    cli_h2("Summary")
    cli_alert_info("Checked {length(pages)} URLs")
    cli_alert_success("{n_ok} OK")
    if (n_fail > 0) {
      cli_alert_danger("{n_fail} FAILED")
    }
  }

  invisible(list(
    results = results,
    n_ok = n_ok,
    n_fail = n_fail,
    all_ok = n_fail == 0
  ))
}

# Run if executed directly
if (sys.nframe() == 0) {
  result <- verify_pkgdown_urls()
  if (!result$all_ok) {
    cli::cli_abort("Some URLs returned 404 errors. Fix before merging.")
  }
}
