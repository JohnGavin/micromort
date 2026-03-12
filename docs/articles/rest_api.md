# REST API

The micromort package includes a full REST API with 30 endpoints for
accessing risk data programmatically. The API is built with
[plumber](https://www.rplumber.io/) and returns JSON with a standard
response envelope.

## Getting Started

Launch the API from R:

``` r
library(micromort)
launch_api()
#> ── Micromort Data API ──
#> ℹ Starting server at http://127.0.0.1:8080
#> ℹ Swagger docs: http://127.0.0.1:8080/__docs__/
```

The interactive Swagger UI at `/__docs__/` lets you explore all
endpoints, view parameter descriptions, and try requests directly in the
browser.

## Response Envelope

Every endpoint returns a standard JSON envelope:

``` json
{
  "data": [ ... ],
  "meta": {
    "source": "micromort v0.4.0",
    "endpoint": "/v1/risks/acute",
    "n_rows": 10,
    "timestamp": "2026-03-09T12:00:00Z",
    "params": { "category": "Medical" }
  }
}
```

The `data` field contains the result (array or object). The `meta` field
includes package version, endpoint path, row count, ISO 8601 timestamp,
and the query parameters used.

## Core Risk Data

### Acute risks

Retrieve enriched acute risk data with optional filtering by category,
minimum micromort threshold, and result limit.

``` bash
curl "http://localhost:8080/v1/risks/acute?category=Medical&limit=10"
```

### Chronic risks

Query chronic lifestyle factors that gain or lose microlives per day.

``` bash
curl "http://localhost:8080/v1/risks/chronic?direction=gain"
```

### Cancer risks

Cancer mortality by type, sex, and age group with family history
multipliers.

``` bash
curl "http://localhost:8080/v1/risks/cancer?age_group=All%20ages"
```

## Risk Analysis

### Risk equivalence

Find activities with equivalent risk to a reference activity. The
response includes the ratio (how many of the reference activity equals
one of each comparison activity).

``` bash
curl "http://localhost:8080/v1/analysis/equivalence?reference=Chest+X-ray+(radiation+per+scan)"
```

### Exchange matrix

Build a cross-comparison matrix for multiple activities. This is a POST
endpoint that accepts a JSON body with an optional `activities` array:

``` bash
curl -X POST "http://localhost:8080/v1/analysis/exchange-matrix" \
  -H "Content-Type: application/json" \
  -d '{"activities": ["Skiing", "Scuba diving, trained", "Skydiving (US)"]}'
```

## Unit Conversion

Convert between probability, micromorts, microlives, and loss of life
expectancy.

``` bash
# Probability to micromorts
curl "http://localhost:8080/v1/convert/to-micromort?prob=0.000001"

# Micromorts to probability
curl "http://localhost:8080/v1/convert/to-probability?micromorts=1"

# Loss of life expectancy (minutes)
curl "http://localhost:8080/v1/convert/lle?prob=0.00001&life_expectancy=40"

# Monetary value of a micromort (default VSL = $10M)
curl "http://localhost:8080/v1/convert/value?vsl=10000000"
```

## Age-Based Hazard Rates

Calculate daily micromort exposure from background mortality at any age,
using Gompertz-Makeham mortality models.

``` bash
curl "http://localhost:8080/v1/convert/hazard-rate?age=50&sex=female"
```

## Full Endpoint Reference

All 30 API endpoints with their HTTP method, path, description, and
parameters:

## Using from R

You can call the API from R using [httr2](https://httr2.r-lib.org/):
