#' Generate Quiz Pairs for "Which Is Riskier?" Game
#'
#' Creates candidate question pairs from [common_risks()] for use in
#' an interactive risk comparison quiz. Each pair contains two activities
#' with similar micromort values, making the comparison challenging and
#' educational.
#'
#' @param min_ratio Minimum ratio between micromort values in a pair.
#'   Values above 1.0 exclude identical-risk pairs that are unanswerable.
#'   Default 1.1.
#' @param max_ratio Maximum ratio between micromort values in a pair.
#'   Lower values produce harder questions. Default 2.0.
#' @param prefer_cross_category If `TRUE` (default), pairs from different
#'   risk categories are prioritised over same-category pairs.
#' @param seed Optional random seed for reproducibility.
#'
#' @return A tibble with columns:
#'   - `activity_a`, `micromorts_a`, `category_a`, `hedgeable_pct_a`, `period_a`
#'   - `activity_b`, `micromorts_b`, `category_b`, `hedgeable_pct_b`, `period_b`
#'   - `ratio` (max/min of the two micromort values)
#'   - `answer` ("a" or "b" — whichever activity is riskier)
#'
#' @examples
#' pairs <- quiz_pairs(seed = 42)
#' head(pairs)
#'
#' @export
quiz_pairs <- function(min_ratio = 1.1, max_ratio = 2.0,
                       prefer_cross_category = TRUE, seed = NULL) {
  checkmate::assert_number(min_ratio, lower = 1.0)
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
    period_a = cr$period[idx[1, ]],
    activity_b = cr$activity[idx[2, ]],
    micromorts_b = cr$micromorts[idx[2, ]],
    category_b = cr$category[idx[2, ]],
    hedgeable_pct_b = cr$hedgeable_pct[idx[2, ]],
    period_b = cr$period[idx[2, ]]
  )

  pairs$ratio <- pmax(pairs$micromorts_a / pairs$micromorts_b,
                       pairs$micromorts_b / pairs$micromorts_a)
  pairs <- pairs[pairs$ratio >= min_ratio & pairs$ratio <= max_ratio, ]

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
            "A ", shiny::strong("micromort (mm)"), " is a one-in-a-million ",
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
  left_period <- pair[[paste0("period_", left_side)]]

  right_activity <- pair[[paste0("activity_", right_side)]]
  right_category <- pair[[paste0("category_", right_side)]]
  right_mm <- pair[[paste0("micromorts_", right_side)]]
  right_period <- pair[[paste0("period_", right_side)]]

  # Button styling after reveal
  left_class <- "btn quiz-btn"
  right_class <- "btn quiz-btn"
  left_extra <- ""
  right_extra <- ""

  if (revealed) {
    is_left_riskier <- left_mm > right_mm
    is_right_riskier <- right_mm > left_mm

    chose_left <- !is.na(answer) && answer == left_side
    chose_right <- !is.na(answer) && answer == right_side

    if (is_left_riskier) {
      left_class <- paste(left_class, "quiz-btn-correct")
      right_class <- paste(right_class,
                           if (chose_right) "quiz-btn-wrong" else "quiz-btn-neutral")
    } else if (is_right_riskier) {
      right_class <- paste(right_class, "quiz-btn-correct")
      left_class <- paste(left_class,
                          if (chose_left) "quiz-btn-wrong" else "quiz-btn-neutral")
    } else {
      left_class <- paste(left_class, "quiz-btn-correct")
      right_class <- paste(right_class, "quiz-btn-correct")
    }

    left_extra <- sprintf("%.2f mm", left_mm)
    right_extra <- sprintf("%.2f mm", right_mm)
  }

  make_btn_content <- function(activity, category, period, mm_text) {
    parts <- list(
      shiny::span(class = "activity-name", activity),
      shiny::div(
        shiny::span(class = "badge bg-secondary me-1", category),
        shiny::span(class = "badge bg-info", period)
      )
    )
    if (nzchar(mm_text)) {
      parts <- c(parts, list(
        shiny::strong(mm_text, style = "font-size: 1.2rem; color: #333;")
      ))
    }
    parts
  }

  # Result text
  result_text <- NULL
  if (revealed) {
    user_correct <- !is.na(answer) && answer == correct_answer
    result_text <- if (user_correct) {
      shiny::div(
        class = "alert alert-success text-center mt-2 py-2",
        shiny::strong("Correct!")
      )
    } else {
      riskier <- pair[[paste0("activity_", correct_answer)]]
      shiny::div(
        class = "alert alert-danger text-center mt-2 py-2",
        if (is.na(answer)) "Skipped! " else shiny::tagList(shiny::strong("Incorrect! ")),
        sprintf("%s is riskier.", riskier)
      )
    }
  }

  # Running tally (shown from question 2 onwards)
  answered_so_far <- sum(!is.na(state$answers[seq_len(q - 1L)]) &
    state$revealed[seq_len(q - 1L)])
  correct_so_far <- sum(vapply(seq_len(q - 1L), function(i) {
    !is.na(state$answers[i]) && state$answers[i] == state$pairs$answer[i]
  }, logical(1)))

  tally_ui <- if (q > 1L) {
    shiny::div(class = "text-center mb-1",
      shiny::tags$small(class = "text-muted",
        sprintf("Score: %d/%d correct", correct_so_far, answered_so_far)
      )
    )
  }

  shiny::tagList(
    shiny::h4(
      sprintf("Question %d of %d", q, n),
      class = "text-center text-muted mb-1"
    ),
    tally_ui,
    shiny::div(
      class = "row align-items-center",
      shiny::div(
        class = "col-5",
        if (!revealed) {
          shiny::actionButton(
            "choose_left",
            shiny::tagList(make_btn_content(
              left_activity, left_category, left_period, left_extra
            )),
            class = left_class
          )
        } else {
          shiny::div(
            class = left_class,
            make_btn_content(
              left_activity, left_category, left_period, left_extra
            )
          )
        }
      ),
      shiny::div(
        class = "col-2 text-center",
        shiny::h3("VS", class = "text-muted mb-0")
      ),
      shiny::div(
        class = "col-5",
        if (!revealed) {
          shiny::actionButton(
            "choose_right",
            shiny::tagList(make_btn_content(
              right_activity, right_category, right_period, right_extra
            )),
            class = right_class
          )
        } else {
          shiny::div(
            class = right_class,
            make_btn_content(
              right_activity, right_category, right_period, right_extra
            )
          )
        }
      )
    ),
    result_text,
    shiny::div(
      class = "d-flex justify-content-between mt-3",
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

  result_info <- quiz_result_phrase(pct)

  shiny::tagList(
    shiny::h2("Results", class = "text-center mb-4"),
    shiny::div(
      class = "row mb-4",
      shiny::div(
        class = "col-6",
        bslib::value_box(
          title = "Your Score",
          value = sprintf("%d / %d", score, n),
          showcase = NULL,
          theme = "primary"
        )
      ),
      shiny::div(
        class = "col-6",
        bslib::value_box(
          title = "Random Guessing",
          value = sprintf("~%.1f / %d", baseline, n),
          showcase = NULL,
          theme = "secondary"
        )
      )
    ),
    shiny::div(
      class = "text-center mb-4",
      shiny::h3(result_info$phrase),
      shiny::tags$em(result_info$fact),
      shiny::br(),
      shiny::tags$a(
        href = result_info$link, target = "_blank",
        "Learn more \u2192"
      )
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


quiz_result_phrase <- function(pct) {
  phrases <- list(
    list(min = 95, phrase = "Actuarial genius!",
         fact = "Actuaries quantify risk for a living.",
         link = "https://en.wikipedia.org/wiki/Actuary"),
    list(min = 90, phrase = "You think in micromorts!",
         fact = "A micromort is a one-in-a-million chance of death.",
         link = "https://en.wikipedia.org/wiki/Micromort"),
    list(min = 80, phrase = "Sharp intuition!",
         fact = "Humans tend to overestimate dramatic risks and underestimate common ones.",
         link = "https://en.wikipedia.org/wiki/Risk_perception"),
    list(min = 70, phrase = "Better than a coin toss!",
         fact = "We judge risk by how easily examples come to mind.",
         link = "https://en.wikipedia.org/wiki/Availability_heuristic"),
    list(min = 60, phrase = "Getting there!",
         fact = "Losses loom larger than gains in our risk calculus.",
         link = "https://en.wikipedia.org/wiki/Prospect_theory"),
    list(min = 50, phrase = "About average!",
         fact = "Ignoring base rates is one of the most common reasoning errors.",
         link = "https://en.wikipedia.org/wiki/Base_rate_fallacy"),
    list(min = 30, phrase = "Surprises everywhere!",
         fact = "We tend to assume things will keep going as normal.",
         link = "https://en.wikipedia.org/wiki/Normalcy_bias"),
    list(min = -1, phrase = "Toss a coin \u2014 less risky!",
         fact = "Past outcomes don't change future probabilities.",
         link = "https://en.wikipedia.org/wiki/Gambler%27s_fallacy")
  )
  for (p in phrases) {
    if (pct >= p$min) return(p)
  }
  phrases[[length(phrases)]]
}


quiz_css <- function() {
  "
  .quiz-btn {
    min-height: 180px;
    width: 100%;
    white-space: normal;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 8px;
    padding: 16px 12px;
    font-size: 1rem;
    border: 2px solid #dee2e6;
    border-radius: 8px;
    transition: border-color 0.3s, background-color 0.1s;
  }
  .quiz-btn:hover { border-color: #2c7be5; background-color: #f0f7ff; }
  .quiz-btn .activity-name { font-weight: 600; font-size: 1.1rem; line-height: 1.3; }
  .quiz-btn .badge { font-size: 0.75em; }
  .quiz-btn-correct {
    border: 3px solid #198754 !important;
    background-color: #d1e7dd !important;
  }
  .quiz-btn-wrong {
    border: 3px solid #dc3545 !important;
    background-color: #f8d7da !important;
  }
  .quiz-btn-neutral {
    border: 3px solid #6c757d !important;
    background-color: #e9ecef !important;
  }
  .gap-3 { gap: 1rem; }
  "
}
