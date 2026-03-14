# Generate pre-computed quiz CSV for Shinylive vignette
# Run this whenever quiz_pairs() logic or common_risks() data changes.
#
# Usage: Rscript data-raw/generate_quiz_csv.R

pkgload::load_all(".")

easy <- quiz_pairs(difficulty = "easy", seed = 42)
medium <- quiz_pairs(difficulty = "medium", seed = 42)
hard <- quiz_pairs(difficulty = "hard", seed = 42)

all_pairs <- rbind(easy, medium, hard)

csv_text <- utils::capture.output(
  utils::write.csv(all_pairs, row.names = FALSE, stdout())
)

cat("Generated", nrow(all_pairs), "quiz pairs:\n")
print(table(all_pairs$difficulty))
cat("\nCSV preview (first 3 lines):\n")
cat(csv_text[1:3], sep = "\n")
cat("\n\nPaste into vignettes/quiz_shinylive.qmd between textConnection() quotes.\n")

# Write to temp file for easy copy
tmp <- tempfile(fileext = ".csv")
writeLines(csv_text, tmp)
cat("Full CSV written to:", tmp, "\n")

# Also save canonical CSV for traceability (pipeline checks this hash)
extdata_dir <- file.path("inst", "extdata", "vignettes")
if (!dir.exists(extdata_dir)) dir.create(extdata_dir, recursive = TRUE)
canonical_path <- file.path(extdata_dir, "quiz_pairs.csv")
utils::write.csv(all_pairs, canonical_path, row.names = FALSE)
cat("Canonical CSV written to:", canonical_path, "\n")
