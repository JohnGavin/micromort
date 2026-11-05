# safe_tar_read() lives in inst/vignette_utils.R for vignettes only. A target
# command that calls it fails at build time (the function is not on the
# pipeline's search path), so targets must depend on upstream targets by symbol.
test_that("no tar_plan target command calls safe_tar_read()", {
  root <- tryCatch(
    rprojroot::find_root(rprojroot::is_r_package),
    error = function(e) NULL
  )
  skip_if(is.null(root), "package root not found")
  plan_dir <- file.path(root, "R", "tar_plans")
  skip_if_not(dir.exists(plan_dir), "R/tar_plans not found")
  files <- list.files(plan_dir, pattern = "\\.R$", full.names = TRUE)
  expect_gt(length(files), 0)
  hits <- Filter(function(f) {
    code <- paste(readLines(f, warn = FALSE), collapse = "\n")
    grepl("safe_tar_read\\(", code)
  }, files)
  expect_equal(basename(hits), character(0))
})
