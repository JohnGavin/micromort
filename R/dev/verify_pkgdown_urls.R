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
  # Key pages to verify — must match _pkgdown.yml navbar + reference sections
  pages <- c(
    # Home
    "/",
    "/index.html",

    # Articles (all 8 from _pkgdown.yml navbar)
    "/articles/architecture.html",
    "/articles/introduction.html",
    "/articles/palatable_units.html",
    "/articles/regional_variation.html",
    "/articles/risk_equivalence.html",
    "/articles/confounding.html",
    "/articles/rest_api.html",
    "/articles/quiz_shinylive.html",

    # Reference index
    "/reference/index.html",

    # Datasets
    "/reference/acute_risks.html",
    "/reference/chronic_risks.html",
    "/reference/risk_sources.html",

    # Data Loaders
    "/reference/load_acute_risks.html",
    "/reference/load_chronic_risks.html",
    "/reference/load_sources.html",

    # Atomic Risk Schema
    "/reference/atomic_risks.html",
    "/reference/risk_components.html",
    "/reference/risk_for_duration.html",
    "/reference/common_risks.html",

    # Risk Equivalence
    "/reference/risk_equivalence.html",
    "/reference/risk_exchange_matrix.html",

    # Radiation Profiles
    "/reference/radiation_profiles.html",
    "/reference/patient_radiation_comparison.html",

    # Legacy Data Functions
    "/reference/demographic_factors.html",
    "/reference/covid_vaccine_rr.html",
    "/reference/risk_data_sources.html",

    # Regional Life Expectancy
    "/reference/regional_life_expectancy.html",
    "/reference/vanguard_regions.html",
    "/reference/laggard_regions.html",
    "/reference/regional_mortality_multiplier.html",

    # Conditional Risk Analysis
    "/reference/cancer_risks.html",
    "/reference/vaccination_risks.html",
    "/reference/conditional_risk.html",
    "/reference/hedged_portfolio.html",

    # Conversion Functions
    "/reference/as_micromort.html",
    "/reference/as_microlife.html",
    "/reference/as_probability.html",
    "/reference/lle.html",
    "/reference/value_of_micromort.html",

    # Analysis Functions
    "/reference/compare_interventions.html",
    "/reference/lifestyle_tradeoff.html",
    "/reference/daily_hazard_rate.html",
    "/reference/annual_risk_budget.html",

    # Visualization
    "/reference/prepare_risks_plot.html",
    "/reference/plot_risks.html",
    "/reference/plot_risks_interactive.html",
    "/reference/plot_risk_components.html",
    "/reference/theme_micromort_dark.html",

    # Interactive Tools
    "/reference/launch_api.html",
    "/reference/launch_dashboard.html",
    "/reference/launch_quiz.html",
    "/reference/quiz_pairs.html",
    "/reference/activity_descriptions.html"
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
