#' Activity Descriptions and Help URLs
#'
#' Returns a tibble of human-readable descriptions and authoritative help URLs
#' for all activities in [common_risks()]. Useful for quiz tooltips, API
#' responses, and dashboards.
#'
#' @return A tibble with columns:
#'   - `activity`: Activity name (matches [common_risks()] exactly)
#'   - `description`: 1-2 sentence explanation of the risk
#'   - `help_url`: Authoritative source URL (Wikipedia or similar)
#'
#' @examples
#' activity_descriptions()
#' activity_descriptions() |> dplyr::filter(grepl("Skydiving", activity))
#'
#' @export
activity_descriptions <- function() {
  tibble::tribble(
    ~activity, ~description, ~help_url,

    # Extreme Risk (>1000 micromorts)
    "Mt. Everest ascent",
    "At 8,849m, extreme altitude, weather, and avalanche risk make Everest the deadliest common mountaineering objective.",
    "https://en.wikipedia.org/wiki/Mount_Everest",

    "Himalayan mountaineering",
    "Expeditions to 8,000m+ peaks carry extreme risk from altitude sickness, avalanches, and exposure.",
    "https://en.wikipedia.org/wiki/Eight-thousander",

    "COVID-19 infection (unvaccinated)",
    "Unvaccinated COVID-19 infection carries substantial mortality risk, especially for older adults.",
    "https://en.wikipedia.org/wiki/COVID-19",

    "Spanish flu infection",
    "The 1918 influenza pandemic killed an estimated 50-100 million people worldwide.",
    "https://en.wikipedia.org/wiki/Spanish_flu",

    "Matterhorn ascent",
    "One of the Alps' deadliest peaks due to rockfall, exposure, and technical climbing difficulty.",
    "https://en.wikipedia.org/wiki/Matterhorn",

    # Very High Risk (100-1000 micromorts)
    "Living in US during COVID-19 (Jul 2020)",
    "Peak US COVID-19 mortality before vaccines were available.",
    "https://en.wikipedia.org/wiki/COVID-19_pandemic_in_the_United_States",

    "Living (one day, age 90)",
    "Daily background mortality risk at age 90 reflects accumulated physiological decline.",
    "https://en.wikipedia.org/wiki/Mortality_rate",

    "Base jumping",
    "Parachuting from fixed objects (buildings, cliffs) with minimal altitude for recovery.",
    "https://en.wikipedia.org/wiki/BASE_jumping",

    "First day of life (newborn)",
    "The first 24 hours carry elevated risk from birth complications and congenital conditions.",
    "https://en.wikipedia.org/wiki/Neonatal_death",

    "COVID-19 unvaccinated (age 80+)",
    "Unvaccinated elderly face the highest COVID-19 mortality rates.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    "Caesarean birth (mother)",
    "Major abdominal surgery carrying risks of hemorrhage, infection, and anesthesia complications.",
    "https://en.wikipedia.org/wiki/Caesarean_section",

    "Scuba diving, trained (yearly)",
    "Cumulative annual risk for trained divers from decompression sickness, drowning, and equipment failure.",
    "https://en.wikipedia.org/wiki/Scuba_diving",

    "Vaginal birth (mother)",
    "Maternal mortality risk from hemorrhage, infection, and eclampsia during vaginal delivery.",
    "https://en.wikipedia.org/wiki/Maternal_death",

    "Living (one day, age 75)",
    "Daily background mortality at age 75 is roughly 100x that of a 20-year-old.",
    "https://en.wikipedia.org/wiki/Mortality_rate",

    # High Risk (10-100 micromorts)
    "COVID-19 unvaccinated (age 65-79)",
    "Unvaccinated 65-79 year-olds had substantially elevated COVID-19 mortality in 2022.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    "Night in hospital",
    "Hospital stays carry risk from medical errors, hospital-acquired infections, and underlying illness severity.",
    "https://en.wikipedia.org/wiki/Hospital-acquired_infection",

    "COVID-19 monovalent vaccine (age 80+)",
    "Even with monovalent vaccination, elderly remained at elevated COVID-19 risk in 2022.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    "Living in NYC COVID-19 (Mar-May 2020)",
    "New York City experienced extreme COVID-19 mortality during the initial wave.",
    "https://en.wikipedia.org/wiki/COVID-19_pandemic_in_New_York_City",

    "Heroin use (per dose)",
    "Each dose carries risk of respiratory depression, overdose, and contaminated supply.",
    "https://en.wikipedia.org/wiki/Heroin",

    "US military in Afghanistan (2010)",
    "Daily risk during peak combat operations in Afghanistan's most dangerous year.",
    "https://en.wikipedia.org/wiki/War_in_Afghanistan_(2001%E2%80%932021)",

    "COVID-19 bivalent booster (age 80+)",
    "Bivalent-boosted elderly still faced elevated COVID-19 risk due to immunosenescence.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    "COVID-19 unvaccinated (all ages)",
    "Population-average COVID-19 mortality risk for unvaccinated individuals in 2022.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    "American football",
    "Contact sport risk from traumatic injury including spinal and head trauma.",
    "https://en.wikipedia.org/wiki/American_football",

    "Living (one day, under age 1)",
    "Infant mortality from congenital conditions, SIDS, and birth complications.",
    "https://en.wikipedia.org/wiki/Infant_mortality",

    "Ecstasy/MDMA (per dose)",
    "Risk from hyperthermia, serotonin syndrome, and contaminated supply.",
    "https://en.wikipedia.org/wiki/MDMA",

    "Swimming",
    "Drowning risk per swim session, higher for open water and unsupervised settings.",
    "https://en.wikipedia.org/wiki/Drowning",

    "General anesthesia (emergency)",
    "Emergency anesthesia carries higher risk than elective due to patient instability.",
    "https://en.wikipedia.org/wiki/General_anaesthesia",

    "Motorcycling (60 miles)",
    "Per-mile fatality rate roughly 30x higher than car travel due to exposure and instability.",
    "https://en.wikipedia.org/wiki/Motorcycle_safety",

    "Skydiving",
    "Risk from parachute malfunction, mid-air collision, and landing errors.",
    "https://en.wikipedia.org/wiki/Skydiving",

    # Moderate Risk (1-10 micromorts)
    "COVID-19 monovalent vaccine (age 65-79)",
    "Monovalent-vaccinated 65-79 year-olds had reduced but still notable COVID-19 risk.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    "Skydiving (US)",
    "US skydiving fatality rate based on USPA incident reports.",
    "https://en.wikipedia.org/wiki/Skydiving",

    "Skydiving (UK)",
    "UK skydiving fatality rate based on British Parachute Association data.",
    "https://en.wikipedia.org/wiki/Skydiving",

    "COVID-19 unvaccinated (age 50-64)",
    "Unvaccinated 50-64 year-olds had moderately elevated COVID-19 mortality.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    "Hang gliding",
    "Unpowered flight with risk from turbulence, structural failure, and pilot error.",
    "https://en.wikipedia.org/wiki/Hang_gliding",

    "Running a marathon",
    "Cardiac events during extreme endurance exercise, mainly in older or predisposed runners.",
    "https://en.wikipedia.org/wiki/Marathon",

    "Living in Maryland COVID-19 (Mar-May 2020)",
    "Maryland experienced moderate COVID-19 mortality during the initial wave.",
    "https://en.wikipedia.org/wiki/COVID-19_pandemic_in_Maryland",

    "Living (one day, age 45)",
    "Daily background mortality at age 45 reflects middle-age cardiovascular and cancer risk.",
    "https://en.wikipedia.org/wiki/Mortality_rate",

    "Scuba diving, trained",
    "Single-dive risk for trained divers from decompression sickness and equipment failure.",
    "https://en.wikipedia.org/wiki/Scuba_diving",

    "Living (one day, age 50)",
    "Daily mortality at age 50 is roughly 4x that of a 20-year-old.",
    "https://en.wikipedia.org/wiki/Mortality_rate",

    "COVID-19 monovalent vaccine (all ages)",
    "Population-average residual COVID-19 risk after monovalent vaccination.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    "Rock climbing",
    "Risk from falls, rockfall, and equipment failure on natural rock.",
    "https://en.wikipedia.org/wiki/Rock_climbing",

    "COVID-19 bivalent booster (age 65-79)",
    "Bivalent-boosted 65-79 year-olds had lowest but still measurable COVID-19 risk.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    "COVID-19 monovalent vaccine (age 50-64)",
    "Monovalent-vaccinated 50-64 year-olds had low residual COVID-19 mortality.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    "COVID-19 unvaccinated (age 18-49)",
    "Young adult unvaccinated COVID-19 mortality was low but non-negligible.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    "Living 2 months with a smoker",
    "Secondhand smoke exposure increases cardiovascular and respiratory disease risk.",
    "https://en.wikipedia.org/wiki/Passive_smoking",

    "Walking (20 miles)",
    "Pedestrian fatality risk from traffic collisions over a 20-mile walk.",
    "https://en.wikipedia.org/wiki/Pedestrian",

    "Driving (230 miles)",
    "Traffic fatality risk for a typical 230-mile car journey.",
    "https://en.wikipedia.org/wiki/Traffic_collision",

    "Train (1000 miles)",
    "Rail travel is one of the safest transport modes per mile.",
    "https://en.wikipedia.org/wiki/Rail_transport",

    "Eating 1000 bananas (radiation)",
    "Cumulative potassium-40 radiation dose from 1000 bananas equals roughly 1 micromort.",
    "https://en.wikipedia.org/wiki/Banana_equivalent_dose",

    "1 hour in a coal mine",
    "Risk from roof collapse, gas explosion, and dust inhalation.",
    "https://en.wikipedia.org/wiki/Coal_mining",

    "Eating 40 tbsp peanut butter (aflatoxin)",
    "Aflatoxin B1 from mould contamination is a potent liver carcinogen.",
    "https://en.wikipedia.org/wiki/Aflatoxin",

    "Eating 100 charbroiled steaks",
    "Polycyclic aromatic hydrocarbons from charring are carcinogenic at high cumulative doses.",
    "https://en.wikipedia.org/wiki/Polycyclic_aromatic_hydrocarbon",

    "Living (one day, age 20)",
    "Daily background mortality at age 20 is dominated by accidents and violence.",
    "https://en.wikipedia.org/wiki/Mortality_rate",

    "Living (one day, age 30)",
    "Daily mortality at age 30 is similar to age 20 with slightly more disease contribution.",
    "https://en.wikipedia.org/wiki/Mortality_rate",

    "COVID-19 bivalent booster (all ages)",
    "Population-average residual COVID-19 risk after bivalent booster vaccination.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    "COVID-19 bivalent booster (age 50-64)",
    "Bivalent-boosted 50-64 year-olds had very low residual COVID-19 mortality.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    # Low Risk (<1 micromort)
    "Skiing",
    "Risk from collisions with trees/other skiers and avalanche in backcountry.",
    "https://en.wikipedia.org/wiki/Skiing",

    "Horse riding",
    "Falls from horseback can cause traumatic brain and spinal injuries.",
    "https://en.wikipedia.org/wiki/Equestrianism",

    "COVID-19 monovalent vaccine (age 18-49)",
    "Young adult monovalent-vaccinated COVID-19 mortality was very low.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    "Kangaroo encounter",
    "Vehicle collisions with kangaroos cause fatalities in rural Australia.",
    "https://en.wikipedia.org/wiki/Kangaroo",

    "COVID-19 bivalent booster (age 18-49)",
    "Bivalent-boosted young adults had near-baseline COVID-19 mortality.",
    "https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm",

    # Flying (decomposed)
    "Flying (2h short-haul)",
    "Short-haul flight risk is dominated by takeoff/landing crash risk; DVT and radiation are minimal.",
    "https://en.wikipedia.org/wiki/Aviation_safety",

    "Flying (5h medium-haul)",
    "Medium-haul flights add DVT risk as immobility exceeds the 4-hour threshold.",
    "https://en.wikipedia.org/wiki/Aviation_safety",

    "Flying (8h long-haul)",
    "Long-haul flights have significant DVT risk, especially for those with risk factors.",
    "https://en.wikipedia.org/wiki/Economy_class_syndrome",

    "Flying (12h ultra-long-haul)",
    "Ultra-long-haul flights carry the highest DVT risk; compression socks can reduce it ~65%.",
    "https://en.wikipedia.org/wiki/Economy_class_syndrome",

    # Medical radiation
    "Chest X-ray (radiation per scan)",
    "Very low radiation dose (~0.02 mSv), equivalent to a few hours of background radiation.",
    "https://en.wikipedia.org/wiki/Chest_radiograph",

    "CT scan chest (radiation per scan)",
    "Moderate radiation dose (~7 mSv) used for diagnosing pulmonary embolism, cancer, and trauma.",
    "https://en.wikipedia.org/wiki/CT_scan",

    "CT scan abdomen (radiation per scan)",
    "Higher radiation dose (~10 mSv) for abdominal imaging; benefits usually outweigh risks.",
    "https://en.wikipedia.org/wiki/CT_scan",

    "Mammogram (radiation per scan)",
    "Very low radiation dose used for breast cancer screening; net benefit is strongly positive.",
    "https://en.wikipedia.org/wiki/Mammography",

    "Dental X-ray (radiation per scan)",
    "Extremely low radiation dose (~0.005 mSv) for dental diagnostics.",
    "https://en.wikipedia.org/wiki/Dental_radiography",

    "Coronary angiogram (radiation per scan)",
    "Moderate radiation dose from fluoroscopy-guided cardiac catheterisation.",
    "https://en.wikipedia.org/wiki/Coronary_catheterization",

    "Barium enema (radiation per scan)",
    "Moderate radiation dose from fluoroscopic imaging of the large intestine.",
    "https://en.wikipedia.org/wiki/Barium_enema",

    "CT scan head (radiation per scan)",
    "Low-moderate radiation dose (~2 mSv) for neurological imaging.",
    "https://en.wikipedia.org/wiki/CT_scan",

    # Mundane
    "Drinking a glass of wine",
    "Acute alcohol effects including impaired judgment and cardiovascular stress.",
    "https://en.wikipedia.org/wiki/Alcohol_(drug)",

    "Cup of coffee",
    "Extremely low acute risk; caffeine-related cardiac events are vanishingly rare.",
    "https://en.wikipedia.org/wiki/Coffee",

    "Commuting by car (30 min)",
    "Short car commute with crash risk from traffic collisions.",
    "https://en.wikipedia.org/wiki/Traffic_collision",

    "Commuting by bicycle (30 min)",
    "Cycling commute with risk from traffic collisions and exertion-related events.",
    "https://en.wikipedia.org/wiki/Bicycle_safety",

    "Working in an office (8 hours)",
    "Background mortality rate during sedentary office work.",
    "https://en.wikipedia.org/wiki/Mortality_rate",

    "Taking a bath",
    "Drowning risk, particularly for elderly and those with medical conditions.",
    "https://en.wikipedia.org/wiki/Drowning",

    "Crossing a road",
    "Pedestrian collision risk at a single road crossing.",
    "https://en.wikipedia.org/wiki/Pedestrian",

    # Annual occupational/environmental radiation
    "Airline pilot (annual radiation)",
    "Cumulative cosmic radiation exposure from ~700 flight hours per year at altitude.",
    "https://en.wikipedia.org/wiki/Airline_pilot",

    "X-ray technician (annual radiation)",
    "Occupational radiation exposure mitigated by lead shielding and ALARA protocols.",
    "https://en.wikipedia.org/wiki/Radiographer",

    "Dental radiographer (annual radiation)",
    "Very low annual occupational radiation dose with standard distance protocols.",
    "https://en.wikipedia.org/wiki/Dental_radiography",

    "Nuclear plant worker (annual radiation)",
    "Controlled occupational exposure within regulatory limits using dosimetry and shielding.",
    "https://en.wikipedia.org/wiki/Nuclear_power_plant",

    "Interventional cardiologist (annual radiation)",
    "Highest occupational medical radiation dose from fluoroscopy-guided procedures.",
    "https://en.wikipedia.org/wiki/Interventional_cardiology",

    "Frequent executive flyer (annual cosmic)",
    "Heavy business travel (~150,000 miles/year) accumulates cosmic radiation dose.",
    "https://en.wikipedia.org/wiki/Cosmic_ray",

    "Business traveller (annual cosmic)",
    "Moderate annual cosmic radiation from ~40,000 miles of flying per year.",
    "https://en.wikipedia.org/wiki/Cosmic_ray",

    "Annual tourist flyer (annual cosmic)",
    "Minimal cosmic radiation from occasional holiday flights (~6,000 miles/year).",
    "https://en.wikipedia.org/wiki/Cosmic_ray",

    "Granite resident (annual radon)",
    "Radon gas seeps from granite bedrock into homes; mitigable with ventilation.",
    "https://en.wikipedia.org/wiki/Radon",

    "High-altitude resident (annual cosmic)",
    "Living above 2,000m increases cosmic radiation exposure compared to sea level.",
    "https://en.wikipedia.org/wiki/Cosmic_ray",

    "Normal background radiation",
    "Average annual radiation dose from natural sources (radon, cosmic, internal, terrestrial).",
    "https://en.wikipedia.org/wiki/Background_radiation",

    # Wildlife encounters
    "Shark encounter (ocean swim)",
    "Shark attack fatality risk per ocean swim, based on ISAF incident data.",
    "https://www.floridamuseum.ufl.edu/shark-attacks/",

    "Dog bite (US)",
    "Dog bite fatality risk in a high-income setting with rabies PEP available.",
    "https://en.wikipedia.org/wiki/Dog_bite",

    "Dog bite (rabies-endemic)",
    "Dog bite fatality risk in rabies-endemic regions with limited post-exposure prophylaxis.",
    "https://www.who.int/news-room/fact-sheets/detail/rabies",

    "Bee/wasp sting (general)",
    "Bee or wasp sting fatality risk for non-allergic individuals.",
    "https://en.wikipedia.org/wiki/Bee_sting",

    "Bee/wasp sting (allergic)",
    "Anaphylactic bee or wasp sting fatality risk for individuals with known allergy.",
    "https://en.wikipedia.org/wiki/Bee_sting",

    "Snake bite (US, with antivenom)",
    "Snake bite fatality risk in the US where antivenom is readily available.",
    "https://en.wikipedia.org/wiki/Snakebite",

    "Snake bite (rural sub-Saharan Africa)",
    "Snake bite fatality risk in rural Africa with limited antivenom access.",
    "https://www.who.int/news-room/fact-sheets/detail/snakebite-envenoming"
  )
}
