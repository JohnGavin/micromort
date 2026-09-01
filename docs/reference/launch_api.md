# Launch Micromort REST API

Starts a Plumber API server exposing 27 endpoints for accessing
micromort and microlife risk datasets. Every response uses a standard
JSON envelope with `data` and `meta` fields including source provenance.

## Usage

``` r
launch_api(host = "127.0.0.1", port = 8080, docs = TRUE)
```

## Arguments

- host:

  Host to bind to (default: "127.0.0.1")

- port:

  Port to listen on (default: 8080)

- docs:

  Enable Swagger documentation (default: TRUE)

## Value

Invisible NULL. Runs the API server until interrupted.

## Core Risks (8 GET)

- `GET /v1/risks/acute` — Enriched acute risks (common_risks)

- `GET /v1/risks/acute/atomic` — Atomic risk components

- `GET /v1/risks/chronic` — Chronic microlife gains/losses

- `GET /v1/risks/cancer` — Cancer risk by type/sex/age

- `GET /v1/risks/vaccination` — Vaccination risk reduction

- `GET /v1/risks/covid-vaccine` — COVID vaccine relative risks

- `GET /v1/risks/conditional` — Conditional risk given disease

- `GET /v1/risks/demographic` — Demographic risk factors

## Regional (4 GET)

- `GET /v1/regional/life-expectancy` — Regional life expectancy

- `GET /v1/regional/vanguard` — Best-performing regions

- `GET /v1/regional/laggard` — Worst-performing regions

- `GET /v1/regional/mortality-multiplier` — Mortality multiplier

## Radiation (2 GET)

- `GET /v1/radiation/profiles` — Exposure by career milestones

- `GET /v1/radiation/patient-comparison` — Patient vs occupational

## Analysis (2 GET + 4 POST)

- `GET /v1/analysis/equivalence` — Risk equivalence lookup

- `GET /v1/analysis/tradeoff` — Lifestyle tradeoff calculator

- `POST /v1/analysis/exchange-matrix` — Risk exchange matrix

- `POST /v1/analysis/interventions` — Compare interventions

- `POST /v1/analysis/budget` — Annual risk budget

- `POST /v1/analysis/hedged-portfolio` — Hedged risk portfolio

## Conversion (6 GET)

- `GET /v1/convert/to-micromort` — Probability to micromorts

- `GET /v1/convert/to-probability` — Micromorts to probability

- `GET /v1/convert/to-microlife` — Minutes to microlives

- `GET /v1/convert/value` — Monetary value of one micromort

- `GET /v1/convert/lle` — Loss of life expectancy

- `GET /v1/convert/hazard-rate` — Daily hazard rate by age

## Quiz (1 GET)

- `GET /v1/quiz/pairs` — Quiz pairs for comparison game

## Metadata (3 endpoints)

- `GET /v1/sources` — Risk data sources registry

- `GET /v1/meta` — API metadata and endpoint listing

- `GET /health` — Health check

## Examples

``` r
if (FALSE) { # \dontrun{
launch_api()

# Example requests (from another terminal):
# curl http://localhost:8080/v1/risks/acute?category=Sport
# curl http://localhost:8080/v1/risks/chronic?direction=gain
# curl http://localhost:8080/v1/convert/hazard-rate?age=35
} # }
```
