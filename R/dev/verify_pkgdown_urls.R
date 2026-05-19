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
library(yaml)

# ---------------------------------------------------------------------------
# Internal helper: read article slugs from _pkgdown.yml dynamically.
# Walks both `articles.contents` and navbar `href:` entries so that articles
# listed in the navbar but not in the articles section (or vice-versa) are
# all captured.
# ---------------------------------------------------------------------------
.pkgdown_article_slugs <- function(pkgdown_yml = "_pkgdown.yml") {
  if (!file.exists(pkgdown_yml)) {
    cli::cli_abort(c(
      "x" = "{.file {pkgdown_yml}} not found.",
      "i" = "Run from the package root or pass the correct path."
    ))
  }
  yml <- yaml::read_yaml(pkgdown_yml)

  slugs <- character(0)

  # Walk articles.contents (handles both plain strings and list items)
  for (section in yml$articles) {
    for (item in section$contents) {
      slug <- as.character(item)
      if (nzchar(slug)) slugs <- c(slugs, slug)
    }
  }

  # Also capture href: entries from the navbar (catches articles that appear
  # in the navbar but not in the articles: section, and vice-versa)
  navbar_text  <- readLines(pkgdown_yml, warn = FALSE)
  href_matches <- regmatches(
    navbar_text,
    regexpr("articles/[A-Za-z0-9_-]+\\.html", navbar_text)
  )
  href_slugs <- sub("\\.html$", "", sub("^articles/", "", href_matches))
  href_slugs <- href_slugs[nzchar(href_slugs)]

  unique(c(slugs, href_slugs))
}

verify_pkgdown_urls <- function(
    base_url = "https://johngavin.github.io/micromort",
    pkgdown_yml = "_pkgdown.yml",
    timeout = 10,
    verbose = TRUE
) {
  # Derive article paths dynamically from _pkgdown.yml so this list never
  # drifts out of sync when articles are added or removed.
  article_slugs <- .pkgdown_article_slugs(pkgdown_yml)
  article_pages <- paste0("/articles/", article_slugs, ".html")

  # Fixed pages: home + reference index (stable, not sourced from yml articles)
  home_pages <- c("/", "/index.html", "/reference/index.html")

  pages <- c(home_pages, article_pages)

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
