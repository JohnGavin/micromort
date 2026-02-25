#' @name ui
#' @title Dashboard UI Components
#' @description Shiny UI elements for the micromort dashboard.

#' Dashboard UI
#'
#' Creates the main dashboard UI.
#'
#' @return A shiny UI object
#' @export
dashboard_ui <- function() {
  shiny::fluidPage(
    shiny::titlePanel("Micromort Risk Explorer"),

    shiny::sidebarLayout(
      shiny::sidebarPanel(
        shiny::h4("Filters"),

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
            min = 0, max = 1000, value = 0
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
        shiny::actionButton("calc_baseline", "Calculate Baseline Risk")
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
            shiny::verbatimTextOutput("baseline_risk"),
            shiny::h4("Your Daily Risk Budget"),
            shiny::p("Select activities to add to your annual risk budget:"),
            DT::DTOutput("budget_table")
          ),
          shiny::tabPanel(
            "About",
            shiny::includeMarkdown(system.file("dashboard", "about.md", package = "micromort"))
          )
        )
      )
    )
  )
}
