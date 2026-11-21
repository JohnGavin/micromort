#!/bin/bash
# data-raw/07_ntsb_balloon_extract.sh
# Fetch the NTSB aviation accident database (avall.zip, an Access .mdb, about
# 100 MB, covers 2008 to the current month) and reduce it to a small CSV of
# balloon accident records, data-raw/sources/ntsb_balloon_events.csv, using
# extract_ntsb_balloon_events() from R/balloon_risk.R. US-government work
# (public domain). The raw database is not committed; the provenance file
# records its URL, size, sha256 and the access date.
#
# Needs: curl, unzip and the project R shell. mdb-export (mdbtools) is used
# from PATH if present, otherwise through `nix-shell -p mdbtools`.
#   nix-shell ROOT/default.nix --run "bash ROOT/data-raw/07_ntsb_balloon_extract.sh ROOT"
# Downloaded data is untrusted: it is only read by mdb-export and R, never run.
#
# usage: bash data-raw/07_ntsb_balloon_extract.sh [REPO_ROOT]
set -euo pipefail

root="${1:-.}"
url="https://data.ntsb.gov/avdata/FileDirectory/DownloadFile?fileID=avall.zip"
out_csv="$root/data-raw/sources/ntsb_balloon_events.csv"
prov_csv="$root/data-raw/sources/ntsb_balloon_events_provenance.csv"

work="$(mktemp -d)"
curl -fsSL --max-time 600 -o "$work/avall.zip" "$url"
sum="$(shasum -a 256 "$work/avall.zip" | cut -d' ' -f1)"
bytes="$(wc -c < "$work/avall.zip" | tr -d ' ')"
mdb_date="$(unzip -l "$work/avall.zip" | awk '/avall\.mdb/ {print $2}')"

mkdir "$work/mdb"
unzip -q -d "$work/mdb" "$work/avall.zip"
for t in aircraft events injury; do
  if command -v mdb-export > /dev/null; then
    mdb-export "$work/mdb/avall.mdb" "$t" > "$work/$t.csv"
  else
    # mktemp paths contain no spaces, so plain interpolation is safe here
    nix-shell -p mdbtools --run "mdb-export $work/mdb/avall.mdb $t" > "$work/$t.csv"
  fi
done

Rscript "$root/data-raw/07_ntsb_balloon_extract.R" \
  "$root" "$work/aircraft.csv" "$work/events.csv" "$work/injury.csv" "$out_csv"

{
  echo "url,sha256_avall_zip,bytes,avall_mdb_date_in_zip,last_accessed"
  echo "\"$url\",$sum,$bytes,$mdb_date,$(date -u +%Y-%m-%d)"
} > "$prov_csv"
echo "wrote $out_csv and $prov_csv (scratch dir: $work)"
