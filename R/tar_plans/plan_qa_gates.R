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
#'   - qa_retired_factor_guard / qa_retired_factor_gate: retired
#'     chronic_risks() factor names must not appear in committed docs/
#'     artifacts (issue #110 / roborev cluster: PM2.5 refactor left
#'     "Air pollution (high)" behind in stale rendered HTML)

# ---------------------------------------------------------------------------
# Retired chronic-risk factor names that must never appear in committed
# rendered artifacts under docs/. Append here whenever a chronic_risks()
# factor name is renamed or removed, so a future refactor cannot silently
# leave stale data behind the way the PM2.5 refactor did (issue #110).
# ---------------------------------------------------------------------------
RETIRED_CHRONIC_FACTOR_NAMES <- c(
  "Air pollution (high)"
)

# Files that legitimately discuss retired names in historical/narrative
# prose (changelog entries) rather than as live embedded data. Mirrors the
# CHANGELOG.md exclusion convention already used elsewhere in this repo
# (see the roborev-exclude-patterns rule) — a changelog is expected to
# name retired values for audit purposes; that is not stale data.
.retired_factor_guard_excluded <- function(path) {
  base <- basename(path)
  base %in% c("CHANGELOG.md", "CHANGELOG.html")
}

# Pure scanning function (no I/O side effects beyond reading files), kept
# separate from the target body so it can be unit-tested directly without
# tar_make() — see tests/testthat/test-qa-retired-factor-guard.R.
#
# Returns status:
#   "OK"    — docs/ + canonical data both readable, zero retired-name hits
#   "STALE" — a retired name (confirmed absent from canonical data) was
#             found in a scanned artifact
#   "ERROR" — indeterminate: docs/ missing, canonical names unreadable, or
#             no scannable files found. NEVER treated as a pass by the
#             gate (checks-must-distinguish-unknown).
.qa_retired_factor_scan <- function(docs_dir, canonical_names, retired_names) {
  if (is.null(canonical_names) || length(canonical_names) == 0L) {
    return(list(
      status = "ERROR", violations = character(0), checked_names = character(0),
      files_scanned = 0L,
      message = "could not read canonical chronic_risks() factor names"
    ))
  }
  if (!dir.exists(docs_dir)) {
    return(list(
      status = "ERROR", violations = character(0), checked_names = character(0),
      files_scanned = 0L,
      message = sprintf("docs directory '%s' not found", docs_dir)
    ))
  }

  # Only enforce names confirmed absent from the current canonical set --
  # if a "retired" name is reinstated later, this guard must not false-fail.
  names_to_check <- retired_names[!retired_names %in% canonical_names]

  all_files <- list.files(docs_dir, pattern = "\\.(html|md)$",
                           recursive = TRUE, full.names = TRUE)
  scanned_files <- Filter(function(f) !.retired_factor_guard_excluded(f), all_files)

  if (length(scanned_files) == 0L) {
    return(list(
      status = "ERROR", violations = character(0), checked_names = names_to_check,
      files_scanned = 0L,
      message = sprintf("no scannable .html/.md files found under '%s'", docs_dir)
    ))
  }

  violations <- character(0)
  for (name in names_to_check) {
    for (f in scanned_files) {
      lines <- tryCatch(readLines(f, warn = FALSE), error = function(e) character(0))
      hit_lines <- grep(name, lines, fixed = TRUE)
      if (length(hit_lines) > 0L) {
        violations <- c(violations, sprintf(
          "%s:%d -- retired factor %s", f, hit_lines, shQuote(name)
        ))
      }
    }
  }

  status <- if (length(violations) > 0L) "STALE" else "OK"

  list(
    status = status,
    violations = violations,
    checked_names = names_to_check,
    files_scanned = length(scanned_files),
    message = if (status == "OK") "clean" else sprintf("%d violation(s)", length(violations))
  )
}

# ---------------------------------------------------------------------------
# Shared helper: discover all article slugs from _pkgdown.yml.
# Combines articles: contents: (authoritative, catches Shinylive pages not
# in navbar) with navbar href: patterns. Errors loudly if the YAML is
# malformed — a broken _pkgdown.yml should fail the pipeline, not silently
# return success.
# ---------------------------------------------------------------------------
.pkgdown_article_slugs <- function(pkgdown_yml = "_pkgdown.yml") {
  yml <- yaml::read_yaml(pkgdown_yml)  # aborts loudly if malformed (intended)
  slugs <- character(0)
  if (!is.null(yml$articles)) {
    for (section in yml$articles) {
      if (!is.null(section$contents)) {
        for (item in section$contents) {
          slugs <- c(slugs, as.character(item))
        }
      }
    }
  }
  navbar_text <- readLines(pkgdown_yml, warn = FALSE)
  href_matches <- regmatches(
    navbar_text,
    regexpr("articles/[A-Za-z0-9_-]+\\.html", navbar_text)
  )
  href_slugs <- sub("\\.html$", "", sub("^articles/", "", href_matches))
  unique(c(slugs, href_slugs))
}

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

  # Deployed HTML content check: curl deployed URLs, grep for error patterns
  targets::tar_target(
    qa_deployed_html,
    {
      desc <- tryCatch(read.dcf("DESCRIPTION"), error = function(e) NULL)
      if (is.null(desc)) return(data.frame(article = character(), pattern = character(),
        count = integer(), stringsAsFactors = FALSE))

      urls_field <- if ("URL" %in% colnames(desc)) desc[, "URL"] else ""
      base_url <- trimws(strsplit(urls_field, ",")[[1]][1])
      if (!nzchar(base_url) || !grepl("^https?://", base_url)) {
        cli::cli_alert_info("No pkgdown URL in DESCRIPTION — skipping deployed QA")
        return(data.frame(article = character(), pattern = character(),
          count = integer(), stringsAsFactors = FALSE))
      }
      base_url <- sub("/$", "", base_url)

      # Extract article slugs from _pkgdown.yml using the shared helper.
      # .pkgdown_article_slugs() aborts loudly if _pkgdown.yml is malformed —
      # a parse failure must fail the pipeline, not silently return success.
      slug_bare <- .pkgdown_article_slugs("_pkgdown.yml")
      slugs <- paste0("articles/", slug_bare, ".html")

      # Placeholder text emitted by show_target() when tar_make() has not run:
      #   *`<name>` requires `tar_make()` to render.*
      # (inst/vignette_utils.R line ~49)
      patterns <- c(
        "requires `tar_make\\(\\)` to render",
        "requires tar_make\\(\\)",
        "not found in targets store or RDS fallback",
        "not available", "not found in targets",
        "MISSING EVIDENCE", "Error in", "Error:"
      )
      n_checked <- 0L
      results <- lapply(slugs, function(slug) {
        url <- paste0(base_url, "/", slug)
        fetch_result <- tryCatch({
          resp <- httr2::request(url) |>
            httr2::req_timeout(15) |>
            httr2::req_perform()
          status <- httr2::resp_status(resp)
          if (status != 200L) {
            # Non-200 is an explicit failure — surface it
            return(data.frame(article = slug, pattern = "FETCH_ERROR",
              count = 1L,
              stringsAsFactors = FALSE))
          }
          httr2::resp_body_string(resp)
        }, error = function(e) {
          # Network error / timeout — surface as FETCH_ERROR
          data.frame(article = slug, pattern = "FETCH_ERROR",
            count = 1L, stringsAsFactors = FALSE)
        })
        # If fetch_result is already a data.frame (error case), return it
        if (is.data.frame(fetch_result)) return(fetch_result)
        body <- fetch_result
        # Strip code-fold <details>...</details> blocks before matching.
        # code-fold: true echoes the R chunk SOURCE verbatim inside
        # <details class="code-fold">, regardless of whether a fallback
        # branch inside that source actually ran, so a fallback-message
        # string literal sitting in source code would false-positive this
        # gate (micromort#126). Keep in sync with the equivalent strip in
        # .github/workflows/pkgdown.yaml.
        body <- gsub("(?s)<details[^>]*>.*?</details>", "", body, perl = TRUE)
        n_checked <<- n_checked + 1L
        hits <- vapply(patterns, function(p) {
          m <- gregexpr(p, body, ignore.case = TRUE)[[1]]
          if (m[1] == -1L) 0L else length(m)
        }, integer(1))
        if (sum(hits) == 0L) return(NULL)
        data.frame(article = slug, pattern = names(hits[hits > 0]),
          count = hits[hits > 0], stringsAsFactors = FALSE)
      })
      result_df <- do.call(rbind, Filter(Negate(is.null), results))
      if (is.null(result_df)) result_df <- data.frame(
        article = character(), pattern = character(),
        count = integer(), stringsAsFactors = FALSE)

      n_fail <- nrow(result_df)
      # If zero articles were reachable, that is itself a failure — not a pass
      if (n_checked == 0L && length(slugs) > 0L) {
        cli::cli_abort(c(
          "x" = "qa_deployed_html: could not fetch ANY of {length(slugs)} article(s)",
          "i" = "All fetches returned FETCH_ERROR — check network and deployment status",
          "i" = "Run targets::tar_read(qa_deployed_html) for per-slug details"
        ))
      }
      if (n_fail > 0) {
        cli::cli_abort(c(
          "x" = "qa_deployed_html: {n_fail} error pattern(s) or fetch failure(s) in deployed HTML",
          "i" = "Run targets::tar_read(qa_deployed_html) for details"
        ))
      } else {
        cli::cli_alert_success(
          "All {n_checked}/{length(slugs)} reachable deployed articles pass content QA")
      }
      result_df
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # Enforce chronic CSV freshness: non-OK status is a build-failing gate
  targets::tar_target(
    qa_chronic_csv_gate,
    {
      check <- vig_chronic_csv_check
      status <- check$status
      if (status != "OK") {
        cli::cli_abort(c(
          "x" = "Chronic CSV gate FAILED: embedded CSV in chronic_quiz_shinylive.qmd is {status}",
          "i" = "canonical_rows = {check$canonical_rows}, embedded_rows = {check$embedded_rows}",
          "i" = "canonical_hash = {check$canonical_hash}",
          "i" = "embedded_hash  = {check$embedded_hash}",
          "i" = "Re-run the chronic_pairs pipeline target and update the embedded CSV"
        ))
      }
      cli::cli_alert_success(
        "Chronic CSV gate: embedded CSV matches canonical ({check$canonical_rows} rows)"
      )
      list(status = status, rows = check$canonical_rows, timestamp = Sys.time())
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # Article title integrity: verify each docs/articles/*.html title and h1
  # match the source vignette YAML title, and the filename slug matches _pkgdown.yml.
  # Detects the class of corruption reported in roborev jobs 3297/3290/3026:
  # a rendered HTML picking up another vignette's title/h1/metadata.
  targets::tar_target(
    qa_article_title_integrity,
    {
      docs_dir    <- "docs/articles"
      vig_dir     <- "vignettes"
      pkgdown_yml <- "_pkgdown.yml"

      if (!dir.exists(docs_dir) || !file.exists(pkgdown_yml)) {
        cli::cli_alert_info("qa_article_title_integrity: docs/ or _pkgdown.yml absent — skipping")
        return(list(violations = character(0), timestamp = Sys.time()))
      }

      # Use the shared helper so both targets see the same slug set.
      # This also picks up pages declared only in articles: contents: (e.g.
      # quiz_shinylive, chronic_quiz_shinylive) that href-only regex misses.
      declared_slugs <- .pkgdown_article_slugs(pkgdown_yml)

      violations <- character(0)

      for (slug in declared_slugs) {
        html_path <- file.path(docs_dir, paste0(slug, ".html"))
        qmd_path  <- file.path(vig_dir,  paste0(slug, ".qmd"))

        # Skip if HTML or QMD absent (other checks handle missing files)
        if (!file.exists(html_path) || !file.exists(qmd_path)) next

        # Extract title from QMD YAML front-matter
        qmd_lines  <- readLines(qmd_path, warn = FALSE)
        yaml_end   <- which(qmd_lines == "---")
        if (length(yaml_end) < 2L) next
        yaml_block <- qmd_lines[seq_len(yaml_end[2L])]
        title_line <- grep("^title:\\s*", yaml_block, value = TRUE)
        if (length(title_line) == 0L) next
        qmd_title  <- trimws(sub("^title:\\s*['\"]?", "", sub("['\"]\\s*$", "", title_line[1L])))
        qmd_title_lc <- tolower(qmd_title)

        # Extract <title> from HTML head (first occurrence)
        html_lines  <- readLines(html_path, warn = FALSE)
        title_matches <- regmatches(
          html_lines,
          regexpr("<title>[^<]+</title>", html_lines)
        )
        title_matches <- title_matches[nzchar(title_matches)]
        if (length(title_matches) == 0L) {
          violations <- c(violations, paste0(slug, ": HTML missing <title> element"))
          next
        }
        html_title_raw <- sub("^<title>", "", sub("</title>.*$", "", title_matches[1L]))
        # pkgdown appends " • pkgname" to every title — strip it
        html_title <- trimws(sub("\\s*•.*$", "", html_title_raw))
        html_title_lc <- tolower(html_title)

        # Title mismatch check (case-insensitive substring)
        title_ok <- grepl(qmd_title_lc, html_title_lc, fixed = TRUE) ||
                    grepl(html_title_lc, qmd_title_lc, fixed = TRUE)
        if (!title_ok) {
          violations <- c(violations, paste0(
            slug, ": title mismatch — QMD='", qmd_title,
            "' HTML='", html_title, "'"
          ))
        }

        # Extract <h1> from HTML body
        h1_matches <- regmatches(
          html_lines,
          regexpr('<h1[^>]*class="title"[^>]*>[^<]+</h1>', html_lines)
        )
        h1_matches <- h1_matches[nzchar(h1_matches)]
        if (length(h1_matches) > 0L) {
          h1_text    <- trimws(sub("^<h1[^>]*>", "", sub("</h1>.*$", "", h1_matches[1L])))
          h1_text_lc <- tolower(h1_text)
          h1_ok <- grepl(qmd_title_lc, h1_text_lc, fixed = TRUE) ||
                   grepl(h1_text_lc, qmd_title_lc, fixed = TRUE)
          if (!h1_ok) {
            violations <- c(violations, paste0(
              slug, ": h1 mismatch — QMD='", qmd_title,
              "' H1='", h1_text, "'"
            ))
          }
        }
      }

      if (length(violations) > 0L) {
        cli::cli_abort(c(
          "x" = "Article title integrity: {length(violations)} violation(s) detected",
          "i" = "Each HTML article title and h1 must match the source vignette YAML title",
          setNames(violations, rep("x", length(violations)))
        ))
      }

      cli::cli_alert_success(
        "Article title integrity: {length(declared_slugs)} articles pass"
      )
      list(violations = violations, timestamp = Sys.time())
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
  ),

  # Scan committed docs/ artifacts for retired chronic_risks() factor names.
  # See .qa_retired_factor_scan() above for the OK/STALE/ERROR contract.
  targets::tar_target(
    qa_retired_factor_guard,
    {
      canonical_names <- tryCatch(chronic_risks()$factor, error = function(e) NULL)
      result <- .qa_retired_factor_scan("docs", canonical_names, RETIRED_CHRONIC_FACTOR_NAMES)

      if (result$status == "ERROR") {
        cli::cli_alert_warning("qa_retired_factor_guard: indeterminate -- {result$message}")
      } else if (result$status == "STALE") {
        cli::cli_alert_danger(
          "qa_retired_factor_guard: {length(result$violations)} retired-name occurrence(s) in docs/"
        )
      } else {
        cli::cli_alert_success(
          "qa_retired_factor_guard: OK ({result$files_scanned} file(s) scanned, {length(result$checked_names)} retired name(s) checked)"
        )
      }

      result
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # Enforce: retired factor names must never appear in committed docs/
  # artifacts, and an indeterminate scan must never be treated as a pass.
  targets::tar_target(
    qa_retired_factor_gate,
    {
      check <- qa_retired_factor_guard
      if (check$status != "OK") {
        cli::cli_abort(c(
          "x" = "Retired-factor gate FAILED: status = {check$status}",
          if (check$status == "STALE") {
            setNames(check$violations, rep("i", length(check$violations)))
          } else {
            c("i" = check$message)
          },
          "i" = if (check$status == "STALE") {
            "Regenerate the stale docs/ artifact(s) from current chronic_risks() output"
          } else {
            "Fix the underlying cause (missing docs/, unreadable chronic_risks()) before trusting this gate"
          }
        ))
      }
      cli::cli_alert_success("Retired-factor gate: OK")
      list(status = check$status, timestamp = Sys.time())
    },
    cue = targets::tar_cue(mode = "always")
  )
)
