# Plan: Pre-computed objects for vignettes
# Per quarto-files.md: "MANDATORY: Vignettes contain ZERO computation"
# All plots, tables, and summaries are built here, loaded via tar_load() in vignettes

plan_vignette_outputs <- list(


  # ==========================================================================
  # BUILD-INFO FOOTER (shared across all vignettes)
  # ==========================================================================

  targets::tar_target(
    vig_build_info,
    {
      gh_url <- tryCatch({
        remote <- system("git remote get-url origin 2>/dev/null", intern = TRUE)
        sub("\\.git$", "", sub("^git@github\\.com:", "https://github.com/", remote))
      }, error = function(e) NULL)

      git_sha_short <- tryCatch(
        system("git rev-parse --short HEAD 2>/dev/null", intern = TRUE),
        error = function(e) "N/A"
      )
      git_sha_full <- tryCatch(
        system("git rev-parse HEAD 2>/dev/null", intern = TRUE),
        error = function(e) git_sha_short
      )

      pkg_ver <- tryCatch(
        as.character(utils::packageVersion("micromort")),
        error = function(e) "dev"
      )

      r_ver <- as.character(getRversion())
      build_time <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

      ver_link <- if (!is.null(gh_url)) {
        sprintf("[%s](%s/releases/tag/v%s)", pkg_ver, gh_url, pkg_ver)
      } else {
        pkg_ver
      }

      sha_link <- if (!is.null(gh_url) && git_sha_short != "N/A") {
        sprintf("[`%s`](%s/commit/%s)", git_sha_short, gh_url, git_sha_full)
      } else {
        sprintf("`%s`", git_sha_short)
      }

      r_link <- sprintf(
        "[%s](https://cran.r-project.org/doc/manuals/r-release/NEWS.html)",
        r_ver
      )

      sprintf(
        "\n---\n\n**micromort** %s | **Git** %s | **R** %s | **Built** %s\n",
        ver_link, sha_link, r_link, build_time
      )
    }
  ),


  # ==========================================================================
  # WHAT-IS-A-MICROMORT VIGNETTE (closeread scrollytelling)
  # ==========================================================================

  # Mundane risks bar chart (plotly)
  targets::tar_target(
    vig_whatis_mundane_plot,
    {
      cr <- common_risks()
      mundane <- cr |>
        dplyr::filter(activity %in% c(
          "Cup of coffee", "Crossing a road",
          "Commuting by car (30 min)", "Commuting by bicycle (30 min)",
          "Taking a bath", "Working in an office (8 hours)",
          "Drinking a glass of wine")) |>
        dplyr::arrange(micromorts) |>
        dplyr::mutate(activity = factor(activity, levels = activity))

      plotly::plot_ly(mundane, y = ~activity, x = ~micromorts, type = "bar",
        orientation = "h",
        marker = list(color = "#2c7be5"),
        hovertemplate = paste0("<b>%{y}</b><br>",
          "%{x:.2f} mm<br>",
          "%{x:.2f} / 0.01 = ", round(mundane$micromorts / 0.01), "x vs coffee",
          "<extra></extra>")) |>
        plotly::layout(
          xaxis = list(title = "Micromorts (mm)"),
          yaxis = list(title = ""),
          paper_bgcolor = "#1a1a2e", plot_bgcolor = "#1a1a2e",
          font = list(color = "#e0e0e0", size = 13),
          annotations = list(list(
            text = "1 mm = one-in-a-million chance of death",
            x = 0.5, y = -0.12, xref = "paper", yref = "paper",
            showarrow = FALSE, font = list(size = 11, color = "#888888")))
        ) |> plotly::config(displayModeBar = FALSE)
    }
  ),

  # Full spectrum dot chart (plotly)
  targets::tar_target(
    vig_whatis_spectrum_plot,
    {
      cr <- common_risks()
      cr_show <- cr |>
        dplyr::filter(micromorts > 0) |>
        dplyr::arrange(dplyr::desc(micromorts)) |>
        dplyr::slice_head(n = 35)

      plotly::plot_ly(cr_show, x = ~micromorts,
        y = ~stats::reorder(activity, micromorts),
        type = "scatter", mode = "markers",
        color = ~category, colors = "Set1",
        marker = list(size = 10),
        hovertemplate = paste0(
          "<b>%{y}</b><br>",
          "%{x:,.1f} mm<br>",
          "Category: %{text}",
          "<extra></extra>"),
        text = ~category) |>
        plotly::layout(
          xaxis = list(title = "Micromorts, mm (log scale)", type = "log",
                       tickformat = ","),
          yaxis = list(title = "", tickfont = list(size = 11)),
          height = 700,
          margin = list(l = 220),
          paper_bgcolor = "#1a1a2e", plot_bgcolor = "#1a1a2e",
          font = list(color = "#e0e0e0", size = 13),
          legend = list(bgcolor = "#1a1a2e", font = list(color = "#e0e0e0"))
        ) |> plotly::config(displayModeBar = FALSE)
    }
  ),

  # Chronic risks bar chart (plotly)
  targets::tar_target(
    vig_whatis_chronic_plot,
    {
      ch <- chronic_risks()
      ch <- ch |>
        dplyr::arrange(microlives_per_day) |>
        dplyr::mutate(
          factor = factor(factor, levels = factor),
          colour = ifelse(direction == "gain", "#198754", "#dc3545"),
          dir_label = ifelse(direction == "gain", "gain", "lose")
        )

      plotly::plot_ly(ch, x = ~microlives_per_day, y = ~factor, type = "bar",
        orientation = "h",
        marker = list(color = ~colour),
        hovertemplate = paste0(
          "<b>%{y}</b><br>",
          "%{x:+.0f} ml/day (%{text})<br>",
          "= %{customdata} min/day",
          "<extra></extra>"),
        text = ~dir_label,
        customdata = ~abs(microlives_per_day) * 30) |>
        plotly::layout(
          xaxis = list(title = "Microlives per day (ml/day)", zeroline = TRUE,
                       zerolinecolor = "#e0e0e0", zerolinewidth = 1),
          yaxis = list(title = "", tickfont = list(size = 10)),
          height = 650,
          margin = list(l = 200),
          paper_bgcolor = "#1a1a2e", plot_bgcolor = "#1a1a2e",
          font = list(color = "#e0e0e0", size = 13),
          annotations = list(list(
            text = "1 ml = 30 min of life expectancy. Red = lose, Green = gain.",
            x = 0.5, y = -0.08, xref = "paper", yref = "paper",
            showarrow = FALSE, font = list(size = 11, color = "#888888")))
        ) |> plotly::config(displayModeBar = FALSE)
    }
  ),


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
    ggplot2::ggplotGrob(plot_risks())
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
    ggplot2::ggplotGrob(plot_risks())
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
        "Commuting by car (30 min)", "Drinking a glass of wine (daily, chronic risk)",
        "Skiing", "Driving (230 miles)", "Flying (8h long-haul)",
        "CT scan head (radiation per scan)", "Scuba diving, trained (per dive)",
        "Running a marathon", "Skydiving (US)",
        "CT scan abdomen (radiation per scan)", "General anesthesia (emergency)",
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
        "Commuting by bicycle (30 min)",
        "Drinking a glass of wine (daily, chronic risk)",
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

  # Everyday activities bar chart (plotly, dark theme)
  targets::tar_target(
    vig_equiv_everyday_chart,
    {
      everyday <- vig_equiv_everyday
      plotly::plot_ly(
        everyday,
        y = ~stats::reorder(activity, xray_equivalents),
        x = ~xray_equivalents,
        type = "bar",
        orientation = "h",
        marker = list(color = "#1976D2")
      ) |>
        plotly::layout(
          title = "Everyday Activities in Chest X-ray Equivalents",
          xaxis = list(title = "Chest X-ray equivalents"),
          yaxis = list(title = ""),
          margin = list(l = 200),
          paper_bgcolor = "#1a1a2e", plot_bgcolor = "#1a1a2e",
          font = list(color = "#e0e0e0", size = 13),
          legend = list(bgcolor = "#1a1a2e", font = list(color = "#e0e0e0"))
        ) |>
        plotly::config(displayModeBar = FALSE)
    }
  ),

  # Flight duration Cleveland dotplot by component (plotly, dark theme)
  targets::tar_target(
    vig_equiv_flight_duration_chart,
    {
      flight_data <- vig_equiv_flight_duration
      totals <- flight_data |>
        dplyr::group_by(activity) |>
        dplyr::summarise(total = sum(micromorts), .groups = "drop") |>
        dplyr::arrange(total)
      flight_data <- flight_data |>
        dplyr::mutate(activity = factor(activity, levels = totals$activity))

      plotly::plot_ly(
        flight_data,
        y = ~activity,
        x = ~micromorts,
        color = ~component_label,
        type = "scatter",
        mode = "markers",
        marker = list(size = 12)
      ) |>
        plotly::layout(
          title = "Flight Risk by Duration and Component (Healthy Profile)",
          xaxis = list(title = "Micromorts"),
          yaxis = list(title = "", categoryorder = "array",
                       categoryarray = totals$activity),
          legend = list(orientation = "h", y = -0.2,
                        bgcolor = "#1a1a2e", font = list(color = "#e0e0e0")),
          paper_bgcolor = "#1a1a2e", plot_bgcolor = "#1a1a2e",
          font = list(color = "#e0e0e0", size = 13)
        ) |>
        plotly::config(displayModeBar = FALSE)
    }
  ),

  # Medical procedures in chest X-ray equivalents (plotly, dark theme)
  targets::tar_target(
    vig_equiv_medical_exchange_chart,
    {
      med <- vig_equiv_medical_focus |>
        dplyr::mutate(xray_equiv = round(micromorts / 0.1, 0))

      plotly::plot_ly(
        med,
        y = ~stats::reorder(activity, xray_equiv),
        x = ~xray_equiv,
        type = "bar",
        orientation = "h",
        marker = list(color = "#C62828")
      ) |>
        plotly::layout(
          title = "Medical Procedures in Chest X-ray Equivalents",
          xaxis = list(title = "Number of chest X-rays"),
          yaxis = list(title = ""),
          margin = list(l = 200),
          paper_bgcolor = "#1a1a2e", plot_bgcolor = "#1a1a2e",
          font = list(color = "#e0e0e0", size = 13),
          legend = list(bgcolor = "#1a1a2e", font = list(color = "#e0e0e0"))
        ) |>
        plotly::config(displayModeBar = FALSE)
    }
  ),

  # Hedgeable vs non-hedgeable flight risk dotplot (plotly, dark theme)
  targets::tar_target(
    vig_equiv_hedgeable_chart,
    {
      flight_data <- vig_equiv_flight_duration |>
        dplyr::mutate(
          hedge_status = ifelse(hedgeable, "Hedgeable", "Not hedgeable")
        )
      totals <- flight_data |>
        dplyr::group_by(activity) |>
        dplyr::summarise(total = sum(micromorts), .groups = "drop") |>
        dplyr::arrange(total)
      flight_data <- flight_data |>
        dplyr::mutate(activity = factor(activity, levels = totals$activity))

      plotly::plot_ly(
        flight_data,
        y = ~activity,
        x = ~micromorts,
        color = ~hedge_status,
        colors = c("Hedgeable" = "#2E7D32", "Not hedgeable" = "#C62828"),
        type = "scatter",
        mode = "markers",
        marker = list(size = 12)
      ) |>
        plotly::layout(
          title = "Hedgeable vs Non-hedgeable Risk by Flight Duration",
          xaxis = list(title = "Micromorts"),
          yaxis = list(title = "", categoryorder = "array",
                       categoryarray = totals$activity),
          legend = list(orientation = "h", y = -0.2,
                        bgcolor = "#1a1a2e", font = list(color = "#e0e0e0")),
          paper_bgcolor = "#1a1a2e", plot_bgcolor = "#1a1a2e",
          font = list(color = "#e0e0e0", size = 13)
        ) |>
        plotly::config(displayModeBar = FALSE)
    }
  ),

  # Cumulative radiation timeline line chart (plotly, dark theme)
  targets::tar_target(
    vig_equiv_radiation_timeline_chart,
    {
      timeline <- vig_radiation_timeline_data
      n_activities <- length(unique(timeline$activity))
      pal <- grDevices::hcl.colors(n_activities, palette = "Dark 3")

      plotly::plot_ly(
        timeline,
        x = ~year,
        y = ~cumulative_micromorts,
        color = ~activity,
        colors = pal,
        type = "scatter",
        mode = "lines"
      ) |>
        plotly::layout(
          title = "Cumulative Radiation Micromorts Over Career",
          xaxis = list(title = "Years of Exposure"),
          yaxis = list(title = "Cumulative Micromorts"),
          legend = list(orientation = "v", x = 1.02, y = 1,
                        bgcolor = "#1a1a2e", font = list(color = "#e0e0e0")),
          paper_bgcolor = "#1a1a2e", plot_bgcolor = "#1a1a2e",
          font = list(color = "#e0e0e0", size = 13)
        ) |>
        plotly::config(displayModeBar = FALSE)
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

  # Check CSV in quiz_shinylive.qmd (via ## file: directive) matches canonical pairs
  targets::tar_target(
    vig_quiz_csv_check,
    {
      # Read CSV from the ## file: quiz_pairs.csv section in the qmd
      qmd_lines <- readLines("vignettes/quiz_shinylive.qmd", warn = FALSE)

      # Find the ## file: quiz_pairs.csv marker
      file_marker <- grep("^## file: quiz_pairs\\.csv", qmd_lines)[1]
      if (is.na(file_marker)) {
        return(list(status = "ERROR", message = "Could not find ## file: quiz_pairs.csv in qmd"))
      }

      # CSV starts after optional ## type: line, ends at closing ```
      csv_start <- file_marker + 1L
      # Skip ## type: line if present
      if (grepl("^## type:", qmd_lines[csv_start])) csv_start <- csv_start + 1L
      # Find closing ``` fence after the marker
      fence_lines <- grep("^```$", qmd_lines)
      csv_end <- fence_lines[fence_lines > file_marker][1] - 1L

      if (is.na(csv_end) || csv_end < csv_start) {
        return(list(status = "ERROR", message = "Could not find CSV boundaries in qmd"))
      }

      csv_text <- qmd_lines[csv_start:csv_end]

      embedded <- tryCatch(
        utils::read.csv(textConnection(paste(csv_text, collapse = "\n")),
                        stringsAsFactors = FALSE),
        error = function(e) NULL
      )

      if (is.null(embedded)) {
        return(list(status = "ERROR", message = "Failed to parse embedded CSV"))
      }

      # Compare — normalize to plain data.frame, round numerics for CSV round-trip tolerance
      canonical <- as.data.frame(vig_quiz_pairs, stringsAsFactors = FALSE)
      canonical <- canonical[order(canonical$activity_a, canonical$activity_b), ]
      embedded <- embedded[order(embedded$activity_a, embedded$activity_b), ]
      rownames(canonical) <- NULL
      rownames(embedded) <- NULL
      # Round numeric columns to handle CSV serialization precision loss
      num_cols <- names(canonical)[vapply(canonical, is.numeric, logical(1))]
      for (col in num_cols) {
        canonical[[col]] <- round(canonical[[col]], 10)
        embedded[[col]] <- round(embedded[[col]], 10)
      }
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
  ),


  # ==========================================================================
  # CHRONIC QUIZ DATA CONSISTENCY (Shinylive WebR limitation)
  # ==========================================================================

  # Canonical chronic quiz pairs generated from chronic_quiz_pairs()
  targets::tar_target(
    vig_chronic_pairs,
    {
      easy <- chronic_quiz_pairs(difficulty = "easy", seed = 42)
      medium <- chronic_quiz_pairs(difficulty = "medium", seed = 42)
      hard <- chronic_quiz_pairs(difficulty = "hard", seed = 42)
      rbind(easy, medium, hard)
    }
  ),


  # ==========================================================================
  # DATA RELIABILITY VIGNETTE
  # ==========================================================================

  # Confidence tier definitions table
  targets::tar_target(
    vig_reliability_confidence_tiers,
    tibble::tribble(
      ~Tier, ~Criteria, ~Example, ~`Source type`,
      "**high**", "Peer-reviewed, large-N studies with defined denominators",
      "Medical radiation (NRC dosimetry)", "Regulatory agency",
      "**medium**", "Reputable sources, reasonable denominators, some extrapolation",
      "Wikipedia micromort list, CDC injury data", "Secondary compilation",
      "**low**", "Limited sources, regional uncertainty, or extrapolated denominators",
      "Snake bite in rural Africa (WHO estimate)", "Expert estimate",
      "**estimated**", "Derived by calculation from a model (e.g., LNT for radiation)",
      "Annual cosmic radiation from LNT model", "Model-derived"
    )
  ),

  # Validation status definitions table
  targets::tar_target(
    vig_reliability_validation_defs,
    tibble::tribble(
      ~Status, ~Definition, ~`Source count`, ~Example,
      "`single_source`", "One citation, no cross-check", "1",
      "Most legacy entries from Wikipedia/micromorts.rip",
      "`corroborated`", "2+ sources agree within 2x", "2+",
      "Flight risks (Boeing + NCRP + medical literature)",
      "`cross_validated`", "3+ sources, range documented, outliers explained", "3+",
      "(Future: entries with systematic literature review)"
    )
  ),

  # Validation status x confidence cross-tabulation
  targets::tar_target(
    vig_reliability_validation_summary,
    {
      ar <- atomic_risks()
      ar |>
        dplyr::count(validation_status, confidence) |>
        tidyr::pivot_wider(names_from = validation_status,
                           values_from = n, values_fill = 0)
    }
  ),

  # Geography-conditioned risks
  targets::tar_target(
    vig_reliability_geography,
    {
      ar <- atomic_risks()
      ar |>
        dplyr::filter(condition_variable == "geography") |>
        dplyr::select(activity, micromorts, condition_value, confidence, notes) |>
        dplyr::arrange(activity, condition_value)
    }
  ),

  # Health-conditioned risks (bee/wasp example)
  targets::tar_target(
    vig_reliability_health_conditioning,
    {
      ar <- atomic_risks()
      ar |>
        dplyr::filter(condition_variable == "health_profile",
                       grepl("bee|wasp", activity, ignore.case = TRUE)) |>
        dplyr::select(activity, micromorts, condition_value,
                       hedge_description, hedge_reduction_pct)
    }
  ),

  # OWID animal encounter conversion table
  targets::tar_target(
    vig_reliability_owid_conversion,
    tibble::tribble(
      ~Animal, ~`Annual deaths (approx)`, ~`Encounters/yr (approx)`,
      ~`Micromorts`, ~`Source for denominator`, ~`In dataset?`,
      "Shark", "~6 (US)", "~100M ocean swims", "0.06", "ISAF", "Yes",
      "Dog (US)", "~30", "~4.5M bites", "6.7", "CDC", "Yes",
      "Bee/wasp (US)", "~62", "~2M stings", "0.03", "CDC", "Yes",
      "Snake (US)", "~5", "~10,000 bites", "0.5", "CDC", "Yes",
      "Snake (Africa)", "~100,000", "~5.4M bites", "18.5", "WHO/Lancet", "Yes",
      "Mosquito", "~600,000+", "Unknown per-bite", "\u2014", "\u2014", "**No**",
      "Crocodile", "~1,000", "Unknown", "\u2014", "\u2014", "**No**",
      "Elephant", "~500", "Unknown", "\u2014", "\u2014", "**No**"
    )
  ),

  # Wildlife estimate ranges
  targets::tar_target(
    vig_reliability_ranges,
    {
      ar <- atomic_risks()
      ar |>
        dplyr::filter(category == "Wildlife", !is.na(estimate_range)) |>
        dplyr::select(activity, micromorts, estimate_range,
                       source_count, validation_status)
    }
  ),


  # ==========================================================================
  # CONFOUNDING VIGNETTE
  # ==========================================================================

  # Snake bite geography comparison
  targets::tar_target(
    vig_confounding_snake_geography,
    {
      ar <- atomic_risks()
      ar |>
        dplyr::filter(grepl("snake_bite", activity_id, ignore.case = TRUE)) |>
        dplyr::select(activity, micromorts, condition_value,
                       hedge_description, confidence)
    }
  ),


  # Bed fall age stratification table (from atomic_risks)
  targets::tar_target(
    vig_confounding_bed_fall_age,
    {
      ar <- atomic_risks()
      ar |>
        dplyr::filter(activity_id == "bed_fall") |>
        dplyr::select(activity, condition_value, micromorts, confidence, notes) |>
        dplyr::arrange(micromorts)
    }
  ),

  # Demographic what-if: top-15 ranking shift (#74)
  # Compare default (all_ages) vs 85+ male age profile
  targets::tar_target(
    vig_confounding_demographic_whatif,
    {
      default_cr <- common_risks()
      aged_cr <- common_risks(profile = list(age = "85_plus_male"))

      default_top <- default_cr |>
        dplyr::arrange(dplyr::desc(micromorts)) |>
        dplyr::slice_head(n = 15) |>
        dplyr::select(activity, micromorts) |>
        dplyr::rename(default_mm = micromorts)

      aged_top <- aged_cr |>
        dplyr::arrange(dplyr::desc(micromorts)) |>
        dplyr::slice_head(n = 15) |>
        dplyr::select(activity, micromorts) |>
        dplyr::rename(aged_mm = micromorts)

      # Full outer join to show activities that appear in either top-15
      merged <- dplyr::full_join(
        default_top |> dplyr::mutate(default_rank = dplyr::row_number()),
        aged_top |> dplyr::mutate(aged_rank = dplyr::row_number()),
        by = "activity"
      ) |>
        dplyr::arrange(
          dplyr::coalesce(aged_rank, 99L),
          dplyr::coalesce(default_rank, 99L)
        )

      merged
    }
  ),

  # Disease mortality by country (OWID/GBD 2023, #75)
  targets::tar_target(
    vig_confounding_disease_by_country,
    {
      ar <- atomic_risks()
      disease_ids <- c(
        "daily_cvd_mortality", "daily_cancer_mortality",
        "daily_lri_mortality", "daily_diarrheal_mortality"
      )
      ar |>
        dplyr::filter(activity_id %in% disease_ids) |>
        dplyr::select(activity_id, condition_value, micromorts, notes) |>
        tidyr::pivot_wider(
          names_from = condition_value,
          values_from = micromorts
        ) |>
        dplyr::select(-notes) |>
        dplyr::arrange(activity_id)
    }
  ),

  # Country what-if: UK vs Nigeria disease profile (#75)
  targets::tar_target(
    vig_confounding_disease_whatif,
    {
      cr_uk <- common_risks(profile = list(country = "UK"))
      cr_ng <- common_risks(profile = list(country = "NG"))

      uk_top <- cr_uk |>
        dplyr::arrange(dplyr::desc(micromorts)) |>
        dplyr::slice_head(n = 15) |>
        dplyr::select(activity, micromorts) |>
        dplyr::rename(uk_mm = micromorts)

      ng_top <- cr_ng |>
        dplyr::arrange(dplyr::desc(micromorts)) |>
        dplyr::slice_head(n = 15) |>
        dplyr::select(activity, micromorts) |>
        dplyr::rename(ng_mm = micromorts)

      merged <- dplyr::full_join(
        uk_top |> dplyr::mutate(uk_rank = dplyr::row_number()),
        ng_top |> dplyr::mutate(ng_rank = dplyr::row_number()),
        by = "activity"
      ) |>
        dplyr::arrange(
          dplyr::coalesce(ng_rank, 99L),
          dplyr::coalesce(uk_rank, 99L)
        )
      merged
    }
  ),

  # ==========================================================================
  # CHRONIC VS ACUTE scrollytelling (#75 Slice 6)
  # ==========================================================================

  # How many days of chronic risk equals one acute event?
  targets::tar_target(
    vig_chronic_acute_equivalences,
    {
      # Acute one-off risks (top activities people worry about)
      acute_events <- common_risks() |>
        dplyr::filter(period_type == "event", micromorts >= 1) |>
        dplyr::arrange(dplyr::desc(micromorts)) |>
        dplyr::slice_head(n = 10) |>
        dplyr::select(activity, micromorts)

      # Chronic daily risks (UK profile)
      uk_daily <- common_risks(profile = list(country = "UK")) |>
        dplyr::filter(grepl("mortality risk", activity)) |>
        dplyr::select(activity, micromorts) |>
        dplyr::rename(daily_activity = activity, daily_mm = micromorts)

      # Cross-join: days of each chronic risk = each acute event
      tidyr::crossing(acute_events, uk_daily) |>
        dplyr::mutate(
          days_equivalent = round(micromorts / daily_mm, 1),
          label = paste0(
            round(days_equivalent, 0), " days of ",
            sub(" \\(UK\\)", "", daily_activity)
          )
        ) |>
        dplyr::arrange(activity, dplyr::desc(daily_mm))
    }
  ),

  # Cumulative annual chronic risk vs top acute activities
  targets::tar_target(
    vig_chronic_acute_waterfall,
    {
      # UK chronic disease risks annualised
      uk_daily <- common_risks(profile = list(country = "UK")) |>
        dplyr::filter(grepl("mortality risk", activity)) |>
        dplyr::mutate(
          annual_mm = round(micromorts * 365, 0),
          cause = sub("Daily | mortality risk \\(UK\\)", "", activity)
        ) |>
        dplyr::select(cause, daily_mm = micromorts, annual_mm) |>
        dplyr::arrange(dplyr::desc(annual_mm))

      # Top acute risks for comparison
      acute_top <- common_risks() |>
        dplyr::filter(period_type == "event", micromorts >= 5) |>
        dplyr::arrange(dplyr::desc(micromorts)) |>
        dplyr::slice_head(n = 8) |>
        dplyr::select(cause = activity, micromorts) |>
        dplyr::rename(one_off_mm = micromorts)

      list(chronic_annual = uk_daily, acute_comparison = acute_top)
    }
  ),

  # UK vs Nigeria profile shift for scrollytelling
  targets::tar_target(
    vig_chronic_acute_country_shift,
    {
      uk <- common_risks(profile = list(country = "UK")) |>
        dplyr::filter(grepl("mortality risk", activity)) |>
        dplyr::select(activity, micromorts) |>
        dplyr::rename(uk_mm = micromorts)

      ng <- common_risks(profile = list(country = "NG")) |>
        dplyr::filter(grepl("mortality risk", activity)) |>
        dplyr::select(activity, micromorts) |>
        dplyr::rename(ng_mm = micromorts)

      # Match by stripping country suffix
      uk$cause <- sub(" \\(UK\\)", "", uk$activity)
      ng$cause <- sub(" \\(Nigeria\\)", "", ng$activity)

      dplyr::inner_join(
        uk |> dplyr::select(cause, uk_mm),
        ng |> dplyr::select(cause, ng_mm),
        by = "cause"
      ) |>
        dplyr::mutate(ratio = round(ng_mm / uk_mm, 1)) |>
        dplyr::arrange(dplyr::desc(ratio))
    }
  ),

  # ==========================================================================
  # TELEMETRY VIGNETTE (supplement existing targets)
  # ==========================================================================

  # Commit velocity chart (ggplotGrob so show_target renders via grid::grid.draw)
  targets::tar_target(
    vig_telemetry_commit_velocity_chart,
    {
      velocity <- safe_tar_read("vig_commit_velocity")
      if (is.null(velocity)) return(NULL)
      p <- ggplot2::ggplot(velocity, ggplot2::aes(x = week, y = commits)) +
        ggplot2::geom_col(fill = "#1976D2") +
        ggplot2::labs(
          title = "Commit Velocity",
          subtitle = "Last 26 weeks",
          x = "Week",
          y = "Commits",
          caption = paste0(
            "Weekly commit frequency over the last 26 weeks. ",
            "Each bar represents commits merged in a calendar week. ",
            "Data sourced from gert::git_log() with a 500-commit lookback window. ",
            "Weeks with zero commits indicate maintenance pauses or release ",
            "stabilization periods. Compare with GitHub Activity table below ",
            "for issue/PR context."
          )
        ) +
        ggplot2::theme_minimal() +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
      ggplot2::ggplotGrob(p)
    }
  ),

  # Top targets by stored object size (extracted from vig_pipeline_summary)
  targets::tar_target(
    vig_telemetry_top_by_size,
    {
      if (!is.null(vig_pipeline_summary) && !is.null(vig_pipeline_summary$top_by_size)) {
        vig_pipeline_summary$top_by_size |>
          dplyr::select(name, size_kb) |>
          utils::head(10)
      } else {
        tibble::tibble(name = character(), size_kb = numeric())
      }
    }
  ),

  # Top targets by computation time (extracted from vig_pipeline_summary)
  targets::tar_target(
    vig_telemetry_top_by_time,
    {
      if (!is.null(vig_pipeline_summary) && !is.null(vig_pipeline_summary$top_by_time)) {
        vig_pipeline_summary$top_by_time |>
          dplyr::select(name, seconds) |>
          utils::head(10)
      } else {
        tibble::tibble(name = character(), seconds = numeric())
      }
    }
  ),


  # ==========================================================================
  # INTRODUCTION VIGNETTE (supplement existing targets)
  # ==========================================================================

  # API demo values for inline display
  targets::tar_target(
    vig_intro_api_demos,
    list(
      micromort_from_prob = as.numeric(as_micromort(1/10000)),
      microlife_smoker = as.numeric(as_microlife(-20 * 30)),
      microlife_exercise = as.numeric(as_microlife(60)),
      microlife_overweight = as.numeric(as_microlife(-30)),
      vsl_us = as.numeric(value_of_micromort(vsl = 10000000)),
      vsl_uk = as.numeric(value_of_micromort(vsl = 1600000)),
      lle_one_micromort = as.numeric(lle(prob = 1/1e6, life_expectancy = 40))
    )
  ),


  # ==========================================================================
  # RANKING QUIZ DATA CONSISTENCY (Shinylive WebR limitation)
  # ==========================================================================

  # Canonical ranking quiz questions
  targets::tar_target(
    vig_ranking_questions,
    {
      q3 <- ranking_quiz_questions(n_questions = 50, items_per_question = 3, seed = 42)
      q4 <- ranking_quiz_questions(n_questions = 30, items_per_question = 4, seed = 42)
      rbind(q3, q4)
    }
  ),

  # JSON script tag for micromort-quiz.qmd (acute pairs)
  # Produces the complete <script id="quiz-data"> HTML string consumed by JS
  targets::tar_target(
    vig_quiz_json_script,
    {
      pairs <- vig_quiz_pairs
      json_str <- jsonlite::toJSON(pairs, dataframe = "rows", auto_unbox = TRUE)
      sprintf('<script id="quiz-data" type="application/json">%s</script>', json_str)
    }
  ),

  # JSON script tag for microlife-quiz.qmd (chronic pairs)
  targets::tar_target(
    vig_chronic_quiz_json_script,
    {
      pairs <- vig_chronic_pairs
      json_str <- jsonlite::toJSON(pairs, dataframe = "rows", auto_unbox = TRUE)
      sprintf('<script id="quiz-data" type="application/json">%s</script>', json_str)
    }
  ),

  # JSON script tag for risk-ranking-quiz.qmd (ranking questions)
  targets::tar_target(
    vig_ranking_quiz_json_script,
    {
      pairs <- vig_ranking_questions
      json_str <- jsonlite::toJSON(pairs, dataframe = "rows", auto_unbox = TRUE)
      sprintf('<script id="quiz-data" type="application/json">%s</script>', json_str)
    }
  ),

  # Check CSV in ranking_quiz_shinylive.qmd matches canonical questions
  targets::tar_target(
    vig_ranking_csv_check,
    {
      qmd_lines <- readLines("vignettes/ranking_quiz_shinylive.qmd", warn = FALSE)
      file_marker <- grep("^## file: ranking_questions\\.csv", qmd_lines)[1]
      if (is.na(file_marker)) {
        return(list(status = "OK", message = "No ranking quiz qmd yet"))
      }
      csv_start <- file_marker + 1L
      if (grepl("^## type:", qmd_lines[csv_start])) csv_start <- csv_start + 1L
      fence_lines <- grep("^```$", qmd_lines)
      csv_end <- fence_lines[fence_lines > file_marker][1] - 1L
      if (is.na(csv_end) || csv_end < csv_start) {
        return(list(status = "ERROR", message = "Could not find CSV boundaries"))
      }
      csv_text <- qmd_lines[csv_start:csv_end]
      embedded <- tryCatch(
        utils::read.csv(textConnection(paste(csv_text, collapse = "\n")), stringsAsFactors = FALSE),
        error = function(e) NULL
      )
      if (is.null(embedded)) {
        return(list(status = "ERROR", message = "Failed to parse embedded CSV"))
      }
      canonical <- as.data.frame(vig_ranking_questions, stringsAsFactors = FALSE)
      # Compare via CSV text to avoid R object serialization differences
      # (ALTREP, attribute order, int vs numeric)
      csv_hash <- function(df) {
        tc <- textConnection("out", "w")
        on.exit(close(tc))
        utils::write.csv(df, tc, row.names = FALSE)
        digest::digest(out)
      }
      hash_canonical <- csv_hash(canonical)
      hash_embedded <- csv_hash(embedded)
      list(
        status = if (hash_canonical == hash_embedded) "OK" else "STALE",
        canonical_rows = nrow(canonical),
        embedded_rows = nrow(embedded),
        canonical_hash = hash_canonical,
        embedded_hash = hash_embedded
      )
    },
    cue = targets::tar_cue(mode = "always")
  ),


  # Check CSV in chronic_quiz_shinylive.qmd matches canonical pairs
  targets::tar_target(
    vig_chronic_csv_check,
    {
      qmd_lines <- readLines("vignettes/chronic_quiz_shinylive.qmd", warn = FALSE)

      file_marker <- grep("^## file: chronic_pairs\\.csv", qmd_lines)[1]
      if (is.na(file_marker)) {
        return(list(status = "ERROR",
                    message = "Could not find ## file: chronic_pairs.csv in qmd"))
      }

      csv_start <- file_marker + 1L
      if (grepl("^## type:", qmd_lines[csv_start])) csv_start <- csv_start + 1L
      fence_lines <- grep("^```$", qmd_lines)
      csv_end <- fence_lines[fence_lines > file_marker][1] - 1L

      if (is.na(csv_end) || csv_end < csv_start) {
        return(list(status = "ERROR",
                    message = "Could not find CSV boundaries in qmd"))
      }

      csv_text <- qmd_lines[csv_start:csv_end]

      embedded <- tryCatch(
        utils::read.csv(textConnection(paste(csv_text, collapse = "\n")),
                        stringsAsFactors = FALSE),
        error = function(e) NULL
      )

      if (is.null(embedded)) {
        return(list(status = "ERROR", message = "Failed to parse embedded CSV"))
      }

      canonical <- as.data.frame(vig_chronic_pairs, stringsAsFactors = FALSE)
      canonical <- canonical[order(canonical$factor_a, canonical$factor_b), ]
      embedded <- embedded[order(embedded$factor_a, embedded$factor_b), ]
      rownames(canonical) <- NULL
      rownames(embedded) <- NULL
      num_cols <- names(canonical)[vapply(canonical, is.numeric, logical(1))]
      for (col in num_cols) {
        canonical[[col]] <- round(canonical[[col]], 10)
        embedded[[col]] <- round(embedded[[col]], 10)
      }
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
