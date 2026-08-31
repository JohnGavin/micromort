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

  # ── P2: Run devtools::document() before site build ──────────────────────
  targets::tar_target(
    site_document,
    {
      force(site_source_hash)
      cli::cli_alert_info("Running devtools::document()...")
      devtools::document(quiet = TRUE)
      cli::cli_alert_success("Documentation updated")
      list(timestamp = Sys.time())
    }
  ),

  # ── P1: Export quiz CSV when quiz_pairs() changes ──────────────────────
  # Writes to inst/extdata/ AND updates the embedded CSV in the .qmd
  targets::tar_target(
    site_quiz_csv_export,
    {
      # 1. Write to inst/extdata/
      csv_path <- "inst/extdata/vignettes/quiz_pairs.csv"
      utils::write.csv(vig_quiz_pairs, csv_path, row.names = FALSE)

      # 2. Update embedded CSV in shinylive qmd (## file: directive)
      qmd_path <- "vignettes/quiz_shinylive.qmd"
      if (fs::file_exists(qmd_path)) {
        lines <- readLines(qmd_path, warn = FALSE)
        marker <- grep("^## file: quiz_pairs\\.csv", lines)[1]
        if (!is.na(marker)) {
          csv_start <- marker + 1L
          if (grepl("^## type:", lines[csv_start])) csv_start <- csv_start + 1L
          fences <- grep("^```$", lines)
          csv_end <- fences[fences > marker][1] - 1L
          csv_text <- utils::capture.output(
            utils::write.csv(vig_quiz_pairs, stdout(), row.names = FALSE)
          )
          new_lines <- c(lines[1:(csv_start - 1)], csv_text,
                         lines[(csv_end + 1):length(lines)])
          writeLines(new_lines, qmd_path)
          cli::cli_alert_success("Embedded CSV updated in {qmd_path}")
        }
      }

      cli::cli_alert_success("Quiz CSV exported: {nrow(vig_quiz_pairs)} pairs")
      list(path = csv_path, n_rows = nrow(vig_quiz_pairs), timestamp = Sys.time())
    }
  ),

  # ── P0: Export all vig_* targets to inst/extdata/vignettes/*.rds ───────
  #
  # NOTE: targets::tar_read_raw() must NOT be called directly inside a
  # running tar_make() pipeline — targets explicitly forbids self-referential
  # access to the active data store from within a target ("attempted to run
  # targets::tar_read_raw() ... during a pipeline, which is unsupported").
  # Before this fix, every call silently errored, the per-name tryCatch
  # swallowed it, and 0 targets were ever exported unless this target
  # happened to run outside a pipeline context — which is how the two
  # RDS fallbacks in inst/extdata/vignettes/ (vig_arch_tar_visnetwork,
  # vig_pipeline_dependency_graph) ended up as 80-byte serialized NULLs
  # (micromort#126). Fix: read every vig_* target in one fresh callr
  # subprocess so the reads are not flagged as "inside the current
  # pipeline".
  targets::tar_target(
    site_rds_export,
    {
      out_dir <- "inst/extdata/vignettes"
      if (!fs::dir_exists(out_dir)) fs::dir_create(out_dir, recurse = TRUE)

      store <- targets::tar_config_get("store")
      manifest <- targets::tar_manifest()
      vig_names <- manifest$name[grepl("^vig_", manifest$name)]

      objs <- callr::r(
        function(names, store) {
          out <- list()
          for (nm in names) {
            val <- tryCatch(
              targets::tar_read_raw(nm, store = store),
              error = function(e) NULL
            )
            if (!is.null(val)) out[[nm]] <- val
          }
          out
        },
        args = list(names = vig_names, store = store)
      )

      exported <- character()
      for (name in names(objs)) {
        obj <- objs[[name]]
        if (is.null(obj)) next

        rds_path <- file.path(out_dir, paste0(name, ".rds"))

        # DT widgets contain Nix paths — extract data.frame
        if (inherits(obj, "datatables")) {
          df <- obj$x$data
          attr(df, "dt_caption") <- obj$x$caption
          saveRDS(df, rds_path, compress = "xz")
        } else if (inherits(obj, "ggplot") || inherits(obj, "gg")) {
          # Save as ggplot (not grob) so it can be print()ed on reload
          saveRDS(obj, rds_path, compress = "xz")
        } else {
          saveRDS(obj, rds_path, compress = "xz")
        }
        exported <- c(exported, name)
      }

      if (length(exported) < length(vig_names)) {
        cli::cli_warn(c(
          "!" = "site_rds_export: only exported {length(exported)}/{length(vig_names)} vig_* targets",
          "i" = "Missing: {paste(setdiff(vig_names, exported), collapse = ', ')}",
          "i" = "Run tar_make() for the missing targets before relying on their RDS fallback"
        ))
      }

      cli::cli_alert_success("Exported {length(exported)} vig_* targets to RDS")
      list(exported = exported, n = length(exported), timestamp = Sys.time())
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # ── P1: Render README.md from README.qmd ───────────────────────────────
  targets::tar_target(
    site_readme,
    {
      if (!fs::file_exists("README.qmd")) {
        cli::cli_alert_info("No README.qmd — skipping")
        return(list(skipped = TRUE, timestamp = Sys.time()))
      }

      cli::cli_alert_info("Rendering README.qmd -> README.md...")
      knitr::knit("README.qmd", output = "README.md", quiet = TRUE)
      cli::cli_alert_success("README.md rendered")
      list(
        md_size = fs::file_size("README.md"),
        timestamp = Sys.time()
      )
    }
  ),

  # Build pkgdown site — depends on source hash + CSV consistency checks

  targets::tar_target(
    site_pkgdown,
    {
      # Depend on pre-build steps (CSV export updates embedded CSV in .qmd)
      force(site_source_hash)
      force(site_document)
      force(site_rds_export)
      force(site_readme)
      force(site_quiz_csv_export)

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
