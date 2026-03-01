#' Prepare Risk Data for Plotting
#'
#' Filters and prepares risk data for visualization. Use this to filter
#' categories before passing to [plot_risks()].
#'
#' @param risks Tibble. Dataframe of risks, defaults to [common_risks()].
#' @param categories Character vector. Categories to include. Use `NULL` (default)
#'   for all categories. See [common_risks()] for available categories.
#' @param exclude_categories Character vector. Categories to exclude. Applied

#'   after `categories` filter.
#' @param min_micromorts Numeric. Minimum micromorts to include (default 0.1
#'   to avoid invisible bars on log scale).
#' @param top_n Integer. If specified, return only the top N risks by micromorts.
#'
#' @return A tibble ready for plotting with [plot_risks()].
#' @export
#' @family visualization
#' @seealso [plot_risks()], [common_risks()]
#' @examples
#' # All risks
#' prepare_risks_plot()
#'
#' # Only COVID-19 risks
#' prepare_risks_plot(categories = "COVID-19")
#'
#' # Exclude COVID-19
#' prepare_risks_plot(exclude_categories = "COVID-19")
#'
#' # Multiple categories
#' prepare_risks_plot(categories = c("Sport", "Travel"))
#'
#' # Top 20 risks
#' prepare_risks_plot(top_n = 20)
#'
#' # Chain with plotting
#' prepare_risks_plot(categories = "Sport") |> plot_risks()
prepare_risks_plot <- function(risks = common_risks(),
                               categories = NULL,
                               exclude_categories = NULL,
                               min_micromorts = 0.1,
                               top_n = NULL) {
  # Filter by minimum micromorts

  risks <- risks |>
    dplyr::filter(micromorts >= min_micromorts)

  # Filter to selected categories
 if (!is.null(categories)) {
    risks <- risks |>
      dplyr::filter(category %in% categories)
  }

  # Exclude categories
  if (!is.null(exclude_categories)) {
    risks <- risks |>
      dplyr::filter(!category %in% exclude_categories)
  }

  # Top N
  if (!is.null(top_n)) {
    risks <- risks |>
      dplyr::slice_max(micromorts, n = top_n)
  }

  # Add facet grouping
  risks <- risks |>
    dplyr::mutate(
      facet_group = factor(
        ifelse(category == "COVID-19", "COVID-19 Risks", "Non-COVID Risks"),
        levels = c("Non-COVID Risks", "COVID-19 Risks")
      )
    )

  risks
}

#' Plot Risk Comparison
#'
#' Visualizes the risk of different activities in micromorts.
#' For filtering by category, use [prepare_risks_plot()] first.
#'
#' @param risks Tibble. Dataframe of risks from [prepare_risks_plot()] or
#'   [common_risks()]. If not pre-filtered, applies default filtering.
#' @param facet Logical. If TRUE, splits plot into COVID-19 and Other panels.
#'   Default is TRUE.
#' @param height Numeric. Plot height in inches. Default is 12 (doubled from
#'   previous default of 6) to prevent label overlap.
#' @param label_size Numeric. Y-axis label font size. Default is 9.
#'
#' @return A ggplot2 object.
#' @importFrom stats reorder
#' @family visualization
#' @seealso [prepare_risks_plot()], [plot_risks_interactive()], [common_risks()]
#' @export
#' @examples
#' # Default plot (all risks)
#' plot_risks()
#'
#' # Without faceting
#' plot_risks(facet = FALSE)
#'
#' # Filter then plot
#' prepare_risks_plot(categories = "Sport") |> plot_risks()
#'
#' # Exclude COVID-19 and show top 20
#' prepare_risks_plot(exclude_categories = "COVID-19", top_n = 20) |>
#'   plot_risks(facet = FALSE)
#'
#' # Custom height for many categories
#' prepare_risks_plot(top_n = 50) |> plot_risks(height = 16)
plot_risks <- function(risks = common_risks(),
                       facet = TRUE,
                       height = 12,
                       label_size = 9) {

 # Apply default filtering if not already prepared
  if (!"facet_group" %in% names(risks)) {
    risks <- prepare_risks_plot(risks)
  }

  # Calculate appropriate label size based on number of activities
  n_activities <- nrow(risks)
  if (n_activities > 40 && label_size == 9) {
    label_size <- 8
  }
  if (n_activities > 60 && label_size >= 8) {
    label_size <- 7
  }

  p <- ggplot2::ggplot(risks, ggplot2::aes(
    x = reorder(activity, micromorts),
    y = micromorts,
    fill = category
  )) +
    ggplot2::geom_col() +
    ggplot2::coord_flip() +
    ggplot2::scale_y_log10(
      labels = scales::comma,
      limits = c(0.01, NA)
    ) +
    ggplot2::labs(
      title = "Risk of Activities in Micromorts",
      subtitle = "Logarithmic Scale (1 micromort = 1 in a million chance of death)",
      x = NULL,
      y = "Micromorts (Log Scale)",
      fill = "Category",
      caption = "Sources: Wikipedia, CDC MMWR (https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm)"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      strip.text = ggplot2::element_text(size = 12, face = "bold"),
      axis.text.y = ggplot2::element_text(size = label_size),
      axis.title = ggplot2::element_text(size = 11),
      plot.title = ggplot2::element_text(size = 14, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 10),
      legend.position = "bottom",
      legend.box = "horizontal",
      panel.spacing = ggplot2::unit(1, "lines")
    )

  if (facet) {
    p <- p +
      ggplot2::facet_wrap(
        ~ facet_group,
        ncol = 1,
        scales = "free_y"
      )
  }

  # Set plot height via theme aspect ratio
  # Note: actual height is controlled when saving/displaying
  # This adds a suggestion for knitr/ggsave
  attr(p, "height") <- height

  p
}

#' Interactive Risk Plot
#'
#' Creates an interactive plotly visualization of risks with category filtering.
#'
#' @param risks Tibble. Dataframe of risks, defaults to [common_risks()].
#' @return A plotly object with interactive filtering.
#' @family visualization
#' @seealso [plot_risks()], [common_risks()]
#' @export
#' @examples
#' if (requireNamespace("plotly", quietly = TRUE)) {
#'   plot_risks_interactive()
#' }
plot_risks_interactive <- function(risks = common_risks()) {
  if (!requireNamespace("plotly", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "Package {.pkg plotly} is required for interactive plots.",
      "i" = "Install it with: {.code install.packages(\"plotly\")}"
    ))
  }

  # Prepare data with hover text
  risks <- risks |>
    dplyr::arrange(dplyr::desc(micromorts)) |>
    dplyr::mutate(
      hover_text = paste0(
        "<b>", activity, "</b><br>",
        "Micromorts: ", scales::comma(micromorts), "<br>",
        "Microlives: ", microlives, "<br>",
        "Period: ", period, "<br>",
        "Category: ", category
      )
    )

  # Create plotly figure with dropdown filter
  fig <- plotly::plot_ly(
    data = risks,
    x = ~micromorts,
    y = ~reorder(activity, micromorts),
    type = "bar",
    orientation = "h",
    color = ~category,
    text = ~hover_text,
    hoverinfo = "text",
    hoverlabel = list(
      bgcolor = "white",
      font = list(color = "black", size = 12),
      bordercolor = "black"
    )
  ) |>
    plotly::layout(
      title = list(
        text = "Risk of Activities in Micromorts<br><sup>Click legend to filter categories</sup>",
        font = list(size = 16)
      ),
      xaxis = list(
        title = "Micromorts (Log Scale)",
        type = "log",
        tickformat = ",d"
      ),
      yaxis = list(
        title = "",
        tickfont = list(size = 9)
      ),
      legend = list(
        title = list(text = "Category"),
        orientation = "h",
        y = -0.15
      ),
      margin = list(l = 200, r = 50, t = 80, b = 100),
      # Add dropdown menu for category filter
      updatemenus = list(
        list(
          type = "dropdown",
          active = 0,
          x = 1.0,
          y = 1.15,
          buttons = list(
            list(
              label = "All Categories",
              method = "update",
              args = list(list(visible = TRUE))
            ),
            list(
              label = "COVID-19 Only",
              method = "update",
              args = list(list(
                visible = vapply(
                  unique(risks$category),
                  function(cat) cat == "COVID-19",
                  logical(1)
                )
              ))
            ),
            list(
              label = "Non-COVID Only",
              method = "update",
              args = list(list(
                visible = vapply(
                  unique(risks$category),
                  function(cat) cat != "COVID-19",
                  logical(1)
                )
              ))
            )
          )
        )
      )
    )

  fig
}

utils::globalVariables(c(
  # common_risks()
  "activity", "micromorts", "microlives", "category", "period", "source_url",
  "period_type", "period_days", "period_parsed", "micromorts_per_day",
  # covid_vaccine_rr()
  "age_group", "vaccination_status", "deaths_per_100k", "relative_risk",
  # chronic_risks()
  "factor", "microlives_per_day", "direction", "description", "annual_effect_days",
  # demographic_factors()
  "comparison", "source",
  # plot_risks()
  "facet_group", "hover_text",
  # cancer_risks()
  "cancer_type", "sex", "family_history_rr", "micromorts_per_year",
  "micromorts_with_family_history", "rank_by_sex",
  # vaccination_risks()
  "vaccine_schedule", "country", "mortality_reduction_pct",
  "micromorts_avoided_per_year", "microlives_gained_per_day", "annual_life_days_gained",
  # conditional_risk()
  "disease_category", "risk_factor", "unhedged_state", "hedged_state",
  "unhedged_microlives_per_day", "hedged_microlives_per_day", "reduction_pct",
  "evidence_quality", "microlives_gained", "annual_days_gained", "micromorts_equivalent_per_day",
  # hedged_portfolio()
  "n_factors", "total_unhedged_ml", "total_hedged_ml", "total_ml_gained", "max_effect"
))
