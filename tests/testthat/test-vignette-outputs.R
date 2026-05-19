# Tests for vignette output targets in plan_vignette_outputs.R

# ---------------------------------------------------------------------------
# Helper: get git last-commit unix timestamp for a repo-relative path.
# Returns NA_real_ when the path has no git history yet.
# ---------------------------------------------------------------------------
.git_mtime <- function(pkg_root, rel_path) {
  out <- system2(
    "git",
    c("-C", pkg_root, "log", "-1", "--format=%ct", "--", rel_path),
    stdout = TRUE, stderr = FALSE
  )
  if (length(out) == 0L || !nzchar(out)) return(NA_real_)
  suppressWarnings(as.numeric(out))
}

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

    qmd_time <- as.numeric(system2(
      "git", c("-C", pkg_root, "log", "-1", "--format=%ct", "--", file.path("vignettes", qmd)),
      stdout = TRUE, stderr = FALSE
    ))
    html_time <- as.numeric(system2(
      "git", c("-C", pkg_root, "log", "-1", "--format=%ct", "--", file.path("docs", "articles", paste0(base, ".html"))),
      stdout = TRUE, stderr = FALSE
    ))

    if (length(qmd_time) == 1 && length(html_time) == 1 &&
        !is.na(qmd_time) && !is.na(html_time) && qmd_time > html_time) {
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

    src_ct <- .git_mtime(pkg_root, src_rel)
    out_ct <- .git_mtime(pkg_root, out_rel)

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

  src_ct <- .git_mtime(pkg_root, "CHANGELOG.md")
  out_ct <- .git_mtime(pkg_root, file.path("docs", "CHANGELOG.html"))

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
