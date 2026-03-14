#' Dark Theme for Micromort Risk Plots
#'
#' A dark-background ggplot2 theme designed for risk comparison plots.
#' White text on `#1a1a1a` background with subtle grid lines.
#'
#' @param label_size Numeric. Y-axis label font size. Default is 9.
#' @return A ggplot2 theme object.
#' @export
#' @family visualization
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(mpg, wt)) + geom_point(color = "white") + theme_micromort_dark()
theme_micromort_dark <- function(label_size = 9) {
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = "#1a1a1a", color = NA),
    panel.background = ggplot2::element_rect(fill = "#1a1a1a", color = NA),
    panel.grid.major.x = ggplot2::element_line(
      color = "#333333", linetype = "dashed", linewidth = 0.3
    ),
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major.y = ggplot2::element_blank(),
    text = ggplot2::element_text(color = "white"),
    axis.text = ggplot2::element_text(color = "white"),
    axis.text.y = ggplot2::element_text(
      size = label_size, face = "bold", color = "white"
    ),
    axis.title = ggplot2::element_text(size = 11, color = "white"),
    plot.title = ggplot2::element_text(size = 14, face = "bold", color = "white"),
    plot.subtitle = ggplot2::element_text(size = 10, color = "#cccccc"),
    plot.caption = ggplot2::element_text(color = "#999999", hjust = 0),
    plot.caption.position = "plot",
    strip.text = ggplot2::element_text(size = 12, face = "bold", color = "white"),
    legend.background = ggplot2::element_rect(fill = "#1a1a1a", color = NA),
    legend.text = ggplot2::element_text(color = "white"),
    legend.title = ggplot2::element_text(color = "white"),
    legend.position = "bottom",
    legend.box = "horizontal",
    panel.spacing = ggplot2::unit(1, "lines")
  )
}

# Jitter unit micromorts for log-scale visibility
#
# Risks with exactly 1 micromort produce log10(1) = 0, making bars invisible
# on a log scale. This applies a small deterministic offset (1.0 -> 1.07)
# so bars are visible. Only affects display, not underlying data.
#
# @param micromorts Numeric vector of micromort values.
# @return Numeric vector with 1.0 values shifted to 1.07.
# @noRd
jitter_unit_micromorts <- function(micromorts) {
  ifelse(micromorts == 1, 1.07, micromorts)
}

# Compute risk clusters
#
# Groups risks with similar micromort values (within log10 tolerance).
# Returns data with cluster_id column for background band annotations.
#
# @param data Tibble with a `micromorts` column.
# @param tolerance Numeric. Log10 distance for clustering. Default 0.05.
# @return Tibble with added `cluster_id` column.
# @noRd
compute_risk_clusters <- function(data, tolerance = 0.05) {
  log_vals <- log10(data$micromorts)
  sorted_idx <- order(log_vals)
  cluster_id <- integer(length(log_vals))
  current_cluster <- 1L
  cluster_id[sorted_idx[1]] <- current_cluster

  for (i in seq_along(sorted_idx)[-1]) {
    if (abs(log_vals[sorted_idx[i]] - log_vals[sorted_idx[i - 1]]) > tolerance) {
      current_cluster <- current_cluster + 1L
    }
    cluster_id[sorted_idx[i]] <- current_cluster
  }

  data$cluster_id <- cluster_id
  data
}

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
#' @param height Numeric. Plot height in inches. Default is 12.
#' @param label_size Numeric. Y-axis label font size. Default is 9.
#' @param dark Logical. If TRUE (default), use [theme_micromort_dark()].
#'   If FALSE, use `theme_minimal()`.
#' @param guide_lines Logical. If TRUE (default), add dashed guide lines
#'   from y-axis labels to bar starts.
#' @param jitter_ones Logical. If TRUE (default), shift 1-micromort values
#'   slightly so bars are visible on log scale.
#' @param cluster_bands Logical. If TRUE (default), add subtle background
#'   bands grouping risks with similar micromort values.
#'
#' @return A ggplot2 object.
#' @importFrom stats reorder
#' @family visualization
#' @seealso [prepare_risks_plot()], [plot_risks_interactive()], [common_risks()]
#' @export
#' @examples
#' # Default dark plot
#' plot_risks()
#'
#' # Light theme
#' plot_risks(dark = FALSE)
#'
#' # Filter then plot
#' prepare_risks_plot(categories = "Sport") |> plot_risks()
#'
#' # Exclude COVID-19 and show top 20
#' prepare_risks_plot(exclude_categories = "COVID-19", top_n = 20) |>
#'   plot_risks(facet = FALSE)
plot_risks <- function(risks = common_risks(),
                       facet = TRUE,
                       height = 12,
                       label_size = 9,
                       dark = TRUE,
                       guide_lines = TRUE,
                       jitter_ones = TRUE,
                       cluster_bands = TRUE) {

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

  # Jitter 1-micromort values for log-scale visibility
  if (jitter_ones) {
    risks$micromorts_display <- jitter_unit_micromorts(risks$micromorts)
  } else {
    risks$micromorts_display <- risks$micromorts
  }

  # Compute clusters for background bands
  if (cluster_bands) {
    risks <- compute_risk_clusters(risks)
  }

  p <- ggplot2::ggplot(risks, ggplot2::aes(
    x = reorder(activity, micromorts),
    y = micromorts_display,
    fill = category
  ))

  # Add cluster background bands (even clusters get a subtle highlight)
  if (cluster_bands && "cluster_id" %in% names(risks)) {
    band_color <- if (dark) "#252525" else "#f0f0f0"
    even_clusters <- unique(risks$cluster_id[risks$cluster_id %% 2 == 0])
    for (cid in even_clusters) {
      cluster_activities <- risks$activity[risks$cluster_id == cid]
      activity_levels <- levels(reorder(risks$activity, risks$micromorts))
      positions <- match(cluster_activities, activity_levels)
      if (length(positions) > 0) {
        p <- p + ggplot2::annotate(
          "rect",
          xmin = min(positions) - 0.5, xmax = max(positions) + 0.5,
          ymin = 0, ymax = Inf,
          fill = band_color, alpha = 0.5
        )
      }
    }
  }

  # Add guide lines from y-axis to bar start
  if (guide_lines) {
    guide_color <- if (dark) "#444444" else "#cccccc"
    p <- p + ggplot2::geom_segment(
      ggplot2::aes(
        x = reorder(activity, micromorts),
        xend = reorder(activity, micromorts),
        y = 0.01,
        yend = micromorts_display
      ),
      color = guide_color, linetype = "dotted", linewidth = 0.2
    )
  }

  p <- p +
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
    )

  # Apply theme

  if (dark) {
    p <- p + theme_micromort_dark(label_size = label_size)
  } else {
    p <- p +
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
  }

  if (facet) {
    p <- p +
      ggplot2::facet_wrap(
        ~ facet_group,
        ncol = 1,
        scales = "free_y"
      )
  }

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

  # Jitter 1-micromort values for log-scale visibility
  risks$micromorts_display <- jitter_unit_micromorts(risks$micromorts)

  # Prepare data with hover text (show original micromorts, not jittered)
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

  # Create plotly figure with dark theme
  fig <- plotly::plot_ly(
    data = risks,
    x = ~micromorts_display,
    y = ~reorder(activity, micromorts),
    type = "bar",
    orientation = "h",
    color = ~category,
    text = ~hover_text,
    hoverinfo = "text",
    hoverlabel = list(
      bgcolor = "#333333",
      font = list(color = "white", size = 12),
      bordercolor = "#555555"
    )
  ) |>
    plotly::layout(
      title = list(
        text = "Risk of Activities in Micromorts<br><sup>Click legend to filter categories</sup>",
        font = list(size = 16, color = "white")
      ),
      xaxis = list(
        title = list(text = "Micromorts (Log Scale)", font = list(color = "white")),
        type = "log",
        tickformat = ",d",
        tickfont = list(color = "white"),
        gridcolor = "#333333"
      ),
      yaxis = list(
        title = "",
        tickfont = list(size = 9, color = "white")
      ),
      legend = list(
        title = list(text = "Category", font = list(color = "white")),
        font = list(color = "white"),
        bgcolor = "rgba(26,26,26,0.8)",
        orientation = "h",
        y = -0.15
      ),
      paper_bgcolor = "#1a1a1a",
      plot_bgcolor = "#1a1a1a",
      font = list(color = "white"),
      margin = list(l = 200, r = 50, t = 80, b = 120),
      annotations = list(
        list(
          text = "Sources: Wikipedia, CDC MMWR",
          xref = "paper", yref = "paper",
          x = 0, y = -0.22,
          showarrow = FALSE,
          font = list(color = "#999999", size = 10),
          xanchor = "left"
        )
      ),
      # Add dropdown menu for category filter
      updatemenus = list(
        list(
          type = "dropdown",
          active = 0,
          x = 1.0,
          y = 1.15,
          bgcolor = "#333333",
          font = list(color = "white"),
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
  "facet_group", "hover_text", "micromorts_display", "cluster_id",
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
  "n_factors", "total_unhedged_ml", "total_hedged_ml", "total_ml_gained", "max_effect",
  # plot_risk_components()
  "component_label", "risk_category"
))


#' Plot Risk Components as Stacked Bar
#'
#' Creates a stacked bar chart showing the breakdown of atomic risk components
#' for selected activities. Hedgeable components are visually distinguished.
#'
#' @param activity_ids Character vector of activity IDs to plot.
#' @param profile A named list of condition variables for filtering.
#' @param risks Optional pre-computed [atomic_risks()] tibble.
#' @return A ggplot2 object.
#' @export
#' @seealso [risk_components()], [atomic_risks()]
#' @examples
#' plot_risk_components(c("flying_2h", "flying_8h", "flying_12h"))
plot_risk_components <- function(activity_ids, profile = list(), risks = NULL) {
  if (is.null(risks)) risks <- atomic_risks()

  available <- unique(risks$activity_id)
  missing <- setdiff(activity_ids, available)
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "x" = "Unknown activity_ids: {.val {missing}}",
      "i" = "Use {.code atomic_risks()$activity_id} to see available IDs."
    ))
  }

  plot_data <- risks |>
    dplyr::filter(activity_id %in% activity_ids) |>
    filter_by_profile(profile) |>
    dplyr::mutate(
      hedge_label = dplyr::if_else(hedgeable, "Hedgeable", "Not hedgeable"),
      activity = factor(activity, levels = unique(activity))
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = stats::reorder(activity, -micromorts, FUN = sum),
      y = micromorts,
      fill = component_label,
      alpha = hedge_label
    )
  ) +
    ggplot2::geom_col(color = "white", linewidth = 0.3) +
    ggplot2::scale_alpha_manual(
      values = c("Hedgeable" = 1.0, "Not hedgeable" = 0.6),
      name = "Mitigation"
    ) +
    ggplot2::scale_fill_viridis_d(option = "D", name = "Component") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Risk Component Breakdown",
      x = NULL,
      y = "Micromorts"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "bottom")
}
