#' Plot Risk Comparison
#'
#' Visualizes the risk of different activities in micromorts.
#'
#' @param risks Tibble. Dataframe of risks, defaults to common_risks().
#' @return A ggplot2 object.
#' @importFrom stats reorder
#' @export
#' @examples
#' plot_risks()
plot_risks <- function(risks = common_risks()) {
  ggplot2::ggplot(risks, ggplot2::aes(x = reorder(activity, micromorts), y = micromorts, fill = category)) +
    ggplot2::geom_col() +
    ggplot2::coord_flip() +
    ggplot2::scale_y_log10(labels = scales::comma) +
    ggplot2::labs(
      title = "Risk of Activities in Micromorts",
      subtitle = "Logarithmic Scale (1 micromort = 1 in a million chance of death)",
      x = "Activity",
      y = "Micromorts (Log Scale)",
      fill = "Category",
      caption = "Sources: Wikipedia, CDC MMWR (https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm)"
    ) +
    ggplot2::theme_minimal()
}

utils::globalVariables(c(
  "activity", "micromorts", "microlives", "category",
  "period", "source_url", "age_group", "vaccination_status"
))
