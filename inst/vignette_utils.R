# Shared utilities for vignettes — source() this in setup chunks
# Provides safe_tar_read() with RDS fallback for pkgdown/CI builds
# and show_target() with class-based rendering dispatch.

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
    val <- readRDS(rds_path)
    if (!is.null(val)) return(val)
  }

  message("Target '", name, "' requires tar_make() to build.")
  NULL
}


# Class-based rendering dispatcher for vignette chunks.
# Resolves the ggplotGrob / htmlwidget / data.frame tension:
# vignette chunks call show_target("vig_name") as a single expression,
# and this function handles the correct rendering method per class.
show_target <- function(name, ...) {
  obj <- safe_tar_read(name)
  if (is.null(obj)) {
    cat(paste0("*`", name, "` requires `tar_make()` to render.*\n"))
    return(invisible(NULL))
  }
  render_target(obj, ...)
}

# S3-style dispatch on object class
render_target <- function(obj, ...) {
  if (inherits(obj, "grob") || inherits(obj, "gtable")) {
    # ggplotGrob objects: render via grid
    grid::grid.newpage()
    grid::grid.draw(obj)
  } else if (inherits(obj, "gg") || inherits(obj, "ggplot")) {
    # Raw ggplot objects (should be grob, but handle gracefully)
    print(obj)
  } else if (inherits(obj, "htmlwidget")) {
    # plotly, visNetwork, DT, leaflet, etc.
    #
    # A widget object read back from a pre-computed RDS fallback needs its
    # OWN package namespace loaded so knit_print.htmlwidget can locate the
    # widget's JS/CSS bindings (htmlwidgets looks these up by widget class,
    # via the defining package). Packages that micromort formally Imports
    # (DT, plotly) get loaded as a side effect of attaching micromort itself;
    # a Suggests-only widget package like visNetwork does not, so a render
    # session that never explicitly attaches it (e.g. pkgdown's default
    # fresh-subprocess quarto render) silently falls back to printing the
    # widget's raw list structure instead of the interactive graph
    # (micromort#126).
    widget_pkg <- class(obj)[1]
    if (requireNamespace(widget_pkg, quietly = TRUE)) {
      try(getNamespace(widget_pkg), silent = TRUE)
    }
    requireNamespace("htmlwidgets", quietly = TRUE)
    obj
  } else if (inherits(obj, "data.frame")) {
    # Data frames: wrap in DT with dark theme
    DT::datatable(obj, rownames = FALSE, filter = "top",
      options = list(
        pageLength = 15, scrollX = TRUE,
        initComplete = DT::JS(
          "function(settings, json) {",
          "  $(this.api().table().container()).css({'background-color': '#1a1a2e', 'color': '#e0e0e0'});",
          "  $(this.api().table().header()).css({'background-color': '#16213e', 'color': '#e0e0e0'});",
          "  $('td', this.api().table().body()).css({'background-color': '#1a1a2e', 'color': '#e0e0e0'});",
          "}"
        )
      ), ...)
  } else if (is.character(obj) && length(obj) == 1) {
    # Single character string: render as raw markdown/HTML (build-info, mermaid)
    cat(obj)
  } else if (is.list(obj) && !is.data.frame(obj)) {
    # Named list: return invisibly (caller extracts elements)
    invisible(obj)
  } else {
    # Fallback: print
    print(obj)
  }
}
