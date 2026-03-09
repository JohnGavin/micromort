#* @apiTitle Micromort Data API
#* @apiDescription Access micromort and microlife risk datasets via 27 REST
#*   endpoints. Every response uses a standard JSON envelope with `data` and
#*   `meta` fields including source provenance.
#* @apiVersion 1.0.0
#* @apiContact list(name = "John Gavin", email = "john.b.gavin@gmail.com")
#* @apiLicense list(name = "MIT", url = "https://opensource.org/licenses/MIT")

library(micromort)

# --- Helpers (named for testability) ------------------------------------------

#' Build standard API response envelope
api_response <- function(data, endpoint, params = list()) {
  n <- if (is.data.frame(data)) nrow(data) else length(data)
  list(
    data = data,
    meta = list(
      source = paste0("micromort v",
        as.character(utils::packageVersion("micromort"))),
      endpoint = endpoint,
      n_rows = n,
      timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      params = params
    )
  )
}

#' Return an error response with HTTP status code
api_error <- function(res, message, status = 400L) {
  res$status <- status
  list(error = message, status = status)
}

#' Parse comma-separated string into integer vector
parse_int_vec <- function(x) {
  as.integer(strsplit(x, ",\\s*")[[1]])
}

# === Group 1: Core Risks (8 GET) =============================================

#* Get acute risks (common_risks enriched dataset)
#* @param category Filter by category (Sport, Travel, Medical, etc.)
#* @param min_micromorts Minimum micromort threshold (default: 0)
#* @param limit Maximum number of records (default: 100)
#* @get /v1/risks/acute
#* @serializer json
handle_acute <- function(res, category = NULL, min_micromorts = 0, limit = 100) {
  tryCatch({
    data <- as.data.frame(common_risks())
    if (!is.null(category)) data <- data[data$category == category, ]
    data <- data[data$micromorts >= as.numeric(min_micromorts), ]
    data <- utils::head(data, as.numeric(limit))
    api_response(data, "/v1/risks/acute",
      list(category = category, min_micromorts = as.numeric(min_micromorts),
        limit = as.numeric(limit)))
  }, error = function(e) api_error(res, e$message))
}

#* Get atomic risk components
#* @param category Filter by category
#* @param component Filter by component type
#* @param hedgeable Filter by hedgeable status (true/false)
#* @get /v1/risks/acute/atomic
#* @serializer json
handle_atomic <- function(res, category = NULL, component = NULL,
                          hedgeable = NULL) {
  tryCatch({
    data <- as.data.frame(atomic_risks())
    if (!is.null(category)) data <- data[data$category == category, ]
    if (!is.null(component)) data <- data[data$component == component, ]
    if (!is.null(hedgeable)) {
      h <- tolower(hedgeable) == "true"
      data <- data[data$hedgeable == h, ]
    }
    api_response(data, "/v1/risks/acute/atomic",
      list(category = category, component = component, hedgeable = hedgeable))
  }, error = function(e) api_error(res, e$message))
}

#* Get chronic risks (microlife gains/losses)
#* @param direction Filter: "gain" or "loss"
#* @param category Filter by category
#* @get /v1/risks/chronic
#* @serializer json
handle_chronic <- function(res, direction = NULL, category = NULL) {
  tryCatch({
    data <- as.data.frame(chronic_risks())
    if (!is.null(direction)) data <- data[data$direction == direction, ]
    if (!is.null(category)) data <- data[data$category == category, ]
    api_response(data, "/v1/risks/chronic",
      list(direction = direction, category = category))
  }, error = function(e) api_error(res, e$message))
}

#* Get cancer risk data
#* @param sex Filter by sex
#* @param age_group Filter by age group
#* @param cancer_type Filter by cancer type
#* @get /v1/risks/cancer
#* @serializer json
handle_cancer <- function(res, sex = NULL, age_group = NULL,
                          cancer_type = NULL) {
  tryCatch({
    data <- as.data.frame(cancer_risks())
    if (!is.null(sex)) data <- data[data$sex == sex, ]
    if (!is.null(age_group)) data <- data[data$age_group == age_group, ]
    if (!is.null(cancer_type)) data <- data[data$cancer_type == cancer_type, ]
    api_response(data, "/v1/risks/cancer",
      list(sex = sex, age_group = age_group, cancer_type = cancer_type))
  }, error = function(e) api_error(res, e$message))
}

#* Get vaccination risk data
#* @param country Filter by country
#* @param age_group Filter by age group
#* @get /v1/risks/vaccination
#* @serializer json
handle_vaccination <- function(res, country = NULL, age_group = NULL) {
  tryCatch({
    data <- as.data.frame(vaccination_risks())
    if (!is.null(country)) data <- data[data$country == country, ]
    if (!is.null(age_group)) data <- data[data$age_group == age_group, ]
    api_response(data, "/v1/risks/vaccination",
      list(country = country, age_group = age_group))
  }, error = function(e) api_error(res, e$message))
}

#* Get COVID vaccine relative risks
#* @param age_group Filter by age group
#* @param vaccination_status Filter by vaccination status
#* @get /v1/risks/covid-vaccine
#* @serializer json
handle_covid_vaccine <- function(res, age_group = NULL,
                                 vaccination_status = NULL) {
  tryCatch({
    data <- as.data.frame(covid_vaccine_rr())
    if (!is.null(age_group)) data <- data[data$age_group == age_group, ]
    if (!is.null(vaccination_status)) {
      data <- data[data$vaccination_status == vaccination_status, ]
    }
    api_response(data, "/v1/risks/covid-vaccine",
      list(age_group = age_group, vaccination_status = vaccination_status))
  }, error = function(e) api_error(res, e$message))
}

#* Get conditional risk given disease
#* @param disease Disease: cardiovascular, cancer, respiratory, infectious, all
#* @get /v1/risks/conditional
#* @serializer json
handle_conditional <- function(res, disease = "all") {
  tryCatch({
    data <- as.data.frame(conditional_risk(disease = disease))
    api_response(data, "/v1/risks/conditional", list(disease = disease))
  }, error = function(e) api_error(res, e$message))
}

#* Get demographic risk factors
#* @get /v1/risks/demographic
#* @serializer json
handle_demographic <- function(res) {
  tryCatch({
    data <- as.data.frame(demographic_factors())
    api_response(data, "/v1/risks/demographic")
  }, error = function(e) api_error(res, e$message))
}

# === Group 2: Regional (4 GET) ================================================

#* Get regional life expectancy data
#* @param country ISO 2-letter country code
#* @param year Year
#* @param sex Sex: Male, Female, or Total
#* @param classification Classification: vanguard, average, or laggard
#* @get /v1/regional/life-expectancy
#* @serializer json
handle_life_expectancy <- function(res, country = NULL, year = NULL,
                                   sex = NULL, classification = NULL) {
  tryCatch({
    yr <- if (!is.null(year)) as.integer(year) else NULL
    data <- as.data.frame(regional_life_expectancy(
      country = country, year = yr, sex = sex, classification = classification
    ))
    api_response(data, "/v1/regional/life-expectancy",
      list(country = country, year = yr, sex = sex,
        classification = classification))
  }, error = function(e) api_error(res, e$message))
}

#* Get vanguard (best-performing) regions
#* @param country ISO 2-letter country code
#* @param year Year
#* @param sex Sex: Male, Female, or Total
#* @get /v1/regional/vanguard
#* @serializer json
handle_vanguard <- function(res, country = NULL, year = NULL, sex = NULL) {
  tryCatch({
    yr <- if (!is.null(year)) as.integer(year) else NULL
    data <- as.data.frame(vanguard_regions(
      country = country, year = yr, sex = sex
    ))
    api_response(data, "/v1/regional/vanguard",
      list(country = country, year = yr, sex = sex))
  }, error = function(e) api_error(res, e$message))
}

#* Get laggard (worst-performing) regions
#* @param country ISO 2-letter country code
#* @param year Year
#* @param sex Sex: Male, Female, or Total
#* @get /v1/regional/laggard
#* @serializer json
handle_laggard <- function(res, country = NULL, year = NULL, sex = NULL) {
  tryCatch({
    yr <- if (!is.null(year)) as.integer(year) else NULL
    data <- as.data.frame(laggard_regions(
      country = country, year = yr, sex = sex
    ))
    api_response(data, "/v1/regional/laggard",
      list(country = country, year = yr, sex = sex))
  }, error = function(e) api_error(res, e$message))
}

#* Get regional mortality multiplier
#* @param region_code NUTS2 region code (required)
#* @param reference Reference: "eu" or "national" (default: "eu")
#* @param year Reference year (default: 2019)
#* @get /v1/regional/mortality-multiplier
#* @serializer json
handle_mortality_multiplier <- function(res, region_code = NULL,
                                        reference = "eu", year = 2019) {
  if (is.null(region_code)) {
    return(api_error(res, "'region_code' parameter is required"))
  }
  tryCatch({
    data <- as.data.frame(regional_mortality_multiplier(
      region_code = region_code, reference = reference,
      year = as.integer(year)
    ))
    api_response(data, "/v1/regional/mortality-multiplier",
      list(region_code = region_code, reference = reference,
        year = as.integer(year)))
  }, error = function(e) api_error(res, e$message))
}

# === Group 3: Radiation (2 GET) ===============================================

#* Get radiation exposure profiles by career milestones
#* @param milestones Comma-separated career years (default: "10,20,40")
#* @get /v1/radiation/profiles
#* @serializer json
handle_radiation_profiles <- function(res, milestones = "10,20,40") {
  tryCatch({
    ms <- parse_int_vec(milestones)
    data <- as.data.frame(radiation_profiles(milestones = ms))
    api_response(data, "/v1/radiation/profiles", list(milestones = ms))
  }, error = function(e) api_error(res, e$message))
}

#* Compare patient vs occupational radiation exposure
#* @param xray_counts Comma-separated X-ray counts (default: "1,10,100")
#* @param career_years Comma-separated career years (default: "10,20,40")
#* @get /v1/radiation/patient-comparison
#* @serializer json
handle_patient_comparison <- function(res, xray_counts = "1,10,100",
                                      career_years = "10,20,40") {
  tryCatch({
    xc <- parse_int_vec(xray_counts)
    cy <- parse_int_vec(career_years)
    data <- as.data.frame(patient_radiation_comparison(
      xray_counts = xc, career_years = cy
    ))
    api_response(data, "/v1/radiation/patient-comparison",
      list(xray_counts = xc, career_years = cy))
  }, error = function(e) api_error(res, e$message))
}

# === Group 4: Analysis (2 GET + 4 POST) =======================================

#* Find activities with equivalent risk to reference
#* @param reference Reference activity name (required)
#* @param min_ratio Minimum ratio (default: 0.01)
#* @param max_ratio Maximum ratio (default: Inf)
#* @get /v1/analysis/equivalence
#* @serializer json
handle_equivalence <- function(res, reference = NULL, min_ratio = 0.01,
                               max_ratio = Inf) {
  if (is.null(reference)) {
    return(api_error(res, "'reference' parameter is required"))
  }
  tryCatch({
    data <- as.data.frame(risk_equivalence(
      reference = reference,
      min_ratio = as.numeric(min_ratio),
      max_ratio = as.numeric(max_ratio)
    ))
    api_response(data, "/v1/analysis/equivalence",
      list(reference = reference, min_ratio = as.numeric(min_ratio),
        max_ratio = as.numeric(max_ratio)))
  }, error = function(e) api_error(res, e$message))
}

#* Calculate lifestyle tradeoff between habits
#* @param bad_habit Bad habit factor name (required)
#* @param good_habit Compensating behavior name (required)
#* @get /v1/analysis/tradeoff
#* @serializer json
handle_tradeoff <- function(res, bad_habit = NULL, good_habit = NULL) {
  if (is.null(bad_habit) || is.null(good_habit)) {
    return(api_error(
      res, "'bad_habit' and 'good_habit' parameters are required"
    ))
  }
  tryCatch({
    data <- as.data.frame(lifestyle_tradeoff(
      bad_habit = bad_habit, good_habit = good_habit
    ))
    api_response(data, "/v1/analysis/tradeoff",
      list(bad_habit = bad_habit, good_habit = good_habit))
  }, error = function(e) api_error(res, e$message))
}

#* Build risk exchange matrix
#* @post /v1/analysis/exchange-matrix
#* @serializer json
handle_exchange_matrix <- function(req, res, activities = NULL) {
  tryCatch({
    result <- as.data.frame(risk_exchange_matrix(activities = activities))
    api_response(result, "/v1/analysis/exchange-matrix",
      list(activities = activities))
  }, error = function(e) api_error(res, e$message))
}

#* Compare risk-reduction interventions
#* @post /v1/analysis/interventions
#* @serializer json
handle_interventions <- function(req, res, interventions = NULL) {
  if (is.null(interventions)) {
    return(api_error(
      res, "Request body must include 'interventions' object"
    ))
  }
  tryCatch({
    result <- as.data.frame(compare_interventions(
      interventions = interventions
    ))
    api_response(result, "/v1/analysis/interventions",
      list(interventions = names(interventions)))
  }, error = function(e) api_error(res, e$message))
}

#* Calculate annual risk budget
#* @post /v1/analysis/budget
#* @serializer json
handle_budget <- function(req, res, activities = NULL, age = NULL) {
  if (is.null(activities)) {
    return(api_error(
      res, "Request body must include 'activities' object"
    ))
  }
  tryCatch({
    acts <- unlist(activities)
    a <- if (!is.null(age)) as.numeric(age) else NULL
    result <- as.data.frame(annual_risk_budget(activities = acts, age = a))
    api_response(result, "/v1/analysis/budget",
      list(n_activities = length(acts), age = a))
  }, error = function(e) api_error(res, e$message))
}

#* Build hedged risk portfolio
#* @post /v1/analysis/hedged-portfolio
#* @serializer json
handle_hedged_portfolio <- function(req, res, include_diseases = NULL) {
  tryCatch({
    if (!is.null(include_diseases)) {
      result <- hedged_portfolio(include_diseases = include_diseases)
    } else {
      result <- hedged_portfolio()
    }
    api_response(result, "/v1/analysis/hedged-portfolio",
      list(include_diseases = include_diseases))
  }, error = function(e) api_error(res, e$message))
}

# === Group 5: Conversion (6 GET) ==============================================

#* Convert probability to micromorts
#* @param prob Probability of death 0-1 (required)
#* @get /v1/convert/to-micromort
#* @serializer json
handle_to_micromort <- function(res, prob = NULL) {
  if (is.null(prob)) {
    return(api_error(res, "'prob' parameter is required"))
  }
  tryCatch({
    result <- as.numeric(as_micromort(as.numeric(prob)))
    api_response(
      list(micromorts = result, prob = as.numeric(prob)),
      "/v1/convert/to-micromort", list(prob = as.numeric(prob))
    )
  }, error = function(e) api_error(res, e$message))
}

#* Convert micromorts to probability
#* @param micromorts Risk in micromorts (required)
#* @get /v1/convert/to-probability
#* @serializer json
handle_to_probability <- function(res, micromorts = NULL) {
  if (is.null(micromorts)) {
    return(api_error(res, "'micromorts' parameter is required"))
  }
  tryCatch({
    result <- as.numeric(as_probability(as.numeric(micromorts)))
    api_response(
      list(probability = result, micromorts = as.numeric(micromorts)),
      "/v1/convert/to-probability",
      list(micromorts = as.numeric(micromorts))
    )
  }, error = function(e) api_error(res, e$message))
}

#* Convert minutes of life expectancy to microlives
#* @param minutes Life expectancy change in minutes (required)
#* @get /v1/convert/to-microlife
#* @serializer json
handle_to_microlife <- function(res, minutes = NULL) {
  if (is.null(minutes)) {
    return(api_error(res, "'minutes' parameter is required"))
  }
  tryCatch({
    result <- as.numeric(as_microlife(as.numeric(minutes)))
    api_response(
      list(microlives = result, minutes = as.numeric(minutes)),
      "/v1/convert/to-microlife", list(minutes = as.numeric(minutes))
    )
  }, error = function(e) api_error(res, e$message))
}

#* Calculate monetary value of one micromort
#* @param vsl Value of Statistical Life (default: 10000000)
#* @get /v1/convert/value
#* @serializer json
handle_value <- function(res, vsl = 10000000) {
  tryCatch({
    result <- as.numeric(value_of_micromort(vsl = as.numeric(vsl)))
    api_response(
      list(value_per_micromort = result, vsl = as.numeric(vsl)),
      "/v1/convert/value", list(vsl = as.numeric(vsl))
    )
  }, error = function(e) api_error(res, e$message))
}

#* Calculate loss of life expectancy
#* @param prob Probability of death 0-1 (required)
#* @param life_expectancy Remaining life expectancy in years (default: 40)
#* @get /v1/convert/lle
#* @serializer json
handle_lle <- function(res, prob = NULL, life_expectancy = 40) {
  if (is.null(prob)) {
    return(api_error(res, "'prob' parameter is required"))
  }
  tryCatch({
    result <- as.numeric(lle(
      as.numeric(prob), life_expectancy = as.numeric(life_expectancy)
    ))
    api_response(
      list(lle_minutes = result, prob = as.numeric(prob),
        life_expectancy = as.numeric(life_expectancy)),
      "/v1/convert/lle",
      list(prob = as.numeric(prob),
        life_expectancy = as.numeric(life_expectancy))
    )
  }, error = function(e) api_error(res, e$message))
}

#* Calculate daily hazard rate by age and sex
#* @param age Age in years (required)
#* @param sex Sex: "male" or "female" (default: "male")
#* @get /v1/convert/hazard-rate
#* @serializer json
handle_hazard_rate <- function(res, age = NULL, sex = "male") {
  if (is.null(age)) {
    return(api_error(res, "'age' parameter is required"))
  }
  tryCatch({
    data <- as.data.frame(daily_hazard_rate(as.numeric(age), sex))
    api_response(data, "/v1/convert/hazard-rate",
      list(age = as.numeric(age), sex = sex))
  }, error = function(e) api_error(res, e$message))
}

# === Group 6: Quiz (1 GET) ====================================================

#* Get quiz pairs for micromort comparison game
#* @param min_ratio Minimum ratio between values (default: 1.1)
#* @param max_ratio Maximum ratio between values (default: 2.0)
#* @param seed Random seed for reproducibility
#* @get /v1/quiz/pairs
#* @serializer json
handle_quiz_pairs <- function(res, min_ratio = 1.1, max_ratio = 2.0,
                              seed = NULL) {
  tryCatch({
    sd <- if (!is.null(seed)) as.integer(seed) else NULL
    data <- as.data.frame(quiz_pairs(
      min_ratio = as.numeric(min_ratio),
      max_ratio = as.numeric(max_ratio),
      seed = sd
    ))
    api_response(data, "/v1/quiz/pairs",
      list(min_ratio = as.numeric(min_ratio),
        max_ratio = as.numeric(max_ratio), seed = sd))
  }, error = function(e) api_error(res, e$message))
}

# === Group 7: Metadata (3 endpoints) ==========================================

#* Get risk data sources registry
#* @param type Filter by source type
#* @get /v1/sources
#* @serializer json
handle_sources <- function(res, type = NULL) {
  tryCatch({
    data <- as.data.frame(load_sources())
    if (!is.null(type)) data <- data[data$type == type, ]
    api_response(data, "/v1/sources", list(type = type))
  }, error = function(e) api_error(res, e$message))
}

#* API metadata: all endpoints and dataset counts
#* @get /v1/meta
#* @serializer json
handle_meta <- function(res) {
  tryCatch({
    list(
      version = "1.0.0",
      package_version = as.character(utils::packageVersion("micromort")),
      endpoints = list(
        risks = list(
          "/v1/risks/acute", "/v1/risks/acute/atomic",
          "/v1/risks/chronic", "/v1/risks/cancer",
          "/v1/risks/vaccination", "/v1/risks/covid-vaccine",
          "/v1/risks/conditional", "/v1/risks/demographic"
        ),
        regional = list(
          "/v1/regional/life-expectancy", "/v1/regional/vanguard",
          "/v1/regional/laggard", "/v1/regional/mortality-multiplier"
        ),
        radiation = list(
          "/v1/radiation/profiles", "/v1/radiation/patient-comparison"
        ),
        analysis = list(
          "/v1/analysis/equivalence", "/v1/analysis/tradeoff",
          "/v1/analysis/exchange-matrix", "/v1/analysis/interventions",
          "/v1/analysis/budget", "/v1/analysis/hedged-portfolio"
        ),
        convert = list(
          "/v1/convert/to-micromort", "/v1/convert/to-probability",
          "/v1/convert/to-microlife", "/v1/convert/value",
          "/v1/convert/lle", "/v1/convert/hazard-rate"
        ),
        quiz = list("/v1/quiz/pairs"),
        metadata = list("/v1/sources", "/v1/meta", "/health")
      ),
      datasets = list(
        acute_risks = nrow(common_risks()),
        chronic_risks = nrow(chronic_risks()),
        cancer_risks = nrow(cancer_risks()),
        vaccination_risks = nrow(vaccination_risks()),
        sources = nrow(load_sources())
      )
    )
  }, error = function(e) api_error(res, e$message))
}

#* Health check
#* @get /health
#* @serializer json
handle_health <- function() {
  list(
    status = "healthy",
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    r_version = R.version.string
  )
}
