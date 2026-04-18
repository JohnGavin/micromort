# Shared utilities for vignettes — source() this in setup chunks
# Provides safe_tar_read() with RDS fallback for pkgdown/CI builds

safe_tar_read <- function(name) {
  # Try targets store first
  store <- Sys.getenv("TARGETS_STORE", unset = NA)
  if (is.na(store)) {
    store <- tryCatch(
      file.path(rprojroot::find_root(rprojroot::is_r_package), "_targets"),
      error = function(e) "_targets"
    )
  }
  obj <- tryCatch(
    targets::tar_read_raw(name, store = store),
    error = function(e) NULL
  )
  if (!is.null(obj)) return(obj)

  # Fallback: pre-computed RDS in inst/extdata/vignettes/
  pkg_root <- tryCatch(
    rprojroot::find_root(rprojroot::is_r_package),
    error = function(e) "."
  )
  rds_path <- file.path(pkg_root, "inst", "extdata", "vignettes",
                         paste0(name, ".rds"))
  if (!file.exists(rds_path)) {
    rds_path <- system.file("extdata", "vignettes",
                             paste0(name, ".rds"),
                             package = "micromort")
  }
  if (nzchar(rds_path) && file.exists(rds_path)) {
    return(readRDS(rds_path))
  }

  message("Target '", name, "' not found in targets store or RDS fallback.")
  NULL
}
