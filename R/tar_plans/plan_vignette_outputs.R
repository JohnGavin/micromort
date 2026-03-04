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
  )

)
