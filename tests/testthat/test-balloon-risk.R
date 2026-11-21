# Hot-air ballooning micromorts (issue #222): parsers and rate calculation.
# Numerator: NTSB aviation accident database. Denominator: FAA General
# Aviation and Part 135 Activity Survey lighter-than-air hours.

fixture_dir <- testthat::test_path("fixtures", "ntsb_mini")

fixture_events <- function() {
  extract_ntsb_balloon_events(
    file.path(fixture_dir, "aircraft.csv"),
    file.path(fixture_dir, "events.csv"),
    file.path(fixture_dir, "injury.csv")
  )
}

source_path <- function(...) testthat::test_path("..", "..", "data-raw", "sources", ...)

# ── NTSB extraction ─────────────────────────────────────────────────────────

test_that("extract_ntsb_balloon_events keeps only balloon aircraft", {
  ev <- fixture_events()
  expect_equal(nrow(ev), 7L) # 8 aircraft rows minus the one airplane
  expect_false("E3" %in% ev$ev_id)
  expect_equal(sum(ev$ev_id == "E7"), 2L) # two balloons in one event
})

test_that("extract_ntsb_balloon_events splits fatalities by person category", {
  ev <- fixture_events()
  e1 <- ev[ev$ev_id == "E1", ]
  expect_equal(e1$fatal_flight_crew, 1L)
  expect_equal(e1$fatal_passenger, 2L)
  expect_equal(e1$fatal_event_total, 3L)
  e7 <- ev[ev$ev_id == "E7" & ev$aircraft_key == 1, ]
  expect_equal(e7$fatal_lap_child, 1L)
  expect_equal(e7$fatal_flight_crew, 0L)
})

test_that("extract_ntsb_balloon_events errors on a missing file and on schema drift", {
  expect_error(
    extract_ntsb_balloon_events("nope.csv", "nope.csv", "nope.csv"),
    "not found"
  )
  bad <- tempfile(fileext = ".csv")
  on.exit(unlink(bad), add = TRUE)
  writeLines("ev_id,something_else\nE1,1", bad)
  expect_error(
    extract_ntsb_balloon_events(
      bad, file.path(fixture_dir, "events.csv"), file.path(fixture_dir, "injury.csv")
    ),
    "missing column"
  )
})

# ── FAA grid parser (pure) ──────────────────────────────────────────────────

faa_grid_old <- function() {
  # 2012-2015 layout: header row 8 has "Total" in column 3
  g <- matrix(NA_character_, nrow = 12, ncol = 5)
  g[8, 1] <- "AIRCRAFT TYPE"
  g[8, 3] <- "Total"
  g[8, 5] <- "General Aviation Use"
  g[9, 1] <- "Gliders"
  g[10, 1] <- "Est. Total Hours"
  g[10, 3] <- "91067"
  g[11, 1] <- "Lighter-than-air"
  g[12, 1] <- "Est. Total Hours"
  g[12, 3] <- "88666"
  g
}

faa_grid_ga_only <- function() {
  # 2016-2023 layout: header row 2, GA total in column 2
  g <- matrix(NA_character_, nrow = 6, ncol = 3)
  g[2, ] <- c("AIRCRAFT TYPE", "General Aviation Use Total Active", "General Aviation Use Personal")
  g[3, 1] <- "Lighter-than-air"
  g[4, ] <- c("Est. Total Hours", "106170", "56837")
  g[5, ] <- c("% Std. Error", "11.2", "13")
  g
}

faa_grid_total_active <- function() {
  # 2024 layout: "Total Active" (all hours) before the GA-only column
  g <- matrix(NA_character_, nrow = 6, ncol = 3)
  g[2, ] <- c("AIRCRAFT TYPE", "Total Active", "General Aviation Use Total Active")
  g[3, 1] <- "Lighter-than-air"
  g[4, ] <- c("Est. Total Hours", "88658.087", "80591.674")
  g
}

test_that("extract_lta_hours_from_grid reads the all-hours column in old and 2024 layouts", {
  old <- extract_lta_hours_from_grid(faa_grid_old())
  expect_equal(old$hours, 88666)
  expect_equal(old$basis, "all_hours")
  new <- extract_lta_hours_from_grid(faa_grid_total_active())
  expect_equal(new$hours, 88658.087)
  expect_equal(new$basis, "all_hours")
})

test_that("extract_lta_hours_from_grid falls back to the GA-only column and says so", {
  res <- extract_lta_hours_from_grid(faa_grid_ga_only())
  expect_equal(res$hours, 106170)
  expect_equal(res$basis, "general_aviation_only")
})

test_that("extract_lta_hours_from_grid fails loudly on suppressed or missing data", {
  g <- faa_grid_ga_only()
  g[4, 2] <- "*"
  expect_error(extract_lta_hours_from_grid(g), "not a number")
  g2 <- faa_grid_ga_only()
  g2[3, 1] <- "Gliders"
  expect_error(extract_lta_hours_from_grid(g2), "Lighter-than-air")
  g3 <- faa_grid_ga_only()
  g3[2, 2] <- "Something else"
  expect_error(extract_lta_hours_from_grid(g3), "total-hours column")
})

test_that("read_faa_lta_hours errors clearly on a missing workbook", {
  skip_if_not_installed("readxl")
  expect_error(read_faa_lta_hours("nope.xlsx", 2012), "not found")
})

# ── Committed FAA hours extract ─────────────────────────────────────────────
# The workbooks are not committed (public repo, document guard); the extract
# records their URL and sha256 and is what the rate is computed from.

test_that("committed FAA lighter-than-air hours carry provenance for every year", {
  p <- source_path("faa_lta_hours.csv")
  skip_if_not(file.exists(p), "FAA hours extract not available")
  h <- utils::read.csv(p, stringsAsFactors = FALSE)
  expect_false(anyDuplicated(h$year) > 0L)
  expect_true(all(h$lta_hours > 0))
  expect_true(all(h$basis %in% c("all_hours", "general_aviation_only")))
  expect_true(all(grepl("^https://www\\.faa\\.gov/", h$url)))
  expect_true(all(grepl("^[0-9a-f]{64}$", h$sha256)))
  expect_true(all(nzchar(h$last_accessed)))
})

# ── Rate calculation ────────────────────────────────────────────────────────

test_that("compute_balloon_risk counts only US accidents under Part 91/135", {
  hours <- data.frame(year = c(2020L, 2021L), lta_hours = c(1e6, 1e6))
  res <- compute_balloon_risk(fixture_events(), hours)
  # E4 is an incident, E5 is Canadian, E6 is NUSN, E3 is an airplane
  expect_setequal(unique(res$events_used$ev_id), c("E1", "E2", "E7"))
  expect_equal(res$by_year$accidents, c(2L, 1L))
  expect_equal(res$by_year$fatal_accidents, c(1L, 1L))
  expect_equal(res$by_year$pilot_deaths, c(1L, 0L))
  expect_equal(res$by_year$passenger_deaths, c(2L, 2L))
})

test_that("compute_balloon_risk rate is pilot deaths per million aircraft hours", {
  hours <- data.frame(year = c(2020L, 2021L), lta_hours = c(1e6, 1e6))
  s <- compute_balloon_risk(fixture_events(), hours)$summary
  expect_equal(s$pilot_deaths, 1L)
  expect_equal(s$lta_hours, 2e6)
  expect_equal(s$pilot_micromorts_per_hour, 0.5)
  expect_lt(s$ci_low, s$pilot_micromorts_per_hour)
  expect_gt(s$ci_high, s$pilot_micromorts_per_hour)
})

test_that("compute_balloon_risk keeps years with zero accidents in the exposure", {
  hours <- data.frame(year = c(2019L, 2020L, 2021L), lta_hours = c(5e5, 1e6, 1e6))
  res <- compute_balloon_risk(fixture_events(), hours)
  expect_equal(res$by_year$accidents[res$by_year$year == 2019L], 0L)
  expect_equal(res$summary$lta_hours, 2.5e6)
})

test_that("compute_balloon_risk rejects duplicate years", {
  hours <- data.frame(year = c(2020L, 2020L), lta_hours = c(1, 2))
  expect_error(compute_balloon_risk(fixture_events(), hours), "more than one row")
})

# ── Committed data: provenance and sanity ───────────────────────────────────

test_that("committed NTSB balloon extract is internally consistent", {
  p <- source_path("ntsb_balloon_events.csv")
  skip_if_not(file.exists(p), "NTSB extract not available")
  ev <- read_ntsb_balloon_events(p)
  expect_true(all(ev$ev_type %in% c("ACC", "INC")))
  by_event <- stats::aggregate(
    cbind(cat = fatal_flight_crew + fatal_cabin_crew + fatal_passenger + fatal_lap_child,
      total = fatal_event_total) ~ ev_id,
    data = ev, FUN = max
  )
  # person-category fatalities can never exceed the event total
  expect_true(all(by_event$cat <= by_event$total))
})

test_that("hot-air ballooning row carries provenance and is derived from the sources", {
  csv <- source_path("acute_risks_base.csv")
  src <- source_path("risk_sources.csv")
  ntsb <- source_path("ntsb_balloon_events.csv")
  faa <- source_path("faa_lta_hours.csv")
  skip_if_not(all(file.exists(c(csv, src, ntsb, faa))), "source files not available")

  acute <- utils::read.csv(csv, stringsAsFactors = FALSE)
  row <- acute[grepl("^Hot-air ballooning", acute$activity), ]
  expect_equal(nrow(row), 1L)
  expect_true(nzchar(row$source_url))
  expect_true(nzchar(row$source_id))
  expect_equal(row$confidence, "low")
  sources <- utils::read.csv(src, stringsAsFactors = FALSE)
  expect_true(row$source_id %in% sources$source_id)
  expect_true(all(nzchar(sources$primary_url[sources$source_id == row$source_id])))

  # Recompute from the committed raw files: the stored value must match.
  ev <- read_ntsb_balloon_events(ntsb)
  hours <- utils::read.csv(faa, stringsAsFactors = FALSE)
  s <- compute_balloon_risk(ev, hours)$summary
  expect_equal(row$micromorts, round(s$pilot_micromorts_per_hour, 2))
  expect_equal(row$year, s$year_to)
})

test_that("ballooning pilot rate is the same order of magnitude as hang gliding and skydiving", {
  csv <- source_path("acute_risks_base.csv")
  skip_if_not(file.exists(csv), "source file not available")
  acute <- utils::read.csv(csv, stringsAsFactors = FALSE)
  balloon <- acute$micromorts[grepl("^Hot-air ballooning", acute$activity)]
  hang <- acute$micromorts[acute$activity == "Hang gliding (per flight)"]
  sky <- acute$micromorts[acute$activity == "Skydiving (per jump)"]
  expect_length(balloon, 1L)
  expect_gt(balloon / hang, 0.01)
  expect_lt(balloon / hang, 100)
  expect_gt(balloon / sky, 0.01)
  expect_lt(balloon / sky, 100)
})

test_that("balloon_acute_row matches the CSV schema", {
  csv <- source_path("acute_risks_base.csv")
  skip_if_not(file.exists(csv), "source file not available")
  cols <- names(utils::read.csv(csv, nrows = 1L, stringsAsFactors = FALSE))
  s <- data.frame(
    year_from = 2012L, year_to = 2024L, pilot_micromorts_per_hour = 8.123456
  )
  row <- balloon_acute_row(s, "https://example.org/x", "some_source", as.Date("2026-11-21"))
  expect_identical(names(row), cols)
  expect_equal(row$micromorts, 8.12)
  expect_equal(row$microlives, round(8.12 * MICROLIVES_PER_MICROMORT, 1))
})
