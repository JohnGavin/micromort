# Hedged Portfolio Risk Summary

Calculate total risk reduction from adopting an optimal "hedged"
lifestyle across multiple disease categories.

## Usage

``` r
hedged_portfolio(
  include_diseases = c("cardiovascular", "cancer", "respiratory", "infectious")
)
```

## Arguments

- include_diseases:

  Character vector. Which disease categories to include. Default is all:
  cardiovascular, cancer, respiratory, infectious.

## Value

A tibble with total hedged vs unhedged comparison and breakdown.

## See also

[`cancer_risks()`](https://johngavin.github.io/micromort/reference/cancer_risks.md),
[`vaccination_risks()`](https://johngavin.github.io/micromort/reference/vaccination_risks.md),
[`conditional_risk()`](https://johngavin.github.io/micromort/reference/conditional_risk.md)

Other conditional-risk:
[`cancer_risks()`](https://johngavin.github.io/micromort/reference/cancer_risks.md),
[`conditional_risk()`](https://johngavin.github.io/micromort/reference/conditional_risk.md),
[`vaccination_risks()`](https://johngavin.github.io/micromort/reference/vaccination_risks.md)

## Examples

``` r
hedged_portfolio()
#> $by_category
#> # A tibble: 4 × 5
#>   disease_category n_factors total_unhedged_ml total_hedged_ml total_ml_gained
#>   <chr>                <int>             <dbl>           <dbl>           <dbl>
#> 1 cancer                   7             -15.5             2              17.5
#> 2 cardiovascular           8             -28               5              33  
#> 3 infectious               4              -5.8            -0.1             5.7
#> 4 respiratory              4              -8               0               8  
#> 
#> $portfolio_summary
#> # A tibble: 6 × 2
#>   metric                                                   value
#>   <chr>                                                    <dbl>
#> 1 Total microlives gained per day (raw)                     64.2
#> 2 Overlap adjustment (smoking affects multiple diseases)   -20  
#> 3 Net microlives gained per day                             44.2
#> 4 Annual days of life gained                               336. 
#> 5 Equivalent micromorts avoided per day                     63.1
#> 6 Life expectancy gain over 40 years (days)              13444  
#> 
#> $included_diseases
#> [1] "cardiovascular" "cancer"         "respiratory"    "infectious"    
#> 
#> $note
#> [1] "Smoking effects deduplicated across disease categories to avoid double-counting."
#> 
hedged_portfolio(include_diseases = c("cardiovascular", "cancer"))
#> $by_category
#> # A tibble: 2 × 5
#>   disease_category n_factors total_unhedged_ml total_hedged_ml total_ml_gained
#>   <chr>                <int>             <dbl>           <dbl>           <dbl>
#> 1 cancer                   7             -15.5               2            17.5
#> 2 cardiovascular           8             -28                 5            33  
#> 
#> $portfolio_summary
#> # A tibble: 6 × 2
#>   metric                                                   value
#>   <chr>                                                    <dbl>
#> 1 Total microlives gained per day (raw)                     50.5
#> 2 Overlap adjustment (smoking affects multiple diseases)   -10  
#> 3 Net microlives gained per day                             40.5
#> 4 Annual days of life gained                               308  
#> 5 Equivalent micromorts avoided per day                     57.9
#> 6 Life expectancy gain over 40 years (days)              12319  
#> 
#> $included_diseases
#> [1] "cardiovascular" "cancer"        
#> 
#> $note
#> [1] "Smoking effects deduplicated across disease categories to avoid double-counting."
#> 
```
