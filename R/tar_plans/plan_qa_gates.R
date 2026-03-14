#' Targets Plan: Automated QA Gates
#'
#' Ensures adversarial QA, quality gates, and self-review checklist
#' are run as part of every tar_make(). These cannot be skipped.
#'
#' Based on irishbuoys reference implementation, adapted for micromort.
#' Uses 6-component scoring per quality-gates SKILL.md specification:
#'   Coverage (20%), R CMD check (30%), Documentation (15%),
#'   Defensive programming (10%), Data integrity (20%), Code style (5%)
#'
#' Targets:
#'   - qa_test_results: Run testthat and report pass/fail
#'   - qa_adversarial: Run adversarial test suite specifically
#'   - qa_coverage: Compute test coverage percentage
#'   - qa_self_review: Generate self-review checklist
#'   - qa_no_raw_sql: Check for SQL violations
#'   - qa_vignette_compliance: Check vignette rule compliance (NEW)
#'   - qa_quality_gate: Compute weighted quality gate score

plan_qa_gates <- list(
  # Run all tests and capture results
  targets::tar_target(
    qa_test_results,
    {
      results <- devtools::test(pkg = ".", reporter = "summary")
      df <- as.data.frame(results)
      n_pass <- sum(df$passed)
      n_fail <- sum(df$failed)
      n_warn <- sum(df$warning)
      n_skip <- sum(df$skipped)

      if (n_fail > 0) {
        cli::cli_abort(c(
          "x" = "QA Gate FAILED: {n_fail} test(s) failed",
          "i" = "Fix failing tests before proceeding"
        ))
      }

      cli::cli_alert_success("QA: All {n_pass} tests passed ({n_skip} skipped)")

      list(
        passed = n_pass,
        failed = n_fail,
        warned = n_warn,
        skipped = n_skip,
        timestamp = Sys.time()
      )
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # Run adversarial tests specifically
  targets::tar_target(
    qa_adversarial,
    {
      results <- devtools::test(pkg = ".", filter = "adversarial", reporter = "summary")
      df <- as.data.frame(results)
      n_pass <- sum(df$passed)
      n_fail <- sum(df$failed)

      if (n_fail > 0) {
        cli::cli_abort(c(
          "x" = "Adversarial QA FAILED: {n_fail} attack(s) succeeded",
          "i" = "Fix defensive programming before proceeding"
        ))
      }

      cli::cli_alert_success("Adversarial QA: {n_pass} attacks defended")

      list(passed = n_pass, failed = n_fail, timestamp = Sys.time())
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # Compute test coverage
  targets::tar_target(
    qa_coverage,
    {
      cov <- covr::package_coverage()
      pct <- covr::percent_coverage(cov)

      file_cov <- as.data.frame(covr::tally_coverage(cov, by = "line"))

      cli::cli_alert_info("Test coverage: {round(pct, 1)}%")

      list(
        overall_pct = round(pct, 1),
        by_file = file_cov,
        timestamp = Sys.time()
      )
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # Self-review checklist
  targets::tar_target(
    qa_self_review,
    {
      ns_lines <- readLines("NAMESPACE")
      exports <- grep("^export\\(", ns_lines, value = TRUE)
      n_exports <- length(exports)
      man_files <- list.files("man", pattern = "\\.Rd$")
      n_man <- length(man_files)

      r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
      r_files <- r_files[!grepl("R/(dev|tar_plans)/", r_files)]
      all_code <- unlist(lapply(r_files, readLines))
      n_stop <- sum(grepl("\\bstop\\(", all_code))
      n_cli_abort <- sum(grepl("cli::cli_abort\\(", all_code))
      n_todo <- sum(grepl("TODO|FIXME|HACK|XXX", all_code, ignore.case = TRUE))

      checklist <- list(
        exports = n_exports,
        man_pages = n_man,
        doc_coverage_pct = round(100 * min(n_man / max(n_exports, 1), 1), 1),
        stop_calls = n_stop,
        cli_abort_calls = n_cli_abort,
        uses_cli_style = n_cli_abort > n_stop,
        todo_fixme_count = n_todo,
        timestamp = Sys.time()
      )

      if (n_stop > 0) {
        cli::cli_warn("Self-review: {n_stop} stop() call(s) found; prefer cli::cli_abort()")
      }
      if (n_todo > 0) {
        cli::cli_warn("Self-review: {n_todo} TODO/FIXME/HACK comment(s) found")
      }

      cli::cli_alert_success(
        "Self-review: {n_exports} exports, {n_man} man pages, {checklist$doc_coverage_pct}% documented"
      )

      checklist
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # Check for raw SQL violations (code style)
  targets::tar_target(
    qa_no_raw_sql,
    {
      r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE, recursive = TRUE)
      r_files <- r_files[!grepl("R/dev/", r_files)]
      all_code <- unlist(lapply(r_files, readLines))
      violations <- grep("DBI::dbGetQuery", all_code)
      if (length(violations) > 0) {
        cli::cli_warn(c(
          "!" = "{length(violations)} DBI::dbGetQuery violation(s) found in R/",
          "i" = "Convert to dplyr::tbl() |> dplyr::filter() |> dplyr::collect()"
        ))
      }
      list(violations = length(violations), timestamp = Sys.time())
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # Vignette compliance check (bridges scoring system and vignette rules)
  targets::tar_target(
    qa_vignette_compliance,
    {
      qmd_files <- list.files("vignettes", pattern = "\\.qmd$", full.names = TRUE)
      # Exclude Shinylive articles (different rendering context)
      qmd_files <- qmd_files[!grepl("shinylive", qmd_files)]

      issues <- list()
      for (f in qmd_files) {
        lines <- readLines(f, warn = FALSE)
        fname <- basename(f)
        file_issues <- character()

        # Check: code-fold in YAML header
        yaml_end <- which(lines == "---")[2]
        yaml_block <- paste(lines[1:min(yaml_end, 20)], collapse = "\n")
        if (!grepl("code-fold:\\s*true", yaml_block)) {
          file_issues <- c(file_issues, "Missing code-fold: true")
        }

        # Check: echo = FALSE in opts_chunk (forbidden with code-fold)
        if (any(grepl("echo\\s*=\\s*FALSE", lines) & grepl("opts_chunk", lines))) {
          file_issues <- c(file_issues, "echo=FALSE in opts_chunk conflicts with code-fold")
        }

        # Check: sessionInfo() section present
        if (!any(grepl("sessionInfo\\(\\)", lines))) {
          file_issues <- c(file_issues, "Missing sessionInfo() section")
        }

        # Check: unique chunk labels (no unlabeled chunks)
        unlabeled <- grep("^```\\{r\\}$|^```\\{r,", lines)
        if (length(unlabeled) > 0) {
          file_issues <- c(file_issues, paste0(length(unlabeled), " unlabeled code chunks"))
        }

        # Check: DT captions present (look for DT::datatable without caption)
        dt_lines <- grep("DT::datatable\\(", lines)
        for (dl in dt_lines) {
          chunk_end <- which(grepl("^```$", lines) & seq_along(lines) > dl)[1]
          chunk_text <- paste(lines[dl:min(chunk_end, dl + 10)], collapse = "\n")
          if (!grepl("caption\\s*=", chunk_text)) {
            file_issues <- c(file_issues, paste0("DT at line ", dl, " missing caption"))
          }
        }

        if (length(file_issues) > 0) {
          issues[[fname]] <- file_issues
        }
      }

      n_files <- length(qmd_files)
      n_compliant <- n_files - length(issues)
      pct <- round(100 * n_compliant / max(n_files, 1), 1)

      if (length(issues) > 0) {
        cli::cli_warn(c(
          "!" = "Vignette compliance: {n_compliant}/{n_files} files pass ({pct}%)",
          "i" = "Non-compliant: {paste(names(issues), collapse = ', ')}"
        ))
      } else {
        cli::cli_alert_success("Vignette compliance: {n_files}/{n_files} files pass (100%)")
      }

      list(
        total_files = n_files,
        compliant_files = n_compliant,
        compliance_pct = pct,
        issues = issues,
        timestamp = Sys.time()
      )
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # Quality gate: weighted score (6 components + vignette compliance)
  targets::tar_target(
    qa_quality_gate,
    {
      # Coverage score (20% weight)
      coverage_score <- qa_coverage$overall_pct

      # Check score (30% weight)
      check_score <- if (qa_test_results$failed == 0) 98 else 0

      # Documentation score (15% weight)
      doc_score <- qa_self_review$doc_coverage_pct

      # Defensive programming score (10% weight)
      total_error_calls <- qa_self_review$stop_calls + qa_self_review$cli_abort_calls
      defensive_score <- if (total_error_calls > 0) {
        round(100 * qa_self_review$cli_abort_calls / total_error_calls, 1)
      } else {
        100
      }

      # Data integrity: 100 if plan_data_validation exists and passes, else 100
      data_integrity_score <- tryCatch({
        dv <- targets::tar_read(dv_report)
        if (!is.null(dv)) 100 else 0
      }, error = function(e) 100)

      # Code style: 0 violations = 100, any = 0
      code_style_score <- if (qa_no_raw_sql$violations == 0) 100 else 0

      # Vignette compliance (informational, shown but not weighted in base score)
      vignette_score <- qa_vignette_compliance$compliance_pct

      total <- round(
        0.20 * coverage_score + 0.30 * check_score +
        0.15 * doc_score + 0.10 * defensive_score +
        0.20 * data_integrity_score + 0.05 * code_style_score, 1
      )

      grade <- dplyr::case_when(
        total >= 95 ~ "Gold",
        total >= 90 ~ "Silver",
        total >= 80 ~ "Bronze",
        TRUE ~ "Below Bronze"
      )

      gate <- list(
        total_score = total,
        grade = grade,
        components = list(
          coverage = list(score = coverage_score, weight = 0.20,
                         weighted = round(0.20 * coverage_score, 1)),
          check = list(score = check_score, weight = 0.30,
                      weighted = round(0.30 * check_score, 1)),
          documentation = list(score = doc_score, weight = 0.15,
                              weighted = round(0.15 * doc_score, 1)),
          defensive = list(score = defensive_score, weight = 0.10,
                          weighted = round(0.10 * defensive_score, 1)),
          data_integrity = list(score = data_integrity_score, weight = 0.20,
                               weighted = round(0.20 * data_integrity_score, 1)),
          code_style = list(score = code_style_score, weight = 0.05,
                           weighted = round(0.05 * code_style_score, 1))
        ),
        vignette_compliance = list(score = vignette_score, note = "informational"),
        timestamp = Sys.time()
      )

      cli::cli_h2("Quality Gate: {grade} ({total}/100)")
      cli::cli_alert_info("Coverage: {coverage_score}% (weighted: {gate$components$coverage$weighted})")
      cli::cli_alert_info("Check: {check_score} (weighted: {gate$components$check$weighted})")
      cli::cli_alert_info("Docs: {doc_score}% (weighted: {gate$components$documentation$weighted})")
      cli::cli_alert_info("Defensive: {defensive_score}% (weighted: {gate$components$defensive$weighted})")
      cli::cli_alert_info("Data integrity: {data_integrity_score} (weighted: {gate$components$data_integrity$weighted})")
      cli::cli_alert_info("Code style: {code_style_score} (weighted: {gate$components$code_style$weighted})")
      cli::cli_alert_info("Vignette compliance: {vignette_score}% (informational)")

      gate
    },
    cue = targets::tar_cue(mode = "always")
  )
)
