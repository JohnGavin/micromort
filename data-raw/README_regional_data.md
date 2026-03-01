# Regional Life Expectancy Data

## Current Status: Sample Data

The `regional_life_expectancy.parquet` file currently contains **sample data** representing 11 regions across 8 Western European countries (1992-2019).

### Sample Regions Included

**Vanguard regions (top performers):**
- FR10: Île-de-France (Paris region)
- ITC4: Lombardy
- CH03: Northwestern Switzerland
- ES51: Catalonia

**Average regions:**
- DE21: Upper Bavaria
- BE10: Brussels-Capital Region
- NL32: North Holland

**Laggard regions (stagnating):**
- DE80: Mecklenburg-Vorpommern
- BE32: Hainaut (Wallonia)
- UKC1: Tees Valley and Durham
- FRE1: Nord (Hauts-de-France)

### Statistics

- **Regions:** 11 (sample)
- **Countries:** 8
- **Years:** 1992-2019
- **Sexes:** Male, Female, Total
- **Rows:** 924
- **File size:** 9.7KB

### Data Source

Based on: Bonnet F. et al. (2026). "Potential and challenges for sustainable progress in human longevity." 
*Nature Communications* 17, 996. https://doi.org/10.1038/s41467-026-68828-z

### Full Dataset

To download the complete dataset with all 450 regions:

1. Add `eurostat` to DESCRIPTION Imports
2. Regenerate `default.nix` with `source("default.R")`
3. Exit and re-enter Nix shell
4. Run `Rscript data-raw/02_regional_life_expectancy.R`

**Note:** The full download may take several minutes and will produce ~24,000 rows.

### Sample Data Generation

The sample data was generated using realistic parameters:
- Vanguard regions: +2.0-2.5 months/year gain (1992-2019)
- Average regions: +1.0-1.5 months/year gain
- Laggard regions: +0.3-0.5 months/year gain (stagnating)
- Base life expectancy (1992): 75-82 years depending on sex and classification

This sample data is sufficient for:
- Package development and testing
- Demonstrating regional variation patterns
- Educational vignettes
- API endpoint testing

For production analyses requiring comprehensive geographic coverage, the full Eurostat dataset should be downloaded.
