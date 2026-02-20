library(targets)
# library(micromort) # Not installed yet

# Set global options
tar_option_set(
  packages = c("testthat", "checkmate"), # micromort loaded via source
  format = "rds"
)

# Load package
devtools::load_all()

# Source plans
source("R/tar_plans/plan_validation.R")

# Combine plans
list(
  plan_validation
)
