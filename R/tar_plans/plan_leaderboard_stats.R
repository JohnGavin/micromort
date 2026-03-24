#' Targets Plan: Leaderboard Stats Pre-computation
#'
#' Fetches quiz scores from the public Google Sheet and computes
#' quantile summaries as static JSON for instant client-side percentile
#' lookups. Avoids every user fetching the full Sheet.
#'
#' Targets:
#'   - leaderboard_raw: Fetch and parse Google Sheet data
#'   - leaderboard_stats_json: Compute quantile stats, write docs/api/quiz_stats.json

plan_leaderboard_stats <- list(

  # Fetch raw scores from Google Sheet
  targets::tar_target(
    leaderboard_raw,
    {
      sheet_url <- paste0(
        "https://docs.google.com/spreadsheets/d/",
        "17HLtIdV3r55dIh06cSaWT8kFXzNrkR-Fu2ZJkjszG8k",
        "/gviz/tq?tqx=out:json"
      )

      resp <- tryCatch(
        readLines(sheet_url, warn = FALSE),
        error = function(e) NULL
      )

      if (is.null(resp) || length(resp) == 0) {
        cli::cli_warn("Could not fetch Google Sheet — returning empty data")
        return(tibble::tibble(
          score = integer(), total = integer(), timestamp = character(),
          quiz_type = character(), difficulty = character(),
          n_questions = integer()
        ))
      }

      # Strip JSONP wrapper: google.visualization.Query.setResponse({...});
      json_text <- paste(resp, collapse = "")
      json_text <- sub(".*google\\.visualization\\.Query\\.setResponse\\(", "", json_text)
      json_text <- sub("\\);\\s*$", "", json_text)

      parsed <- jsonlite::fromJSON(json_text, simplifyVector = FALSE)
      rows <- parsed$table$rows

      if (length(rows) == 0) {
        cli::cli_alert_info("Leaderboard: 0 rows in Google Sheet")
        return(tibble::tibble(
          score = integer(), total = integer(), timestamp = character(),
          quiz_type = character(), difficulty = character(),
          n_questions = integer()
        ))
      }

      # Extract cell values — columns: score, total, timestamp, quiz_type, difficulty, n_questions
      # Extract raw value from a gviz row cell as character (1-based col_idx)
      extract_val <- function(row, col_idx) {
        if (col_idx > length(row$c)) return(NA_character_)
        cell <- row$c[[col_idx]]
        if (is.null(cell) || is.null(cell$v)) NA_character_ else as.character(cell$v)
      }

      # Columns: 1=form_timestamp, 2=Score, 3=Total, 4=Timestamp(ISO),
      #          5=quiz_type, 6=difficulty, 7=n_questions
      df <- tibble::tibble(
        score = as.numeric(vapply(rows, extract_val, character(1), col_idx = 2)),
        total = as.numeric(vapply(rows, extract_val, character(1), col_idx = 3)),
        timestamp = vapply(rows, extract_val, character(1), col_idx = 4),
        quiz_type = vapply(rows, extract_val, character(1), col_idx = 5),
        difficulty = vapply(rows, extract_val, character(1), col_idx = 6),
        n_questions = as.numeric(vapply(rows, extract_val, character(1), col_idx = 7))
      )
      # Default quiz_type for old submissions without the field
      df$quiz_type[is.na(df$quiz_type)] <- "acute"

      # Clean: drop rows with missing score/total
      df <- df[!is.na(df$score) & !is.na(df$total) & df$total > 0, ]
      df$score_pct <- round(df$score / df$total * 100, 1)

      cli::cli_alert_info("Leaderboard: {nrow(df)} valid submissions fetched")
      df
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # Compute quantile stats and write static JSON
  targets::tar_target(
    leaderboard_stats_json,
    {
      df <- leaderboard_raw

      # Helper: compute percentile breakpoints for a score_pct vector
      compute_quantiles <- function(x) {
        if (length(x) < 2) {
          return(list(
            n = length(x),
            percentiles = seq(0, 100, by = 10),
            scores_pct = rep(if (length(x) == 1) x[1] else 50, 11)
          ))
        }
        probs <- seq(0, 1, by = 0.1)
        list(
          n = length(x),
          percentiles = as.integer(probs * 100),
          scores_pct = round(as.numeric(stats::quantile(x, probs = probs)), 1)
        )
      }

      # Build stats for a quiz type
      build_quiz_stats <- function(data) {
        overall <- compute_quantiles(data$score_pct)

        # Subgroups by difficulty x n_questions
        configs <- expand.grid(
          difficulty = c("easy", "medium", "hard", "mixed"),
          n_questions = c(5, 10),
          stringsAsFactors = FALSE
        )

        by_config <- list()
        for (i in seq_len(nrow(configs))) {
          d <- configs$difficulty[i]
          nq <- configs$n_questions[i]
          key <- paste0(d, "_", nq)
          subset <- data[
            !is.na(data$difficulty) & data$difficulty == d &
            !is.na(data$n_questions) & data$n_questions == nq,
          ]
          if (nrow(subset) > 0) {
            by_config[[key]] <- compute_quantiles(subset$score_pct)
          }
        }

        list(overall = overall, by_config = by_config)
      }

      stats <- list(
        generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
        acute = build_quiz_stats(df[df$quiz_type == "acute" | is.na(df$quiz_type), ]),
        chronic = build_quiz_stats(df[df$quiz_type == "chronic", ]),
        ranking = build_quiz_stats(df[df$quiz_type == "ranking", ])
      )

      # Write to docs/api/
      api_dir <- "docs/api"
      if (!fs::dir_exists(api_dir)) fs::dir_create(api_dir, recurse = TRUE)
      json_path <- file.path(api_dir, "quiz_stats.json")
      jsonlite::write_json(stats, json_path, auto_unbox = TRUE, pretty = TRUE)

      cli::cli_alert_success(
        "Leaderboard stats written to {json_path} ({round(fs::file_size(json_path) / 1024, 1)} KB)"
      )
      cli::cli_alert_info(
        "Acute: {stats$acute$overall$n}, Chronic: {stats$chronic$overall$n}, Ranking: {stats$ranking$overall$n} submissions"
      )

      list(
        json_path = json_path,
        acute_n = stats$acute$overall$n,
        chronic_n = stats$chronic$overall$n,
        ranking_n = stats$ranking$overall$n,
        n_configs = length(stats$acute$by_config) + length(stats$chronic$by_config) + length(stats$ranking$by_config),
        timestamp = Sys.time()
      )
    },
    cue = targets::tar_cue(mode = "always")
  )
)
