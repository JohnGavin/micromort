# Conditional Risk Comparison (Hedged vs Unhedged)

Compare mortality risk between "hedged" (optimal
lifestyle/interventions) and "unhedged" (baseline/suboptimal) scenarios
for major disease categories.

## Usage

``` r
conditional_risk(disease = "all")
```

## Arguments

- disease:

  Character. Disease category: "cardiovascular", "cancer",
  "respiratory", "infectious", or "all".

## Value

A tibble comparing hedged vs unhedged risks in micromorts and
microlives.

## Examples

``` r
conditional_risk("cardiovascular")
#> # A tibble: 8 × 11
#>   disease_category risk_factor    unhedged_state                hedged_state    
#>   <chr>            <chr>          <chr>                         <chr>           
#> 1 cardiovascular   Smoking        20 cigarettes/day             Non-smoker      
#> 2 cardiovascular   Blood pressure Untreated hypertension        Controlled <130…
#> 3 cardiovascular   Exercise       Sedentary (<30 min/week)      150 min moderat…
#> 4 cardiovascular   Diet           Western diet (high processed) Mediterranean d…
#> 5 cardiovascular   Cholesterol    High LDL untreated            Statin therapy …
#> 6 cardiovascular   Weight         15 kg overweight              Healthy BMI     
#> 7 cardiovascular   Diabetes       Poorly controlled T2D         Well-controlled…
#> 8 cardiovascular   Alcohol        Heavy (4+ drinks/day)         Moderate (1 dri…
#> # ℹ 7 more variables: unhedged_microlives_per_day <dbl>,
#> #   hedged_microlives_per_day <dbl>, reduction_pct <dbl>,
#> #   evidence_quality <chr>, microlives_gained <dbl>, annual_days_gained <dbl>,
#> #   micromorts_equivalent_per_day <dbl>
conditional_risk("cancer")
#> # A tibble: 7 × 11
#>   disease_category risk_factor       unhedged_state                 hedged_state
#>   <chr>            <chr>             <chr>                          <chr>       
#> 1 cancer           Smoking           20 cigarettes/day              Non-smoker  
#> 2 cancer           Alcohol           Heavy drinking                 No alcohol  
#> 3 cancer           Physical activity Sedentary                      Regular exe…
#> 4 cancer           Diet              Low fiber, high processed meat High fiber,…
#> 5 cancer           Screening         No screening                   Age-appropr…
#> 6 cancer           Sun exposure      Frequent sunburn               Sun protect…
#> 7 cancer           Family history    Strong family history, no sur… Enhanced su…
#> # ℹ 7 more variables: unhedged_microlives_per_day <dbl>,
#> #   hedged_microlives_per_day <dbl>, reduction_pct <dbl>,
#> #   evidence_quality <chr>, microlives_gained <dbl>, annual_days_gained <dbl>,
#> #   micromorts_equivalent_per_day <dbl>
conditional_risk("all")
#> # A tibble: 23 × 11
#>    disease_category risk_factor    unhedged_state                hedged_state   
#>    <chr>            <chr>          <chr>                         <chr>          
#>  1 cardiovascular   Smoking        20 cigarettes/day             Non-smoker     
#>  2 cardiovascular   Blood pressure Untreated hypertension        Controlled <13…
#>  3 cardiovascular   Exercise       Sedentary (<30 min/week)      150 min modera…
#>  4 cardiovascular   Diet           Western diet (high processed) Mediterranean …
#>  5 cardiovascular   Cholesterol    High LDL untreated            Statin therapy…
#>  6 cardiovascular   Weight         15 kg overweight              Healthy BMI    
#>  7 cardiovascular   Diabetes       Poorly controlled T2D         Well-controlle…
#>  8 cardiovascular   Alcohol        Heavy (4+ drinks/day)         Moderate (1 dr…
#>  9 cancer           Smoking        20 cigarettes/day             Non-smoker     
#> 10 cancer           Alcohol        Heavy drinking                No alcohol     
#> # ℹ 13 more rows
#> # ℹ 7 more variables: unhedged_microlives_per_day <dbl>,
#> #   hedged_microlives_per_day <dbl>, reduction_pct <dbl>,
#> #   evidence_quality <chr>, microlives_gained <dbl>, annual_days_gained <dbl>,
#> #   micromorts_equivalent_per_day <dbl>
```
