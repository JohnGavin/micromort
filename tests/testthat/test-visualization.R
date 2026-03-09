test_that("theme_micromort_dark() returns a ggplot2 theme", {
  th <- theme_micromort_dark()
  expect_s3_class(th, "theme")
  expect_s3_class(th, "gg")
  # Dark background

  expect_equal(th$plot.background$fill, "#1a1a1a")
  expect_equal(th$panel.background$fill, "#1a1a1a")
  # White text

  expect_equal(th$text$colour, "white")
  # Bold y-axis labels
  expect_equal(th$axis.text.y$face, "bold")
  # Caption left-aligned
  expect_equal(th$plot.caption$hjust, 0)
})

test_that("theme_micromort_dark() respects label_size", {
  th <- theme_micromort_dark(label_size = 7)
  expect_equal(th$axis.text.y$size, 7)
})

test_that("jitter_unit_micromorts() shifts exactly-1 values", {
  expect_equal(
    jitter_unit_micromorts(c(0.5, 1, 2, 1, 10)),
    c(0.5, 1.07, 2, 1.07, 10)
  )
})

test_that("jitter_unit_micromorts() leaves non-1 values unchanged", {
  vals <- c(0.1, 0.99, 1.01, 5, 100)
  expect_equal(jitter_unit_micromorts(vals), vals)
})

test_that("compute_risk_clusters() produces expected groupings", {
  data <- tibble::tibble(
    activity = c("a", "b", "c", "d"),
    micromorts = c(1, 1.05, 10, 10.5)
  )
  result <- compute_risk_clusters(data)
  expect_true("cluster_id" %in% names(result))
  # a and b should be in the same cluster (close in log10 space)
  expect_equal(result$cluster_id[1], result$cluster_id[2])
  # c and d should be in the same cluster
  expect_equal(result$cluster_id[3], result$cluster_id[4])
  # a/b cluster differs from c/d cluster
  expect_false(result$cluster_id[1] == result$cluster_id[3])
})

test_that("plot_risks() returns ggplot with dark theme by default", {
  p <- plot_risks()
  expect_s3_class(p, "ggplot")
  # Dark theme applied
  th <- p$theme
  expect_equal(th$plot.background$fill, "#1a1a1a")
})

test_that("plot_risks(dark = FALSE) returns ggplot with minimal theme", {
  p <- plot_risks(dark = FALSE)
  expect_s3_class(p, "ggplot")
  # Should NOT have dark background
  bg_fill <- p$theme$plot.background$fill
  expect_true(is.null(bg_fill) || bg_fill != "#1a1a1a")
})

test_that("plot_risks() jitters 1-micromort values by default", {
  risks <- tibble::tibble(
    activity = c("test_a", "test_b"),
    micromorts = c(1, 5),
    microlives = c(0.7, 3.5),
    category = c("Test", "Test"),
    period = c("per event", "per event")
  )
  p <- plot_risks(risks, facet = FALSE, guide_lines = FALSE, cluster_bands = FALSE)
  # Check that micromorts_display column was created in the data
  expect_true("micromorts_display" %in% names(p$data))
  expect_equal(p$data$micromorts_display[p$data$micromorts == 1], 1.07)
})

test_that("plot_risks_interactive() returns plotly object", {
  skip_if_not_installed("plotly")
  fig <- plot_risks_interactive()
  expect_s3_class(fig, "plotly")
})
