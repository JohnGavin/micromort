# Launch Micromort REST API

Starts a Plumber API server for accessing micromort datasets.

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

## Details

The API provides endpoints for:

- GET /v1/acute - Acute risks dataset

- GET /v1/chronic - Chronic risks dataset

- GET /v1/sources - Risk sources registry

- GET /v1/hazard - Daily hazard rate by age

- GET /v1/categories - Unique categories

- GET /v1/meta - API metadata

- GET /health - Health check

## Examples

``` r
if (FALSE) { # \dontrun{
# Start the API server
launch_api()

# Then in another session or browser:
# curl http://localhost:8080/v1/acute
# curl http://localhost:8080/v1/chronic?direction=gain
# curl http://localhost:8080/v1/hazard?age=35
} # }
```
