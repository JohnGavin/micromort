# Internal functions that generate mermaid diagram text from package metadata.
# Called by targets in plan_vignette_outputs.R -- never in vignettes directly.
# All functions return character strings of valid mermaid markup.

#' Shared dark theme header for mermaid diagrams
#'
#' Returns the `%%{init:...}%%` block with high-contrast dark theme:
#' black background, gray-60 (`#999999`) box fill, black text, red arrows.
#'
#' @return Single character string.
#' @noRd
mermaid_dark_theme_header <- function() {

  # High-contrast dark theme: black background, gray-60 boxes,

  # black text, red arrows/connections.
  paste0(
    "%%{init: {'theme': 'dark', 'themeVariables': {",
    "'primaryColor': '#999999', ",
    "'primaryTextColor': '#000000', ",
    "'primaryBorderColor': '#CC0000', ",
    "'lineColor': '#CC0000', ",
    "'secondaryColor': '#999999', ",
    "'tertiaryColor': '#999999', ",
    "'background': '#000000', ",
    "'mainBkg': '#999999', ",
    "'nodeBorder': '#CC0000', ",
    "'clusterBkg': '#333333', ",
    "'clusterBorder': '#CC0000', ",
    "'titleColor': '#000000', ",
    "'edgeLabelBackground': '#999999'",
    "}}}%%"
  )
}


# Category lookup for package exports.
# Maps function names to high-level categories. New exports not listed here
# will appear under "Other", signalling the lookup needs updating.
.export_categories <- function() {
  c(
    # Conversion
    as_micromort = "Conversion", as_microlife = "Conversion",
    as_probability = "Conversion", lle = "Conversion",
    value_of_micromort = "Conversion",
    # Data
    load_acute_risks = "Data", load_chronic_risks = "Data",
    load_sources = "Data", common_risks = "Data",
    atomic_risks = "Data", risk_components = "Data",
    risk_for_duration = "Data", risk_data_sources = "Data",
    acute_risks = "Data", chronic_risks = "Data",
    # Regional
    regional_life_expectancy = "Regional",
    vanguard_regions = "Regional", laggard_regions = "Regional",
    regional_mortality_multiplier = "Regional",
    # Conditional
    cancer_risks = "Conditional", vaccination_risks = "Conditional",
    conditional_risk = "Conditional", hedged_portfolio = "Conditional",
    covid_vaccine_rr = "Conditional", demographic_factors = "Conditional",
    # Radiation
    radiation_profiles = "Radiation",
    patient_radiation_comparison = "Radiation",
    # Analysis
    risk_equivalence = "Analysis", risk_exchange_matrix = "Analysis",
    compare_interventions = "Analysis", lifestyle_tradeoff = "Analysis",
    daily_hazard_rate = "Analysis", annual_risk_budget = "Analysis",
    # Visualization
    prepare_risks_plot = "Visualization", plot_risks = "Visualization",
    plot_risks_interactive = "Visualization",
    plot_risk_components = "Visualization",
    theme_micromort_dark = "Visualization",
    # Apps
    launch_api = "Apps", launch_dashboard = "Apps",
    launch_quiz = "Apps", quiz_pairs = "Apps",
    activity_descriptions = "Apps", format_activity_name = "Apps"
  )
}


#' Generate pipeline overview diagram
#'
#' Reads plan files from `R/tar_plans/` and counts `tar_target()` calls
#' per plan to show the data pipeline stages.
#'
#' @return Character string of mermaid `graph LR`.
#' @noRd
generate_pipeline_diagram <- function() {
  pkg_root <- tryCatch(
    rprojroot::find_root(rprojroot::is_r_package),
    error = function(e) "."
  )

  plan_dir <- file.path(pkg_root, "R", "tar_plans")
  plan_files <- list.files(plan_dir, pattern = "^plan_.*\\.R$", full.names = TRUE)

  counts <- vapply(plan_files, function(f) {
    sum(grepl("tar_target\\s*\\(", readLines(f, warn = FALSE)))
  }, integer(1))
  nms <- gsub("^plan_|\\.R$", "", basename(names(counts)))
  names(counts) <- nms

  n <- function(name) {
    val <- counts[name]
    if (is.na(val)) 0L else unname(val)
  }

  lines <- c(
    mermaid_dark_theme_header(),
    "graph LR",
    "",
    "  subgraph S1[\"1. Data Acquisition\"]",
    sprintf("    acq[\"CSV + API sources<br>%d targets\"]", n("data_acquisition")),
    "  end",
    "",
    "  subgraph S2[\"2. Normalisation\"]",
    sprintf("    norm[\"Schema validation<br>%d targets\"]", n("normalization")),
    "  end",
    "",
    "  subgraph S3[\"3. Export\"]",
    sprintf("    exp[\"Parquet + RDS<br>%d targets\"]", n("export")),
    "  end",
    "",
    "  subgraph S4[\"4. Quality\"]",
    sprintf("    log[\"Logging: %d targets\"]", n("logging")),
    sprintf("    val[\"Validation: %d targets\"]", n("validation")),
    "  end",
    "",
    "  subgraph S5[\"5. Documentation\"]",
    sprintf("    doc[\"Docs: %d targets\"]", n("documentation")),
    sprintf("    vig[\"Vignettes: %d targets\"]", n("vignette_outputs")),
    "  end",
    "",
    "  S1 --> S2 --> S3 --> S4 --> S5",
    "",
    "  style S1 fill:#999999,stroke:#CC0000,color:#000000",
    "  style S2 fill:#999999,stroke:#CC0000,color:#000000",
    "  style S3 fill:#999999,stroke:#CC0000,color:#000000",
    "  style S4 fill:#999999,stroke:#CC0000,color:#000000",
    "  style S5 fill:#999999,stroke:#CC0000,color:#000000"
  )

  paste(lines, collapse = "\n")
}


#' Generate concept hierarchy diagram
#'
#' Introspects `getNamespaceExports("micromort")` and groups by category.
#'
#' @param simplified If `TRUE`, merge sub-categories into a 5-box overview.
#' @param clickable If `TRUE`, add click directives linking to pkgdown pages.
#' @return Character string of mermaid diagram.
#' @noRd
generate_concept_diagram <- function(simplified = FALSE, clickable = TRUE) {
  exports <- sort(getNamespaceExports("micromort"))
  cats <- .export_categories()

  export_cat <- vapply(exports, function(fn) {
    if (fn %in% names(cats)) unname(cats[fn]) else "Other"
  }, character(1))

  # -- Simplified: 5-box left-to-right overview (for README) --
  if (simplified) {
    merged_cat <- export_cat
    merged_cat[merged_cat %in% c("Regional", "Conditional", "Radiation")] <- "Data"
    groups <- split(names(merged_cat), merged_cat)

    n <- function(name) length(groups[[name]])

    lines <- c(
      mermaid_dark_theme_header(),
      "graph LR",
      "",
      sprintf("  Conversion[\"Unit Conversion<br>%d functions\"]", n("Conversion")),
      sprintf("  Data[\"Risk Datasets<br>%d functions\"]", n("Data")),
      sprintf("  Analysis[\"Risk Analysis<br>%d functions\"]", n("Analysis")),
      sprintf("  Viz[\"Visualization<br>%d functions\"]", n("Visualization")),
      sprintf("  Apps[\"Interactive Apps<br>%d functions\"]", n("Apps")),
      "",
      "  Conversion --> Data --> Analysis --> Viz --> Apps",
      "",
      "  style Conversion fill:#999999,stroke:#CC0000,color:#000000",
      "  style Data fill:#999999,stroke:#CC0000,color:#000000",
      "  style Analysis fill:#999999,stroke:#CC0000,color:#000000",
      "  style Viz fill:#999999,stroke:#CC0000,color:#000000",
      "  style Apps fill:#999999,stroke:#CC0000,color:#000000"
    )

    other_fns <- groups[["Other"]]
    if (!is.null(other_fns) && length(other_fns) > 0) {
      lines <- c(lines,
        "",
        sprintf("  Other[\"Other<br>%d functions\"]", length(other_fns)),
        "  style Other fill:#999999,stroke:#CC0000,color:#000000"
      )
    }

    return(paste(lines, collapse = "\n"))
  }

  # -- Full: subgraphs with individual functions --
  groups <- split(names(export_cat), export_cat)

  cat_order <- c("Conversion", "Data", "Regional", "Conditional",
                 "Radiation", "Analysis", "Visualization", "Apps", "Other")

  cat_meta <- list(
    Conversion    = list(label = "Unit Conversion",  style = "fill:#999999,stroke:#CC0000,color:#000000"),
    Data          = list(label = "Risk Datasets",    style = "fill:#999999,stroke:#CC0000,color:#000000"),
    Regional      = list(label = "Regional",         style = "fill:#999999,stroke:#CC0000,color:#000000"),
    Conditional   = list(label = "Conditional Risk", style = "fill:#999999,stroke:#CC0000,color:#000000"),
    Radiation     = list(label = "Radiation",        style = "fill:#999999,stroke:#CC0000,color:#000000"),
    Analysis      = list(label = "Risk Analysis",    style = "fill:#999999,stroke:#CC0000,color:#000000"),
    Visualization = list(label = "Visualization",    style = "fill:#999999,stroke:#CC0000,color:#000000"),
    Apps          = list(label = "Interactive Apps",  style = "fill:#999999,stroke:#CC0000,color:#000000"),
    Other         = list(label = "Other",            style = "fill:#999999,stroke:#CC0000,color:#000000")
  )

  lines <- c(mermaid_dark_theme_header(), "graph TD", "")

  for (cat_name in cat_order) {
    fns <- groups[[cat_name]]
    if (is.null(fns) || length(fns) == 0) next
    meta <- cat_meta[[cat_name]]

    lines <- c(lines,
      sprintf("  subgraph %s[\"%s\"]", cat_name, meta$label),
      vapply(fns, function(fn) {
        sprintf("    %s[\"%s()\"]", fn, fn)
      }, character(1)),
      "  end",
      sprintf("  style %s %s", cat_name, meta$style),
      ""
    )
  }

  # Flow arrows between subgraphs
  lines <- c(lines,
    "  Conversion --> Data",
    "  Data --> Regional",
    "  Data --> Conditional",
    "  Data --> Radiation",
    "  Data --> Analysis",
    "  Analysis --> Visualization",
    "  Visualization --> Apps"
  )

  # Click directives for pkgdown navigation
  if (clickable) {
    lines <- c(lines, "")
    for (cat_name in cat_order) {
      fns <- groups[[cat_name]]
      if (is.null(fns)) next
      for (fn in fns) {
        lines <- c(lines,
          sprintf("  click %s \"../reference/%s.html\" \"%s\"", fn, fn, fn)
        )
      }
    }
  }

  paste(lines, collapse = "\n")
}


#' Generate user journey decision-tree diagram
#'
#' Maps common user intents to the appropriate functions and vignettes.
#'
#' @return Character string of mermaid `graph TD`.
#' @noRd
generate_user_journey_diagram <- function() {
  lines <- c(
    mermaid_dark_theme_header(),
    "graph TD",
    "",
    "  start{{\"What do you want to do?\"}}",
    "",
    "  start --> explore[\"Explore risk data\"]",
    "  start --> compare[\"Compare risks\"]",
    "  start --> analyse[\"Analyse my risk\"]",
    "  start --> build[\"Build on the data\"]",
    "",
    "  explore --> cr[\"common_risks()\"]",
    "  explore --> lr[\"load_acute_risks()\"]",
    "  explore --> ch[\"chronic_risks()\"]",
    "",
    "  compare --> eq[\"risk_equivalence()\"]",
    "  compare --> mx[\"risk_exchange_matrix()\"]",
    "  compare --> lt[\"lifestyle_tradeoff()\"]",
    "",
    "  analyse --> ci[\"compare_interventions()\"]",
    "  analyse --> hp[\"hedged_portfolio()\"]",
    "  analyse --> hz[\"daily_hazard_rate()\"]",
    "",
    "  build --> api[\"launch_api()\"]",
    "  build --> dash[\"launch_dashboard()\"]",
    "  build --> quiz[\"launch_quiz()\"]",
    "",
    "  cr --> v_intro[\"Introduction vignette\"]",
    "  eq --> v_equiv[\"Risk Equivalence vignette\"]",
    "  ci --> v_pal[\"Palatable Units vignette\"]",
    "  api --> v_api[\"REST API vignette\"]",
    "",
    "  style start fill:#999999,stroke:#CC0000,color:#000000",
    "  style explore fill:#999999,stroke:#CC0000,color:#000000",
    "  style compare fill:#999999,stroke:#CC0000,color:#000000",
    "  style analyse fill:#999999,stroke:#CC0000,color:#000000",
    "  style build fill:#999999,stroke:#CC0000,color:#000000",
    "",
    "  click cr \"../reference/common_risks.html\" \"common_risks\"",
    "  click lr \"../reference/load_acute_risks.html\" \"load_acute_risks\"",
    "  click ch \"../reference/chronic_risks.html\" \"chronic_risks\"",
    "  click eq \"../reference/risk_equivalence.html\" \"risk_equivalence\"",
    "  click mx \"../reference/risk_exchange_matrix.html\" \"risk_exchange_matrix\"",
    "  click lt \"../reference/lifestyle_tradeoff.html\" \"lifestyle_tradeoff\"",
    "  click ci \"../reference/compare_interventions.html\" \"compare_interventions\"",
    "  click hp \"../reference/hedged_portfolio.html\" \"hedged_portfolio\"",
    "  click hz \"../reference/daily_hazard_rate.html\" \"daily_hazard_rate\"",
    "  click api \"../reference/launch_api.html\" \"launch_api\"",
    "  click dash \"../reference/launch_dashboard.html\" \"launch_dashboard\"",
    "  click quiz \"../reference/launch_quiz.html\" \"launch_quiz\"",
    "  click v_intro \"../articles/introduction.html\" \"Introduction\"",
    "  click v_equiv \"../articles/risk_equivalence.html\" \"Risk Equivalence\"",
    "  click v_pal \"../articles/palatable_units.html\" \"Palatable Units\"",
    "  click v_api \"../articles/rest_api.html\" \"REST API\""
  )

  paste(lines, collapse = "\n")
}


#' Generate developer workflow diagram
#'
#' Shows the 9-step PR workflow used by this project.
#'
#' @return Character string of mermaid `graph LR`.
#' @noRd
generate_developer_diagram <- function() {
  lines <- c(
    mermaid_dark_theme_header(),
    "graph LR",
    "",
    "  s1[\"1. Plan<br>Architecture\"]",
    "  s2[\"2. Issue<br>gh::gh()\"]",
    "  s3[\"3. Branch<br>pr_init()\"]",
    "  s4[\"4. Test<br>testthat\"]",
    "  s5[\"5. Code<br>Implement\"]",
    "  s6[\"6. Document<br>roxygen2\"]",
    "  s7[\"7. Check<br>R CMD check\"]",
    "  s8[\"8. PR<br>pr_push()\"]",
    "  s9[\"9. Merge<br>pr_merge_main()\"]",
    "",
    "  s1 --> s2 --> s3 --> s4 --> s5 --> s6 --> s7 --> s8 --> s9",
    "",
    "  s4 -.->|RED| s5",
    "  s5 -.->|GREEN| s4",
    "",
    "  style s1 fill:#999999,stroke:#CC0000,color:#000000",
    "  style s2 fill:#999999,stroke:#CC0000,color:#000000",
    "  style s3 fill:#999999,stroke:#CC0000,color:#000000",
    "  style s4 fill:#999999,stroke:#CC0000,color:#000000",
    "  style s5 fill:#999999,stroke:#CC0000,color:#000000",
    "  style s6 fill:#999999,stroke:#CC0000,color:#000000",
    "  style s7 fill:#999999,stroke:#CC0000,color:#000000",
    "  style s8 fill:#999999,stroke:#CC0000,color:#000000",
    "  style s9 fill:#999999,stroke:#CC0000,color:#000000"
  )

  paste(lines, collapse = "\n")
}
