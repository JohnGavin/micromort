# Package index

## Datasets

Core data exports

- [`acute_risks`](https://johngavin.github.io/micromort/reference/acute_risks.md)
  : Acute Risks Dataset
- [`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md)
  : Chronic Risks Dataset
- [`risk_sources`](https://johngavin.github.io/micromort/reference/risk_sources.md)
  : Risk Sources Registry

## Data Loaders

Load parquet datasets

- [`load_acute_risks()`](https://johngavin.github.io/micromort/reference/load_acute_risks.md)
  : Load Acute Risks Dataset
- [`load_chronic_risks()`](https://johngavin.github.io/micromort/reference/load_chronic_risks.md)
  : Load Chronic Risks Dataset
- [`load_sources()`](https://johngavin.github.io/micromort/reference/load_sources.md)
  : Load Risk Sources Registry

## Atomic Risk Schema

Component-level risk data and decomposition

- [`atomic_risks()`](https://johngavin.github.io/micromort/reference/atomic_risks.md)
  : Atomic Risk Components
- [`risk_components()`](https://johngavin.github.io/micromort/reference/risk_components.md)
  : View Risk Components for an Activity
- [`risk_for_duration()`](https://johngavin.github.io/micromort/reference/risk_for_duration.md)
  : Calculate Risk for Custom Duration
- [`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)
  : Acute Risks in Micromorts

## Risk Equivalence

Cross-activity risk comparison

- [`risk_equivalence()`](https://johngavin.github.io/micromort/reference/risk_equivalence.md)
  : Risk Equivalence Table
- [`risk_exchange_matrix()`](https://johngavin.github.io/micromort/reference/risk_exchange_matrix.md)
  : Risk Exchange Matrix

## Radiation Profiles

Occupational, passenger, and environmental radiation comparison

- [`radiation_profiles()`](https://johngavin.github.io/micromort/reference/radiation_profiles.md)
  : Radiation Exposure Profiles
- [`patient_radiation_comparison()`](https://johngavin.github.io/micromort/reference/patient_radiation_comparison.md)
  : Patient vs Occupational Radiation Comparison

## Legacy Data Functions

Original data functions (retained for compatibility)

- [`demographic_factors()`](https://johngavin.github.io/micromort/reference/demographic_factors.md)
  : Demographic Life Expectancy Factors
- [`covid_vaccine_rr()`](https://johngavin.github.io/micromort/reference/covid_vaccine_rr.md)
  : COVID-19 Vaccine Relative Risks
- [`risk_data_sources()`](https://johngavin.github.io/micromort/reference/risk_data_sources.md)
  : Data Sources for Micromort and Microlife Research

## Regional Life Expectancy

Geographic variation in mortality risk

- [`regional_life_expectancy()`](https://johngavin.github.io/micromort/reference/regional_life_expectancy.md)
  : Regional Life Expectancy in Western Europe
- [`vanguard_regions()`](https://johngavin.github.io/micromort/reference/vanguard_regions.md)
  : Vanguard Regions with Highest Life Expectancy
- [`laggard_regions()`](https://johngavin.github.io/micromort/reference/laggard_regions.md)
  : Laggard Regions with Stalled Life Expectancy Gains
- [`regional_mortality_multiplier()`](https://johngavin.github.io/micromort/reference/regional_mortality_multiplier.md)
  : Regional Mortality Multiplier

## Conditional Risk Analysis

Compare hedged vs unhedged risk scenarios

- [`cancer_risks()`](https://johngavin.github.io/micromort/reference/cancer_risks.md)
  : Cancer Risks by Type, Sex, and Age
- [`vaccination_risks()`](https://johngavin.github.io/micromort/reference/vaccination_risks.md)
  : Vaccination Risk Reduction
- [`conditional_risk()`](https://johngavin.github.io/micromort/reference/conditional_risk.md)
  : Conditional Risk Comparison (Hedged vs Unhedged)
- [`hedged_portfolio()`](https://johngavin.github.io/micromort/reference/hedged_portfolio.md)
  : Hedged Portfolio Risk Summary

## Conversion Functions

Convert between risk units

- [`as_micromort()`](https://johngavin.github.io/micromort/reference/as_micromort.md)
  : Convert Probability to Micromorts
- [`as_microlife()`](https://johngavin.github.io/micromort/reference/as_microlife.md)
  : Convert Minutes to Microlives
- [`as_probability()`](https://johngavin.github.io/micromort/reference/as_probability.md)
  : Convert Micromorts to Probability
- [`lle()`](https://johngavin.github.io/micromort/reference/lle.md) :
  Loss of Life Expectancy (LLE)
- [`value_of_micromort()`](https://johngavin.github.io/micromort/reference/value_of_micromort.md)
  : Value of a Statistical Life (VSL) to Micromort Value

## Analysis Functions

Risk analysis and modeling

- [`compare_interventions()`](https://johngavin.github.io/micromort/reference/compare_interventions.md)
  : Compare Lifestyle Interventions
- [`lifestyle_tradeoff()`](https://johngavin.github.io/micromort/reference/lifestyle_tradeoff.md)
  : Calculate Lifestyle Tradeoff
- [`daily_hazard_rate()`](https://johngavin.github.io/micromort/reference/daily_hazard_rate.md)
  : Daily Hazard Rate by Age
- [`annual_risk_budget()`](https://johngavin.github.io/micromort/reference/annual_risk_budget.md)
  : Annual Risk Budget

## Visualization

Risk visualization

- [`prepare_risks_plot()`](https://johngavin.github.io/micromort/reference/prepare_risks_plot.md)
  : Prepare Risk Data for Plotting
- [`plot_risks()`](https://johngavin.github.io/micromort/reference/plot_risks.md)
  : Plot Risk Comparison
- [`plot_risks_interactive()`](https://johngavin.github.io/micromort/reference/plot_risks_interactive.md)
  : Interactive Risk Plot
- [`plot_risk_components()`](https://johngavin.github.io/micromort/reference/plot_risk_components.md)
  : Plot Risk Components as Stacked Bar

## Interactive Tools

API, dashboard, and quiz

- [`launch_api()`](https://johngavin.github.io/micromort/reference/launch_api.md)
  : Launch Micromort REST API
- [`launch_dashboard()`](https://johngavin.github.io/micromort/reference/launch_dashboard.md)
  : Launch Risk Explorer Dashboard
- [`launch_quiz()`](https://johngavin.github.io/micromort/reference/launch_quiz.md)
  : Launch Interactive "Which Is Riskier?" Quiz
- [`quiz_pairs()`](https://johngavin.github.io/micromort/reference/quiz_pairs.md)
  : Generate Quiz Pairs for "Which Is Riskier?" Game
