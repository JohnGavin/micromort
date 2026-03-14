# Plan: Pipeline telemetry and project health metrics
# Provides data for the telemetry vignette: pipeline stats, GitHub activity,
# codebase metrics, and commit velocity.

plan_telemetry <- list(

  # Pipeline summary: plan files, target counts, top 5 by size and time

  targets::tar_target(
    vig_pipeline_summary,
    {
      plan_files <- list.files("R/tar_plans", pattern = "^plan_.*\\.R$",
                                full.names = TRUE)

      # Count tar_target() calls per plan file (exclude comments and strings)
      plan_counts <- vapply(plan_files, function(f) {
        lines <- readLines(f, warn = FALSE)
        # Only count lines starting with optional whitespace + targets::tar_target(
        sum(grepl("^\\s*targets::tar_target\\(", lines))
      }, integer(1))

      plan_tbl <- tibble::tibble(
        plan = basename(names(plan_counts)),
        n_targets = unname(plan_counts)
      )

      # Get metadata for top targets by size and time
      meta <- tryCatch(
        targets::tar_meta() |>
          dplyr::filter(!is.na(bytes), !is.na(seconds)) |>
          dplyr::select(name, bytes, seconds),
        error = function(e) NULL
      )

      top_by_size <- if (!is.null(meta)) {
        meta |>
          dplyr::arrange(dplyr::desc(bytes)) |>
          utils::head(5) |>
          dplyr::mutate(size_kb = round(bytes / 1024, 1))
      }

      top_by_time <- if (!is.null(meta)) {
        meta |>
          dplyr::arrange(dplyr::desc(seconds)) |>
          utils::head(5) |>
          dplyr::mutate(seconds = round(seconds, 2))
      }

      list(
        plans = plan_tbl,
        total_targets = sum(plan_counts),
        top_by_size = top_by_size,
        top_by_time = top_by_time
      )
    },
    cue = targets::tar_cue(mode = "always")
  ),


  # Pipeline dependency graph as mermaid text
  targets::tar_target(
    vig_pipeline_dependency_graph,
    tryCatch({
      net <- targets::tar_network(targets_only = TRUE)
      edges <- net$edges
      if (nrow(edges) == 0) return(NULL)

      # Build mermaid flowchart from edges
      lines <- c("graph LR")
      for (i in seq_len(nrow(edges))) {
        lines <- c(lines, paste0("  ", edges$from[i], " --> ", edges$to[i]))
      }
      paste(lines, collapse = "\n")
    }, error = function(e) NULL),
    cue = targets::tar_cue(mode = "always")
  ),


  # GitHub activity: issues open/closed, PRs merged
  targets::tar_target(
    vig_github_activity,
    tryCatch({
      issues_open <- gh::gh(
        "GET /repos/{owner}/{repo}/issues",
        owner = "JohnGavin", repo = "micromort",
        state = "open", per_page = 100, .limit = 100
      )
      issues_closed <- gh::gh(
        "GET /repos/{owner}/{repo}/issues",
        owner = "JohnGavin", repo = "micromort",
        state = "closed", per_page = 100, .limit = 100
      )

      # Separate issues from PRs
      open_issues <- Filter(function(x) is.null(x$pull_request), issues_open)
      closed_issues <- Filter(function(x) is.null(x$pull_request), issues_closed)
      open_prs <- Filter(function(x) !is.null(x$pull_request), issues_open)
      merged_prs <- Filter(function(x) !is.null(x$pull_request), issues_closed)

      tibble::tibble(
        category = c("Issues open", "Issues closed", "PRs open", "PRs merged"),
        count = c(
          length(open_issues), length(closed_issues),
          length(open_prs), length(merged_prs)
        )
      )
    }, error = function(e) {
      tibble::tibble(
        category = "Error",
        count = NA_integer_,
        note = conditionMessage(e)
      )
    }),
    cue = targets::tar_cue(mode = "always")
  ),


  # Codebase metrics: R files, test files, exports, LOC, version
  targets::tar_target(
    vig_codebase_metrics,
    {
      r_files <- list.files("R", pattern = "\\.R$", recursive = TRUE)
      test_files <- list.files("tests/testthat", pattern = "^test-.*\\.R$")

      # Count lines of R code (excluding blanks and comments)
      count_loc <- function(files, base_dir) {
        total <- 0L
        for (f in files) {
          lines <- readLines(file.path(base_dir, f), warn = FALSE)
          code_lines <- lines[!grepl("^\\s*$|^\\s*#", lines)]
          total <- total + length(code_lines)
        }
        total
      }

      r_loc <- count_loc(r_files, "R")
      test_loc <- count_loc(test_files, "tests/testthat")

      # Count exports from NAMESPACE
      ns_lines <- readLines("NAMESPACE", warn = FALSE)
      n_exports <- sum(grepl("^export\\(", ns_lines))

      # Version from DESCRIPTION
      desc <- read.dcf("DESCRIPTION", fields = "Version")[1, 1]

      tibble::tibble(
        metric = c("R source files", "Test files", "Exported functions",
                    "R source LOC", "Test LOC", "Package version"),
        value = c(length(r_files), length(test_files), n_exports,
                  r_loc, test_loc, desc)
      )
    }
  ),


  # Commit velocity: weekly commit counts from git log
  targets::tar_target(
    vig_commit_velocity,
    tryCatch({
      log <- gert::git_log(max = 500)
      log$week <- format(log$time, "%Y-W%V")
      log |>
        dplyr::count(week, name = "commits") |>
        dplyr::arrange(week) |>
        utils::tail(26)  # last 26 weeks
    }, error = function(e) NULL),
    cue = targets::tar_cue(mode = "always")
  )

)
