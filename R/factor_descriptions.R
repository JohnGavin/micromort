#' Chronic Factor Descriptions and Help URLs
#'
#' Returns a tibble of human-readable descriptions and authoritative help URLs
#' for all factors in [chronic_risks()]. Useful for quiz tooltips, API
#' responses, and dashboards.
#'
#' @return A tibble with columns:
#'   - `factor`: Factor name (matches [chronic_risks()] exactly)
#'   - `description`: 1-2 sentence explanation of the factor
#'   - `help_url`: Authoritative source URL
#'
#' @examples
#' factor_descriptions()
#' factor_descriptions() |> dplyr::filter(grepl("exercise", factor, ignore.case = TRUE))
#'
#' @export
factor_descriptions <- function() {
  tibble::tribble(
    ~factor, ~description, ~help_url,

    # Smoking
    "Smoking 20 cigarettes",
    "A pack-a-day habit accelerates aging so that each day lived costs 29 hours of life expectancy. The single largest modifiable mortality risk.",
    "https://en.wikipedia.org/wiki/Health_effects_of_tobacco",

    "Smoking 10 cigarettes",
    "Half-a-pack daily. Dose-response is roughly linear: half the cigarettes, half the microlife cost.",
    "https://en.wikipedia.org/wiki/Health_effects_of_tobacco",

    "Smoking 2 cigarettes",
    "Even light smoking (2 cigarettes/day) carries measurable cardiovascular and cancer risk. Each cigarette costs roughly 15 minutes of life.",
    "https://en.wikipedia.org/wiki/Health_effects_of_tobacco",

    # Weight
    "Being 5 kg overweight",
    "Each 5 kg above optimum BMI increases risk of type 2 diabetes, cardiovascular disease, and several cancers.",
    "https://en.wikipedia.org/wiki/Obesity#Effects_on_health",

    "Being 10 kg overweight",
    "Cumulative metabolic and cardiovascular burden of moderate obesity (BMI ~28-30).",
    "https://en.wikipedia.org/wiki/Obesity#Effects_on_health",

    "Being 15 kg overweight",
    "Significant obesity (BMI ~30+) with substantially elevated risks of heart disease, stroke, and cancer.",
    "https://en.wikipedia.org/wiki/Obesity#Effects_on_health",

    # Alcohol
    "2nd-3rd alcoholic drink",
    "After the first drink's potential protective effect, the second and third drinks increase liver disease and accident risk.",
    "https://en.wikipedia.org/wiki/Alcohol_and_health",

    "4th-5th alcoholic drink",
    "Heavy daily drinking (4-5 drinks) dramatically increases liver cirrhosis, cancer, and cardiovascular mortality.",
    "https://en.wikipedia.org/wiki/Alcohol_and_health",

    # Diet
    "Red meat (1 portion/day)",
    "Daily red meat consumption is associated with increased colorectal cancer and cardiovascular disease risk.",
    "https://www.who.int/news-room/questions-and-answers/item/cancer-carcinogenicity-of-the-consumption-of-red-meat-and-processed-meat",

    "Processed meat (1 portion/day)",
    "Bacon, sausages, ham, etc. classified as Group 1 carcinogens by IARC. Strongest evidence for colorectal cancer.",
    "https://www.who.int/news-room/questions-and-answers/item/cancer-carcinogenicity-of-the-consumption-of-red-meat-and-processed-meat",

    "Low fiber diet",
    "Less than 25 g fiber daily increases colorectal cancer risk and is associated with higher cardiovascular mortality.",
    "https://en.wikipedia.org/wiki/Dietary_fiber#Health_effects",

    "High sugar diet",
    "Excess refined sugar intake drives insulin resistance, type 2 diabetes, obesity, and cardiovascular disease.",
    "https://en.wikipedia.org/wiki/Sugar#Health_effects",

    "2-3 cups coffee (men)",
    "Heavy coffee consumption in men shows a small mortality association, though the evidence is mixed and coffee also has protective effects.",
    "https://en.wikipedia.org/wiki/Health_effects_of_coffee",

    # Sedentary
    "2 hours TV watching",
    "Prolonged sedentary behaviour (sitting/lying) increases cardiovascular mortality independent of exercise. TV time is a proxy for total sitting.",
    "https://en.wikipedia.org/wiki/Sedentary_lifestyle",

    "Sitting 8+ hours/day",
    "Full-day desk work without breaks substantially increases cardiovascular disease, diabetes, and all-cause mortality risk.",
    "https://en.wikipedia.org/wiki/Sedentary_lifestyle",

    # Environment
    "Living with a smoker",
    "Second-hand smoke exposure increases lung cancer risk by 20-30% and heart disease risk by 25-30%.",
    "https://en.wikipedia.org/wiki/Passive_smoking",

    "Air pollution (high)",
    "Living in a highly polluted urban area (PM2.5 > 25 ug/m3) causes chronic respiratory and cardiovascular damage.",
    "https://en.wikipedia.org/wiki/Air_pollution#Health_effects",

    # Cardiovascular
    "Untreated hypertension",
    "Systolic BP > 140 mmHg left untreated is the leading modifiable risk factor for stroke, heart attack, and kidney disease.",
    "https://en.wikipedia.org/wiki/Hypertension",

    "Type 2 diabetes (poorly controlled)",
    "HbA1c > 8% dramatically increases risk of cardiovascular disease, neuropathy, retinopathy, and kidney failure.",
    "https://en.wikipedia.org/wiki/Type_2_diabetes",

    "High LDL cholesterol (untreated)",
    "LDL > 160 mg/dL without statin therapy accelerates atherosclerosis and coronary heart disease.",
    "https://en.wikipedia.org/wiki/Low-density_lipoprotein#Role_in_disease",

    "Family history of heart disease",
    "First-degree relative with CVD before age 55 roughly doubles your own cardiovascular risk.",
    "https://en.wikipedia.org/wiki/Cardiovascular_disease#Risk_factors",

    # Cancer risk
    "Family history of cancer",
    "First-degree relative with cancer increases your own risk, especially for breast, colorectal, and prostate cancers.",
    "https://en.wikipedia.org/wiki/Cancer#Genetics",

    "Low physical activity",
    "Less than 150 minutes of moderate exercise per week increases cancer risk (colon, breast, endometrial) by 20-30%.",
    "https://www.who.int/news-room/fact-sheets/detail/physical-activity",

    "Excessive alcohol (cancer)",
    "More than 2 drinks/day increases risk of mouth, throat, oesophageal, liver, breast, and colorectal cancers.",
    "https://en.wikipedia.org/wiki/Alcohol_and_cancer",

    # Demographics
    "Being male (vs female)",
    "Males have 4-5 year shorter life expectancy than females in most populations, driven by biology and behaviour.",
    "https://en.wikipedia.org/wiki/Life_expectancy#Sex_differences",

    # Mental Health
    "Chronic stress/poor sleep",
    "Chronic stress and sleep deprivation elevate cortisol, drive inflammation, and increase cardiovascular and metabolic disease risk.",
    "https://en.wikipedia.org/wiki/Health_effects_of_chronic_stress",

    # ---- GAINS (positive microlives) ----

    "First alcoholic drink",
    "Moderate alcohol intake (1 drink/day) shows a J-shaped mortality curve, with possible protective cardiovascular effects.",
    "https://en.wikipedia.org/wiki/Alcohol_and_cardiovascular_disease",

    "20 min moderate exercise",
    "Daily brisk walking or equivalent moderate activity reduces all-cause mortality by ~30%. The single most effective lifestyle intervention.",
    "https://www.who.int/news-room/fact-sheets/detail/physical-activity",

    "150 min weekly exercise",
    "Meeting WHO physical activity guidelines reduces cardiovascular, cancer, and all-cause mortality substantially.",
    "https://www.who.int/news-room/fact-sheets/detail/physical-activity",

    "5 servings fruit/veg",
    "Daily fruit and vegetable intake reduces cardiovascular disease, cancer, and all-cause mortality. Largest benefit from 5+ servings.",
    "https://en.wikipedia.org/wiki/Five_A_Day",

    "High fiber diet",
    "25 g+ fiber daily from whole grains, fruit, and vegetables reduces colorectal cancer, cardiovascular disease, and type 2 diabetes.",
    "https://en.wikipedia.org/wiki/Dietary_fiber#Health_effects",

    "Mediterranean diet",
    "Rich in olive oil, fish, vegetables, and whole grains. Proven to reduce cardiovascular events and cancer incidence.",
    "https://en.wikipedia.org/wiki/Mediterranean_diet",

    "Statin therapy (if indicated)",
    "Cholesterol-lowering statins reduce major cardiovascular events by ~25% in high-risk patients.",
    "https://en.wikipedia.org/wiki/Statin",

    "Blood pressure control",
    "Achieving target BP < 130/80 mmHg through medication and lifestyle reduces stroke risk by 35-40%.",
    "https://en.wikipedia.org/wiki/Antihypertensive_drug",

    "Cancer screening (age-appropriate)",
    "Age-appropriate screening (mammography, colonoscopy, cervical smears) detects cancer early when treatment is most effective.",
    "https://en.wikipedia.org/wiki/Cancer_screening",

    "Being female (vs male)",
    "Female sex advantage: longer telomeres, oestrogen cardioprotection, and lower risk-taking behaviour.",
    "https://en.wikipedia.org/wiki/Life_expectancy#Sex_differences",

    "Living in 2010 vs 1910",
    "A century of medical, nutritional, and public health progress added ~30 years to life expectancy in developed countries.",
    "https://en.wikipedia.org/wiki/Life_expectancy#Variation_over_time",

    "Living in Sweden vs Russia (male)",
    "Swedish males live ~15 years longer than Russian males, reflecting differences in healthcare, alcohol consumption, and social policy.",
    "https://en.wikipedia.org/wiki/List_of_countries_by_life_expectancy"
  )
}
