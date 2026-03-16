# ---- Difficulty assignment ----

#' Assign difficulty labels based on ratio terciles
#'
#' Low ratios are hard (activities close in risk), high ratios are easy.
#' @param ratios Numeric vector of risk ratios.
#' @return Character vector of `"hard"`, `"medium"`, or `"easy"`.
#' @noRd
assign_difficulty <- function(ratios) {
  breaks <- stats::quantile(ratios, probs = c(0, 1 / 3, 2 / 3, 1))
  breaks <- unique(breaks)
  if (length(breaks) < 4) return(rep("mixed", length(ratios)))
  as.character(cut(
    ratios, breaks, include.lowest = TRUE,
    labels = c("hard", "medium", "easy")
  ))
}


#' Generate Quiz Pairs for "Which Is Riskier?" Game
#'
#' Creates candidate question pairs from [common_risks()] for use in
#' an interactive risk comparison quiz. Each pair contains two activities
#' with similar micromort values, making the comparison challenging and
#' educational.
#'
#' @param min_ratio Minimum ratio between micromort values in a pair.
#'   Values above 1.0 exclude identical-risk pairs that are unanswerable.
#'   Default 1.1. Ignored when `difficulty` is non-NULL.
#' @param max_ratio Maximum ratio between micromort values in a pair.
#'   Lower values produce harder questions. Default 2.0. Ignored when
#'   `difficulty` is non-NULL.
#' @param prefer_cross_category If `TRUE` (default), pairs from different
#'   risk categories are prioritised over same-category pairs.
#' @param seed Optional random seed for reproducibility.
#' @param difficulty Optional difficulty level. One of `"easy"`, `"medium"`,
#'   `"hard"`, or `"mixed"`. When non-NULL, overrides `min_ratio` and
#'   `max_ratio` to use the full pool (ratios 1.5--10) and assigns difficulty
#'
#'   based on data-driven terciles:
#'   - **hard**: lowest third of ratios (hardest to distinguish)
#'   - **medium**: middle third
#'   - **easy**: highest third (easiest to distinguish)
#'   - **mixed**: samples equally from all three tiers
#'
#'   When `NULL` (default), the original `min_ratio`/`max_ratio` behaviour
#'   is preserved and no `difficulty` column is added.
#'
#' @return A tibble with columns:
#'   - `activity_a`, `micromorts_a`, `category_a`, `hedgeable_pct_a`, `period_a`
#'   - `activity_b`, `micromorts_b`, `category_b`, `hedgeable_pct_b`, `period_b`
#'   - `description_a`, `help_url_a`, `description_b`, `help_url_b`
#'   - `ratio` (max/min of the two micromort values)
#'   - `answer` ("a" or "b" — whichever activity is riskier)
#'   - `difficulty` (only when `difficulty` is non-NULL)
#'
#' @examples
#' pairs <- quiz_pairs(seed = 42)
#' head(pairs)
#'
#' # Easy questions (large ratio differences)
#' easy <- quiz_pairs(difficulty = "easy", seed = 42)
#' head(easy)
#'
#' @export
quiz_pairs <- function(min_ratio = 1.1, max_ratio = 2.0,
                       prefer_cross_category = TRUE, seed = NULL,
                       difficulty = NULL) {
  checkmate::assert_number(min_ratio, lower = 1.0)
  checkmate::assert_number(max_ratio, lower = 1.0)
  checkmate::assert_flag(prefer_cross_category)
  checkmate::assert_int(seed, null.ok = TRUE)
  checkmate::assert_choice(difficulty, c("easy", "medium", "hard", "mixed"),
                           null.ok = TRUE)

  # When difficulty is set, use wider ratio pool

  if (!is.null(difficulty)) {
    min_ratio <- 1.5
    max_ratio <- 10
  }

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

  # Assign difficulty tiers when requested
  if (!is.null(difficulty)) {
    pairs$difficulty <- assign_difficulty(pairs$ratio)
    if (difficulty != "mixed") {
      pairs <- pairs[pairs$difficulty == difficulty, ]
    }
  }

  pairs$cross_category <- pairs$category_a != pairs$category_b

  if (!is.null(difficulty) && difficulty == "mixed") {
    # Round-robin interleave tiers for equal representation
    tiers <- split(pairs, pairs$difficulty)
    tiers <- lapply(tiers, function(t) {
      if (prefer_cross_category) {
        t[order(!t$cross_category, t$ratio), ]
      } else {
        t[order(t$ratio), ]
      }
    })
    max_rows <- max(vapply(tiers, nrow, integer(1)))
    indices <- lapply(tiers, function(t) seq_len(nrow(t)))
    interleaved <- list()
    for (i in seq_len(max_rows)) {
      for (nm in names(tiers)) {
        if (i <= nrow(tiers[[nm]])) {
          interleaved <- c(interleaved, list(tiers[[nm]][i, ]))
        }
      }
    }
    pairs <- do.call(rbind, interleaved)
  } else if (prefer_cross_category) {
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

  # Remove difficulty column for legacy mode (NULL difficulty)
  # Keep it when difficulty is explicitly requested
  if (is.null(difficulty) && "difficulty" %in% names(pairs)) {
    pairs$difficulty <- NULL
  }

  # Join activity descriptions for tooltips and explanations
  desc <- activity_descriptions()
  desc_a <- desc
  names(desc_a) <- c("activity_a", "description_a", "help_url_a")
  desc_b <- desc
  names(desc_b) <- c("activity_b", "description_b", "help_url_b")
  pairs <- merge(pairs, desc_a, by = "activity_a", all.x = TRUE)
  pairs <- merge(pairs, desc_b, by = "activity_b", all.x = TRUE)

  tibble::as_tibble(pairs)
}


#' Generate Quiz Pairs for "Which Daily Habit Has a Bigger Effect?" Game
#'
#' Creates candidate question pairs from [chronic_risks()] for use in an
#' interactive microlife comparison quiz. Each pair contains two chronic
#' lifestyle factors, and the player guesses which has the larger absolute
#' effect on life expectancy (in microlives per day).
#'
#' @param min_ratio Minimum ratio between absolute microlife values in a pair.
#'   Default 1.1. Ignored when `difficulty` is non-NULL.
#' @param max_ratio Maximum ratio. Default 2.0. Ignored when `difficulty` is
#'   non-NULL.
#' @param prefer_cross_category If `TRUE` (default), pairs from different
#'   categories are prioritised.
#' @param seed Optional random seed for reproducibility.
#' @param difficulty Optional difficulty level. One of `"easy"`, `"medium"`,
#'   `"hard"`, or `"mixed"`. When non-NULL, overrides `min_ratio`/`max_ratio`
#'   to use the full pool (ratios 1.5--10) and assigns difficulty via
#'   data-driven terciles.
#'
#' @return A tibble with columns:
#'   - `factor_a`, `microlives_a`, `direction_a`, `category_a`,
#'     `description_a`, `help_url_a`, `annual_days_a`
#'   - `factor_b`, `microlives_b`, `direction_b`, `category_b`,
#'     `description_b`, `help_url_b`, `annual_days_b`
#'   - `ratio` (max/min of absolute microlife values)
#'   - `answer` ("a" or "b" -- whichever factor has the larger absolute effect)
#'   - `difficulty` (only when `difficulty` is non-NULL)
#'
#' @examples
#' pairs <- chronic_quiz_pairs(seed = 42)
#' head(pairs)
#'
#' easy <- chronic_quiz_pairs(difficulty = "easy", seed = 42)
#' head(easy)
#'
#' @export
chronic_quiz_pairs <- function(min_ratio = 1.1, max_ratio = 2.0,
                                prefer_cross_category = TRUE, seed = NULL,
                                difficulty = NULL) {
  checkmate::assert_number(min_ratio, lower = 1.0)
  checkmate::assert_number(max_ratio, lower = 1.0)
  checkmate::assert_flag(prefer_cross_category)
  checkmate::assert_int(seed, null.ok = TRUE)
  checkmate::assert_choice(difficulty, c("easy", "medium", "hard", "mixed"),
                           null.ok = TRUE)

  if (!is.null(difficulty)) {
    min_ratio <- 1.5
    max_ratio <- 10
  }

  if (!is.null(seed)) set.seed(seed)

  cr <- chronic_risks()
  # Exclude extreme outliers that make pairs too obvious
  cr <- cr[abs(cr$microlives_per_day) <= 10, ]

  n <- nrow(cr)
  idx <- utils::combn(n, 2)

  abs_a <- abs(cr$microlives_per_day[idx[1, ]])
  abs_b <- abs(cr$microlives_per_day[idx[2, ]])

  pairs <- tibble::tibble(
    factor_a = cr$factor[idx[1, ]],
    microlives_a = cr$microlives_per_day[idx[1, ]],
    direction_a = cr$direction[idx[1, ]],
    category_a = cr$category[idx[1, ]],
    annual_days_a = cr$annual_effect_days[idx[1, ]],
    factor_b = cr$factor[idx[2, ]],
    microlives_b = cr$microlives_per_day[idx[2, ]],
    direction_b = cr$direction[idx[2, ]],
    category_b = cr$category[idx[2, ]],
    annual_days_b = cr$annual_effect_days[idx[2, ]]
  )

  pairs$ratio <- pmax(abs_a, abs_b) / pmin(abs_a, abs_b)
  # Drop unanswerable pairs where both have equal absolute value
  pairs <- pairs[is.finite(pairs$ratio), ]
  pairs <- pairs[pairs$ratio >= min_ratio & pairs$ratio <= max_ratio, ]

  if (nrow(pairs) == 0) {
    return(tibble::tibble())
  }

  # Assign difficulty tiers when requested
  if (!is.null(difficulty)) {
    pairs$difficulty <- assign_difficulty(pairs$ratio)
    if (difficulty != "mixed") {
      pairs <- pairs[pairs$difficulty == difficulty, ]
    }
  }

  pairs$cross_category <- pairs$category_a != pairs$category_b

  if (!is.null(difficulty) && difficulty == "mixed") {
    tiers <- split(pairs, pairs$difficulty)
    tiers <- lapply(tiers, function(t) {
      if (prefer_cross_category) {
        t[order(!t$cross_category, t$ratio), ]
      } else {
        t[order(t$ratio), ]
      }
    })
    max_rows <- max(vapply(tiers, nrow, integer(1)))
    interleaved <- list()
    for (i in seq_len(max_rows)) {
      for (nm in names(tiers)) {
        if (i <= nrow(tiers[[nm]])) {
          interleaved <- c(interleaved, list(tiers[[nm]][i, ]))
        }
      }
    }
    pairs <- do.call(rbind, interleaved)
  } else if (prefer_cross_category) {
    pairs <- pairs[order(!pairs$cross_category, pairs$ratio), ]
  } else {
    pairs <- pairs[order(pairs$ratio), ]
  }

  # Greedy select: each factor at most 3 times
  selected <- logical(nrow(pairs))
  factor_counts <- list()
  max_pairs <- 50L

  for (i in seq_len(nrow(pairs))) {
    if (sum(selected) >= max_pairs) break
    a <- pairs$factor_a[i]
    b <- pairs$factor_b[i]
    count_a <- if (is.null(factor_counts[[a]])) 0L else factor_counts[[a]]
    count_b <- if (is.null(factor_counts[[b]])) 0L else factor_counts[[b]]

    if (count_a < 3L && count_b < 3L) {
      selected[i] <- TRUE
      factor_counts[[a]] <- count_a + 1L
      factor_counts[[b]] <- count_b + 1L
    }
  }

  pairs <- pairs[selected, ]

  # Answer: whichever factor has larger absolute microlife effect
  pairs$answer <- ifelse(
    abs(pairs$microlives_a) >= abs(pairs$microlives_b), "a", "b"
  )

  # Shuffle order
  pairs <- pairs[sample(nrow(pairs)), ]

  pairs$cross_category <- NULL

  if (is.null(difficulty) && "difficulty" %in% names(pairs)) {
    pairs$difficulty <- NULL
  }

  # Join factor descriptions for tooltips
  desc <- factor_descriptions()
  desc_a <- desc
  names(desc_a) <- c("factor_a", "description_a", "help_url_a")
  desc_b <- desc
  names(desc_b) <- c("factor_b", "description_b", "help_url_b")
  pairs <- merge(pairs, desc_a, by = "factor_a", all.x = TRUE)
  pairs <- merge(pairs, desc_b, by = "factor_b", all.x = TRUE)

  tibble::as_tibble(pairs)
}


#' Format Activity Name with Line Break Before Parenthetical
#'
#' Inserts an HTML `<br>` before the first opening parenthesis in an activity
#' name, making quiz buttons more readable by separating the qualifier.
#'
#' @param name Character string. The activity name to format.
#' @return A [shiny::HTML()] object with `<br>` inserted before `(`, or the
#'   original string wrapped in `HTML()` if no parenthesis is present.
#'
#' @examples
#' format_activity_name("airline pilot (annual radiation)")
#' format_activity_name("Skydiving")
#'
#' @export
format_activity_name <- function(name) {
  formatted <- sub("\\s*\\(", "<br>(", name)
  shiny::HTML(formatted)
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

quiz_title_ui <- function() {
  shiny::h3(
    "Which lifestyle event is more likely to kill you?",
    class = "text-center mb-3 quiz-title"
  )
}

quiz_ui <- function() {
  bslib::page_fluid(
    theme = bslib::bs_theme(bootswatch = "flatly", version = 5),
    shiny::tags$head(
      shiny::tags$style(shiny::HTML(quiz_css())),
      shiny::tags$script(shiny::HTML(leaderboard_js()))
    ),
    shiny::div(
      class = "container",
      style = "width: 95%; max-width: 100%; margin: auto; padding-top: 20px;",
      quiz_title_ui(),
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
      diff <- input$difficulty
      pool <- quiz_pairs(seed = NULL, difficulty = diff)
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
      } else {
        state$phase <- "instructions"
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

    shiny::observeEvent(input$try_again_detail, {
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

quiz_encouragement_lines <- function() {
  c(
    "Go on, your inner actuary is dying to play. (Not literally.)",
    "Warning: may cause sudden urge to recalculate your commute.",
    "Spoiler: everything is riskier than you think.",
    "No micromorts were harmed in the making of this quiz.",
    "Side effects may include newfound respect for seatbelts.",
    "Think you know risk? Prove it.",
    "Your overconfidence is showing. Let's test it.",
    "Statistically, you'll enjoy this. Probably."
  )
}

instructions_ui <- function(n_pairs = NULL) {
  encouragement <- sample(quiz_encouragement_lines(), 1L)

  shiny::tagList(
    shiny::h4("Hints", class = "text-center mb-3"),
    bslib::card(
      bslib::card_body(
        shiny::tags$ul(
          shiny::tags$li(
            "Each question shows two risky activities."
          ),
          shiny::tags$li(
            "Tap the activity that you think is ", shiny::strong("riskier"), "."
          ),
          shiny::tags$li(
            "You can ", shiny::strong("skip"), " questions or go ",
            shiny::strong("back"), " and review previous answers."
          ),
          shiny::tags$li(
            "Skipped (unanswered) questions score zero."
          ),
          shiny::tags$li(
            "A ", shiny::strong("micromort (mm)"), " is a one-in-a-million ",
            "chance of death."
          )
        ),
        shiny::div(
          class = "text-center mt-2 mb-3",
          shiny::tags$em(encouragement)
        ),
        shiny::radioButtons(
          "difficulty", "Difficulty:",
          choices = c("Easy" = "easy", "Medium" = "medium",
                      "Hard" = "hard", "Mixed" = "mixed"),
          selected = "mixed", inline = TRUE
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
  left_desc <- pair[[paste0("description_", left_side)]]
  left_help <- pair[[paste0("help_url_", left_side)]]

  right_activity <- pair[[paste0("activity_", right_side)]]
  right_category <- pair[[paste0("category_", right_side)]]
  right_mm <- pair[[paste0("micromorts_", right_side)]]
  right_period <- pair[[paste0("period_", right_side)]]
  right_desc <- pair[[paste0("description_", right_side)]]
  right_help <- pair[[paste0("help_url_", right_side)]]

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

  make_btn_content <- function(activity, category, period, mm_text,
                               description = NULL, help_url = NULL) {
    # Activity name with tooltip
    name_el <- shiny::span(class = "activity-name", format_activity_name(activity))
    if (!is.null(description) && nzchar(description)) {
      name_el <- shiny::tagList(
        name_el,
        bslib::tooltip(
          shiny::span(class = "help-icon", "\u24d8"),
          description
        )
      )
    }
    parts <- list(
      name_el,
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
    if (!is.null(help_url) && nzchar(help_url)) {
      parts <- c(parts, list(
        shiny::tags$a(
          class = "help-link", href = help_url, target = "_blank",
          onclick = "event.stopPropagation();",
          "Learn more \u2192"
        )
      ))
    }
    parts
  }

  # Result text
  result_text <- NULL
  explanation_panel <- NULL
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

    # Explanation panel
    ratio_text <- sprintf("%.1f", pair$ratio)
    riskier_side <- pair$answer
    safer_side <- if (riskier_side == "a") "b" else "a"
    hedge_a <- pair$hedgeable_pct_a
    hedge_b <- pair$hedgeable_pct_b

    explanation_panel <- bslib::card(
      class = "explanation-panel mt-2",
      bslib::card_body(
        shiny::tags$p(
          shiny::strong(pair[[paste0("activity_", riskier_side)]]),
          sprintf(" has %.2f mm: ", pair[[paste0("micromorts_", riskier_side)]]),
          pair[[paste0("description_", riskier_side)]]
        ),
        shiny::tags$p(
          shiny::strong(pair[[paste0("activity_", safer_side)]]),
          sprintf(" has %.2f mm: ", pair[[paste0("micromorts_", safer_side)]]),
          pair[[paste0("description_", safer_side)]]
        ),
        shiny::tags$p(
          sprintf(
            "%s is %sx riskier than %s.",
            pair[[paste0("activity_", riskier_side)]],
            ratio_text,
            pair[[paste0("activity_", safer_side)]]
          )
        ),
        if (hedge_a > 0 || hedge_b > 0) {
          hedgeable_parts <- character(0)
          if (hedge_a > 0) {
            hedgeable_parts <- c(hedgeable_parts,
              sprintf("%s is %.0f%% hedgeable", pair$activity_a, hedge_a))
          }
          if (hedge_b > 0) {
            hedgeable_parts <- c(hedgeable_parts,
              sprintf("%s is %.0f%% hedgeable", pair$activity_b, hedge_b))
          }
          shiny::tags$p(
            shiny::tags$em(paste(hedgeable_parts, collapse = "; "),
                           " \u2014 you can reduce this risk!")
          )
        },
        shiny::tags$p(
          class = "mb-0",
          "Learn more: ",
          shiny::tags$a(
            href = pair[[paste0("help_url_", riskier_side)]],
            target = "_blank", pair[[paste0("activity_", riskier_side)]]
          ),
          " | ",
          shiny::tags$a(
            href = pair[[paste0("help_url_", safer_side)]],
            target = "_blank", pair[[paste0("activity_", safer_side)]]
          )
        )
      )
    )
  }

  # Running tally (shown from question 1)
  answered_so_far <- sum(!is.na(state$answers[seq_len(q - 1L)]) &
    state$revealed[seq_len(q - 1L)])
  correct_so_far <- sum(vapply(seq_len(q - 1L), function(i) {
    !is.na(state$answers[i]) && state$answers[i] == state$pairs$answer[i]
  }, logical(1)))

  tally_text <- sprintf("Score: %d/%d correct", correct_so_far, answered_so_far)

  # Top navigation row: [Back] ... [N of M · Score] ... [Next]
  nav_ui <- shiny::div(
    class = "d-flex justify-content-between align-items-center mb-3",
    shiny::actionButton(
      "prev_q", "\u2190 Back",
      class = "btn-secondary"
    ),
    shiny::span(
      class = "text-muted",
      if ("difficulty" %in% names(pair) && !is.na(pair$difficulty)) {
        diff_colors <- c(easy = "success", medium = "warning", hard = "danger")
        shiny::span(
          class = paste0("badge bg-", diff_colors[pair$difficulty], " me-2"),
          pair$difficulty
        )
      },
      sprintf("%d of %d", q, n),
      " \u00b7 ",
      shiny::tags$small(tally_text)
    ),
    shiny::actionButton(
      "next_q",
      if (q == n) "Finish" else "Next \u2192",
      class = "btn-primary"
    )
  )

  shiny::tagList(
    nav_ui,
    shiny::div(
      class = "row align-items-center",
      shiny::div(
        class = "col-5",
        if (!revealed) {
          shiny::actionButton(
            "choose_left",
            shiny::tagList(make_btn_content(
              left_activity, left_category, left_period, left_extra,
              left_desc, left_help
            )),
            class = left_class
          )
        } else {
          shiny::div(
            class = left_class,
            make_btn_content(
              left_activity, left_category, left_period, left_extra,
              left_desc, left_help
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
              right_activity, right_category, right_period, right_extra,
              right_desc, right_help
            )),
            class = right_class
          )
        } else {
          shiny::div(
            class = right_class,
            make_btn_content(
              right_activity, right_category, right_period, right_extra,
              right_desc, right_help
            )
          )
        }
      )
    ),
    result_text,
    explanation_panel
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
      ),
      shiny::tags$button(
        id = "share_btn",
        class = "btn btn-success btn-lg",
        onclick = sprintf(
          paste0(
            "var text = 'I scored %d/%d on ",
            "\"Which lifestyle event is more likely to kill you?\"\\n",
            "Can you beat my score? Take the quiz:\\n",
            "https://johngavin.github.io/micromort/articles/quiz_shinylive.html';",
            "navigator.clipboard.writeText(text).then(function(){",
            "var btn=document.getElementById('share_btn');",
            "btn.textContent='Copied!';",
            "setTimeout(function(){btn.textContent='Share';},2000);",
            "});"
          ),
          score, n
        ),
        "Share"
      ),
      shiny::tags$button(
        id = "submit_btn",
        class = "btn btn-warning btn-lg",
        onclick = sprintf("submitScore(%d, %d)", score, n),
        "Submit Score"
      )
    ),
    shiny::div(
      class = "text-center mt-2",
      shiny::tags$small(id = "percentile_text", class = "text-muted"),
      shiny::tags$br(),
      shiny::tags$small(
        class = "text-muted",
        "Scores are recorded anonymously (score, total, timestamp only)."
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
    shiny::div(
      class = "d-flex justify-content-between align-items-center mb-4",
      shiny::actionButton(
        "back_to_summary", "\u2190 Back to Results",
        class = "btn-secondary"
      ),
      shiny::h3("Question-by-Question Detail", class = "mb-0"),
      shiny::actionButton(
        "try_again_detail", "Try Again",
        class = "btn-primary"
      )
    ),
    if (requireNamespace("DT", quietly = TRUE)) {
      DT::DTOutput("detail_table")
    } else {
      shiny::tableOutput("detail_table_basic")
    }
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
  .quiz-title {
    white-space: nowrap;
    font-size: clamp(1rem, 2.5vw, 1.5rem);
  }
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
    user-select: text;
    -webkit-user-select: text;
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
  .quiz-btn .help-icon { font-size: 0.8rem; color: #6c757d; cursor: help; margin-left: 4px; }
  .quiz-btn .help-link { font-size: 0.7rem; color: #0d6efd; text-decoration: none; }
  .quiz-btn .help-link:hover { text-decoration: underline; }
  .explanation-panel { background-color: #f8f9fa; border: 1px solid #dee2e6; border-radius: 8px; padding: 12px 16px; font-size: 0.9rem; }
  .gap-3 { gap: 1rem; }
  #submit_btn:disabled { opacity: 0.6; cursor: not-allowed; }
  "
}


leaderboard_js <- function() {
  # Google Form POST URL and Sheet JSON endpoint
  "
  var FORM_URL = 'https://docs.google.com/forms/d/e/1FAIpQLSc1HX5kPVO6G982zOxH2BLv1FWexiITPnbjfWMN3a1M9yDtvw/formResponse';
  var SHEET_URL = 'https://docs.google.com/spreadsheets/d/17HLtIdV3r55dIh06cSaWT8kFXzNrkR-Fu2ZJkjszG8k/gviz/tq?tqx=out:json';
  var scoreSubmitted = false;

  function submitScore(score, total) {
    if (scoreSubmitted) return;
    var btn = document.getElementById('submit_btn');
    if (btn) btn.disabled = true;

    var data = new URLSearchParams();
    data.append('entry.335579146', score);
    data.append('entry.2122920576', total);
    data.append('entry.621716914', new Date().toISOString());

    fetch(FORM_URL, {
      method: 'POST',
      mode: 'no-cors',
      body: data
    }).then(function() {
      scoreSubmitted = true;
      if (btn) btn.textContent = 'Submitted!';
      getPercentile(score, total);
    }).catch(function() {
      if (btn) {
        btn.textContent = 'Score saved locally';
        btn.disabled = true;
      }
    });
  }

  function getPercentile(score, total) {
    fetch(SHEET_URL)
      .then(function(r) { return r.text(); })
      .then(function(text) {
        var json = JSON.parse(text.replace(/.*google.visualization.Query.setResponse\\(/, '').replace(/\\);$/, ''));
        var rows = json.table.rows;
        var pct = score / total * 100;
        var below = 0;
        for (var i = 0; i < rows.length; i++) {
          var s = rows[i].c[0] ? rows[i].c[0].v : 0;
          var t = rows[i].c[1] ? rows[i].c[1].v : 10;
          if ((s / t * 100) < pct) below++;
        }
        var percentile = rows.length > 0 ? Math.round(below / rows.length * 100) : 50;
        var el = document.getElementById('percentile_text');
        if (el) el.textContent = 'You scored better than ' + percentile + '% of players!';
      })
      .catch(function() {});
  }
  "
}


# ===========================================================================
# CHRONIC QUIZ (Microlife version)
# ===========================================================================

#' Launch Interactive "Which Daily Habit Has a Bigger Effect?" Quiz
#'
#' A standalone Shiny app where users compare pairs of chronic lifestyle
#' factors and guess which has the larger absolute effect on life expectancy
#' (microlives per day). Built with bslib cards for a modern UI.
#'
#' @param n_pairs Number of question pairs. If `NULL` (default), the user
#'   chooses on the instructions page.
#' @param ... Additional arguments passed to [shiny::shinyApp()].
#'
#' @return A Shiny app object (runs interactively).
#'
#' @examples
#' if (interactive()) {
#'   launch_chronic_quiz()
#' }
#'
#' @export
launch_chronic_quiz <- function(n_pairs = NULL, ...) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "{.pkg shiny} is required for {.fn launch_chronic_quiz}.",
      "i" = "Install it with {.code install.packages('shiny')}"
    ))
  }
  if (!requireNamespace("bslib", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "{.pkg bslib} is required for {.fn launch_chronic_quiz}.",
      "i" = "Install it with {.code install.packages('bslib')}"
    ))
  }

  ui <- chronic_quiz_ui()
  server <- chronic_quiz_server(n_pairs = n_pairs)
  shiny::shinyApp(ui = ui, server = server, ...)
}


# ---- Chronic quiz internal UI ----

chronic_quiz_title_ui <- function() {
  shiny::h3(
    "Which daily habit affects your lifespan more?",
    class = "text-center mb-3 quiz-title"
  )
}

chronic_quiz_ui <- function() {
  bslib::page_fluid(
    theme = bslib::bs_theme(bootswatch = "flatly", version = 5),
    shiny::tags$head(
      shiny::tags$style(shiny::HTML(chronic_quiz_css()))
    ),
    shiny::div(
      class = "container",
      style = "width: 95%; max-width: 100%; margin: auto; padding-top: 20px;",
      chronic_quiz_title_ui(),
      shiny::uiOutput("main_ui")
    )
  )
}


chronic_quiz_server <- function(n_pairs = NULL) {
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
      diff <- input$difficulty
      pool <- chronic_quiz_pairs(seed = NULL, difficulty = diff)
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
      } else {
        state$phase <- "instructions"
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

    shiny::observeEvent(input$try_again_detail, {
      state$phase <- "instructions"
    })

    # ---- Render main UI ----
    output$main_ui <- shiny::renderUI({
      switch(state$phase,
        instructions = chronic_instructions_ui(n_pairs),
        question = chronic_question_ui(state),
        results_summary = chronic_results_summary_ui(state),
        results_detail = chronic_results_detail_ui(state)
      )
    })
  }
}


# ---- Chronic quiz page builders ----

chronic_encouragement_lines <- function() {
  c(
    "30 minutes of life expectancy per microlife. Choose wisely.",
    "Your daily habits are quietly writing your life story.",
    "Think you know which choices matter most? Prove it.",
    "Every day is a longevity experiment. How's yours going?",
    "Side effects may include sudden urge to eat more vegetables.",
    "Some habits give you time. Others take it away.",
    "Spoiler: your lifestyle choices matter more than you think.",
    "Statistically, this quiz will be good for you. Probably."
  )
}

chronic_instructions_ui <- function(n_pairs = NULL) {
  encouragement <- sample(chronic_encouragement_lines(), 1L)

  shiny::tagList(
    shiny::h4("How it works", class = "text-center mb-3"),
    bslib::card(
      bslib::card_body(
        shiny::tags$ul(
          shiny::tags$li(
            "Each question shows two daily habits or risk factors."
          ),
          shiny::tags$li(
            "Tap the one with the ", shiny::strong("bigger effect"),
            " on your lifespan (regardless of direction)."
          ),
          shiny::tags$li(
            "Some habits ", shiny::strong("gain"), " time (",
            shiny::span(class = "badge bg-success", "+"),
            "), others ", shiny::strong("cost"), " time (",
            shiny::span(class = "badge bg-danger", "\u2212"), ")."
          ),
          shiny::tags$li(
            "You can ", shiny::strong("skip"), " questions or go ",
            shiny::strong("back"), "."
          ),
          shiny::tags$li(
            "A ", shiny::strong("microlife"),
            " equals 30 minutes of life expectancy.",
            " Smoking 20/day costs 10 microlives: like aging 29 hours every 24."
          )
        ),
        shiny::div(
          class = "text-center mt-2 mb-3",
          shiny::tags$em(encouragement)
        ),
        shiny::radioButtons(
          "difficulty", "Difficulty:",
          choices = c("Easy" = "easy", "Medium" = "medium",
                      "Hard" = "hard", "Mixed" = "mixed"),
          selected = "mixed", inline = TRUE
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


chronic_question_ui <- function(state) {

  q <- state$current_q
  n <- state$n_questions
  pair <- state$pairs[q, ]
  ord <- state$display_order[[q]]
  revealed <- state$revealed[q]
  answer <- state$answers[q]
  correct_answer <- pair$answer

  left_side <- ord[1]
  right_side <- ord[2]

  left_factor <- pair[[paste0("factor_", left_side)]]
  left_category <- pair[[paste0("category_", left_side)]]
  left_ml <- pair[[paste0("microlives_", left_side)]]
  left_dir <- pair[[paste0("direction_", left_side)]]
  left_days <- pair[[paste0("annual_days_", left_side)]]
  left_desc <- pair[[paste0("description_", left_side)]]
  left_help <- pair[[paste0("help_url_", left_side)]]

  right_factor <- pair[[paste0("factor_", right_side)]]
  right_category <- pair[[paste0("category_", right_side)]]
  right_ml <- pair[[paste0("microlives_", right_side)]]
  right_dir <- pair[[paste0("direction_", right_side)]]
  right_days <- pair[[paste0("annual_days_", right_side)]]
  right_desc <- pair[[paste0("description_", right_side)]]
  right_help <- pair[[paste0("help_url_", right_side)]]

  left_class <- "btn quiz-btn"
  right_class <- "btn quiz-btn"
  left_extra <- ""
  right_extra <- ""

  if (revealed) {
    left_bigger <- abs(left_ml) > abs(right_ml)
    right_bigger <- abs(right_ml) > abs(left_ml)

    chose_left <- !is.na(answer) && answer == left_side
    chose_right <- !is.na(answer) && answer == right_side

    if (left_bigger) {
      left_class <- paste(left_class, "quiz-btn-correct")
      right_class <- paste(right_class,
                           if (chose_right) "quiz-btn-wrong" else "quiz-btn-neutral")
    } else if (right_bigger) {
      right_class <- paste(right_class, "quiz-btn-correct")
      left_class <- paste(left_class,
                          if (chose_left) "quiz-btn-wrong" else "quiz-btn-neutral")
    } else {
      left_class <- paste(left_class, "quiz-btn-correct")
      right_class <- paste(right_class, "quiz-btn-correct")
    }

    left_extra <- chronic_ml_label(left_ml, left_dir)
    right_extra <- chronic_ml_label(right_ml, right_dir)
  }

  make_btn_content <- function(factor_name, category, direction, ml_text,
                               description = NULL, help_url = NULL) {
    dir_badge <- if (direction == "gain") {
      shiny::span(class = "badge bg-success", "GAIN")
    } else {
      shiny::span(class = "badge bg-danger", "LOSS")
    }

    name_el <- shiny::span(class = "activity-name", format_activity_name(factor_name))
    if (!is.null(description) && nzchar(description)) {
      name_el <- shiny::tagList(
        name_el,
        bslib::tooltip(
          shiny::span(class = "help-icon", "\u24d8"),
          description
        )
      )
    }
    parts <- list(
      name_el,
      shiny::div(
        shiny::span(class = "badge bg-secondary me-1", category),
        dir_badge
      )
    )
    if (nzchar(ml_text)) {
      parts <- c(parts, list(
        shiny::strong(shiny::HTML(ml_text), style = "font-size: 1.2rem;")
      ))
    }
    if (!is.null(help_url) && nzchar(help_url)) {
      parts <- c(parts, list(
        shiny::tags$a(
          class = "help-link", href = help_url, target = "_blank",
          onclick = "event.stopPropagation();",
          "Learn more \u2192"
        )
      ))
    }
    parts
  }

  result_text <- NULL
  explanation_panel <- NULL
  if (revealed) {
    user_correct <- !is.na(answer) && answer == correct_answer
    result_text <- if (user_correct) {
      shiny::div(
        class = "alert alert-success text-center mt-2 py-2",
        shiny::strong("Correct!")
      )
    } else {
      bigger <- pair[[paste0("factor_", correct_answer)]]
      shiny::div(
        class = "alert alert-danger text-center mt-2 py-2",
        if (is.na(answer)) "Skipped! " else shiny::tagList(shiny::strong("Incorrect! ")),
        sprintf("%s has a bigger effect.", bigger)
      )
    }

    # Explanation panel
    ratio_text <- sprintf("%.1f", pair$ratio)
    bigger_side <- pair$answer
    smaller_side <- if (bigger_side == "a") "b" else "a"

    bigger_ml <- pair[[paste0("microlives_", bigger_side)]]
    smaller_ml <- pair[[paste0("microlives_", smaller_side)]]
    bigger_days <- pair[[paste0("annual_days_", bigger_side)]]
    smaller_days <- pair[[paste0("annual_days_", smaller_side)]]
    bigger_dir <- pair[[paste0("direction_", bigger_side)]]
    smaller_dir <- pair[[paste0("direction_", smaller_side)]]

    explanation_panel <- bslib::card(
      class = "explanation-panel mt-2",
      bslib::card_body(
        shiny::tags$p(
          shiny::strong(pair[[paste0("factor_", bigger_side)]]),
          sprintf(
            " %s %s microlives/day (%.1f days/year): ",
            if (bigger_dir == "gain") "gains" else "costs",
            abs(bigger_ml), abs(bigger_days)
          ),
          pair[[paste0("description_", bigger_side)]]
        ),
        shiny::tags$p(
          shiny::strong(pair[[paste0("factor_", smaller_side)]]),
          sprintf(
            " %s %s microlives/day (%.1f days/year): ",
            if (smaller_dir == "gain") "gains" else "costs",
            abs(smaller_ml), abs(smaller_days)
          ),
          pair[[paste0("description_", smaller_side)]]
        ),
        shiny::tags$p(
          sprintf(
            "%s has a %sx larger effect on lifespan than %s.",
            pair[[paste0("factor_", bigger_side)]],
            ratio_text,
            pair[[paste0("factor_", smaller_side)]]
          )
        ),
        shiny::tags$p(
          class = "text-muted mb-0",
          sprintf(
            "1 microlife = 30 min. Over a year, %s microlives/day = %.1f days.",
            abs(bigger_ml), abs(bigger_days)
          )
        )
      )
    )
  }

  # Running tally
  answered_so_far <- sum(!is.na(state$answers[seq_len(q - 1L)]) &
    state$revealed[seq_len(q - 1L)])
  correct_so_far <- sum(vapply(seq_len(q - 1L), function(i) {
    !is.na(state$answers[i]) && state$answers[i] == state$pairs$answer[i]
  }, logical(1)))

  tally_text <- sprintf("Score: %d/%d correct", correct_so_far, answered_so_far)

  nav_ui <- shiny::div(
    class = "d-flex justify-content-between align-items-center mb-3",
    shiny::actionButton(
      "prev_q", "\u2190 Back",
      class = "btn-secondary"
    ),
    shiny::span(
      class = "text-muted",
      if ("difficulty" %in% names(pair) && !is.na(pair$difficulty)) {
        diff_colors <- c(easy = "success", medium = "warning", hard = "danger")
        shiny::span(
          class = paste0("badge bg-", diff_colors[pair$difficulty], " me-2"),
          pair$difficulty
        )
      },
      sprintf("%d of %d", q, n),
      " \u00b7 ",
      shiny::tags$small(tally_text)
    ),
    shiny::actionButton(
      "next_q",
      if (q == n) "Finish" else "Next \u2192",
      class = "btn-primary"
    )
  )

  shiny::tagList(
    nav_ui,
    shiny::div(
      class = "row align-items-center",
      shiny::div(
        class = "col-5",
        if (!revealed) {
          shiny::actionButton(
            "choose_left",
            shiny::tagList(make_btn_content(
              left_factor, left_category, left_dir, left_extra,
              left_desc, left_help
            )),
            class = left_class
          )
        } else {
          shiny::div(
            class = left_class,
            make_btn_content(
              left_factor, left_category, left_dir, left_extra,
              left_desc, left_help
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
              right_factor, right_category, right_dir, right_extra,
              right_desc, right_help
            )),
            class = right_class
          )
        } else {
          shiny::div(
            class = right_class,
            make_btn_content(
              right_factor, right_category, right_dir, right_extra,
              right_desc, right_help
            )
          )
        }
      )
    ),
    result_text,
    explanation_panel
  )
}


chronic_results_summary_ui <- function(state) {
  pairs <- state$pairs
  answers <- state$answers
  n <- state$n_questions

  correct <- vapply(seq_len(n), function(i) {
    !is.na(answers[i]) && answers[i] == pairs$answer[i]
  }, logical(1))
  score <- sum(correct)
  pct <- score / n * 100

  baseline <- n / 2
  result_info <- chronic_result_phrase(pct)

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
      ),
      shiny::tags$button(
        id = "share_btn",
        class = "btn btn-success btn-lg",
        onclick = sprintf(
          paste0(
            "var text = 'I scored %d/%d on ",
            "\"Which daily habit affects your lifespan more?\"\\n",
            "Can you beat my score? Take the quiz:\\n",
            "https://johngavin.github.io/micromort/articles/chronic_quiz_shinylive.html';",
            "navigator.clipboard.writeText(text).then(function(){",
            "var btn=document.getElementById('share_btn');",
            "btn.textContent='Copied!';",
            "setTimeout(function(){btn.textContent='Share';},2000);",
            "});"
          ),
          score, n
        ),
        "Share"
      )
    )
  )
}


chronic_results_detail_ui <- function(state) {
  pairs <- state$pairs
  answers <- state$answers
  n <- state$n_questions

  detail <- tibble::tibble(
    Q = seq_len(n),
    `Factor A` = pairs$factor_a,
    `Factor B` = pairs$factor_b,
    `Your Answer` = ifelse(
      is.na(answers), "Skipped",
      ifelse(answers == "a", pairs$factor_a, pairs$factor_b)
    ),
    `Correct Answer` = ifelse(
      pairs$answer == "a", pairs$factor_a, pairs$factor_b
    ),
    Result = ifelse(
      is.na(answers), "\u2014",
      ifelse(answers == pairs$answer, "\u2713", "\u2717")
    ),
    `ml/day A` = pairs$microlives_a,
    `ml/day B` = pairs$microlives_b,
    `Dir A` = pairs$direction_a,
    `Dir B` = pairs$direction_b,
    Ratio = round(pairs$ratio, 2)
  )

  shiny::tagList(
    shiny::div(
      class = "d-flex justify-content-between align-items-center mb-4",
      shiny::actionButton(
        "back_to_summary", "\u2190 Back to Results",
        class = "btn-secondary"
      ),
      shiny::h3("Question-by-Question Detail", class = "mb-0"),
      shiny::actionButton(
        "try_again_detail", "Try Again",
        class = "btn-primary"
      )
    ),
    if (requireNamespace("DT", quietly = TRUE)) {
      DT::DTOutput("detail_table")
    } else {
      shiny::tableOutput("detail_table_basic")
    }
  )
}


chronic_result_phrase <- function(pct) {
  phrases <- list(
    list(min = 95, phrase = "Longevity expert!",
         fact = "A microlife equals 30 minutes of life expectancy.",
         link = "https://en.wikipedia.org/wiki/Microlife"),
    list(min = 90, phrase = "You think in microlives!",
         fact = "David Spiegelhalter introduced microlives to communicate chronic risk.",
         link = "https://en.wikipedia.org/wiki/Microlife"),
    list(min = 80, phrase = "Impressive health literacy!",
         fact = "Most people underestimate the effect of everyday habits on lifespan.",
         link = "https://en.wikipedia.org/wiki/Health_literacy"),
    list(min = 70, phrase = "Better than average!",
         fact = "Exercise is one of the most effective longevity interventions known.",
         link = "https://en.wikipedia.org/wiki/Exercise#Health_effects"),
    list(min = 60, phrase = "Getting there!",
         fact = "Gains from healthy habits can partially offset losses from unhealthy ones.",
         link = "https://en.wikipedia.org/wiki/Healthy_diet"),
    list(min = 50, phrase = "About average!",
         fact = "Many chronic risk factors interact, making individual effects hard to estimate.",
         link = "https://en.wikipedia.org/wiki/Risk_factor"),
    list(min = 30, phrase = "Surprises everywhere!",
         fact = "Small daily habits compound over years into large effects on life expectancy.",
         link = "https://en.wikipedia.org/wiki/Life_expectancy"),
    list(min = -1, phrase = "Room to learn!",
         fact = "Understanding risk helps you make better decisions about your health.",
         link = "https://en.wikipedia.org/wiki/Risk_communication")
  )
  for (p in phrases) {
    if (pct >= p$min) return(p)
  }
  phrases[[length(phrases)]]
}


#' @noRd
chronic_ml_label <- function(ml, direction) {
  sign_char <- if (direction == "gain") "+" else "\u2212"
  color <- if (direction == "gain") "#198754" else "#dc3545"
  sprintf('<span style="color: %s;">%s%s ml/day</span>', color, sign_char, abs(ml))
}


chronic_quiz_css <- function() {
  "
  .quiz-title {
    white-space: nowrap;
    font-size: clamp(1rem, 2.5vw, 1.5rem);
  }
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
    user-select: text;
    -webkit-user-select: text;
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
  .quiz-btn .help-icon { font-size: 0.8rem; color: #6c757d; cursor: help; margin-left: 4px; }
  .quiz-btn .help-link { font-size: 0.7rem; color: #0d6efd; text-decoration: none; }
  .quiz-btn .help-link:hover { text-decoration: underline; }
  .explanation-panel { background-color: #f8f9fa; border: 1px solid #dee2e6; border-radius: 8px; padding: 12px 16px; font-size: 0.9rem; }
  .gap-3 { gap: 1rem; }
  "
}
