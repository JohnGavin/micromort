#* @apiTitle Micromort Data API
#* @apiDescription Access micromort and microlife datasets via REST API.
#* Provides endpoints for acute risks, chronic risks, and risk analysis.
#* @apiVersion 1.0.0
#* @apiContact list(name = "John Gavin", email = "john.b.gavin@gmail.com")
#* @apiLicense list(name = "MIT", url = "https://opensource.org/licenses/MIT")

library(micromort)

#* API metadata
#* @get /v1/meta
#* @serializer json
function() {
  list(
    version = "1.0.0",
    package_version = as.character(packageVersion("micromort")),
    endpoints = list(
      acute = "/v1/acute",
      chronic = "/v1/chronic",
      sources = "/v1/sources",
      hazard = "/v1/hazard",
      compare = "/v1/compare"
    ),
    documentation = "https://johngavin.github.io/micromort/",
    datasets = list(
      acute_count = nrow(load_acute_risks()),
      chronic_count = nrow(load_chronic_risks()),
      sources_count = nrow(load_sources())
    )
  )
}

#* Get acute risks dataset
#* @param category Filter by category (Sport, Travel, Medical, etc.)
#* @param min_micromorts Minimum micromort threshold (default: 0)
#* @param limit Maximum number of records to return (default: 100)
#* @get /v1/acute
#* @serializer json
function(category = NULL, min_micromorts = 0, limit = 100) {
  data <- load_acute_risks()

  if (!is.null(category)) {
    data <- data[data$category == category, ]
  }

  data <- data[data$micromorts >= as.numeric(min_micromorts), ]
  data <- head(data, as.numeric(limit))

  as.data.frame(data)
}

#* Get chronic risks dataset
#* @param direction Filter by direction: "gain" or "loss"
#* @param category Filter by category
#* @get /v1/chronic
#* @serializer json
function(direction = NULL, category = NULL) {
  data <- load_chronic_risks()

  if (!is.null(direction)) {
    data <- data[data$direction == direction, ]
  }

  if (!is.null(category)) {
    data <- data[data$category == category, ]
  }

  as.data.frame(data)
}

#* Get risk sources registry
#* @param type Filter by source type (academic, government, database, etc.)
#* @get /v1/sources
#* @serializer json
function(type = NULL) {
  data <- load_sources()

  if (!is.null(type)) {
    data <- data[data$type == type, ]
  }

  as.data.frame(data)
}

#* Calculate daily hazard rate by age
#* @param age Age in years (required)
#* @param sex Sex: "male" or "female" (default: "male")
#* @get /v1/hazard
#* @serializer json
function(age, sex = "male") {
  if (missing(age)) {
    return(list(error = "age parameter is required"))
  }

  result <- tryCatch(
    daily_hazard_rate(as.numeric(age), sex),
    error = function(e) list(error = e$message)
  )

  if (is.data.frame(result)) {
    as.data.frame(result)
  } else {
    result
  }
}

#* Get unique categories
#* @param type Type of data: "acute" or "chronic"
#* @get /v1/categories
#* @serializer json
function(type = "acute") {
  if (type == "acute") {
    data <- load_acute_risks()
  } else {
    data <- load_chronic_risks()
  }

  sort(unique(data$category))
}

#* Health check
#* @get /health
#* @serializer json
function() {
  list(
    status = "healthy",
    timestamp = Sys.time(),
    r_version = R.version.string
  )
}
