#' Generate Quiz Pairs for "Which Is Riskier?" Game
#'
#' Creates candidate question pairs from [common_risks()] for use in
#' an interactive risk comparison quiz. Each pair contains two activities
#' with similar micromort values, making the comparison challenging and
#' educational.
#'
#' @param max_ratio Maximum ratio between micromort values in a pair.
#'   Lower values produce harder questions. Default 2.0.
#' @param prefer_cross_category If `TRUE` (default), pairs from different
#'   risk categories are prioritised over same-category pairs.
#' @param seed Optional random seed for reproducibility.
#'
#' @return A tibble with columns:
#'   - `activity_a`, `micromorts_a`, `category_a`, `hedgeable_pct_a`
#'   - `activity_b`, `micromorts_b`, `category_b`, `hedgeable_pct_b`
#'   - `ratio` (max/min of the two micromort values)
#'   - `answer` ("a" or "b" — whichever activity is riskier)
#'
#' @examples
#' pairs <- quiz_pairs(seed = 42)
#' head(pairs)
#'
#' @export
quiz_pairs <- function(max_ratio = 2.0, prefer_cross_category = TRUE,
                       seed = NULL) {
  checkmate::assert_number(max_ratio, lower = 1.0)
  checkmate::assert_flag(prefer_cross_category)
  checkmate::assert_int(seed, null.ok = TRUE)

  if (!is.null(seed)) set.seed(seed)

  cr <- common_risks()
  cr <- cr[cr$micromorts > 0, ]

  n <- nrow(cr)
  idx <- utils::combn(n, 2)

  pairs <- tibble::tibble(
    activity_a = cr$activity[idx[1, ]],
    micromorts_a = cr$micromorts[idx[1, ]],
    category_a = cr$category[idx[1, ]],
    hedgeable_pct_a = cr$hedgeable_pct[idx[1, ]],
    activity_b = cr$activity[idx[2, ]],
    micromorts_b = cr$micromorts[idx[2, ]],
    category_b = cr$category[idx[2, ]],
    hedgeable_pct_b = cr$hedgeable_pct[idx[2, ]]
  )

  pairs$ratio <- pmax(pairs$micromorts_a / pairs$micromorts_b,
                       pairs$micromorts_b / pairs$micromorts_a)
  pairs <- pairs[pairs$ratio <= max_ratio, ]

  pairs$cross_category <- pairs$category_a != pairs$category_b

  if (prefer_cross_category) {
    pairs <- pairs[order(!pairs$cross_category, pairs$ratio), ]
  } else {
    pairs <- pairs[order(pairs$ratio), ]
  }

  # Greedy select: each activity at most 3 times
  selected <- logical(nrow(pairs))
  activity_counts <- list()
  max_pairs <- 50L

  for (i in seq_len(nrow(pairs))) {
    if (sum(selected) >= max_pairs) break
    a <- pairs$activity_a[i]
    b <- pairs$activity_b[i]
    count_a <- if (is.null(activity_counts[[a]])) 0L else activity_counts[[a]]
    count_b <- if (is.null(activity_counts[[b]])) 0L else activity_counts[[b]]

    if (count_a < 3L && count_b < 3L) {
      selected[i] <- TRUE
      activity_counts[[a]] <- count_a + 1L
      activity_counts[[b]] <- count_b + 1L
    }
  }

  pairs <- pairs[selected, ]

  # Set answer
  pairs$answer <- ifelse(
    pairs$micromorts_a >= pairs$micromorts_b, "a", "b"
  )

  # Shuffle order
  pairs <- pairs[sample(nrow(pairs)), ]

  pairs$cross_category <- NULL
  tibble::as_tibble(pairs)
}


#' Launch Interactive "Which Is Riskier?" Quiz
#'
#' A standalone Shiny app where users compare pairs of risky activities
#' and guess which carries more micromort risk. Built with bslib cards
#' for a modern UI.
#'
#' @param n_pairs Number of question pairs to offer as options (5 or 10).
#'   If `NULL` (default), the user chooses on the instructions page.
#' @param ... Additional arguments passed to [shiny::shinyApp()].
#'
#' @return A Shiny app object (runs interactively).
#'
#' @examples
#' if (interactive()) {
#'   launch_quiz()
#' }
#'
#' @export
launch_quiz <- function(n_pairs = NULL, ...) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "{.pkg shiny} is required for {.fn launch_quiz}.",
      "i" = "Install it with {.code install.packages('shiny')}"
    ))
  }
  if (!requireNamespace("bslib", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "{.pkg bslib} is required for {.fn launch_quiz}.",
      "i" = "Install it with {.code install.packages('bslib')}"
    ))
  }

  ui <- quiz_ui()
  server <- quiz_server(n_pairs = n_pairs)
  shiny::shinyApp(ui = ui, server = server, ...)
}


# ---- Internal UI ----

quiz_ui <- function() {
  bslib::page_fluid(
    theme = bslib::bs_theme(bootswatch = "flatly", version = 5),
    shiny::tags$head(shiny::tags$style(shiny::HTML(quiz_css()))),
    shiny::div(
      class = "container",
      style = "max-width: 800px; margin: auto; padding-top: 20px;",
      shiny::uiOutput("main_ui")
    )
  )
}


quiz_server <- function(n_pairs = NULL) {
  function(input, output, session) {
    state <- shiny::reactiveValues(
      phase = "instructions",
      n_questions = if (!is.null(n_pairs)) n_pairs else 10L,
      current_q = 1L,
      pairs = NULL,
      answers = NULL,
      display_order = NULL,
      revealed = NULL
    )

    # ---- Instructions ----
    shiny::observeEvent(input$start_quiz, {
      n <- as.integer(input$n_questions %||% state$n_questions)
      pool <- quiz_pairs(seed = NULL)
      n <- min(n, nrow(pool))
      state$n_questions <- n
      state$pairs <- pool[sample(nrow(pool), n), ]
      state$answers <- rep(NA_character_, n)
      state$display_order <- lapply(seq_len(n), function(i) sample(c("a", "b")))
      state$revealed <- rep(FALSE, n)
      state$current_q <- 1L
      state$phase <- "question"
    })

    # ---- Answer buttons ----
    shiny::observeEvent(input$choose_left, {
      q <- state$current_q
      state$answers[q] <- state$display_order[[q]][1]
      state$revealed[q] <- TRUE
    })

    shiny::observeEvent(input$choose_right, {
      q <- state$current_q
      state$answers[q] <- state$display_order[[q]][2]
      state$revealed[q] <- TRUE
    })

    # ---- Navigation ----
    shiny::observeEvent(input$next_q, {
      if (state$current_q < state$n_questions) {
        state$current_q <- state$current_q + 1L
      } else {
        state$phase <- "results_summary"
      }
    })

    shiny::observeEvent(input$prev_q, {
      if (state$current_q > 1L) {
        state$current_q <- state$current_q - 1L
      }
    })

    shiny::observeEvent(input$view_details, {
      state$phase <- "results_detail"
    })

    shiny::observeEvent(input$back_to_summary, {
      state$phase <- "results_summary"
    })

    shiny::observeEvent(input$try_again, {
      state$phase <- "instructions"
    })

    # ---- Render main UI ----
    output$main_ui <- shiny::renderUI({
      switch(state$phase,
        instructions = instructions_ui(n_pairs),
        question = question_ui(state),
        results_summary = results_summary_ui(state),
        results_detail = results_detail_ui(state)
      )
    })
  }
}


# ---- Page builders ----

instructions_ui <- function(n_pairs = NULL) {
  shiny::tagList(
    shiny::h2("Which Is Riskier?", class = "text-center mb-4"),
    bslib::card(
      bslib::card_body(
        shiny::tags$ul(
          shiny::tags$li(
            "A ", shiny::strong("micromort"), " is a one-in-a-million ",
            "chance of death."
          ),
          shiny::tags$li(
            "You face some of these risks every day \u2014 ",
            "do you know which ones are bigger?"
          ),
          shiny::tags$li(
            "Each question shows two activities \u2014 ",
            "guess which carries more risk."
          ),
          shiny::tags$li(
            "You can ", shiny::strong("skip"), " questions or go ",
            shiny::strong("back"), " and change answers."
          ),
          shiny::tags$li(
            "Skipped (unanswered) questions score zero."
          )
        ),
        if (is.null(n_pairs)) {
          shiny::radioButtons(
            "n_questions", "Number of questions:",
            choices = c("5" = 5, "10" = 10),
            selected = 10, inline = TRUE
          )
        },
        shiny::div(
          class = "text-center mt-3",
          shiny::actionButton(
            "start_quiz", "Start Quiz",
            class = "btn-primary btn-lg"
          )
        )
      )
    )
  )
}


question_ui <- function(state) {
  q <- state$current_q
  n <- state$n_questions
  pair <- state$pairs[q, ]
  ord <- state$display_order[[q]]
  revealed <- state$revealed[q]
  answer <- state$answers[q]
  correct_answer <- pair$answer

  left_side <- ord[1]
  right_side <- ord[2]

  left_activity <- pair[[paste0("activity_", left_side)]]
  left_category <- pair[[paste0("category_", left_side)]]
  left_mm <- pair[[paste0("micromorts_", left_side)]]


  right_activity <- pair[[paste0("activity_", right_side)]]
  right_category <- pair[[paste0("category_", right_side)]]
  right_mm <- pair[[paste0("micromorts_", right_side)]]

  # Card styling based on reveal state
  left_border <- ""
  right_border <- ""
  if (revealed) {
    is_left_riskier <- left_mm >= right_mm
    left_border <- if (is_left_riskier) "border-success" else "border-danger"
    right_border <- if (!is_left_riskier) "border-success" else "border-danger"
  }

  # Result text
  result_text <- NULL
  if (revealed) {
    user_correct <- !is.na(answer) && answer == correct_answer
    result_text <- if (user_correct) {
      shiny::div(
        class = "alert alert-success text-center mt-3",
        shiny::strong("Correct!"),
        sprintf(
          " %s (%.2f mm) vs %s (%.2f mm)",
          pair[[paste0("activity_", correct_answer)]],
          pair[[paste0("micromorts_", correct_answer)]],
          pair[[paste0("activity_", if (correct_answer == "a") "b" else "a")]],
          pair[[paste0("micromorts_", if (correct_answer == "a") "b" else "a")]]
        )
      )
    } else {
      shiny::div(
        class = "alert alert-danger text-center mt-3",
        if (is.na(answer)) "Skipped! " else shiny::tagList(shiny::strong("Incorrect! ")),
        sprintf(
          "%s (%.2f mm) is riskier than %s (%.2f mm)",
          pair[[paste0("activity_", correct_answer)]],
          pair[[paste0("micromorts_", correct_answer)]],
          pair[[paste0("activity_", if (correct_answer == "a") "b" else "a")]],
          pair[[paste0("micromorts_", if (correct_answer == "a") "b" else "a")]]
        )
      )
    }
  }

  shiny::tagList(
    shiny::h4(
      sprintf("Question %d of %d", q, n),
      class = "text-center text-muted mb-3"
    ),
    shiny::div(
      class = "row",
      shiny::div(
        class = "col-5",
        bslib::card(
          class = left_border,
          bslib::card_header(
            class = "text-center",
            shiny::h5(left_activity),
            shiny::span(class = "badge bg-secondary", left_category)
          ),
          if (revealed) {
            bslib::card_body(
              class = "text-center",
              shiny::h4(sprintf("%.2f mm", left_mm))
            )
          }
        )
      ),
      shiny::div(
        class = "col-2 d-flex align-items-center justify-content-center",
        shiny::h3("VS", class = "text-muted")
      ),
      shiny::div(
        class = "col-5",
        bslib::card(
          class = right_border,
          bslib::card_header(
            class = "text-center",
            shiny::h5(right_activity),
            shiny::span(class = "badge bg-secondary", right_category)
          ),
          if (revealed) {
            bslib::card_body(
              class = "text-center",
              shiny::h4(sprintf("%.2f mm", right_mm))
            )
          }
        )
      )
    ),
    if (!revealed) {
      shiny::div(
        class = "row mt-3",
        shiny::div(
          class = "col-5 text-center",
          shiny::actionButton(
            "choose_left",
            paste0("\u2190 ", left_activity, " is riskier"),
            class = "btn-outline-primary btn-sm",
            style = "white-space: normal; width: 100%;"
          )
        ),
        shiny::div(class = "col-2"),
        shiny::div(
          class = "col-5 text-center",
          shiny::actionButton(
            "choose_right",
            paste0(right_activity, " is riskier \u2192"),
            class = "btn-outline-primary btn-sm",
            style = "white-space: normal; width: 100%;"
          )
        )
      )
    },
    result_text,
    shiny::div(
      class = "d-flex justify-content-between mt-4",
      shiny::actionButton(
        "prev_q", "\u2190 Back",
        class = if (q == 1L) "btn-secondary disabled" else "btn-secondary"
      ),
      shiny::actionButton(
        "next_q",
        if (q == n) "Finish" else "Next \u2192",
        class = "btn-primary"
      )
    )
  )
}


results_summary_ui <- function(state) {
  pairs <- state$pairs
  answers <- state$answers
  n <- state$n_questions

  correct <- vapply(seq_len(n), function(i) {
    !is.na(answers[i]) && answers[i] == pairs$answer[i]
  }, logical(1))
  score <- sum(correct)
  pct <- score / n * 100

  # Random baseline (not always 50% since ratios vary)
  baseline <- n / 2

  rating <- if (pct >= 90) {
    "Risk Expert!"
  } else if (pct >= 70) {
    "Sharp Intuition!"
  } else if (pct >= 50) {
    "Getting There!"
  } else {
    "Surprising, isn't it?"
  }

  shiny::tagList(
    shiny::h2("Results", class = "text-center mb-4"),
    shiny::div(
      class = "row mb-4",
      shiny::div(
        class = "col-6",
        bslib::value_box(
          title = "Your Score",
          value = sprintf("%d / %d", score, n),
          theme = "primary"
        )
      ),
      shiny::div(
        class = "col-6",
        bslib::value_box(
          title = "Random Guessing",
          value = sprintf("~%.1f / %d", baseline, n),
          theme = "secondary"
        )
      )
    ),
    shiny::div(
      class = "text-center mb-4",
      shiny::h3(rating)
    ),
    shiny::div(
      class = "d-flex justify-content-center gap-3",
      shiny::actionButton(
        "view_details", "View Details",
        class = "btn-outline-primary btn-lg"
      ),
      shiny::actionButton(
        "try_again", "Try Again",
        class = "btn-primary btn-lg"
      )
    )
  )
}


results_detail_ui <- function(state) {
  pairs <- state$pairs
  answers <- state$answers
  n <- state$n_questions

  detail <- tibble::tibble(
    Q = seq_len(n),
    `Activity A` = pairs$activity_a,
    `Activity B` = pairs$activity_b,
    `Your Answer` = ifelse(
      is.na(answers), "Skipped",
      ifelse(answers == "a", pairs$activity_a, pairs$activity_b)
    ),
    `Correct Answer` = ifelse(
      pairs$answer == "a", pairs$activity_a, pairs$activity_b
    ),
    Result = ifelse(
      is.na(answers), "\u2014",
      ifelse(answers == pairs$answer, "\u2713", "\u2717")
    ),
    `mm A` = round(pairs$micromorts_a, 2),
    `mm B` = round(pairs$micromorts_b, 2),
    Ratio = round(pairs$ratio, 2),
    `Fun Fact` = vapply(seq_len(n), function(i) {
      ha <- pairs$hedgeable_pct_a[i]
      hb <- pairs$hedgeable_pct_b[i]
      cross <- pairs$category_a[i] != pairs$category_b[i]
      if (ha > 0 && hb > 0) {
        "Both risks have hedgeable components"
      } else if (ha > 0) {
        paste0(pairs$activity_a[i], " is partly hedgeable \u2014 you can reduce this risk!")
      } else if (hb > 0) {
        paste0(pairs$activity_b[i], " is partly hedgeable \u2014 you can reduce this risk!")
      } else if (cross) {
        "Different domains but nearly identical risk"
      } else {
        "Neither risk is hedgeable"
      }
    }, character(1))
  )

  shiny::tagList(
    shiny::h3("Question-by-Question Detail", class = "text-center mb-4"),
    if (requireNamespace("DT", quietly = TRUE)) {
      DT::DTOutput("detail_table")
    } else {
      shiny::tableOutput("detail_table_basic")
    },
    shiny::div(
      class = "text-center mt-4",
      shiny::actionButton(
        "back_to_summary", "\u2190 Back to Summary",
        class = "btn-secondary btn-lg"
      )
    )
  )
}


quiz_css <- function() {
  "
  .card { transition: border-color 0.3s; }
  .border-success { border: 3px solid #198754 !important; }
  .border-danger { border: 3px solid #dc3545 !important; }
  .badge { font-size: 0.8em; }
  .gap-3 { gap: 1rem; }
  "
}
