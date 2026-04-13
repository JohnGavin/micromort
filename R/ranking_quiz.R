# ---- Tag-to-category mapping ----

#' Tag-to-Category Mapping for Ranking Quiz
#'
#' Returns the mapping between user-facing quiz tags and dataset categories.
#' Tags group related risks across both acute (micromort) and chronic
#' (microlife) datasets for the ranking quiz.
#'
#' @return A tibble with columns `tag`, `source` ("acute"/"chronic"),
#'   `category`, and optionally `pattern` (regex for activity-level filtering).
#'
#' @examples
#' ranking_tag_mapping()
#'
#' @export
ranking_tag_mapping <- function() {
  tibble::tribble(
    ~tag, ~source, ~category, ~pattern,
    "Radiation", "acute", "Medical", "radiation|X-ray|CT scan|Mammogram|angiogram|enema",
    "Radiation", "acute", "Occupation", "radiation|pilot",
    "Radiation", "acute", "Environment", "radon|cosmic|background",
    "Radiation", "acute", "Travel", "cosmic",
    "Travel", "acute", "Travel", NA,
    "Medical", "acute", "Medical", NA,
    "Medical", "chronic", "Medical", NA,
    "Diet & Drink", "acute", "Diet", NA,
    "Diet & Drink", "acute", "Daily Life", "coffee|wine",
    "Diet & Drink", "chronic", "Diet", NA,
    "Diet & Drink", "chronic", "Alcohol", NA,
    "Sport & Adventure", "acute", "Sport", NA,
    "Sport & Adventure", "acute", "Mountaineering", NA,
    "Sport & Adventure", "chronic", "Exercise", NA,
    "Sport & Adventure", "chronic", "Sedentary", NA,
    "Workplace", "acute", "Occupation", NA,
    "Lifestyle", "acute", "Daily Life", NA,
    "Lifestyle", "acute", "Environment", NA,
    "Lifestyle", "chronic", "Smoking", NA,
    "Lifestyle", "chronic", "Weight", NA,
    "Lifestyle", "chronic", "Cardiovascular", NA,
    "Lifestyle", "chronic", "Mental Health", NA,
    "Disease", "acute", "COVID-19", NA,
    "Disease", "acute", "Disease", NA,
    "Disease", "acute", "Wildlife", NA,
    "Disease", "chronic", "Cancer", NA,
    "Disease", "chronic", "Cardiovascular", NA
  )
}


# ---- Kendall tau scoring ----

#' Kendall Tau Score for Ranking Quiz
#'
#' Computes how well a user's ranking matches the correct ranking using
#' the Kendall tau distance. Counts concordant pairs (user agrees with
#' correct order) vs discordant pairs (user disagrees).
#'
#' @param user_order Integer vector of item indices in the user's order
#'   (first element = user's #1 pick, i.e. most risky).
#' @param correct_order Integer vector of item indices in the correct order.
#'
#' @return A list with:
#'   - `score`: number of concordant pairs
#'   - `max_score`: total number of pairs = k*(k-1)/2
#'   - `n_concordant`: same as score
#'   - `n_discordant`: pairs where user and correct order disagree
#'   - `pct`: percentage score (0-100)
#'
#' @examples
#' # Perfect score
#' kendall_tau_score(c(1, 2, 3), c(1, 2, 3))
#'
#' # Completely reversed
#' kendall_tau_score(c(3, 2, 1), c(1, 2, 3))
#'
#' # One swap
#' kendall_tau_score(c(2, 1, 3), c(1, 2, 3))
#'
#' @export
kendall_tau_score <- function(user_order, correct_order) {
  checkmate::assert_integerish(user_order, min.len = 2)
  checkmate::assert_integerish(correct_order, min.len = 2)
  checkmate::assert_true(length(user_order) == length(correct_order))
  checkmate::assert_true(setequal(user_order, correct_order))

  k <- length(user_order)
  max_pairs <- k * (k - 1L) / 2L

  # Build rank maps: item -> position
  user_rank <- stats::setNames(seq_along(user_order), user_order)
  correct_rank <- stats::setNames(seq_along(correct_order), correct_order)

  # Count discordant pairs
  items <- as.character(user_order)
  n_discordant <- 0L
  for (i in seq_len(k - 1L)) {
    for (j in (i + 1L):k) {
      a <- items[i]
      b <- items[j]
      # In user's order: a before b (user_rank[a] < user_rank[b])
      # In correct order: check if a should be before b
      user_agrees <- (user_rank[a] < user_rank[b]) ==
                     (correct_rank[a] < correct_rank[b])
      if (!user_agrees) n_discordant <- n_discordant + 1L
    }
  }

  n_concordant <- max_pairs - n_discordant
  pct <- round(100 * n_concordant / max(max_pairs, 1L), 1)

  list(
    score = n_concordant,
    max_score = max_pairs,
    n_concordant = n_concordant,
    n_discordant = n_discordant,
    pct = pct
  )
}


# ---- Question generation ----

#' Generate Ranking Quiz Questions
#'
#' Creates questions for the ranking quiz by combining acute (micromort)
#' and chronic (microlife) risks, converting to a common Loss of Life
#' Expectancy (LLE) scale, and grouping into rankable sets.
#'
#' @param tags Character vector of tags to include (e.g. "Radiation",
#'   "Travel"). Use `NULL` for all tags. See [ranking_tag_mapping()] for
#'   available tags.
#' @param items_per_question Integer. Number of items per question (2, 3, or 4).
#'   Default 3.
#' @param n_questions Integer. Number of questions to generate. Default 5.
#' @param seed Optional integer seed for reproducibility.
#' @param difficulty Optional difficulty level: "easy", "medium", "hard",
#'   or "mixed". Easy = large LLE spread within question, hard = small spread.
#' @param profile A named list of condition variables for filtering conditional
#'   risks, passed to [common_risks()]. E.g. `list(country = "NG")` to include
#'   Nigerian disease mortality in the acute risk pool. Default `list()`.
#'
#' @return A tibble with columns:
#'   - `question_id`, `tag`, `item_name`, `item_source` ("acute"/"chronic"),
#'     `lle_minutes`, `micromorts`, `microlives_per_day`, `category`,
#'     `description`, `help_url`, `correct_rank`, `difficulty`
#'
#' @examples
#' ranking_quiz_questions(tags = "Travel", n_questions = 3, seed = 42)
#'
#' @export
ranking_quiz_questions <- function(tags = NULL,
                                    items_per_question = 3L,
                                    n_questions = 5L,
                                    seed = NULL,
                                    difficulty = NULL,
                                    profile = list()) {
  checkmate::assert_character(tags, null.ok = TRUE, min.len = 1)
  checkmate::assert_int(items_per_question, lower = 2L, upper = 4L)
  checkmate::assert_int(n_questions, lower = 1L)
  # min_ratio: minimum LLE ratio between any adjacent pair in a question
  # Prevents ties and near-ties that users cannot meaningfully rank
  min_item_ratio <- 1.1
  checkmate::assert_int(seed, null.ok = TRUE)
  checkmate::assert_choice(difficulty, c("easy", "medium", "hard", "mixed"),
                           null.ok = TRUE)
  checkmate::assert_list(profile, names = "named")

  if (!is.null(seed)) set.seed(seed)

  lle_per_mm <- as.numeric(lle(1 / 1e6, 40))  # ~21.04 minutes

  # Build unified pool
  acute <- common_risks(profile = profile)
  acute <- acute[acute$micromorts > 0, ]
  acute_pool <- tibble::tibble(
    item_name = acute$activity,
    item_source = "acute",
    lle_minutes = acute$micromorts * lle_per_mm,
    micromorts = acute$micromorts,
    microlives_per_day = NA_real_,
    category = acute$category
  )

  chronic <- chronic_risks()
  chronic_pool <- tibble::tibble(
    item_name = chronic$factor,
    item_source = "chronic",
    lle_minutes = abs(chronic$microlives_per_day) * 30,
    micromorts = NA_real_,
    microlives_per_day = chronic$microlives_per_day,
    category = chronic$category
  )

  pool <- rbind(acute_pool, chronic_pool)
  pool <- pool[pool$lle_minutes > 0, ]

  # Assign tags to items based on mapping

  mapping <- ranking_tag_mapping()
  available_tags <- unique(mapping$tag)
  if (!is.null(tags)) {
    checkmate::assert_subset(tags, available_tags)
  } else {
    tags <- available_tags
  }

  # For each item, determine which tags it belongs to
  item_tags <- list()
  for (i in seq_len(nrow(pool))) {
    row <- pool[i, ]
    matched_tags <- character()
    for (j in seq_len(nrow(mapping))) {
      m <- mapping[j, ]
      if (m$source != row$item_source) next
      if (m$category != row$category) next
      # If pattern specified, check activity name matches
      if (!is.na(m$pattern)) {
        if (!grepl(m$pattern, row$item_name, ignore.case = TRUE)) next
      }
      matched_tags <- c(matched_tags, m$tag)
    }
    item_tags[[i]] <- unique(matched_tags)
  }
  pool$tags <- item_tags

  # Filter to items matching selected tags
  has_tag <- vapply(pool$tags, function(t) any(t %in% tags), logical(1))
  pool <- pool[has_tag, ]

  if (nrow(pool) < items_per_question) {
    cli::cli_warn("Only {nrow(pool)} items match selected tags — need {items_per_question}")
    return(tibble::tibble())
  }

  # Join descriptions
  adesc <- activity_descriptions()
  names(adesc) <- c("item_name", "description", "help_url")
  fdesc <- factor_descriptions()
  names(fdesc) <- c("item_name", "description", "help_url")
  desc_all <- rbind(adesc, fdesc)
  pool <- merge(pool, desc_all, by = "item_name", all.x = TRUE)

  # Generate questions by greedy sampling
  used_items <- character()
  questions <- list()
  q_id <- 0L

  # Shuffle pool order for variety
  pool <- pool[sample(nrow(pool)), ]

  for (q in seq_len(n_questions)) {
    available <- pool[!(pool$item_name %in% used_items), ]
    if (nrow(available) < items_per_question) break

    # Sample items with LLE spread and no ties
    # Reject candidates where any adjacent pair has ratio < min_item_ratio
    best_items <- NULL
    best_spread <- 0
    for (attempt in seq_len(50L)) {
      idx <- sample(nrow(available), items_per_question)
      candidate <- available[idx, ]
      sorted_lle <- sort(candidate$lle_minutes, decreasing = TRUE)
      # Check all adjacent pairs have sufficient ratio
      adjacent_ratios <- sorted_lle[-length(sorted_lle)] /
                         pmax(sorted_lle[-1], 0.001)
      if (any(adjacent_ratios < min_item_ratio)) next  # ties or near-ties
      spread <- max(sorted_lle) / max(min(sorted_lle), 0.01)
      if (spread > best_spread) {
        best_spread <- spread
        best_items <- candidate
      }
      if (spread >= 5) break  # good enough
    }

    # If no valid candidate found (all had ties), skip this question
    if (is.null(best_items)) next

    q_id <- q_id + 1L
    # Rank by LLE (highest = most dangerous = rank 1)
    best_items <- best_items[order(-best_items$lle_minutes), ]
    best_items$correct_rank <- seq_len(items_per_question)
    best_items$question_id <- q_id

    # Assign primary tag
    primary_tag <- vapply(best_items$tags, function(t) {
      t_in_selected <- t[t %in% tags]
      if (length(t_in_selected) > 0) t_in_selected[1] else t[1]
    }, character(1))
    best_items$tag <- primary_tag

    used_items <- c(used_items, best_items$item_name)
    questions[[q_id]] <- best_items
  }

  if (length(questions) == 0) {
    cli::cli_warn("Could not generate any questions from selected tags")
    return(tibble::tibble())
  }

  result <- do.call(rbind, questions)
  result$tags <- NULL  # remove list column

  # Assign difficulty based on LLE spread within each question
  spreads <- vapply(split(result$lle_minutes, result$question_id), function(x) {
    max(x) / max(min(x), 0.01)
  }, numeric(1))

  if (length(unique(spreads)) >= 3) {
    breaks <- stats::quantile(spreads, probs = c(0, 1 / 3, 2 / 3, 1))
    breaks <- unique(breaks)
    if (length(breaks) >= 4) {
      diff_labels <- as.character(cut(spreads, breaks, include.lowest = TRUE,
                                       labels = c("hard", "medium", "easy")))
    } else {
      diff_labels <- rep("mixed", length(spreads))
    }
  } else {
    diff_labels <- rep("mixed", length(spreads))
  }
  result$difficulty <- diff_labels[result$question_id]

  # Filter by requested difficulty
  if (!is.null(difficulty) && difficulty != "mixed") {
    result <- result[result$difficulty == difficulty, ]
    # Renumber question_ids
    if (nrow(result) > 0) {
      result$question_id <- as.integer(factor(result$question_id))
    }
  }

  # Select and order columns
  result <- result[, c("question_id", "tag", "item_name", "item_source",
                         "lle_minutes", "micromorts", "microlives_per_day",
                         "category", "description", "help_url",
                         "correct_rank", "difficulty")]
  rownames(result) <- NULL
  tibble::as_tibble(result)
}
