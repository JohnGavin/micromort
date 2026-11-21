#' Hot-air balloon risk from NTSB accident records and FAA flight hours
#'
#' Parsers and a rate calculation for the hot-air ballooning row (issue #222).
#' The numerator comes from the NTSB aviation accident database and the
#' denominator from the FAA General Aviation and Part 135 Activity Survey
#' (lighter-than-air hours). Both are US-government works. Every number is
#' derived from the committed source files by the functions below; nothing is
#' typed in by hand.
#'
#' @name balloon_risk
#' @keywords internal
NULL

# NTSB injury-person categories in the `injury` table of avall.mdb.
.ntsb_inj_categories <- c(
  flight_crew = "Flig",
  cabin_crew = "Cabi",
  passenger = "Pass",
  lap_child = "LapC"
)

#' Extract balloon accident records from NTSB table exports
#'
#' Reads CSV exports of the `aircraft`, `events` and `injury` tables of the
#' NTSB `avall.mdb` database (made by `data-raw/07_ntsb_balloon_extract.sh`)
#' and returns one row per balloon aircraft involved in an event, with the
#' fatalities split by person category.
#'
#' @param aircraft_csv Path to the `aircraft` table export.
#' @param events_csv Path to the `events` table export.
#' @param injury_csv Path to the `injury` table export.
#' @return A data frame with columns `ev_id`, `aircraft_key`, `ev_year`,
#'   `ev_type`, `ev_country`, `far_part`, `site_seeing`, `fatal_flight_crew`,
#'   `fatal_cabin_crew`, `fatal_passenger`, `fatal_lap_child` and
#'   `fatal_event_total` (all fatalities in the event, ground included).
#' @keywords internal
#' @noRd
extract_ntsb_balloon_events <- function(aircraft_csv, events_csv, injury_csv) {
  for (p in c(aircraft_csv, events_csv, injury_csv)) {
    if (!file.exists(p)) {
      cli::cli_abort(c(
        "x" = "NTSB export not found: {.file {p}}",
        "i" = "Run {.file data-raw/07_ntsb_balloon_extract.sh} to create it."
      ))
    }
  }
  ac <- read_csv_codes(aircraft_csv)
  ev <- read_csv_codes(events_csv)
  inj <- read_csv_codes(injury_csv)

  need <- list(
    aircraft = c("ev_id", "Aircraft_Key", "acft_category", "far_part", "site_seeing"),
    events = c("ev_id", "ev_type", "ev_year", "ev_country", "inj_tot_f"),
    injury = c("ev_id", "Aircraft_Key", "inj_person_category", "injury_level", "inj_person_count")
  )
  have <- list(aircraft = names(ac), events = names(ev), injury = names(inj))
  for (tb in names(need)) {
    miss <- setdiff(need[[tb]], have[[tb]])
    if (length(miss) > 0L) {
      cli::cli_abort(c(
        "x" = "NTSB {tb} export is missing column{?s}: {.field {miss}}",
        "i" = "The NTSB schema may have changed; check the data dictionary."
      ))
    }
  }

  balloons <- ac[!is.na(ac$acft_category) & ac$acft_category == "BALL",
    c("ev_id", "Aircraft_Key", "far_part", "site_seeing"),
    drop = FALSE
  ]
  out <- merge(
    balloons,
    ev[, c("ev_id", "ev_type", "ev_year", "ev_country", "inj_tot_f"), drop = FALSE],
    by = "ev_id", all.x = TRUE
  )

  fatal <- inj[!is.na(inj$injury_level) & inj$injury_level == "FATL", , drop = FALSE]
  for (nm in names(.ntsb_inj_categories)) {
    sub <- fatal[fatal$inj_person_category %in% .ntsb_inj_categories[[nm]], , drop = FALSE]
    key_sub <- paste(sub$ev_id, sub$Aircraft_Key)
    key_out <- paste(out$ev_id, out$Aircraft_Key)
    sums <- tapply(sub$inj_person_count, key_sub, sum)
    vals <- unname(sums[key_out])
    vals[is.na(vals)] <- 0
    out[[paste0("fatal_", nm)]] <- as.integer(vals)
  }

  out$inj_tot_f[is.na(out$inj_tot_f)] <- 0
  names(out)[names(out) == "Aircraft_Key"] <- "aircraft_key"
  names(out)[names(out) == "inj_tot_f"] <- "fatal_event_total"
  out$fatal_event_total <- as.integer(out$fatal_event_total)
  out <- out[order(out$ev_year, out$ev_id, out$aircraft_key), , drop = FALSE]
  rownames(out) <- NULL
  out[, c(
    "ev_id", "aircraft_key", "ev_year", "ev_type", "ev_country", "far_part",
    "site_seeing", "fatal_flight_crew", "fatal_cabin_crew", "fatal_passenger",
    "fatal_lap_child", "fatal_event_total"
  )]
}

#' Read the committed balloon accident extract
#'
#' @param path Path to `data-raw/sources/ntsb_balloon_events.csv`.
#' @return The data frame written by `extract_ntsb_balloon_events()`, with
#'   `ev_id` and `far_part` kept as character.
#' @keywords internal
#' @noRd
read_ntsb_balloon_events <- function(path) {
  if (!file.exists(path)) {
    cli::cli_abort(c(
      "x" = "Balloon accident extract not found: {.file {path}}",
      "i" = "Run {.file data-raw/07_ntsb_balloon_extract.sh} to create it."
    ))
  }
  read_csv_codes(path)
}

# Read a CSV keeping identifier and code columns as character: "091" would
# otherwise become 91. Only columns present in the file are given a class.
read_csv_codes <- function(path) {
  code_cols <- c(
    "ev_id", "far_part", "ev_type", "ev_country", "site_seeing",
    "inj_person_category", "injury_level", "acft_category"
  )
  hdr <- names(utils::read.csv(path, nrows = 1L, stringsAsFactors = FALSE))
  classes <- stats::setNames(rep("character", sum(hdr %in% code_cols)), hdr[hdr %in% code_cols])
  utils::read.csv(
    path,
    stringsAsFactors = FALSE, na.strings = "", colClasses = classes
  )
}

#' Pull lighter-than-air total hours out of an FAA survey Table 3.2 grid
#'
#' Pure function over the raw cell grid of the `3.2` sheet (total hours flown
#' by actual use by aircraft type). It finds the "Lighter-than-air" block,
#' the `Est. Total Hours` row beneath it, and the all-hours column. Older
#' tables (2012-2015) have a column headed `Total`; 2024 has `Total Active`;
#' 2016-2023 only give the general-aviation total, headed
#' `General Aviation Use Total Active`. The column used is reported in
#' `basis`.
#'
#' @param grid A character matrix or data frame of the sheet's cells, as read
#'   with `readxl::read_excel(col_names = FALSE, col_types = "text")`.
#' @return A list with `hours` (numeric) and `basis` (`"all_hours"` or
#'   `"general_aviation_only"`).
#' @keywords internal
#' @noRd
extract_lta_hours_from_grid <- function(grid) {
  g <- as.matrix(grid)
  cell <- function(i, j) trimws(as.character(g[i, j]))
  labels <- vapply(seq_len(nrow(g)), function(i) cell(i, 1L), character(1))

  lta_row <- grep("^lighter[- ]than[- ]air$", labels, ignore.case = TRUE)
  if (length(lta_row) != 1L) {
    cli::cli_abort(c(
      "x" = "Expected exactly one {.val Lighter-than-air} row, found {length(lta_row)}.",
      "i" = "The FAA table layout may have changed."
    ))
  }
  window <- seq(lta_row + 1L, min(lta_row + 3L, nrow(g)))
  hrs_row <- window[grepl("^Est\\. Total Hours", labels[window])]
  if (length(hrs_row) < 1L) {
    cli::cli_abort(c(
      "x" = "No {.val Est. Total Hours} row under the Lighter-than-air label.",
      "i" = "The FAA table layout may have changed."
    ))
  }
  hrs_row <- hrs_row[[1L]]

  hdr_row <- which(toupper(labels) == "AIRCRAFT TYPE")
  if (length(hdr_row) < 1L) {
    cli::cli_abort(c("x" = "No {.val AIRCRAFT TYPE} header row found in the FAA table."))
  }
  hdr <- vapply(seq_len(ncol(g)), function(j) cell(hdr_row[[1L]], j), character(1))
  all_col <- which(hdr %in% c("Total", "Total Active"))
  ga_col <- which(hdr == "General Aviation Use Total Active")
  if (length(all_col) >= 1L) {
    col <- all_col[[1L]]
    basis <- "all_hours"
  } else if (length(ga_col) >= 1L) {
    col <- ga_col[[1L]]
    basis <- "general_aviation_only"
  } else {
    cli::cli_abort(c(
      "x" = "No total-hours column found in the FAA table header.",
      "i" = "Looked for {.val Total}, {.val Total Active} and {.val General Aviation Use Total Active}."
    ))
  }

  raw <- cell(hrs_row, col)
  if (is.na(raw) || !grepl("^[0-9]+(\\.[0-9]+)?$", raw)) {
    cli::cli_abort(c(
      "x" = "Lighter-than-air total hours is not a number: {.val {raw}}.",
      "i" = "A {.val *} means the FAA suppressed the estimate."
    ))
  }
  hours <- as.numeric(raw)
  if (hours <= 0) {
    cli::cli_abort(c("x" = "Lighter-than-air total hours is not positive: {.val {raw}}."))
  }
  list(hours = hours, basis = basis)
}

#' Read lighter-than-air flight hours from one FAA survey workbook
#'
#' @param path Path to a Chapter III workbook (`.xls` or `.xlsx`).
#' @param year Survey year, recorded in the result.
#' @return A one-row data frame with `year`, `lta_hours`, `basis` and `file`.
#' @keywords internal
#' @noRd
read_faa_lta_hours <- function(path, year) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    cli::cli_abort(c("x" = "Package {.pkg readxl} is required to read FAA survey workbooks."))
  }
  if (!file.exists(path)) {
    cli::cli_abort(c("x" = "FAA survey workbook not found: {.file {path}}"))
  }
  grid <- suppressMessages(
    readxl::read_excel(path, sheet = "3.2", col_names = FALSE, col_types = "text")
  )
  res <- extract_lta_hours_from_grid(grid)
  data.frame(
    year = as.integer(year),
    lta_hours = res$hours,
    basis = res$basis,
    file = basename(path),
    stringsAsFactors = FALSE
  )
}

#' Pilot micromort rate for hot-air ballooning
#'
#' Combines the NTSB balloon accident records with the FAA lighter-than-air
#' hours over the years present in `hours`. A balloon carries one pilot, so
#' aircraft hours are pilot hours and the pilot fatality rate per hour is a
#' per-person risk. Passenger deaths are counted but not turned into a rate:
#' the FAA survey gives aircraft hours, not passenger hours.
#'
#' Only accidents (`ev_type == "ACC"`) in the USA under 14 CFR Part 91 or 135
#' count, which matches US-registered aircraft in the FAA survey.
#'
#' @param events Output of `extract_ntsb_balloon_events()`.
#' @param hours Data frame with `year` and `lta_hours` (and optionally
#'   `basis`), one row per year.
#' @return A list with `by_year` (one row per year), `summary` (one row: window,
#'   counts, hours, pilot micromorts per hour and a 95% exact Poisson interval)
#'   and `events_used`.
#' @keywords internal
#' @noRd
compute_balloon_risk <- function(events, hours) {
  checkmate::assert_data_frame(events)
  checkmate::assert_data_frame(hours, min.rows = 1L)
  checkmate::assert_subset(c("year", "lta_hours"), names(hours))
  if (anyDuplicated(hours$year) > 0L) {
    cli::cli_abort(c("x" = "{.arg hours} has more than one row for a year."))
  }

  used <- events[
    events$ev_type %in% "ACC" &
      events$ev_country %in% "USA" &
      events$far_part %in% c("091", "135") &
      events$ev_year %in% hours$year, ,
    drop = FALSE
  ]

  yrs <- sort(hours$year)
  by_year <- do.call(rbind, lapply(yrs, function(y) {
    e <- used[used$ev_year == y, , drop = FALSE]
    ev_fatal <- unique(e$ev_id[e$fatal_event_total > 0L])
    data.frame(
      year = y,
      lta_hours = hours$lta_hours[hours$year == y],
      accidents = length(unique(e$ev_id)),
      fatal_accidents = length(ev_fatal),
      pilot_deaths = sum(e$fatal_flight_crew),
      passenger_deaths = sum(e$fatal_passenger + e$fatal_lap_child),
      stringsAsFactors = FALSE
    )
  }))

  total_hours <- sum(by_year$lta_hours)
  pilot_deaths <- sum(by_year$pilot_deaths)
  ci <- stats::poisson.test(pilot_deaths, T = total_hours)$conf.int * 1e6
  summary <- data.frame(
    year_from = min(yrs),
    year_to = max(yrs),
    n_years = length(yrs),
    lta_hours = total_hours,
    accidents = sum(by_year$accidents),
    fatal_accidents = sum(by_year$fatal_accidents),
    pilot_deaths = pilot_deaths,
    passenger_deaths = sum(by_year$passenger_deaths),
    pilot_micromorts_per_hour = pilot_deaths / total_hours * 1e6,
    ci_low = ci[[1L]],
    ci_high = ci[[2L]],
    stringsAsFactors = FALSE
  )
  list(by_year = by_year, summary = summary, events_used = used)
}

#' Build the acute-risk CSV row for hot-air ballooning
#'
#' @param summary One-row `summary` from `compute_balloon_risk()`.
#' @param source_url Citation URL for the row.
#' @param source_id Source registry id.
#' @param last_accessed Date the sources were accessed.
#' @return A one-row data frame with the columns of
#'   `data-raw/sources/acute_risks_base.csv`.
#' @keywords internal
#' @noRd
balloon_acute_row <- function(summary, source_url, source_id, last_accessed) {
  mm <- round(summary$pilot_micromorts_per_hour, 2)
  data.frame(
    activity = "Hot-air ballooning, pilot (per flight hour)",
    micromorts = mm,
    microlives = round(mm * MICROLIVES_PER_MICROMORT, 1),
    category = "Sport",
    period = "per flight hour",
    period_type = "hour",
    period_days = 1 / 24,
    micromorts_per_day = round(mm * 24, 1),
    source_url = source_url,
    n_components = 1L,
    hedgeable_pct = 0,
    source_id = source_id,
    confidence = "low",
    year = summary$year_to,
    geography = "US",
    age_group = "all",
    last_accessed = as.character(last_accessed),
    stringsAsFactors = FALSE
  )
}
