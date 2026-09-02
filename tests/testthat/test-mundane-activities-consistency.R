# Regression test for micromort#104:
# "mundane-activity allowlist defined twice — refactor claimed but incomplete"
#
# The refactor commit message previously claimed the mundane-activity
# allowlist was a shared module-level constant, but the vector was still
# defined separately inside both vig_whatis_mundane_plot and
# vig_whatis_mundane_table target bodies (flagged 67 times across roborev
# range-reviews before it was actually fixed). This test asserts:
#   (1) a single top-level MUNDANE_ACTIVITIES constant exists in
#       plan_vignette_outputs.R, and
#   (2) the plot and table targets, when evaluated, both use exactly that
#       activity set.
#
# This test sources plan_vignette_outputs.R directly (not via tar_make()) so
# it runs fast in CI without requiring a built targets store: tar_target()
# only captures its command as an unevaluated expression at definition time,
# so sourcing the plan file is cheap, and the two target commands are then
# eval()'d directly against the live package functions (common_risks() etc.)
# to get the same real result tar_make() would have produced.
test_that("vig_whatis_mundane_plot and vig_whatis_mundane_table share one activity constant", {
  pkg_root  <- rprojroot::find_root(rprojroot::is_r_package)
  plan_file <- file.path(pkg_root, "R", "tar_plans", "plan_vignette_outputs.R")
  testthat::skip_if_not(file.exists(plan_file), "plan_vignette_outputs.R not found")

  env <- new.env(parent = globalenv())
  res <- source(plan_file, local = env)
  plan <- res$value

  # (1) Single top-level constant must exist -- this is the part of the fix
  # that was previously claimed but never implemented.
  expect_true(
    exists("MUNDANE_ACTIVITIES", envir = env, inherits = FALSE),
    info = "MUNDANE_ACTIVITIES must be a single top-level constant in plan_vignette_outputs.R"
  )

  nms <- vapply(plan, function(t) t$settings$name, character(1))
  idx_plot  <- which(nms == "vig_whatis_mundane_plot")
  idx_table <- which(nms == "vig_whatis_mundane_table")
  expect_length(idx_plot, 1L)
  expect_length(idx_table, 1L)

  # Evaluate each target's command expression directly (real common_risks()/
  # chronic_risks() data, no targets store needed) in the plan file's own
  # environment, so both see the same MUNDANE_ACTIVITIES binding.
  plot_result  <- eval(plan[[idx_plot]]$command$expr, envir = env)
  table_result <- eval(plan[[idx_table]]$command$expr, envir = env)

  # Plotly widget stores its underlying data frame in a closure inside
  # $x$visdat (same access pattern as the existing RDS-based test above).
  plot_activities  <- as.character(plot_result$x$visdat[[1]]()$activity)
  table_activities <- as.character(table_result$Activity)

  # (2) Plot and table must use exactly the same activity set as each other,
  # and exactly the shared constant -- not two independently-maintained lists
  # that merely happen to agree today.
  expect_setequal(plot_activities, table_activities)
  expect_setequal(plot_activities, env$MUNDANE_ACTIVITIES)
  expect_setequal(table_activities, env$MUNDANE_ACTIVITIES)
})
