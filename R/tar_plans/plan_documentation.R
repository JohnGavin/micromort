#' Documentation Plan
#'
#' Generates documentation artifacts including project tree for README.
#'
#' @return List of targets for documentation
plan_documentation <- list(
  # Track top-level directory structure via file hash
  targets::tar_target(
    project_dirs_hash,
    {
      # Get top-level directories
      dirs <- list.dirs(".", recursive = FALSE)

      # Exclude hidden dirs and build artifacts
      dirs <- dirs[!grepl("^\\./\\.", dirs)]
      dirs <- dirs[!grepl("_targets|renv|node_modules|nix-shell", dirs)]

      # Hash for change detection
      digest::digest(sort(dirs))
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # Generate annotated tree when structure changes
  targets::tar_target(
    project_tree,
    {
      force(project_dirs_hash)  # Dependency on structure hash

      # Build annotated tree with comments
      tibble::tribble(
        ~path, ~description,
        "R/", "Package functions (exported)",
        "R/tar_plans/", "Modular pipeline definitions",
        "box/", "box modules (API, data, models, dashboard)",
        "box/data/", "Data loading and schema validation",
        "box/models/", "Analysis and comparison models",
        "box/api/", "Plumber API endpoints",
        "box/dashboard/", "Shinylive dashboard components",
        "data-raw/", "Source data and processing scripts",
        "data-raw/sources/", "Raw CSV/JSON source files",
        "inst/extdata/", "Parquet datasets (output)",
        "inst/extdata/logs/", "Pipeline execution logs",
        "inst/plumber/", "API entry point",
        "inst/dashboard/", "Dashboard assets",
        "vignettes/", "Documentation and examples",
        "tests/", "Unit tests",
        "man/", "Generated documentation"
      )
    }
  ),

  # Format for README display
  targets::tar_target(
    project_tree_formatted,
    {
      lines <- c(
        "```",
        "micromort/",
        sprintf("%-28s # %s", project_tree$path, project_tree$description),
        "_targets.R               # Pipeline orchestrator",
        "```"
      )
      paste(lines, collapse = "\n")
    }
  ),

  # Dataset summaries for README
  targets::tar_target(
    dataset_summary,
    {
      tibble::tribble(
        ~dataset, ~records, ~description,
        "acute_risks", nrow(acute_risks_merged), "Micromort values for acute activities",
        "chronic_risks", nrow(chronic_risks_merged), "Microlife values for chronic factors",
        "risk_sources", nrow(risk_sources_merged), "Data source registry"
      )
    }
  )
)
