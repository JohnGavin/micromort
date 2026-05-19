# Tests for vignette output targets in plan_vignette_outputs.R

# ---------------------------------------------------------------------------
# Helper: get git last-commit unix timestamp for a repo-relative path.
# Returns NA_real_ when the path has no git history yet.
# ---------------------------------------------------------------------------
.git_commit_mtime <- function(pkg_root, rel_path) {
  out <- system2(
    "git",
    c("-C", pkg_root, "log", "-1", "--format=%ct", "--", rel_path),
    stdout = TRUE, stderr = FALSE
  )
  if (length(out) == 0L || !nzchar(out)) return(NA_real_)
  ct <- as.numeric(out)
  if (is.na(ct)) return(NA_real_)
  ct
}

# ---------------------------------------------------------------------------
# Helper: "source last touched" timestamp for a repo-relative path.
# Returns the LATER of:
#   (a) the git last-commit timestamp (catches committed-but-not-rebuilt)
#   (b) the filesystem mtime           (catches working-tree edits)
# Both are in seconds since Unix epoch (numeric).
# Returns NA_real_ when neither is available.
# ---------------------------------------------------------------------------
.source_mtime <- function(pkg_root, rel_path) {
  full_path  <- file.path(pkg_root, rel_path)
  git_ct     <- .git_commit_mtime(pkg_root, rel_path)
  fs_ct      <- tryCatch(
    as.numeric(file.mtime(full_path)),
    error = function(e) NA_real_
  )
  if (is.na(git_ct) && is.na(fs_ct)) return(NA_real_)
  max(c(git_ct, fs_ct), na.rm = TRUE)
}

# Keep the old name as an alias so callers that compare OUTPUT html timestamps
# (which live only in git, not in working-tree) still work correctly.
.git_mtime <- .git_commit_mtime

test_that("vig_whatis_mundane_plot and vig_whatis_mundane_table use the same activities", {
  # Read from cached RDS (CI/test friendly — doesn't require tar_make())
  table <- readRDS(testthat::test_path("..", "..", "inst", "extdata", "vignettes",
                                       "vig_whatis_mundane_table.rds"))
  table_activities <- as.character(table$Activity)

  # Plot is a plotly object built with plot_ly() using formula (~activity) aesthetics.
  # The underlying data frame is stored in p$x$visdat as a named closure list;
  # calling the closure returns the data frame used to build the chart.
  plot <- readRDS(testthat::test_path("..", "..", "inst", "extdata", "vignettes",
                                      "vig_whatis_mundane_plot.rds"))
  plot_activities <- as.character(plot$x$visdat[[1]]()$activity)

  expect_setequal(plot_activities, table_activities)
})

test_that("docs/articles/*.html is not stale relative to vignettes/*.qmd", {
  testthat::skip_on_cran()
  testthat::skip_if_not(
    rprojroot::find_root(rprojroot::is_r_package) |>
      file.path(".git") |>
      file.exists(),
    "test only runs inside a git checkout (needs git log timestamps)"
  )

  pkg_root <- rprojroot::find_root(rprojroot::is_r_package)
  vig_dir  <- file.path(pkg_root, "vignettes")
  doc_dir  <- file.path(pkg_root, "docs", "articles")

  qmd_files <- list.files(vig_dir, pattern = "\\.qmd$", full.names = FALSE)
  stale <- character(0)

  for (qmd in qmd_files) {
    base <- sub("\\.qmd$", "", qmd)
    html <- file.path(doc_dir, paste0(base, ".html"))
    if (!file.exists(html)) next  # no deployed counterpart

    # Source: take the LATER of git-commit time and working-tree mtime so
    # that an uncommitted edit to the .qmd is also caught as "stale".
    qmd_time  <- .source_mtime(pkg_root, file.path("vignettes", qmd))
    # Output: only git-commit time matters (deployed HTML has no working-tree edits)
    html_time <- .git_commit_mtime(pkg_root, file.path("docs", "articles", paste0(base, ".html")))

    if (!is.na(qmd_time) && !is.na(html_time) && qmd_time > html_time) {
      stale <- c(stale, base)
    }
  }

  if (length(stale) > 0) {
    cli::cli_warn(c(
      "!" = "{length(stale)} stale rendered article{?s} detected.",
      "i" = "Sources have newer last-commit than their HTML: {.val {stale}}.",
      "i" = "Run pkgdown::build_article() for each, commit, push."
    ))
  }
  expect_length(stale, 0L)
})

# ---------------------------------------------------------------------------
# Top-level pkgdown pages: CHANGELOG, README/index.
#
# pkgdown renders several top-level Markdown files into docs/*.html that are
# NOT covered by the vignettes/*.qmd → docs/articles/*.html check above:
#
#   CHANGELOG.md  → docs/CHANGELOG.html
#   README.qmd    → docs/index.html   (preferred over README.md when both exist)
#   NEWS.md       → docs/news/index.html  (checked if NEWS.md is present)
#
# The slug mapping here is explicit and derived from pkgdown's documented
# behaviour (https://pkgdown.r-lib.org/reference/build_home.html), not from
# walking pkg$meta$articles — pkgdown::as_pkgdown() requires pkgdown to be
# loaded with the full package tree, which adds install-time complexity not
# appropriate for a lightweight test.  The mapping is stable: pkgdown has
# used these output names since v1.0.
# ---------------------------------------------------------------------------
test_that("top-level pkgdown pages are not stale (CHANGELOG, README, NEWS)", {
  testthat::skip_on_cran()
  testthat::skip_if_not(
    rprojroot::find_root(rprojroot::is_r_package) |>
      file.path(".git") |>
      file.exists(),
    "test only runs inside a git checkout (needs git log timestamps)"
  )

  pkg_root <- rprojroot::find_root(rprojroot::is_r_package)

  # Build the explicit (source-rel-path, output-rel-path) mapping.
  # README.qmd takes priority over README.md when both exist.
  readme_src <- if (file.exists(file.path(pkg_root, "README.qmd"))) {
    "README.qmd"
  } else if (file.exists(file.path(pkg_root, "README.md"))) {
    "README.md"
  } else {
    NULL
  }

  top_level_map <- list()
  if (file.exists(file.path(pkg_root, "CHANGELOG.md")))
    top_level_map[["CHANGELOG.md"]] <- file.path("docs", "CHANGELOG.html")
  if (!is.null(readme_src))
    top_level_map[[readme_src]] <- file.path("docs", "index.html")
  if (file.exists(file.path(pkg_root, "NEWS.md")))
    top_level_map[["NEWS.md"]] <- file.path("docs", "news", "index.html")

  if (length(top_level_map) == 0L) {
    skip("No top-level source files to check")
  }

  stale   <- character(0)
  missing <- character(0)

  for (src_rel in names(top_level_map)) {
    out_rel  <- top_level_map[[src_rel]]
    out_full <- file.path(pkg_root, out_rel)

    if (!file.exists(out_full)) {
      missing <- c(missing, out_rel)
      next
    }

    # Source: max(git-commit, fs mtime) so working-tree edits are caught.
    src_ct <- .source_mtime(pkg_root, src_rel)
    # Output: git-commit time only (HTML has no relevant working-tree edits).
    out_ct <- .git_commit_mtime(pkg_root, out_rel)

    if (anyNA(c(src_ct, out_ct))) next  # no git history yet — skip

    if (src_ct > out_ct) {
      stale <- c(
        stale,
        sprintf(
          "%s (src %s > out %s)",
          src_rel,
          format(as.POSIXct(src_ct, origin = "1970-01-01", tz = "UTC"), "%Y-%m-%d %H:%M UTC"),
          format(as.POSIXct(out_ct, origin = "1970-01-01", tz = "UTC"), "%Y-%m-%d %H:%M UTC")
        )
      )
    }
  }

  if (length(missing) > 0L) {
    cli::cli_abort(c(
      "x" = "{length(missing)} top-level pkgdown output{?s} missing from docs/.",
      "i" = "Missing: {.val {missing}}.",
      "i" = "Run `pkgdown::build_site()` to generate them."
    ))
  }

  if (length(stale) > 0L) {
    cli::cli_abort(c(
      "x" = "{length(stale)} top-level pkgdown page{?s} {?is/are} stale.",
      "i" = "Source committed more recently than rendered HTML:",
      " " = "{stale}",
      "i" = "Run `pkgdown::build_home()` (README/index) or",
      " " = "`pkgdown::build_news()` (CHANGELOG/NEWS), commit docs/, push."
    ))
  }

  # Explicit expectation so testthat registers a PASS (not just no error).
  expect_length(stale, 0L)
  expect_length(missing, 0L)
})

# ---------------------------------------------------------------------------
# Targeted regression test: CHANGELOG.md staleness is caught.
# This test verifies the guard is wired up correctly by checking the specific
# pair that was missing before this fix (roborev jobs 3297/3290/3026).
# ---------------------------------------------------------------------------
test_that("CHANGELOG.md git-commit timestamp is older than or equal to docs/CHANGELOG.html", {
  testthat::skip_on_cran()

  pkg_root    <- rprojroot::find_root(rprojroot::is_r_package)
  changelog   <- file.path(pkg_root, "CHANGELOG.md")
  html_out    <- file.path(pkg_root, "docs", "CHANGELOG.html")

  testthat::skip_if_not(file.exists(changelog),  "CHANGELOG.md not present")
  testthat::skip_if_not(
    file.exists(file.path(pkg_root, ".git")),
    "test only runs inside a git checkout"
  )

  # If docs/CHANGELOG.html doesn't exist the top-level test above already
  # catches it with cli_abort(); here we only assert timestamp ordering when
  # the file IS present.
  if (!file.exists(html_out)) {
    cli::cli_abort(c(
      "x" = "docs/CHANGELOG.html does not exist.",
      "i" = "Run `pkgdown::build_site()` then commit and push docs/."
    ))
  }

  # Source: max(git-commit, fs mtime) catches working-tree edits to CHANGELOG.md.
  src_ct <- .source_mtime(pkg_root, "CHANGELOG.md")
  out_ct <- .git_commit_mtime(pkg_root, file.path("docs", "CHANGELOG.html"))

  testthat::skip_if(anyNA(c(src_ct, out_ct)), "No git history for one or both files")

  if (src_ct > out_ct) {
    cli::cli_abort(c(
      "x" = "docs/CHANGELOG.html is stale.",
      "i" = "CHANGELOG.md last committed: {format(as.POSIXct(src_ct, origin='1970-01-01', tz='UTC'), '%Y-%m-%d %H:%M UTC')}",
      "i" = "docs/CHANGELOG.html last committed: {format(as.POSIXct(out_ct, origin='1970-01-01', tz='UTC'), '%Y-%m-%d %H:%M UTC')}",
      "i" = "Run `pkgdown::build_news()`, commit docs/CHANGELOG.html, push."
    ))
  }

  expect_lte(src_ct, out_ct)
})

# ---------------------------------------------------------------------------
# Working-tree edit detection: .source_mtime() picks up fs mtime > git-commit.
#
# This test proves the guard is not git-log-only: when a .qmd is modified on
# disk but not yet committed, .source_mtime() returns the filesystem mtime
# (which is newer than the git commit time), so the staleness check fires.
# ---------------------------------------------------------------------------
test_that(".source_mtime() detects working-tree edits beyond last git commit", {
  testthat::skip_on_cran()
  testthat::skip_if_not(
    rprojroot::find_root(rprojroot::is_r_package) |>
      file.path(".git") |>
      file.exists(),
    "test only runs inside a git checkout"
  )

  pkg_root <- rprojroot::find_root(rprojroot::is_r_package)

  # Pick the first .qmd that has a git-commit history.
  vig_dir   <- file.path(pkg_root, "vignettes")
  qmd_files <- list.files(vig_dir, pattern = "\\.qmd$", full.names = FALSE)
  candidate <- NULL
  for (qmd in qmd_files) {
    ct <- .git_commit_mtime(pkg_root, file.path("vignettes", qmd))
    if (!is.na(ct)) { candidate <- qmd; break }
  }
  testthat::skip_if(is.null(candidate), "No .qmd with git history found")

  rel_path <- file.path("vignettes", candidate)
  full_path <- file.path(pkg_root, rel_path)

  # Baseline: .source_mtime >= git_commit_mtime always.
  git_ct  <- .git_commit_mtime(pkg_root, rel_path)
  base_ct <- .source_mtime(pkg_root, rel_path)
  expect_gte(base_ct, git_ct)

  # Simulate a working-tree edit: advance the file's mtime by 60 seconds
  # beyond the current .source_mtime (without modifying content).
  # Restore the original mtime after the test via on.exit.
  original_mtime <- file.mtime(full_path)
  on.exit(Sys.setFileTime(full_path, original_mtime), add = TRUE)

  future_mtime <- as.POSIXct(base_ct + 60, origin = "1970-01-01", tz = "UTC")
  Sys.setFileTime(full_path, future_mtime)

  edited_ct <- .source_mtime(pkg_root, rel_path)
  # The helper must now return the filesystem mtime, not the git-commit time.
  expect_gt(edited_ct, git_ct)
  expect_equal(edited_ct, as.numeric(future_mtime), tolerance = 2)
})

# ---- qa_article_title_integrity unit tests --------------------------------

# Helper: given a slug, QMD title, and HTML lines, extract the HTML title
# and h1 and return a list of violations (character vector, empty = OK).
.check_article_title <- function(slug, qmd_title, html_lines) {
  qmd_title_lc <- tolower(qmd_title)
  violations   <- character(0)

  title_matches <- regmatches(
    html_lines,
    regexpr("<title>[^<]+</title>", html_lines)
  )
  title_matches <- title_matches[nzchar(title_matches)]

  if (length(title_matches) == 0L) {
    return(paste0(slug, ": HTML missing <title> element"))
  }

  html_title_raw <- sub("^<title>", "", sub("</title>.*$", "", title_matches[1L]))
  html_title     <- trimws(sub("\\s*•.*$", "", html_title_raw))
  html_title_lc  <- tolower(html_title)

  title_ok <- grepl(qmd_title_lc, html_title_lc, fixed = TRUE) ||
              grepl(html_title_lc, qmd_title_lc, fixed = TRUE)
  if (!title_ok) {
    violations <- c(violations, paste0(
      slug, ": title mismatch — QMD='", qmd_title, "' HTML='", html_title, "'"
    ))
  }

  h1_matches <- regmatches(
    html_lines,
    regexpr('<h1[^>]*class="title"[^>]*>[^<]+</h1>', html_lines)
  )
  h1_matches <- h1_matches[nzchar(h1_matches)]
  if (length(h1_matches) > 0L) {
    h1_text   <- trimws(sub("^<h1[^>]*>", "", sub("</h1>.*$", "", h1_matches[1L])))
    h1_ok <- grepl(qmd_title_lc, tolower(h1_text), fixed = TRUE) ||
             grepl(tolower(h1_text), qmd_title_lc, fixed = TRUE)
    if (!h1_ok) {
      violations <- c(violations, paste0(
        slug, ": h1 mismatch — QMD='", qmd_title, "' H1='", h1_text, "'"
      ))
    }
  }

  violations
}

test_that("article title checker: known-good HTML returns no violations", {
  # Simulate a correctly rendered palatable_units article
  qmd_title <- "Palatable Units: The Spiegelhalter Philosophy"
  good_html  <- c(
    "<title>Palatable Units: The Spiegelhalter Philosophy • micromort</title>",
    '<h1 class="title">Palatable Units: The Spiegelhalter Philosophy</h1>'
  )
  violations <- .check_article_title("palatable_units", qmd_title, good_html)
  expect_length(violations, 0L)
})

test_that("article title checker: mismatched title raises violation", {
  # Simulate the corruption: HTML has quiz analytics title in a palatable_units page
  qmd_title <- "Palatable Units: The Spiegelhalter Philosophy"
  bad_html   <- c(
    "<title>Your Quiz Analytics • micromort</title>",
    '<h1 class="title">Your Quiz Analytics</h1>'
  )
  violations <- .check_article_title("palatable_units", qmd_title, bad_html)
  expect_true(length(violations) >= 1L)
  # Both title and h1 should be flagged
  expect_true(any(grepl("title mismatch", violations)))
  expect_true(any(grepl("h1 mismatch", violations)))
})

test_that("article title checker: missing <title> element raises violation", {
  qmd_title <- "Palatable Units: The Spiegelhalter Philosophy"
  no_title_html <- c(
    "<html><body><h1>content</h1></body></html>"
  )
  violations <- .check_article_title("palatable_units", qmd_title, no_title_html)
  expect_true(length(violations) >= 1L)
  expect_true(any(grepl("missing", violations)))
})
