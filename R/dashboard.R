#' Launch Risk Explorer Dashboard
#'
#' Starts an interactive Shiny dashboard for exploring micromort and
#' microlife data.
#'
#' @param ... Additional arguments passed to shiny::runApp()
#' @return Invisible NULL. Runs the dashboard until closed.
#' @export
#' @examples
#' \dontrun{
#' launch_dashboard()
#' }
launch_dashboard <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "Package 'shiny' is required to run the dashboard",
      "i" = "Install with: install.packages('shiny')"
    ))
  }

  if (!requireNamespace("DT", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "Package 'DT' is required to run the dashboard",
      "i" = "Install with: install.packages('DT')"
    ))
  }

  if (!requireNamespace("plotly", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "Package 'plotly' is required to run the dashboard",
      "i" = "Install with: install.packages('plotly')"
    ))
  }

  # Define UI inline
  ui <- shiny::fluidPage(
    shiny::titlePanel("Micromort Risk Explorer"),

    shiny::sidebarLayout(
      shiny::sidebarPanel(
        shiny::selectInput(
          "risk_type",
          "Risk Type:",
          choices = c("Acute (Micromorts)" = "acute", "Chronic (Microlives)" = "chronic")
        ),

        shiny::conditionalPanel(
          condition = "input.risk_type == 'acute'",
          shiny::selectInput("acute_category", "Category:", choices = NULL),
          shiny::sliderInput(
            "min_micromorts",
            "Minimum Micromorts:",
            min = 0, max = 1000, value = 0, step = 10
          )
        ),

        shiny::conditionalPanel(
          condition = "input.risk_type == 'chronic'",
          shiny::selectInput(
            "direction",
            "Direction:",
            choices = c("All" = "all", "Gains" = "gain", "Losses" = "loss")
          )
        ),

        shiny::hr(),

        shiny::h4("Personal Risk Calculator"),
        shiny::numericInput("age", "Your Age:", value = 35, min = 1, max = 100),
        shiny::selectInput("sex", "Sex:", choices = c("Male" = "male", "Female" = "female")),
        shiny::actionButton("calc_baseline", "Calculate Baseline Risk", class = "btn-primary")
      ),

      shiny::mainPanel(
        shiny::tabsetPanel(
          shiny::tabPanel(
            "Risk Table",
            DT::DTOutput("risk_table")
          ),
          shiny::tabPanel(
            "Visualization",
            plotly::plotlyOutput("risk_plot", height = "600px")
          ),
          shiny::tabPanel(
            "Personal Risk",
            shiny::verbatimTextOutput("baseline_risk")
          ),
          shiny::tabPanel(
            "About",
            shiny::h3("About Micromort Risk Explorer"),
            shiny::p("A micromort is a one-in-a-million chance of death."),
            shiny::p("A microlife represents 30 minutes of life expectancy."),
            shiny::hr(),
            shiny::p("Data sources:"),
            shiny::tags$ul(
              shiny::tags$li(shiny::a("Wikipedia: Micromort", href = "https://en.wikipedia.org/wiki/Micromort")),
              shiny::tags$li(shiny::a("Wikipedia: Microlife", href = "https://en.wikipedia.org/wiki/Microlife")),
              shiny::tags$li(shiny::a("micromorts.rip", href = "https://micromorts.rip/")),
              shiny::tags$li(shiny::a("CDC MMWR", href = "https://www.cdc.gov/mmwr/"))
            )
          )
        )
      )
    )
  )

  # Define server
  server <- function(input, output, session) {
    acute_data <- shiny::reactive({
      load_acute_risks()
    })

    chronic_data <- shiny::reactive({
      load_chronic_risks()
    })

    shiny::observe({
      categories <- sort(unique(acute_data()$category))
      shiny::updateSelectInput(session, "acute_category",
        choices = c("All" = "all", stats::setNames(categories, categories))
      )
    })

    filtered_data <- shiny::reactive({
      if (input$risk_type == "acute") {
        data <- acute_data()
        if (!is.null(input$acute_category) && input$acute_category != "all") {
          data <- data[data$category == input$acute_category, ]
        }
        data <- data[data$micromorts >= input$min_micromorts, ]
      } else {
        data <- chronic_data()
        if (!is.null(input$direction) && input$direction != "all") {
          data <- data[data$direction == input$direction, ]
        }
      }
      data
    })

    output$risk_table <- DT::renderDT({
      DT::datatable(
        filtered_data(),
        options = list(pageLength = 15, scrollX = TRUE),
        filter = "top"
      )
    })

    output$risk_plot <- plotly::renderPlotly({
      data <- filtered_data()

      if (input$risk_type == "acute") {
        top_data <- data[order(-data$micromorts), ][1:min(20, nrow(data)), ]

        plotly::plot_ly(
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
        plotly::plot_ly(
          data,
          x = ~microlives_per_day,
          y = ~stats::reorder(factor, microlives_per_day),
          type = "bar",
          orientation = "h",
          color = ~category,
          text = ~sprintf("%s: %+.1f ml/day", factor, microlives_per_day),
          hoverinfo = "text"
        ) |>
          plotly::layout(
            title = "Chronic Risk Factors (Microlives/Day)",
            xaxis = list(title = "Microlives per Day"),
            yaxis = list(title = ""),
            showlegend = TRUE
          )
      }
    })

    baseline <- shiny::eventReactive(input$calc_baseline, {
      daily_hazard_rate(input$age, input$sex)
    })

    output$baseline_risk <- shiny::renderPrint({
      shiny::req(input$calc_baseline)
      b <- baseline()
      cat("Daily Baseline Risk at Age", b$age, "(", b$sex, ")\n")
      cat("=====================================\n")
      cat("Daily mortality probability:", format(b$daily_prob, scientific = TRUE), "\n")
      cat("Micromorts per day:", b$micromorts, "\n")
      cat("Annual micromorts:", round(b$micromorts * 365, 0), "\n")
      cat("\nInterpretation:", b$interpretation, "\n")
    })
  }

  cli::cli_h1("Micromort Risk Explorer")
  cli::cli_alert_info("Starting dashboard...")
  shiny::shinyApp(ui = ui, server = server, ...)
}
