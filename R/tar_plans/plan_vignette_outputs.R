# Plan: Pre-computed objects for vignettes
# Per quarto-files.md: "MANDATORY: Vignettes contain ZERO computation"
# All plots, tables, and summaries are built here, loaded via tar_load() in vignettes

plan_vignette_outputs <- list(


  # ==========================================================================
  # REGIONAL VARIATION VIGNETTE
  # ==========================================================================


  # Table: Classification summary (2019)
  targets::tar_target(
    vig_regional_classification_summary,
    regional_life_expectancy(year = 2019, sex = "Total") |>
      dplyr::group_by(classification) |>
      dplyr::summarise(
        n_regions = dplyr::n(),
        mean_le = round(mean(life_expectancy), 1),
        min_le = round(min(life_expectancy), 1),
        max_le = round(max(life_expectancy), 1),
        mean_microlives_diff = round(mean(microlives_vs_eu_avg), 1),
        .groups = "drop"
      )
  ),


  # Gap data for microlives calculation
  targets::tar_target(
    vig_regional_le_gap,
    {
      gap_data <- regional_life_expectancy(year = 2019, sex = "Total") |>
        dplyr::group_by(classification) |>
        dplyr::summarise(mean_le = mean(life_expectancy), .groups = "drop") |>
        dplyr::filter(classification %in% c("vanguard", "laggard"))

      le_gap <- diff(gap_data$mean_le)

      list(
        le_gap_years = round(abs(le_gap), 1),
        lifetime_microlives = format(round(abs(le_gap) * 17520), big.mark = ","),
        daily_microlives = round(abs(le_gap) * 1.2, 1)
      )
    }
  ),


  # Full data table for Regional Data Explorer
  targets::tar_target(
    vig_regional_explorer_data,
    regional_life_expectancy(year = 2019, sex = "Total") |>
      dplyr::select(region_name, country_code, life_expectancy,
                    microlives_vs_eu_avg, classification) |>
      dplyr::arrange(dplyr::desc(life_expectancy))
  ),


  # Trends plot: Life expectancy by classification over time
  targets::tar_target(
    vig_regional_trends_plot,
    {
      regional_life_expectancy(sex = "Total") |>
        dplyr::group_by(year, classification) |>
        dplyr::summarise(mean_le = mean(life_expectancy), .groups = "drop") |>
        ggplot2::ggplot(ggplot2::aes(x = year, y = mean_le, color = classification)) +
        ggplot2::geom_line(linewidth = 1.2) +
        ggplot2::geom_vline(xintercept = 2005, linetype = "dashed", alpha = 0.5) +
        ggplot2::annotate("text", x = 2006, y = 74, label = "Divergence\nbegins",
                          hjust = 0, size = 3) +
        ggplot2::scale_color_manual(
          values = c("vanguard" = "#2E7D32", "average" = "#1976D2", "laggard" = "#C62828"),
          labels = c("vanguard" = "Vanguard", "average" = "Average", "laggard" = "Laggard")
        ) +
        ggplot2::labs(
          title = "Life Expectancy Trends by Region Classification",
          subtitle = "Western Europe, 1992-2019",
          x = "Year",
          y = "Life Expectancy at Birth (years)",
          color = "Classification",
          caption = "Source: Eurostat demo_r_mlifexp; Classification per Bonnet et al. (2026)"
        ) +
        ggplot2::theme_minimal() +
        ggplot2::theme(legend.position = "bottom")
    }
  ),


  # Paris (FR10) mortality multiplier table
  targets::tar_target(
    vig_regional_paris_multiplier,
    regional_mortality_multiplier("FR10")
  ),


  # ==========================================================================
  # INTRODUCTION VIGNETTE
  # ==========================================================================

  # Common risks data (for DT::datatable)
  targets::tar_target(
    vig_intro_common_risks,
    common_risks()
  ),


  # Risk ladder plot (faceted by COVID vs Other)
  targets::tar_target(
    vig_intro_risk_plot,
    plot_risks()
  ),


  # Interactive risk plot
  targets::tar_target(
    vig_intro_risk_plot_interactive,
    plot_risks_interactive()
  ),


  # Cancer risks: Top 3 by sex

  targets::tar_target(
    vig_intro_cancer_top3,
    cancer_risks() |>
      dplyr::filter(age_group == "All ages", sex != "Both") |>
      dplyr::group_by(sex) |>
      dplyr::slice_min(rank_by_sex, n = 3) |>
      dplyr::select(cancer_type, sex, deaths_per_100k, micromorts_per_year, family_history_rr) |>
      dplyr::ungroup()
  ),


  # Cancer risks: Family history comparison (Male 50-64)
  targets::tar_target(
    vig_intro_cancer_family_history,
    cancer_risks() |>
      dplyr::filter(sex == "Male", age_group == "50-64") |>
      dplyr::select(cancer_type, micromorts_per_year, micromorts_with_family_history) |>
      dplyr::mutate(
        increase_mm = micromorts_with_family_history - micromorts_per_year
      )
  ),


  # Vaccination risks: Childhood (0-5)
  targets::tar_target(
    vig_intro_vaccination_childhood,
    vaccination_risks() |>
      dplyr::filter(age_group == "0-5", grepl("Complete", vaccine_schedule)) |>
      dplyr::select(country, mortality_reduction_pct, micromorts_avoided_per_year,
                    annual_life_days_gained)
  ),


  # Vaccination risks: Adult (US 65+)
  targets::tar_target(
    vig_intro_vaccination_adult,
    vaccination_risks() |>
      dplyr::filter(age_group == "65+", country == "US") |>
      dplyr::select(vaccine_schedule, micromorts_avoided_per_year, microlives_gained_per_day)
  ),


  # Conditional risk: Cardiovascular
  targets::tar_target(
    vig_intro_cardiovascular_risk,
    conditional_risk("cardiovascular") |>
      dplyr::select(risk_factor, unhedged_state, hedged_state,
                    microlives_gained, annual_days_gained)
  ),


  # Hedged portfolio
  targets::tar_target(
    vig_intro_hedged_portfolio,
    hedged_portfolio()
  ),


  # ==========================================================================
  # PALATABLE UNITS VIGNETTE
  # ==========================================================================

  # Common risks filtered for Travel/Medical/Sport/Daily Life
  targets::tar_target(
    vig_palatable_risks_filtered,
    common_risks() |>
      dplyr::filter(category %in% c("Travel", "Medical", "Sport", "Daily Life")) |>
      dplyr::select(activity, micromorts, microlives, category, period)
  ),


  # Chronic risks for daily habits table
  targets::tar_target(
    vig_palatable_chronic_risks,
    chronic_risks() |>
      dplyr::select(factor, microlives_per_day, category, direction, annual_effect_days)
  ),


  # Risk ladder plot (same as intro but explicitly for this vignette)
  targets::tar_target(
    vig_palatable_risk_plot,
    plot_risks()
  ),


  # Interactive risk plot
  targets::tar_target(
    vig_palatable_risk_plot_interactive,
    plot_risks_interactive()
  ),


  # ==========================================================================
  # RISK EQUIVALENCE DASHBOARD VIGNETTE
  # ==========================================================================

  # All risks including new activities
  targets::tar_target(
    vig_equiv_all_risks,
    common_risks()
  ),

  # Curated landmark comparisons
  targets::tar_target(
    vig_equiv_landmarks,
    {
      cr <- common_risks()
      landmarks <- c(
        "Cup of coffee", "Crossing a road", "Chest X-ray (radiation per scan)",
        "Commuting by car (30 min)", "Drinking a glass of wine",
        "Skiing", "Driving (230 miles)", "Flying (8h long-haul)",
        "CT scan head (radiation per scan)", "Scuba diving, trained",
        "Running a marathon", "Skydiving (US)",
        "CT scan abdomen (radiation per scan)", "General anesthesia (emergency)",
        "Night in hospital", "Vaginal birth (mother)",
        "Base jumping", "Mt. Everest ascent"
      )
      cr |>
        dplyr::filter(activity %in% landmarks) |>
        dplyr::arrange(micromorts) |>
        dplyr::mutate(
          xray_equivalents = round(micromorts / 0.1, 1)
        )
    }
  ),

  # Flight component breakdown for healthy + DVT-risk
  targets::tar_target(
    vig_equiv_flight_components,
    {
      healthy <- risk_components("flying_8h") |>
        dplyr::mutate(profile = "Healthy")
      dvt_risk <- risk_components("flying_8h",
        profile = list(health_profile = "dvt_risk_factors")) |>
        dplyr::mutate(profile = "DVT risk factors")
      dplyr::bind_rows(healthy, dvt_risk) |>
        dplyr::select(profile, component_label, micromorts, hedgeable,
                      hedge_description, risk_category)
    }
  ),

  # Flight duration stacked bar data (for plotly)
  targets::tar_target(
    vig_equiv_flight_duration,
    {
      ar <- atomic_risks() |>
        filter_by_profile() |>
        dplyr::filter(grepl("^flying_", activity_id)) |>
        dplyr::mutate(
          activity = factor(activity, levels = c(
            "Flying (2h short-haul)", "Flying (5h medium-haul)",
            "Flying (8h long-haul)", "Flying (12h ultra-long-haul)"
          ))
        ) |>
        dplyr::select(activity, component_label, micromorts, hedgeable,
                      duration_hours)
      ar
    }
  ),

  # Risk equivalence table: everything in X-ray units
  targets::tar_target(
    vig_equiv_explorer,
    risk_equivalence("Chest X-ray (radiation per scan)")
  ),

  # Exchange chart: "How many X-rays = ..."
  targets::tar_target(
    vig_equiv_exchange_chart,
    {
      re <- risk_equivalence("Chest X-ray (radiation per scan)", min_ratio = 1)
      re |>
        dplyr::slice_head(n = 20) |>
        dplyr::select(activity, ratio, equivalence)
    }
  ),

  # Medical radiation comparison
  targets::tar_target(
    vig_equiv_medical_focus,
    {
      cr <- common_risks()
      cr |>
        dplyr::filter(
          category == "Medical",
          grepl("radiation|X-ray|CT scan|Mammogram|angiogram|enema",
                activity)
        ) |>
        dplyr::arrange(micromorts)
    }
  ),

  # 10x10 exchange matrix
  targets::tar_target(
    vig_equiv_matrix,
    risk_exchange_matrix()
  ),

  # Everyday activities in equivalence table
  targets::tar_target(
    vig_equiv_everyday,
    {
      cr <- common_risks()
      everyday <- c(
        "Cup of coffee", "Crossing a road", "Working in an office (8 hours)",
        "Taking a bath", "Commuting by car (30 min)",
        "Commuting by bicycle (30 min)", "Drinking a glass of wine",
        "Skiing", "Horse riding"
      )
      cr |>
        dplyr::filter(activity %in% everyday) |>
        dplyr::arrange(micromorts) |>
        dplyr::mutate(
          xray_equivalents = round(micromorts / 0.1, 1)
        )
    }
  ),

  # Hedgeability summary
  targets::tar_target(
    vig_equiv_hedgeable_summary,
    {
      cr <- common_risks()
      cr |>
        dplyr::filter(hedgeable_pct > 0) |>
        dplyr::arrange(dplyr::desc(hedgeable_pct)) |>
        dplyr::select(activity, micromorts, hedgeable_pct, n_components)
    }
  ),


  # ==========================================================================
  # RADIATION EXPOSURE PROFILES (#24 + #25)
  # ==========================================================================

  # Full radiation profiles table

  targets::tar_target(
    vig_radiation_profiles,
    radiation_profiles()
  ),

  # Patient vs occupational cross-tabulation
  targets::tar_target(
    vig_radiation_patient_vs_occ,
    patient_radiation_comparison()
  ),

  # Timeline data for cumulative plotly chart (yearly increments 0-40)
  targets::tar_target(
    vig_radiation_timeline_data,
    {
      rp <- radiation_profiles(milestones = integer(0))
      years <- 0:40
      do.call(dplyr::bind_rows, lapply(years, function(y) {
        rp |>
          dplyr::mutate(
            year = y,
            cumulative_micromorts = annual_micromorts * y
          )
      }))
    }
  ),

  # Regulatory limits comparison
  targets::tar_target(
    vig_radiation_regulatory,
    {
      rp <- radiation_profiles()
      rp |>
        dplyr::mutate(
          pct_of_limit = round(annual_msv / regulatory_limit_msv * 100, 1)
        ) |>
        dplyr::select(activity, category, annual_msv, regulatory_limit_msv,
                      pct_of_limit) |>
        dplyr::arrange(dplyr::desc(pct_of_limit))
    }
  ),

  # Key insights for vignette prose
  targets::tar_target(
    vig_radiation_key_insights,
    {
      rp <- radiation_profiles()
      prc <- patient_radiation_comparison()

      pilot_40y <- rp$annual_micromorts[rp$activity_id == "airline_pilot_annual"] * 40
      pilot_xray_equiv <- pilot_40y / 0.1

      xray100_vs_tech40 <- prc[prc$occupation == "X-ray technician (annual radiation)" &
                                prc$xray_count == 100 &
                                prc$career_years == 40, ]

      list(
        pilot_40y_mm = pilot_40y,
        pilot_40y_xrays = pilot_xray_equiv,
        xray100_patient_mm = xray100_vs_tech40$patient_micromorts,
        xray100_tech40_mm = xray100_vs_tech40$occupational_micromorts,
        xray100_vs_tech40_ratio = xray100_vs_tech40$ratio
      )
    }
  ),


  # ==========================================================================
  # REST API VIGNETTE
  # ==========================================================================

  # Acute risks sample (Medical category)
  targets::tar_target(
    vig_api_acute_sample,
    common_risks() |>
      dplyr::filter(category == "Medical") |>
      dplyr::select(activity, micromorts, microlives, category, period) |>
      utils::head(10)
  ),

  # Chronic risks: gains only
  targets::tar_target(
    vig_api_chronic_gains,
    chronic_risks() |>
      dplyr::filter(direction == "gain") |>
      dplyr::select(factor, microlives_per_day, category, direction,
                    annual_effect_days)
  ),


  # Cancer risks: top 3 per sex (All ages)
  targets::tar_target(
    vig_api_cancer_top3,
    cancer_risks() |>
      dplyr::filter(age_group == "All ages", sex != "Both") |>
      dplyr::group_by(sex) |>
      dplyr::slice_min(rank_by_sex, n = 3) |>
      dplyr::select(cancer_type, sex, deaths_per_100k, micromorts_per_year) |>
      dplyr::ungroup()
  ),

  # Risk equivalence sample (Chest X-ray reference)
  targets::tar_target(
    vig_api_equivalence_sample,
    risk_equivalence("Chest X-ray (radiation per scan)") |>
      utils::head(15)
  ),

  # Unit conversion examples table
  targets::tar_target(
    vig_api_conversion_table,
    {
      probs <- c(1e-7, 1e-6, 1e-5, 1e-4, 1e-3)
      tibble::tibble(
        probability = probs,
        micromorts = as.numeric(vapply(probs, as_micromort, numeric(1))),
        lle_minutes = as.numeric(vapply(probs, lle, numeric(1))),
        microlife = as.numeric(vapply(
          vapply(probs, lle, numeric(1)), as_microlife, numeric(1)
        ))
      )
    }
  ),

  # Daily hazard rates for selected ages (both sexes)
  targets::tar_target(
    vig_api_hazard_ages,
    {
      ages <- c(20, 35, 50, 65, 80)
      do.call(dplyr::bind_rows, lapply(ages, function(a) {
        dplyr::bind_rows(
          daily_hazard_rate(a, "male"),
          daily_hazard_rate(a, "female")
        )
      }))
    }
  ),

  # Full endpoint reference table
  targets::tar_target(
    vig_api_endpoint_summary,
    tibble::tribble(
      ~method, ~path, ~description, ~params,
      "GET", "/v1/risks/acute", "Enriched acute risks (common_risks)", "category, min_micromorts, limit",
      "GET", "/v1/risks/acute/atomic", "Atomic risk components", "category, component, hedgeable",
      "GET", "/v1/risks/chronic", "Chronic microlife gains/losses", "direction, category",
      "GET", "/v1/risks/cancer", "Cancer risk by type/sex/age", "sex, age_group, cancer_type",
      "GET", "/v1/risks/vaccination", "Vaccination risk reduction", "country, age_group",
      "GET", "/v1/risks/covid-vaccine", "COVID vaccine relative risks", "age_group, vaccination_status",
      "GET", "/v1/risks/conditional", "Conditional risk given disease", "disease",
      "GET", "/v1/risks/demographic", "Demographic risk factors", "",
      "GET", "/v1/regional/life-expectancy", "Regional life expectancy", "country, year, sex, classification",
      "GET", "/v1/regional/vanguard", "Best-performing regions", "country, year, sex",
      "GET", "/v1/regional/laggard", "Worst-performing regions", "country, year, sex",
      "GET", "/v1/regional/mortality-multiplier", "Mortality multiplier by region", "region_code, reference, year",
      "GET", "/v1/radiation/profiles", "Exposure by career milestones", "milestones",
      "GET", "/v1/radiation/patient-comparison", "Patient vs occupational exposure", "xray_counts, career_years",
      "GET", "/v1/analysis/equivalence", "Risk equivalence lookup", "reference, min_ratio, max_ratio",
      "GET", "/v1/analysis/tradeoff", "Lifestyle tradeoff calculator", "bad_habit, good_habit",
      "POST", "/v1/analysis/exchange-matrix", "Risk exchange matrix", "activities (JSON body)",
      "POST", "/v1/analysis/interventions", "Compare interventions", "interventions (JSON body)",
      "POST", "/v1/analysis/budget", "Annual risk budget", "activities, age (JSON body)",
      "POST", "/v1/analysis/hedged-portfolio", "Hedged risk portfolio", "include_diseases (JSON body)",
      "GET", "/v1/convert/to-micromort", "Probability to micromorts", "prob",
      "GET", "/v1/convert/to-probability", "Micromorts to probability", "micromorts",
      "GET", "/v1/convert/to-microlife", "Minutes to microlives", "minutes",
      "GET", "/v1/convert/value", "Monetary value of one micromort", "vsl",
      "GET", "/v1/convert/lle", "Loss of life expectancy", "prob, life_expectancy",
      "GET", "/v1/convert/hazard-rate", "Daily hazard rate by age", "age, sex",
      "GET", "/v1/quiz/pairs", "Quiz pairs for comparison game", "min_ratio, max_ratio, seed",
      "GET", "/v1/sources", "Risk data sources registry", "type",
      "GET", "/v1/meta", "API metadata and endpoint listing", "",
      "GET", "/health", "Health check", ""
    )
  ),


  # ==========================================================================
  # ARCHITECTURE DIAGRAMS (Issue #41)
  # ==========================================================================

  # Pipeline overview — regenerates when plan files change
  targets::tar_target(
    vig_arch_pipeline_diagram,
    {
      plan_files <- list.files("R/tar_plans", pattern = "^plan_.*\\.R$",
                               full.names = TRUE)
      plan_hash <- digest::digest(lapply(plan_files, readLines, warn = FALSE))
      generate_pipeline_diagram()
    }
  ),

  # Concept hierarchy — regenerates when NAMESPACE changes
  targets::tar_target(
    vig_arch_concept_diagram,
    {
      ns_hash <- digest::digest(file = "NAMESPACE")
      generate_concept_diagram()
    }
  ),

  # User journey decision tree
  targets::tar_target(
    vig_arch_user_journey_diagram,
    generate_user_journey_diagram()
  ),

  # Developer workflow
  targets::tar_target(
    vig_arch_developer_diagram,
    generate_developer_diagram()
  ),

  # Targets DAG (auto-generated)
  targets::tar_target(
    vig_arch_tar_visnetwork,
    tryCatch(
      targets::tar_visnetwork(targets_only = TRUE, label = "name"),
      error = function(e) NULL
    )
  ),

  # README concept diagram (simplified, no click for GitHub)
  targets::tar_target(
    readme_concept_diagram,
    {
      ns_hash <- digest::digest(file = "NAMESPACE")
      generate_concept_diagram(simplified = TRUE, clickable = FALSE)
    }
  ),


  # ==========================================================================
  # QUIZ DATA CONSISTENCY (Shinylive WebR limitation)
  # ==========================================================================

  # Canonical quiz pairs generated from quiz_pairs()
  targets::tar_target(
    vig_quiz_pairs,
    {
      easy <- quiz_pairs(difficulty = "easy", seed = 42)
      medium <- quiz_pairs(difficulty = "medium", seed = 42)
      hard <- quiz_pairs(difficulty = "hard", seed = 42)
      rbind(easy, medium, hard)
    }
  ),

  # Check embedded CSV in quiz_shinylive.qmd matches canonical pairs
  targets::tar_target(
    vig_quiz_csv_check,
    {
      # Read embedded CSV from the qmd file
      qmd_lines <- readLines("vignettes/quiz_shinylive.qmd", warn = FALSE)

      # Find the CSV block: starts after textConnection(, ends at line with ')
      csv_start <- grep("textConnection\\(", qmd_lines)[1]
      # The closing line contains '), stringsAsFactors or just ')
      csv_end <- grep("'\\),\\s*stringsAsFactors|'\\)\\s*\\)", qmd_lines)
      csv_end <- csv_end[csv_end > csv_start][1]

      if (is.na(csv_start) || is.na(csv_end)) {
        return(list(status = "ERROR", message = "Could not find CSV in qmd"))
      }

      # Extract CSV lines: from line after textConnection( to closing line
      # The first CSV line starts with ' (quote), last line ends with ')
      csv_text <- qmd_lines[(csv_start + 1):csv_end]
      # First line starts with ' — remove leading quote
      csv_text[1] <- sub("^'", "", csv_text[1])
      # Last line ends with '), stringsAsFactors... — trim after closing quote
      csv_text[length(csv_text)] <- sub("'\\).*$", "", csv_text[length(csv_text)])

      embedded <- tryCatch(
        utils::read.csv(textConnection(paste(csv_text, collapse = "\n")),
                        stringsAsFactors = FALSE),
        error = function(e) NULL
      )

      if (is.null(embedded)) {
        return(list(status = "ERROR", message = "Failed to parse embedded CSV"))
      }

      # Compare hashes — normalize to plain data.frame for consistent hashing
      canonical <- as.data.frame(vig_quiz_pairs, stringsAsFactors = FALSE)
      canonical <- canonical[order(canonical$activity_a, canonical$activity_b), ]
      embedded <- embedded[order(embedded$activity_a, embedded$activity_b), ]
      rownames(canonical) <- NULL
      rownames(embedded) <- NULL
      hash_canonical <- digest::digest(canonical)
      hash_embedded <- digest::digest(embedded)

      list(
        status = if (hash_canonical == hash_embedded) "OK" else "STALE",
        canonical_rows = nrow(canonical),
        embedded_rows = nrow(embedded),
        canonical_hash = hash_canonical,
        embedded_hash = hash_embedded
      )
    },
    cue = targets::tar_cue(mode = "always")
  )

)
