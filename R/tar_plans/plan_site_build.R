#' Targets Plan: Site Build Pipeline
#'
#' Automates pkgdown site build and Shinylive article rendering.
#' Eliminates manual steps — everything flows through tar_make().
#'
#' Rebuilds only when source files change (R/, vignettes/, config).
#'
#' Targets (in dependency order):
#'   - site_source_hash: Hash of all source files that affect the site
#'   - site_pkgdown: Build pkgdown site (docs/)
#'   - site_quiz_shinylive: Render micromort quiz via quarto
#'   - site_chronic_shinylive: Render microlife quiz via quarto
#'   - site_deploy_shinylive: Copy shinylive outputs into docs/articles/
#'   - site_verify: Check all navbar articles exist in docs/

plan_site_build <- list(

  # Hash source files that affect the site — downstream targets
  # only rebuild when this hash changes
  targets::tar_target(
    site_source_hash,
    {
      src_files <- c(
        list.files("R", pattern = "\\.R$", full.names = TRUE, recursive = TRUE),
        list.files("man", pattern = "\\.Rd$", full.names = TRUE),
        list.files("vignettes", pattern = "\\.qmd$", full.names = TRUE),
        "DESCRIPTION", "NAMESPACE", "_pkgdown.yml"
      )
      src_files <- src_files[file.exists(src_files)]
      digest::digest(lapply(src_files, function(f) {
        list(path = f, mtime = file.mtime(f), size = file.size(f))
      }))
    }
  ),

  # Build pkgdown site — depends on source hash + CSV consistency checks

  targets::tar_target(
    site_pkgdown,
    {
      # Depend on source hash
      force(site_source_hash)

      # Fail fast if quiz data is stale
      if (!identical(vig_quiz_csv_check$status, "OK")) {
        cli::cli_abort(c(
          "x" = "Quiz CSV is {vig_quiz_csv_check$status}",
          "i" = "Regenerate quiz_pairs.csv in vignettes/quiz_shinylive.qmd"
        ))
      }
      if (!identical(vig_chronic_csv_check$status, "OK")) {
        cli::cli_abort(c(
          "x" = "Chronic quiz CSV is {vig_chronic_csv_check$status}",
          "i" = "Regenerate chronic_pairs.csv in vignettes/chronic_quiz_shinylive.qmd"
        ))
      }
      if (!identical(vig_ranking_csv_check$status, "OK")) {
        cli::cli_abort(c(
          "x" = "Ranking quiz CSV is {vig_ranking_csv_check$status}",
          "i" = "Regenerate ranking_questions.csv in vignettes/ranking_quiz_shinylive.qmd"
        ))
      }

      cli::cli_alert_info("Building pkgdown site...")
      pkgdown::build_site(preview = FALSE)

      if (!fs::dir_exists("docs")) {
        cli::cli_abort("pkgdown::build_site() did not create docs/")
      }

      cli::cli_alert_success("pkgdown site built")
      list(
        docs_exists = TRUE,
        n_articles = length(fs::dir_ls("docs/articles", glob = "*.html")),
        timestamp = Sys.time()
      )
    }
  ),

  # Render micromort quiz (Shinylive article)
  targets::tar_target(
    site_quiz_shinylive,
    {
      # Depend on site_pkgdown so docs/ exists first
      force(site_pkgdown)

      qmd_path <- "vignettes/quiz_shinylive.qmd"
      if (!fs::file_exists(qmd_path)) {
        cli::cli_abort("Missing {qmd_path}")
      }

      cli::cli_alert_info("Rendering {qmd_path} with quarto...")
      result <- system2(
        "quarto", c("render", qmd_path),
        stdout = TRUE, stderr = TRUE
      )
      status <- attr(result, "status")
      if (!is.null(status) && status != 0) {
        cli::cli_abort(c(
          "x" = "quarto render failed for {qmd_path}",
          "i" = paste(utils::tail(result, 20), collapse = "\n")
        ))
      }

      cli::cli_alert_success("Quiz shinylive rendered")
      list(qmd = qmd_path, output = result, timestamp = Sys.time())
    }
  ),

  # Render microlife quiz (Shinylive article)
  targets::tar_target(
    site_chronic_shinylive,
    {
      # Depend on site_pkgdown so docs/ exists first
      force(site_pkgdown)

      qmd_path <- "vignettes/chronic_quiz_shinylive.qmd"
      if (!fs::file_exists(qmd_path)) {
        cli::cli_abort("Missing {qmd_path}")
      }

      cli::cli_alert_info("Rendering {qmd_path} with quarto...")
      result <- system2(
        "quarto", c("render", qmd_path),
        stdout = TRUE, stderr = TRUE
      )
      status <- attr(result, "status")
      if (!is.null(status) && status != 0) {
        cli::cli_abort(c(
          "x" = "quarto render failed for {qmd_path}",
          "i" = paste(utils::tail(result, 20), collapse = "\n")
        ))
      }

      cli::cli_alert_success("Chronic quiz shinylive rendered")
      list(qmd = qmd_path, output = result, timestamp = Sys.time())
    }
  ),

  # Render ranking quiz (Shinylive article)
  targets::tar_target(
    site_ranking_shinylive,
    {
      force(site_pkgdown)

      qmd_path <- "vignettes/ranking_quiz_shinylive.qmd"
      if (!fs::file_exists(qmd_path)) {
        cli::cli_alert_info("Ranking quiz qmd not found — skipping")
        return(list(qmd = qmd_path, skipped = TRUE, timestamp = Sys.time()))
      }

      cli::cli_alert_info("Rendering {qmd_path} with quarto...")
      result <- system2(
        "quarto", c("render", qmd_path),
        stdout = TRUE, stderr = TRUE
      )
      status <- attr(result, "status")
      if (!is.null(status) && status != 0) {
        cli::cli_abort(c(
          "x" = "quarto render failed for {qmd_path}",
          "i" = paste(utils::tail(result, 20), collapse = "\n")
        ))
      }

      cli::cli_alert_success("Ranking quiz shinylive rendered")
      list(qmd = qmd_path, output = result, timestamp = Sys.time())
    }
  ),

  # Render closeread article (pkgdown strips closeread-html format)
  targets::tar_target(
    site_closeread,
    {
      force(site_pkgdown)

      qmd_path <- "vignettes/chronic_vs_acute.qmd"
      if (!fs::file_exists(qmd_path)) {
        cli::cli_alert_info("Closeread qmd not found — skipping")
        return(list(qmd = qmd_path, skipped = TRUE, timestamp = Sys.time()))
      }

      # Must render from vignettes/ dir so _extensions/qmd-lab/closeread is found
      cli::cli_alert_info("Rendering {qmd_path} with quarto (closeread)...")
      result <- withr::with_dir("vignettes", {
        system2(
          "quarto", c("render", "chronic_vs_acute.qmd"),
          stdout = TRUE, stderr = TRUE
        )
      })
      status <- attr(result, "status")
      if (!is.null(status) && status != 0) {
        cli::cli_abort(c(
          "x" = "quarto render failed for {qmd_path}",
          "i" = paste(utils::tail(result, 20), collapse = "\n")
        ))
      }

      # Copy to docs/articles/ (overwrite pkgdown's stripped version)
      articles_dir <- "docs/articles"
      html_src <- "vignettes/chronic_vs_acute.html"
      files_src <- "vignettes/chronic_vs_acute_files"

      if (fs::file_exists(html_src)) {
        fs::file_copy(html_src, file.path(articles_dir, "chronic_vs_acute.html"),
                      overwrite = TRUE)
      }
      if (fs::dir_exists(files_src)) {
        dest <- file.path(articles_dir, "chronic_vs_acute_files")
        if (fs::dir_exists(dest)) fs::dir_delete(dest)
        fs::dir_copy(files_src, dest)
      }

      cli::cli_alert_success("Closeread article rendered and deployed")
      list(qmd = qmd_path, output = result, timestamp = Sys.time())
    }
  ),

  # Copy shinylive outputs into docs/articles/
  targets::tar_target(
    site_deploy_shinylive,
    {
      # Depend on all shinylive renders
      force(site_quiz_shinylive)
      force(site_chronic_shinylive)
      force(site_ranking_shinylive)

      articles_dir <- "docs/articles"
      if (!fs::dir_exists(articles_dir)) {
        cli::cli_abort("docs/articles/ does not exist — pkgdown build failed?")
      }

      copied <- character()

      # Copy each shinylive article's HTML and _files/ directory
      for (article in c("quiz_shinylive", "chronic_quiz_shinylive", "ranking_quiz_shinylive")) {
        html_src <- file.path("vignettes", paste0(article, ".html"))
        files_src <- file.path("vignettes", paste0(article, "_files"))

        if (fs::file_exists(html_src)) {
          fs::file_copy(html_src, file.path(articles_dir, basename(html_src)),
                        overwrite = TRUE)
          copied <- c(copied, basename(html_src))
        }

        if (fs::dir_exists(files_src)) {
          dest <- file.path(articles_dir, basename(files_src))
          if (fs::dir_exists(dest)) fs::dir_delete(dest)
          fs::dir_copy(files_src, dest)
          copied <- c(copied, basename(files_src))
        }
      }

      # Copy shinylive service worker
      sw_src <- file.path("vignettes", "shinylive-sw.js")
      sw_dest <- file.path(articles_dir, "shinylive-sw.js")
      if (fs::file_exists(sw_src)) {
        fs::file_copy(sw_src, sw_dest, overwrite = TRUE)
        copied <- c(copied, "shinylive-sw.js")
      } else if (!fs::file_exists(sw_dest)) {
        cli::cli_warn("shinylive-sw.js not found in vignettes/ or docs/articles/")
      }

      cli::cli_alert_success("Deployed shinylive assets: {paste(copied, collapse = ', ')}")
      list(copied = copied, timestamp = Sys.time())
    }
  ),

  # Verify all navbar articles exist in docs/
  targets::tar_target(
    site_verify,
    {
      # Depend on deploy steps and leaderboard stats
      force(site_deploy_shinylive)
      force(site_closeread)
      force(leaderboard_stats_json)

      # Check leaderboard stats JSON exists
      if (!fs::file_exists("docs/api/quiz_stats.json")) {
        cli::cli_warn("docs/api/quiz_stats.json missing — leaderboard stats not available")
      }

      # Parse _pkgdown.yml for article hrefs
      yml_lines <- readLines("_pkgdown.yml", warn = FALSE)
      href_lines <- grep("href:\\s*articles/", yml_lines, value = TRUE)
      hrefs <- trimws(sub(".*href:\\s*", "", href_lines))

      missing <- character()
      for (href in hrefs) {
        full_path <- file.path("docs", href)
        if (!fs::file_exists(full_path)) {
          missing <- c(missing, href)
        }
      }

      if (length(missing) > 0) {
        cli::cli_abort(c(
          "x" = "{length(missing)} navbar article(s) missing from docs/",
          "i" = "Missing: {paste(missing, collapse = ', ')}"
        ))
      }

      cli::cli_alert_success("Site verified: all {length(hrefs)} navbar articles present")
      list(
        articles_checked = length(hrefs),
        all_present = TRUE,
        hrefs = hrefs,
        timestamp = Sys.time()
      )
    }
  )
)
