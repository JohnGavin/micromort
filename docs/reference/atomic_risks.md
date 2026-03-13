# Atomic Risk Components

Returns a tibble where each row represents ONE risk component of ONE
activity. Different risk types (physical, medical, radiation) are never
mixed in the same row. This is the foundational dataset from which
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)
aggregates composite values.

## Usage

``` r
atomic_risks()
```

## Value

A tibble with columns:

- component_id:

  Unique identifier: `{activity_id}_{component}_{condition}`

- activity_id:

  Groups components into one activity

- activity:

  Human-readable activity name with duration

- component:

  Risk component: `"all_causes"`, `"crash"`, `"dvt"`, `"radiation"`,
  etc.

- risk_category:

  `"physical"`, `"medical"`, `"radiation"`, `"environmental"`, `"mixed"`

- component_label:

  Human-readable label for this component

- micromorts:

  Risk for this component at this duration for this condition

- duration_hours:

  Activity duration this row applies to (`NA` for
  non-duration-dependent)

- category:

  Activity category: `"Travel"`, `"Medical"`, `"Daily Life"`, etc.

- period:

  Human-readable period: `"per day"`, `"per event"`, etc.

- period_type:

  `"event"`, `"day"`, `"hour"`, `"year"`, `"month"`, `"period"`

- hedgeable:

  Can this component be mitigated?

- hedge_description:

  How to mitigate (if hedgeable)

- hedge_reduction_pct:

  Estimated percent reduction from hedging

- condition_variable:

  What this risk depends on: `"health_profile"`, `"geography"`, or `NA`

- condition_value:

  Condition value: `"healthy"`, `"dvt_risk_factors"`, `"high_income"`,
  `"low_income"`, `"allergic"`, or `NA`

- confidence:

  Data confidence: `"high"`, `"medium"`, `"low"`, `"estimated"`

- source_url:

  Citation URL

- notes:

  Scaling behavior, caveats

- validation_status:

  `"single_source"`, `"corroborated"`, or `"cross_validated"`

- source_count:

  Integer count of independent sources checked

- estimate_range:

  Character range (e.g. `"0.05-0.15"`) or `NA` for point estimates

## Details

Activities that have not yet been decomposed use
`component = "all_causes"` and `risk_category = "mixed"` as honest
placeholders.

## See also

[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)
for the aggregated view.

## Examples

``` r
atomic_risks()
#> # A tibble: 131 × 22
#>    component_id     activity_id activity component risk_category component_label
#>    <chr>            <chr>       <chr>    <chr>     <chr>         <chr>          
#>  1 mt_everest_asce… mt_everest… Mt. Eve… all_caus… mixed         Mt. Everest as…
#>  2 himalayan_mount… himalayan_… Himalay… all_caus… mixed         Himalayan moun…
#>  3 covid_19_infect… covid_19_i… COVID-1… all_caus… mixed         COVID-19 infec…
#>  4 spanish_flu_inf… spanish_fl… Spanish… all_caus… mixed         Spanish flu in…
#>  5 matterhorn_asce… matterhorn… Matterh… all_caus… mixed         Matterhorn asc…
#>  6 living_in_us_du… living_in_… Living … all_caus… mixed         Living in US d…
#>  7 living_one_day_… living_one… Living … all_caus… mixed         Living (one da…
#>  8 base_jumping_al… base_jumpi… Base ju… all_caus… mixed         Base jumping   
#>  9 first_day_of_li… first_day_… First d… all_caus… mixed         First day of l…
#> 10 covid_19_unvacc… covid_19_u… COVID-1… all_caus… mixed         COVID-19 unvac…
#> # ℹ 121 more rows
#> # ℹ 16 more variables: micromorts <dbl>, duration_hours <dbl>, category <chr>,
#> #   period <chr>, period_type <chr>, hedgeable <lgl>, hedge_description <chr>,
#> #   hedge_reduction_pct <dbl>, condition_variable <chr>, condition_value <chr>,
#> #   confidence <chr>, source_url <chr>, notes <chr>, validation_status <chr>,
#> #   source_count <int>, estimate_range <chr>
atomic_risks() |> dplyr::filter(component != "all_causes")
#> # A tibble: 38 × 22
#>    component_id     activity_id activity component risk_category component_label
#>    <chr>            <chr>       <chr>    <chr>     <chr>         <chr>          
#>  1 flying_2h_2h_cr… flying_2h   Flying … crash     physical      Aircraft crash 
#>  2 flying_2h_2h_dv… flying_2h   Flying … dvt       medical       Deep vein thro…
#>  3 flying_2h_2h_ra… flying_2h   Flying … radiation radiation     Cosmic radiati…
#>  4 flying_2h_2h_dv… flying_2h   Flying … dvt       medical       Deep vein thro…
#>  5 flying_5h_5h_cr… flying_5h   Flying … crash     physical      Aircraft crash 
#>  6 flying_5h_5h_dv… flying_5h   Flying … dvt       medical       Deep vein thro…
#>  7 flying_5h_5h_dv… flying_5h   Flying … dvt       medical       Deep vein thro…
#>  8 flying_5h_5h_ra… flying_5h   Flying … radiation radiation     Cosmic radiati…
#>  9 flying_8h_8h_cr… flying_8h   Flying … crash     physical      Aircraft crash 
#> 10 flying_8h_8h_dv… flying_8h   Flying … dvt       medical       Deep vein thro…
#> # ℹ 28 more rows
#> # ℹ 16 more variables: micromorts <dbl>, duration_hours <dbl>, category <chr>,
#> #   period <chr>, period_type <chr>, hedgeable <lgl>, hedge_description <chr>,
#> #   hedge_reduction_pct <dbl>, condition_variable <chr>, condition_value <chr>,
#> #   confidence <chr>, source_url <chr>, notes <chr>, validation_status <chr>,
#> #   source_count <int>, estimate_range <chr>
atomic_risks() |> dplyr::filter(hedgeable)
#> # A tibble: 21 × 22
#>    component_id     activity_id activity component risk_category component_label
#>    <chr>            <chr>       <chr>    <chr>     <chr>         <chr>          
#>  1 flying_2h_2h_dv… flying_2h   Flying … dvt       medical       Deep vein thro…
#>  2 flying_2h_2h_dv… flying_2h   Flying … dvt       medical       Deep vein thro…
#>  3 flying_5h_5h_dv… flying_5h   Flying … dvt       medical       Deep vein thro…
#>  4 flying_5h_5h_dv… flying_5h   Flying … dvt       medical       Deep vein thro…
#>  5 flying_8h_8h_dv… flying_8h   Flying … dvt       medical       Deep vein thro…
#>  6 flying_8h_8h_dv… flying_8h   Flying … dvt       medical       Deep vein thro…
#>  7 flying_12h_12h_… flying_12h  Flying … dvt       medical       Deep vein thro…
#>  8 flying_12h_12h_… flying_12h  Flying … dvt       medical       Deep vein thro…
#>  9 airline_pilot_a… airline_pi… Airline… radiation radiation     Ionizing radia…
#> 10 xray_tech_annua… xray_tech_… X-ray t… radiation radiation     Ionizing radia…
#> # ℹ 11 more rows
#> # ℹ 16 more variables: micromorts <dbl>, duration_hours <dbl>, category <chr>,
#> #   period <chr>, period_type <chr>, hedgeable <lgl>, hedge_description <chr>,
#> #   hedge_reduction_pct <dbl>, condition_variable <chr>, condition_value <chr>,
#> #   confidence <chr>, source_url <chr>, notes <chr>, validation_status <chr>,
#> #   source_count <int>, estimate_range <chr>
```
