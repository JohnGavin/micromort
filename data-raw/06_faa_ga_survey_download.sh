#!/bin/bash
# data-raw/06_faa_ga_survey_download.sh
# Download FAA General Aviation and Part 135 Activity Survey, Chapter III
# (Table 3.2: total hours flown by actual use by aircraft type) for each year
# listed in data-raw/sources/faa_ga_survey_urls.csv, and reduce them to
# data-raw/sources/faa_lta_hours.csv (lighter-than-air hours per year, with the
# URL, sha256 and access date of each workbook) using read_faa_lta_hours() from
# R/balloon_risk.R. US-government work (public domain).
#
# The workbooks themselves are not committed (the repository's document guard
# keeps spreadsheets out of public repos); the sha256 in the output lets anyone
# check that a fresh download is the file that was parsed.
#
# usage: nix-shell ROOT/default.nix --run "bash ROOT/data-raw/06_faa_ga_survey_download.sh ROOT"
# Downloaded files are untrusted data: they are only read by readxl, never run.
set -euo pipefail

root="${1:-.}"
work="$(mktemp -d)"
accessed="$(date -u +%Y-%m-%d)"

tail -n +2 "$root/data-raw/sources/faa_ga_survey_urls.csv" | while IFS=, read -r year file url; do
  curl -fsSL --max-time 120 -o "$work/$file" "$url"
  echo "downloaded $year -> $file"
done

Rscript "$root/data-raw/06_faa_lta_hours_extract.R" \
  "$root" "$work" "$accessed" "$root/data-raw/sources/faa_lta_hours.csv"
echo "scratch dir: $work"
