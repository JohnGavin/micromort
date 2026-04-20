.onLoad <- function(libname, pkgname) {
  if (requireNamespace("units", quietly = TRUE)) {
    tryCatch(
      {
        units::install_unit("micromort")
        units::install_unit("microlife")
      },
      error = function(e) NULL
    )
  }
}

.onUnload <- function(libpath) {
  if (requireNamespace("units", quietly = TRUE)) {
    tryCatch(
      {
        units::remove_unit("microlife")
        units::remove_unit("micromort")
      },
      error = function(e) NULL
    )
  }
}
