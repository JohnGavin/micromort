# Fix #36: Public REST API (27 Endpoints)
# https://github.com/johngavin/micromort/issues/36
#
# Changes:
# 1. inst/plumber/api.R — REWRITTEN: 7 → 27 endpoints
#    - Standard JSON envelope (data + meta) on every response
#    - api_response(), api_error(), parse_int_vec() helpers
#    - All handlers named (handle_*) for testability
#    - tryCatch error handling with HTTP 400 on bad input
#    - Routes renamed: /v1/acute → /v1/risks/acute etc.
#    - Uses common_risks() not load_acute_risks() for richer schema
#
# 2. R/api.R — roxygen updated to list all 27 endpoints by group
#
# 3. tests/testthat/test-api.R — CREATED: ~30 tests
#    - Envelope structure (data + meta keys)
#    - Filter params narrow results
#    - Required params missing → HTTP 400
#    - POST body absent → 400
#    - Comma-separated int parsing
#    - /v1/meta lists all 27 routes
#
# Endpoint groups:
#   Group 1: Core Risks      — 8 GET
#   Group 2: Regional         — 4 GET
#   Group 3: Radiation        — 2 GET
#   Group 4: Analysis         — 2 GET + 4 POST
#   Group 5: Conversion       — 6 GET
#   Group 6: Quiz             — 1 GET
#   Group 7: Metadata         — 3 endpoints
#   Total                     — 27

# Verify
if (FALSE) {
  devtools::document()
  devtools::test(filter = "api")
  pkgload::load_all()
}
