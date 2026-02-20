#' Common Risks in Micromorts
#'
#' A dataset of common activities and their associated risk in micromorts.
#' Source: Wikipedia and other public risk assessments.
#'
#' @return A tibble with columns: activity, risk_micromorts, category.
#' @export
#' @examples
#' common_risks()
common_risks <- function() {
  tibble::tribble(
    ~activity, ~risk_micromorts, ~category,
    "Skydiving (one jump)", 7, "Sport",
    "Running a marathon", 7, "Sport",
    "Scuba diving (per dive)", 5, "Sport",
    "Skiing (one day)", 0.5, "Sport",
    "Motorcycling (60 miles)", 10, "Travel",
    "Walking (20 miles)", 1, "Travel",
    "Bicycling (20 miles)", 1, "Travel",
    "Driving (230 miles)", 1, "Travel",
    "Jet plane (1000 miles)", 1, "Travel",
    "General Anesthesia", 10, "Medical",
    "Living (one day, age 30)", 1, "Daily Life",
    "Living (one day, age 50)", 4, "Daily Life",
    "Living (one day, age 90)", 400, "Daily Life",
    "Eating 40 tbsp peanut butter", 1, "Diet (Cancer Risk)",
    "Smoking 1.4 cigarettes", 1, "Chronic (Microlife equivalent)"
  )
}
