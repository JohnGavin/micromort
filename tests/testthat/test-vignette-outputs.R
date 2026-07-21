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
# Helper: "last touched" timestamp for any repo-relative path.
# Returns the LATER of:
#   (a) the git last-commit timestamp (catches committed-but-not-rebuilt)
#   (b) the filesystem mtime           (catches working-tree edits)
# Both are in seconds since Unix epoch (numeric).
# Returns NA_real_ when neither is available.
#
# Using max(git_ct, fs_ct) for BOTH source and output paths means the test
# correctly handles the common local workflow where pkgdown::build_site()
# updates docs/articles/*.html working-tree mtimes before those files have
# been committed — the output is recognised as "fresh" rather than falsely
# flagged as STALE.
# ---------------------------------------------------------------------------
.path_mtime <- function(pkg_root, rel_path) {
  full_path  <- file.path(pkg_root, rel_path)
  git_ct     <- .git_commit_mtime(pkg_root, rel_path)
  fs_ct      <- tryCatch(
    as.numeric(file.mtime(full_path)),
    error = function(e) NA_real_
  )
  if (is.na(git_ct) && is.na(fs_ct)) return(NA_real_)
  max(c(git_ct, fs_ct), na.rm = TRUE)
}

# Backward-compat alias: .source_mtime was the original name; callers that
# still use it (e.g. inline test blocks below) are updated, but keep the alias
# to avoid breaking any external scripts that may reference it.
.source_mtime <- .path_mtime

# Keep the old name as an alias so callers that compare OUTPUT html timestamps
# (which live only in git, not in working-tree) still work correctly.
.git_mtime <- .git_commit_mtime

# ---------------------------------------------------------------------------
# Helper: does `rel_path` have real uncommitted changes (staged, unstaged, or
# untracked) in the working tree?
# ---------------------------------------------------------------------------
.has_uncommitted_changes <- function(pkg_root, rel_path) {
  out <- tryCatch(
    system2(
      "git",
      c("-C", pkg_root, "status", "--porcelain", "--", rel_path),
      stdout = TRUE, stderr = FALSE
    ),
    error = function(e) character(0)
  )
  length(out) > 0L && any(nzchar(out))
}

# ---------------------------------------------------------------------------
# Helper: "effective" timestamp used for STALENESS DECISIONS (as opposed to
# .path_mtime(), which is a general-purpose "last touched" helper tested in
# isolation below).
#
# .path_mtime() returns max(git_ct, fs_ct) so a genuine, uncommitted
# working-tree edit is caught. But a fresh `git clone` or `git worktree add`
# stamps EVERY checked-out file with an ~simultaneous "now" mtime (in git's
# internal tree-walk order, which visits "docs/" before "vignettes/"
# alphabetically) that has zero relationship to real edit history. Because
# that checkout-time fs_ct is always newer than any historic git-commit
# time, max(git_ct, fs_ct) alone can never distinguish "just checked out"
# from "actually edited a moment ago" -- so every fresh checkout/worktree
# spuriously flagged ~all vignettes as ~1-second "stale" relative to their
# HTML (llm#763).
#
# .effective_mtime() trusts the filesystem mtime only when the path has a
# real uncommitted change (the actual signal for "locally edited/rebuilt,
# not yet committed"); a pristine file always resolves to its git-commit
# timestamp, which is immune to checkout-order noise.
# ---------------------------------------------------------------------------
.effective_mtime <- function(pkg_root, rel_path) {
  if (.has_uncommitted_changes(pkg_root, rel_path)) {
    return(.path_mtime(pkg_root, rel_path))
  }
  .git_commit_mtime(pkg_root, rel_path)
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

    # Source: real uncommitted edit -> fs mtime; pristine -> git-commit time
    # (immune to checkout-order noise; see .effective_mtime() above).
    qmd_time  <- .effective_mtime(pkg_root, file.path("vignettes", qmd))
    # Output: same rule so a locally-built HTML that hasn't been committed
    # yet is not incorrectly flagged as stale.
    html_time <- .effective_mtime(pkg_root, file.path("docs", "articles", paste0(base, ".html")))

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

    # Source: real uncommitted edit -> fs mtime; pristine -> git-commit time
    # (immune to checkout-order noise; see .effective_mtime() above).
    src_ct <- .effective_mtime(pkg_root, src_rel)
    # Output: same rule so a locally-rebuilt HTML that hasn't been committed
    # yet is not incorrectly flagged as stale.
    out_ct <- .effective_mtime(pkg_root, out_rel)

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

  # Source: real uncommitted edit -> fs mtime; pristine -> git-commit time
  # (immune to checkout-order noise; see .effective_mtime() above).
  src_ct <- .effective_mtime(pkg_root, "CHANGELOG.md")
  # Output: same rule so a locally-rebuilt CHANGELOG.html that hasn't been
  # committed yet is not incorrectly flagged as stale.
  out_ct <- .effective_mtime(pkg_root, file.path("docs", "CHANGELOG.html"))

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
# Working-tree edit detection: .path_mtime() picks up fs mtime > git-commit.
#
# This test proves the guard is not git-log-only: when a .qmd is modified on
# disk but not yet committed, .path_mtime() returns the filesystem mtime
# (which is newer than the git commit time), so the staleness check fires.
# ---------------------------------------------------------------------------
test_that(".path_mtime() detects working-tree edits beyond last git commit", {
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

  # Baseline: .path_mtime >= git_commit_mtime always.
  git_ct  <- .git_commit_mtime(pkg_root, rel_path)
  base_ct <- .path_mtime(pkg_root, rel_path)
  expect_gte(base_ct, git_ct)

  # Simulate a working-tree edit: advance the file's mtime by 60 seconds
  # beyond the current .path_mtime (without modifying content).
  # Restore the original mtime after the test via on.exit.
  original_mtime <- file.mtime(full_path)
  on.exit(Sys.setFileTime(full_path, original_mtime), add = TRUE)

  future_mtime <- as.POSIXct(base_ct + 60, origin = "1970-01-01", tz = "UTC")
  Sys.setFileTime(full_path, future_mtime)

  edited_ct <- .path_mtime(pkg_root, rel_path)
  # The helper must now return the filesystem mtime, not the git-commit time.
  expect_gt(edited_ct, git_ct)
  expect_equal(edited_ct, as.numeric(future_mtime), tolerance = 2)
})

# ---------------------------------------------------------------------------
# Symmetric output-side mtime: .path_mtime() on a locally-built HTML
# returns its working-tree mtime when that is newer than the git-commit time.
#
# This is the roborev Issue F fix: before this fix, the output side used
# .git_commit_mtime() only, so a locally-rebuilt docs/articles/*.html that
# hadn't been committed yet was incorrectly flagged as stale relative to the
# .qmd source.
# ---------------------------------------------------------------------------
test_that(".path_mtime() returns fs mtime for output file when fs > git-commit", {
  testthat::skip_on_cran()
  testthat::skip_if_not(
    rprojroot::find_root(rprojroot::is_r_package) |>
      file.path(".git") |>
      file.exists(),
    "test only runs inside a git checkout"
  )

  pkg_root <- rprojroot::find_root(rprojroot::is_r_package)

  # Pick the first docs/articles/*.html that has a git-commit history.
  doc_dir   <- file.path(pkg_root, "docs", "articles")
  if (!dir.exists(doc_dir)) {
    testthat::skip("docs/articles/ not present — run pkgdown::build_site() first")
  }
  html_files <- list.files(doc_dir, pattern = "\\.html$", full.names = FALSE)
  candidate  <- NULL
  for (html in html_files) {
    ct <- .git_commit_mtime(pkg_root, file.path("docs", "articles", html))
    if (!is.na(ct)) { candidate <- html; break }
  }
  testthat::skip_if(is.null(candidate), "No docs/articles/*.html with git history found")

  rel_path  <- file.path("docs", "articles", candidate)
  full_path <- file.path(pkg_root, rel_path)

  git_ct  <- .git_commit_mtime(pkg_root, rel_path)
  base_ct <- .path_mtime(pkg_root, rel_path)

  # Advance the HTML's working-tree mtime to simulate a fresh local pkgdown build
  # that has not yet been committed.
  original_mtime <- file.mtime(full_path)
  on.exit(Sys.setFileTime(full_path, original_mtime), add = TRUE)

  future_mtime <- as.POSIXct(base_ct + 120, origin = "1970-01-01", tz = "UTC")
  Sys.setFileTime(full_path, future_mtime)

  rebuilt_ct <- .path_mtime(pkg_root, rel_path)

  # .path_mtime() must return the fs mtime (the rebuild time), not git_ct.
  expect_gt(rebuilt_ct, git_ct)
  expect_equal(rebuilt_ct, as.numeric(future_mtime), tolerance = 2)

  # Crucially: if the corresponding source .qmd has an older timestamp than
  # this rebuilt HTML, the freshness check must NOT flag it as stale.
  qmd_base <- sub("\\.html$", ".qmd", candidate)
  qmd_rel  <- file.path("vignettes", qmd_base)
  qmd_ct   <- .path_mtime(pkg_root, qmd_rel)

  if (!is.na(qmd_ct)) {
    # A locally-rebuilt HTML that is NEWER than the source must not be stale.
    expect_lte(qmd_ct, rebuilt_ct)
  }
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

# ---- .pkgdown_article_slugs() unit tests ----------------------------------

# Helper: write a minimal _pkgdown.yml to a temp directory and return the path.
.write_fixture_pkgdown <- function(dir) {
  yml_path <- file.path(dir, "_pkgdown.yml")
  writeLines(c(
    "url: https://example.github.io/mypkg/",
    "navbar:",
    "  components:",
    "    articles:",
    "      menu:",
    "      - text: Quiz",
    "        href: articles/micromort-quiz.html",
    "articles:",
    "- title: 'Concepts'",
    "  contents:",
    "  - introduction",
    "  - palatable_units",
    "- title: 'Quizzes (Shinylive)'",
    "  contents:",
    "  - quiz_shinylive",
    "  - chronic_quiz_shinylive",
    "  - micromort-quiz"
  ), yml_path)
  yml_path
}

test_that(".pkgdown_article_slugs() returns slugs from articles:contents: AND navbar hrefs", {
  tmp <- withr::local_tempdir()
  yml <- .write_fixture_pkgdown(tmp)

  # Load the helper from the package source (avoids install requirement)
  source(here::here("R", "tar_plans", "plan_qa_gates.R"), local = TRUE)

  slugs <- .pkgdown_article_slugs(yml)

  # articles: contents: entries
  expect_true("introduction"         %in% slugs)
  expect_true("palatable_units"      %in% slugs)
  expect_true("quiz_shinylive"       %in% slugs)
  expect_true("chronic_quiz_shinylive" %in% slugs)
  # navbar href entry (union, deduped)
  expect_true("micromort-quiz"       %in% slugs)
  # No duplicates (micromort-quiz appears in both navbar and articles:contents)
  expect_equal(length(slugs), length(unique(slugs)))
})

test_that(".pkgdown_article_slugs() aborts on malformed YAML", {
  tmp <- withr::local_tempdir()
  bad_yml <- file.path(tmp, "_pkgdown.yml")
  writeLines(c("url: ok", "articles: [bad: yaml: { unclosed"), bad_yml)

  source(here::here("R", "tar_plans", "plan_qa_gates.R"), local = TRUE)

  expect_error(.pkgdown_article_slugs(bad_yml))
})

# ---------------------------------------------------------------------------
# Regression test for micromort#126: targets::tar_visnetwork(),
# targets::tar_network(), and targets::tar_read_raw() all raise
# "attempted to run ... during a pipeline, which is unsupported" when called
# directly from inside a running tar_make() pipeline. The old
# tryCatch(..., error = function(e) NULL) handlers swallowed this silently,
# so vig_arch_tar_visnetwork and vig_pipeline_dependency_graph always built
# to NULL and were exported as 80-byte serialized-NULL RDS fallbacks that
# rendered a permanent placeholder in the deployed architecture.html
# (root cause of the 2026-07-10 deploy failure). This test guards against
# ANY vig_* RDS fallback silently regressing to NULL again, regardless of
# which target caused it.
# ---------------------------------------------------------------------------
test_that("no inst/extdata/vignettes/*.rds deserializes to NULL", {
  pkg_root <- rprojroot::find_root(rprojroot::is_r_package)
  rds_dir  <- file.path(pkg_root, "inst", "extdata", "vignettes")
  testthat::skip_if_not(dir.exists(rds_dir), "inst/extdata/vignettes/ not present")

  rds_files <- list.files(rds_dir, pattern = "\\.rds$", full.names = TRUE)
  testthat::skip_if(length(rds_files) == 0L, "no RDS fallbacks to check")

  null_files <- character(0)
  for (f in rds_files) {
    obj <- tryCatch(readRDS(f), error = function(e) NULL)
    if (is.null(obj)) null_files <- c(null_files, basename(f))
  }

  if (length(null_files) > 0L) {
    cli::cli_abort(c(
      "x" = "{length(null_files)} RDS fallback{?s} deserialize{?s/} to NULL.",
      "i" = "Files: {.val {null_files}}.",
      "i" = paste(
        "This means the underlying tar_target() silently failed to build",
        "(commonly: tar_network()/tar_visnetwork()/tar_read_raw() called",
        "directly inside tar_make(), which targets forbids — wrap in",
        "callr::r() instead) and site_rds_export exported the NULL as-is."
      )
    ))
  }

  expect_length(null_files, 0L)
})
