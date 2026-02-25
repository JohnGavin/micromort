#' @name server
#' @title Dashboard Server Logic
#' @description Shiny server functions for the micromort dashboard.

box::use(../data[load_acute_risks, load_chronic_risks])
box::use(../models[daily_hazard_rate])

#' Dashboard Server
#'
#' Creates the main dashboard server function.
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @return NULL
#' @export
dashboard_server <- function(input, output, session) {
  # Load data reactively
  acute_data <- shiny::reactive({
    load_acute_risks()
  })

  chronic_data <- shiny::reactive({
    load_chronic_risks()
  })

  # Update category choices
  shiny::observe({
    categories <- sort(unique(acute_data()$category))
    shiny::updateSelectInput(session, "acute_category",
      choices = c("All" = "all", stats::setNames(categories, categories))
    )
  })

  # Filter data based on inputs
  filtered_data <- shiny::reactive({
    if (input$risk_type == "acute") {
      data <- acute_data()
      if (input$acute_category != "all") {
        data <- data[data$category == input$acute_category, ]
      }
      data <- data[data$micromorts >= input$min_micromorts, ]
    } else {
      data <- chronic_data()
      if (input$direction != "all") {
        data <- data[data$direction == input$direction, ]
      }
    }
    data
  })

  # Risk table
  output$risk_table <- DT::renderDT({
    data <- filtered_data()
    DT::datatable(
      data,
      options = list(pageLength = 20, scrollX = TRUE),
      filter = "top"
    )
  })

  # Risk plot
  output$risk_plot <- plotly::renderPlotly({
    data <- filtered_data()

    if (input$risk_type == "acute") {
      # Top 20 risks bar chart
      top_data <- data[order(-data$micromorts), ][1:min(20, nrow(data)), ]

      p <- plotly::plot_ly(
        top_data,
        x = ~micromorts,
        y = ~stats::reorder(activity, micromorts),
        type = "bar",
        orientation = "h",
        color = ~category,
        text = ~sprintf("%s: %.1f micromorts", activity, micromorts),
        hoverinfo = "text"
      ) |>
        plotly::layout(
          title = "Top Acute Risks (Micromorts)",
          xaxis = list(title = "Micromorts (log scale)", type = "log"),
          yaxis = list(title = ""),
          showlegend = TRUE
        )
    } else {
      # Chronic risks
      p <- plotly::plot_ly(
        data,
        x = ~microlives_per_day,
        y = ~stats::reorder(factor, microlives_per_day),
        type = "bar",
        orientation = "h",
        color = ~category,
        text = ~sprintf("%s: %+.1f microlives/day", factor, microlives_per_day),
        hoverinfo = "text"
      ) |>
        plotly::layout(
          title = "Chronic Risk Factors (Microlives per Day)",
          xaxis = list(title = "Microlives per Day"),
          yaxis = list(title = ""),
          showlegend = TRUE
        )
    }

    p
  })

  # Baseline risk calculation
  baseline <- shiny::eventReactive(input$calc_baseline, {
    daily_hazard_rate(input$age, input$sex)
  })

  output$baseline_risk <- shiny::renderPrint({
    req(input$calc_baseline)
    b <- baseline()
    cat("Daily Baseline Risk at Age", b$age, "(", b$sex, ")\n")
    cat("=====================================\n")
    cat("Daily mortality probability:", format(b$daily_prob, scientific = TRUE), "\n")
    cat("Micromorts per day:", b$micromorts, "\n")
    cat("Annual micromorts:", round(b$micromorts * 365, 0), "\n")
    cat("\nInterpretation:", b$interpretation, "\n")
  })
}
