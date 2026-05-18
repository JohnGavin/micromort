# Tests for vignette output targets in plan_vignette_outputs.R

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
  testthat::skip_if_not(file.exists(".git"),
    "test only runs inside a git checkout (needs git log timestamps)")

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
