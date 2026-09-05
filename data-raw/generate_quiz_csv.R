# Generate pre-computed quiz CSVs for Shinylive vignettes
# Run this whenever quiz_pairs() logic or common_risks() data changes.
#
# Usage: Rscript data-raw/generate_quiz_csv.R

pkgload::load_all(".")

# ── Standard quiz pairs (unconditional) ────────────────────────────────
easy <- quiz_pairs(difficulty = "easy", seed = 42)
medium <- quiz_pairs(difficulty = "medium", seed = 42)
hard <- quiz_pairs(difficulty = "hard", seed = 42)

all_pairs <- rbind(easy, medium, hard)

csv_text <- utils::capture.output(
  utils::write.csv(all_pairs, row.names = FALSE, stdout())
)

cat("Generated", nrow(all_pairs), "standard quiz pairs:\n")
print(table(all_pairs$difficulty))

# Write to temp file for easy copy
tmp <- tempfile(fileext = ".csv")
writeLines(csv_text, tmp)
cat("Full CSV written to:", tmp, "\n")
cat("The instant JS quiz (micromort-quiz.qmd) picks this up automatically via\n")
cat("the vig_quiz_json_script/site_quiz_csv_export targets — no manual paste\n")
cat("needed (the quiz_shinylive.qmd Shinylive vignette this used to be pasted\n")
cat("into was retired 2026-09-05).\n\n")

# Also save canonical CSV for traceability (pipeline checks this hash)
extdata_dir <- file.path("inst", "extdata", "vignettes")
if (!dir.exists(extdata_dir)) dir.create(extdata_dir, recursive = TRUE)
canonical_path <- file.path(extdata_dir, "quiz_pairs.csv")
utils::write.csv(all_pairs, canonical_path, row.names = FALSE)
cat("Canonical CSV written to:", canonical_path, "\n\n")

# ── Geography quiz pairs (UK vs Nigeria) ───────────────────────────────
geo_pairs <- geography_quiz_pairs(
  countries = c("UK", "NG", "US", "IN"),
  seed = 42
)

geo_csv_text <- utils::capture.output(
  utils::write.csv(geo_pairs, row.names = FALSE, stdout())
)

cat("Generated", nrow(geo_pairs), "geography quiz pairs:\n")
print(table(geo_pairs$pair_type))

geo_canonical <- file.path(extdata_dir, "geography_quiz_pairs.csv")
utils::write.csv(geo_pairs, geo_canonical, row.names = FALSE)
cat("Geography CSV written to:", geo_canonical, "\n")
