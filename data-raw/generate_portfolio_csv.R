# Generate pre-computed CSVs for Portfolio Risk Builder Shinylive vignette
# Run this whenever atomic_risks() or chronic_risks() data changes.
#
# Usage: Rscript data-raw/generate_portfolio_csv.R

pkgload::load_all(".")

# ── Portfolio activities (from atomic_risks) ────────────��────────────────

ar <- atomic_risks()

# Keep population-average rows only (all_ages, healthy, or no condition)
ar <- ar[is.na(ar$condition_value) |
         ar$condition_value %in% c("all_ages", "healthy"), ]

# Aggregate by activity_id: sum micromorts across components
agg <- stats::aggregate(
  micromorts ~ activity_id + activity + category + period + period_type,
  data = ar,
  FUN = sum
)

# Add frequency metadata based on period_type
agg$default_freq <- ifelse(agg$period_type == "day", 365L,
                   ifelse(agg$period_type == "year", 1L,
                   ifelse(agg$period_type == "hour", 100L,
                   ifelse(agg$period_type == "month", 12L, 5L))))

agg$freq_label <- ifelse(agg$period_type == "day", "days per year",
                 ifelse(agg$period_type == "year", "(annual rate)",
                 ifelse(agg$period_type == "hour", "hours per year",
                 ifelse(agg$period_type == "month", "months per year",
                        "times per year"))))

agg$freq_max <- ifelse(agg$period_type == "day", 365L,
               ifelse(agg$period_type == "year", 1L,
               ifelse(agg$period_type == "hour", 2000L,
               ifelse(agg$period_type == "month", 12L, 100L))))

# Add synergy tags for known interaction pairs
agg$synergy_tag <- NA_character_
agg$synergy_tag[grepl("alcohol|wine|beer|spirit", agg$activity, ignore.case = TRUE)] <- "alcohol"
agg$synergy_tag[grepl("smoking|cigarette|tobacco", agg$activity, ignore.case = TRUE)] <- "smoking"

# Sort by category then descending micromorts
agg <- agg[order(agg$category, -agg$micromorts), ]

# Select and rename columns
portfolio_activities <- agg[, c("activity_id", "activity", "category",
                                "micromorts", "period_type", "default_freq",
                                "freq_label", "freq_max", "synergy_tag")]

cat("Generated", nrow(portfolio_activities), "portfolio activities:\n")
print(table(portfolio_activities$category))

# ── Portfolio chronic factors (from chronic_risks) ────────────────────────

cr <- chronic_risks()

portfolio_chronic <- data.frame(
  factor_id = gsub("[^a-z0-9]+", "_", tolower(cr$factor)),
  factor = cr$factor,
  category = cr$category,
  microlives_per_day = cr$microlives_per_day,
  direction = cr$direction,
  description = cr$description,
  synergy_tag = NA_character_,
  stringsAsFactors = FALSE
)

# Assign synergy tags
portfolio_chronic$synergy_tag[grepl("alcohol|wine|beer", portfolio_chronic$factor,
                                   ignore.case = TRUE)] <- "alcohol"
portfolio_chronic$synergy_tag[grepl("smoking|cigarette", portfolio_chronic$factor,
                                   ignore.case = TRUE)] <- "smoking"
portfolio_chronic$synergy_tag[grepl("overweight|obese|bmi", portfolio_chronic$factor,
                                   ignore.case = TRUE)] <- "obesity"

cat("\nGenerated", nrow(portfolio_chronic), "chronic factors:\n")
print(table(portfolio_chronic$category))

# ── Write CSVs ────────────────────────────────────────────────────────────

extdata_dir <- file.path("inst", "extdata", "vignettes")
if (!dir.exists(extdata_dir)) dir.create(extdata_dir, recursive = TRUE)

utils::write.csv(portfolio_activities,
                 file.path(extdata_dir, "portfolio_activities.csv"),
                 row.names = FALSE)
utils::write.csv(portfolio_chronic,
                 file.path(extdata_dir, "portfolio_chronic.csv"),
                 row.names = FALSE)

cat("\nCSVs written to:", extdata_dir, "\n")
cat("  portfolio_activities.csv:", nrow(portfolio_activities), "rows\n")
cat("  portfolio_chronic.csv:", nrow(portfolio_chronic), "rows\n")
