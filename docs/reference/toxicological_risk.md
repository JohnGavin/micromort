# Calculate micromorts from substance exposure using LD50 data

Uses human LD50 estimates from `inst/extdata/ld50_human.csv` to
translate a dose into a micromort risk estimate via linear extrapolation
from the LD50 reference point. At the LD50, 50% lethality equals 500,000
micromorts.

## Usage

``` r
toxicological_risk(substance = NULL, dose_mg = NULL, body_weight_kg = 70)
```

## Arguments

- substance:

  Character scalar. Name of substance (case-insensitive, partial match
  supported). Pass `NULL` (default) to return the full reference table
  of all substances with their LD50 values.

- dose_mg:

  Numeric scalar. Dose in milligrams. Required when `substance` is
  specified; ignored otherwise.

- body_weight_kg:

  Numeric scalar. Body weight in kg. Default `70`.

## Value

A tibble. When `substance = NULL`, returns all substances with columns
`substance`, `route`, `ld50_mg_per_kg`, `source`. When a substance is
specified, returns a single-row tibble with additional columns:
`dose_mg`, `fraction_of_ld50`, `micromorts`, `risk_category`.

## See also

[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md),
[`risk_sensitivity()`](https://johngavin.github.io/micromort/reference/risk_sensitivity.md)

Other analysis:
[`annual_risk_budget()`](https://johngavin.github.io/micromort/reference/annual_risk_budget.md),
[`compare_interventions()`](https://johngavin.github.io/micromort/reference/compare_interventions.md),
[`daily_hazard_rate()`](https://johngavin.github.io/micromort/reference/daily_hazard_rate.md),
[`lifestyle_tradeoff()`](https://johngavin.github.io/micromort/reference/lifestyle_tradeoff.md),
[`risk_sensitivity()`](https://johngavin.github.io/micromort/reference/risk_sensitivity.md)

## Examples

``` r
# Full reference table
toxicological_risk()
#> # A tibble: 16 × 4
#>    substance            route        ld50_mg_per_kg source         
#>    <chr>                <chr>                 <dbl> <chr>          
#>  1 Botulinum toxin      oral               0.000001 CDC estimates  
#>  2 VX nerve agent       dermal             0.14     US Army        
#>  3 Batrachotoxin        subcutaneous       0.002    Daly et al 1965
#>  4 Ricin                oral               1        Audi et al 2005
#>  5 Amatoxin (death cap) oral               0.1      Wieland 1986   
#>  6 Saxitoxin            oral               0.0057   EFSA 2009      
#>  7 Dimethylmercury      dermal             0.05     Nierenberg 1998
#>  8 Cantharidin          oral               0.5      Karras 1996    
#>  9 Strychnine           oral               1.5      IPCS           
#> 10 Nicotine             oral               6.5      Mayer 2014     
#> 11 Arsenic trioxide     oral              15        ATSDR          
#> 12 Methanol             oral             810        EPA            
#> 13 Ethanol              oral            7060        NIOSH          
#> 14 Caffeine             oral             192        EFSA           
#> 15 Aspirin              oral             200        FDA            
#> 16 Table salt (NaCl)    oral            3000        MSDS           

# Risk from 1 mg nicotine for a 70 kg person
toxicological_risk("Nicotine", dose_mg = 1)
#> # A tibble: 1 × 8
#>   substance route ld50_mg_per_kg source     dose_mg fraction_of_ld50 micromorts
#>   <chr>     <chr>          <dbl> <chr>        <dbl>            <dbl>      <dbl>
#> 1 Nicotine  oral             6.5 Mayer 2014       1          0.00220      1099.
#> # ℹ 1 more variable: risk_category <chr>

# Partial name matching
toxicological_risk("nico", dose_mg = 1)
#> # A tibble: 1 × 8
#>   substance route ld50_mg_per_kg source     dose_mg fraction_of_ld50 micromorts
#>   <chr>     <chr>          <dbl> <chr>        <dbl>            <dbl>      <dbl>
#> 1 Nicotine  oral             6.5 Mayer 2014       1          0.00220      1099.
#> # ℹ 1 more variable: risk_category <chr>

# Different body weight
toxicological_risk("Caffeine", dose_mg = 200, body_weight_kg = 80)
#> # A tibble: 1 × 8
#>   substance route ld50_mg_per_kg source dose_mg fraction_of_ld50 micromorts
#>   <chr>     <chr>          <dbl> <chr>    <dbl>            <dbl>      <dbl>
#> 1 Caffeine  oral             192 EFSA       200           0.0130      6510.
#> # ℹ 1 more variable: risk_category <chr>
```
