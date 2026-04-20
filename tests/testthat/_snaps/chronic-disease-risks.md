# invalid year raises informative error

    Code
      chronic_disease_risks("GBR", year = 1900L)
    Condition
      Error in `chronic_disease_risks()`:
      x Year 1900 not found in the bundled dataset.
      i Available years: 2019.

# unknown ISO-3 raises informative error

    Code
      chronic_disease_risks("XYZ")
    Condition
      Error in `chronic_disease_risks()`:
      x ISO-3 code not found in the bundled dataset: "XYZ".
      i Available codes: "ARG", "AUS", "BGD", "BRA", "CAN", "CHN", "DEU", "ESP", "ETH", "FRA", "GBR", "IDN", "IND", "ITA", "JPN", "KOR", "MEX", "NGA", ..., "TUR", and "USA".
      i Use `country = "all"` to return all available countries.

# chronic_disease_risks() GBR structure snapshot

    Code
      names(result)
    Output
      [1] "cause"             "country"           "iso3"             
      [4] "year"              "deaths_per_100k"   "daily_micromorts" 
      [7] "annual_micromorts"

---

    Code
      nrow(result)
    Output
      [1] 7

