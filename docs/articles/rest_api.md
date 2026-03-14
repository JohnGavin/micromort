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

Show code

``` r
acute <- safe_tar_read("vig_api_acute_sample")
if (!is.null(acute)) {
  DT::datatable(
    acute,
    caption = "GET /v1/risks/acute?category=Medical — Medical activities ranked by risk",
    options = list(pageLength = 10, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatRound(c("micromorts", "microlives"), 2)
}
```

### Chronic risks

Query chronic lifestyle factors that gain or lose microlives per day.

``` bash
curl "http://localhost:8080/v1/risks/chronic?direction=gain"
```

Show code

``` r
chronic <- safe_tar_read("vig_api_chronic_gains")
if (!is.null(chronic)) {
  DT::datatable(
    chronic,
    caption = "GET /v1/risks/chronic?direction=gain — Factors that extend life",
    options = list(pageLength = 15, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatRound("microlives_per_day", 1)
}
```

### Cancer risks

Cancer mortality by type, sex, and age group with family history
multipliers.

``` bash
curl "http://localhost:8080/v1/risks/cancer?age_group=All%20ages"
```

Show code

``` r
cancer <- safe_tar_read("vig_api_cancer_top3")
if (!is.null(cancer)) {
  DT::datatable(
    cancer,
    caption = "GET /v1/risks/cancer — Top 3 cancers per sex (All ages)",
    options = list(pageLength = 10, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatRound(c("deaths_per_100k", "micromorts_per_year"), 1)
}
```

## Risk Analysis

### Risk equivalence

Find activities with equivalent risk to a reference activity. The
response includes the ratio (how many of the reference activity equals
one of each comparison activity).

``` bash
curl "http://localhost:8080/v1/analysis/equivalence?reference=Chest+X-ray+(radiation+per+scan)"
```

Show code

``` r
equiv <- safe_tar_read("vig_api_equivalence_sample")
if (!is.null(equiv)) {
  DT::datatable(
    equiv,
    caption = "GET /v1/analysis/equivalence — Activities expressed in chest X-ray equivalents",
    options = list(pageLength = 15, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatRound("ratio", 1)
}
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

Show code

``` r
conversions <- safe_tar_read("vig_api_conversion_table")
if (!is.null(conversions)) {
  DT::datatable(
    conversions,
    caption = "Unit conversions across the probability-to-microlife spectrum",
    options = list(pageLength = 10, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatSignif(c("probability", "micromorts", "lle_minutes", "microlife"), 3)
}
```

## Age-Based Hazard Rates

Calculate daily micromort exposure from background mortality at any age,
using Gompertz-Makeham mortality models.

``` bash
curl "http://localhost:8080/v1/convert/hazard-rate?age=50&sex=female"
```

Show code

``` r
hazard <- safe_tar_read("vig_api_hazard_ages")
if (!is.null(hazard)) {
  DT::datatable(
    hazard,
    caption = "GET /v1/convert/hazard-rate — Daily background mortality by age and sex",
    options = list(pageLength = 12, dom = "tip", scrollX = TRUE),
    rownames = FALSE
  ) |>
    DT::formatRound("micromorts", 1) |>
    DT::formatSignif("daily_prob", 3)
}
```

## Full Endpoint Reference

All 30 API endpoints with their HTTP method, path, description, and
parameters:

Show code

``` r
endpoints <- safe_tar_read("vig_api_endpoint_summary")
if (!is.null(endpoints)) {
  DT::datatable(
    endpoints,
    caption = "Complete API endpoint reference",
    options = list(
      pageLength = 30,
      dom = "ftip",
      columnDefs = list(list(width = "250px", targets = 1))
    ),
    rownames = FALSE,
    filter = "top"
  )
}
```

## Using from R

You can call the API from R using [httr2](https://httr2.r-lib.org/):

Show code

``` r
library(httr2)

base_url <- "http://localhost:8080"

# GET request with query parameters
resp <- request(base_url) |>
  req_url_path("/v1/risks/acute") |>
  req_url_query(category = "Sport", limit = 5) |>
  req_perform() |>
  resp_body_json()

# The data lives in resp$data
tibble::as_tibble(do.call(rbind, lapply(resp$data, as.data.frame)))

# POST request with JSON body
resp <- request(base_url) |>
  req_url_path("/v1/analysis/exchange-matrix") |>
  req_body_json(list(
    activities = c("Skiing", "Scuba diving, trained")
  )) |>
  req_perform() |>
  resp_body_json()
```

## Reproducibility

Show code

``` r
sessionInfo()
#> R version 4.5.2 (2025-10-31)
#> Platform: aarch64-apple-darwin25.2.0
#> Running under: macOS Tahoe 26.3
#> 
#> Matrix products: default
#> BLAS:   /nix/store/ab8sq4g14lg45192ykfqcklgw6fvaswh-blas-3/lib/libblas.dylib 
#> LAPACK: /nix/store/ssl6kfm7w37gz5pn57jn2x7xzw3bss24-openblas-0.3.30/lib/libopenblasp-r0.3.30.dylib;  LAPACK version 3.12.0
#> 
#> locale:
#> [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
#> 
#> time zone: Europe/Belfast
#> tzcode source: internal
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] DT_0.34.0       targets_1.11.4  micromort_0.1.0 testthat_3.3.2 
#> 
#> loaded via a namespace (and not attached):
#>  [1] gtable_0.3.6        xfun_0.56           bslib_0.10.0       
#>  [4] ggplot2_4.0.1       htmlwidgets_1.6.4   processx_3.8.6     
#>  [7] callr_3.7.6         vctrs_0.7.1         tools_4.5.2        
#> [10] crosstalk_1.2.2     ps_1.9.1            generics_0.1.4     
#> [13] base64url_1.4       tibble_3.3.1        pkgconfig_2.0.3    
#> [16] data.table_1.18.2.1 checkmate_2.3.3     secretbase_1.1.1   
#> [19] RColorBrewer_1.1-3  S7_0.2.1            desc_1.4.3         
#> [22] assertthat_0.2.1    lifecycle_1.0.5     compiler_4.5.2     
#> [25] farver_2.1.2        credentials_2.0.3   brio_1.1.5         
#> [28] codetools_0.2-20    sass_0.4.10         htmltools_0.5.9    
#> [31] sys_3.4.3           usethis_3.2.1       yaml_2.3.12        
#> [34] jquerylib_0.1.4     pillar_1.11.1       openssl_2.3.4      
#> [37] cachem_1.1.0        tidyselect_1.2.1    digest_0.6.39      
#> [40] dplyr_1.1.4         purrr_1.2.1         arrow_22.0.0       
#> [43] rprojroot_2.1.1     fastmap_1.2.0       grid_4.5.2         
#> [46] cli_3.6.5           magrittr_2.0.4      pkgbuild_1.4.8     
#> [49] withr_3.0.2         prettyunits_1.2.0   scales_1.4.0       
#> [52] backports_1.5.0     bit64_4.6.0-1       rmarkdown_2.30     
#> [55] igraph_2.2.1        bit_4.6.0           otel_0.2.0         
#> [58] askpass_1.2.1       evaluate_1.0.5      knitr_1.51         
#> [61] rlang_1.1.7         gert_2.3.1          glue_1.8.0         
#> [64] pkgload_1.4.1       jsonlite_2.0.0      R6_2.6.1           
#> [67] fs_1.6.6
```
