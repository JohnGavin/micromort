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
        "Cup of coffee", "Crossing a road", "Chest X-ray (radiation)",
        "Commuting by car (30 min)", "Drinking a glass of wine",
        "Skiing (per day)", "Driving (230 miles)", "Flying (8h long-haul)",
        "CT scan head (radiation)", "Scuba diving (per dive, trained)",
        "Running a marathon", "Skydiving (per jump, US)",
        "CT scan abdomen (radiation)", "General anesthesia (emergency)",
        "Night in hospital", "Vaginal birth (mother)",
        "Base jumping (per jump)", "Mt. Everest ascent"
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
    risk_equivalence("Chest X-ray (radiation)")
  ),

  # Exchange chart: "How many X-rays = ..."
  targets::tar_target(
    vig_equiv_exchange_chart,
    {
      re <- risk_equivalence("Chest X-ray (radiation)", min_ratio = 1)
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
        "Skiing (per day)", "Horseback riding"
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
  )

)
