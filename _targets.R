library(targets)

# Set global options
tar_option_set(
  packages = c(
    "testthat", "checkmate",
    "dplyr", "tibble", "readr",
    "arrow", "digest", "cli"
  ),
  format = "rds"
)

# Load package functions
devtools::load_all()

# Source all plan files from R/tar_plans/
plan_files <- list.files(
  "R/tar_plans",
  pattern = "^plan_.*\\.R$",
  full.names = TRUE
)
for (plan_file in plan_files) {
  source(plan_file)
}

# Combine all plans
c(
  # Data pipeline
  plan_data_acquisition,
  plan_normalization,
  plan_export,
  plan_logging,

  # Documentation
  plan_documentation,

  # Telemetry: pipeline health, GitHub activity, codebase metrics
  plan_telemetry,

  # Vignette pre-computed objects (MANDATORY per quarto-files.md)
  plan_vignette_outputs,

  # Validation (existing)
  if (exists("plan_validation")) plan_validation else list()
)
