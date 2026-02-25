#' @name box/models
#' @title Risk Analysis and Modeling Module
#' @description Provides functions for lifestyle comparisons and hazard calculations.

box::use(
  ./compare[compare_interventions, lifestyle_tradeoff],
  ./hazard[daily_hazard_rate, annual_risk_budget]
)

#' @export
box::export(
  compare_interventions,
  lifestyle_tradeoff,
  daily_hazard_rate,
  annual_risk_budget
)
