# Chronic Risks Dataset

A curated dataset of chronic lifestyle factors measured in microlives.
One microlife equals 30 minutes of life expectancy gained or lost.

A dataset of chronic lifestyle factors and their impact on life
expectancy, measured in microlives (30 minutes of life expectancy per
day).

## Usage

``` r
chronic_risks()
```

## Format

A tibble with 22 rows and 12 columns:

- record_id:

  Unique record identifier

- factor:

  Human-readable factor name

- factor_normalized:

  Standardized factor name for grouping

- microlives_per_day:

  Daily impact in microlives (+/- 30 min units)

- direction:

  Effect direction: "gain" or "loss"

- category:

  Factor category (Diet, Exercise, Smoking, etc.)

- description:

  Detailed description of the factor

- annual_effect_days:

  Days of life gained/lost per year

- source_id:

  Source identifier

- source_url:

  Direct URL to source

- confidence:

  Data quality level

- last_accessed:

  Date data was retrieved

## Source

Spiegelhalter D (2012). "Using speed of ageing and 'microlives' to
communicate the effects of lifetime habits and environment." BMJ
2012;345:e8223.
[doi:10.1136/bmj.e8223](https://doi.org/10.1136/bmj.e8223)

## Value

A tibble with columns: factor, microlives_per_day, category, direction,
annual_effect_days, source_url.

## Details

Positive values indicate life expectancy gains; negative values indicate
losses. Based on the framework introduced by David Spiegelhalter (2012).

Positive values indicate life expectancy gains; negative values indicate
losses. Effects are cumulative over a lifetime of adult exposure (~57
years).

## References

<https://en.wikipedia.org/wiki/Microlife>

Spiegelhalter D (2012). "Using speed of ageing and 'microlives' to
communicate the effects of lifetime habits and environment." BMJ
2012;345:e8223.
[doi:10.1136/bmj.e8223](https://doi.org/10.1136/bmj.e8223)

<https://en.wikipedia.org/wiki/Microlife>

<https://pubmed.ncbi.nlm.nih.gov/23247978/>

## See also

Other datasets:
[`acute_risks`](https://johngavin.github.io/micromort/reference/acute_risks.md),
[`risk_sources`](https://johngavin.github.io/micromort/reference/risk_sources.md)

## Examples

``` r
# Load the chronic risks dataset
chronic <- load_chronic_risks()
head(chronic)
#> # A tibble: 6 × 12
#>   record_id       factor factor_normalized microlives_per_day direction category
#>   <chr>           <chr>  <chr>                          <dbl> <chr>     <chr>   
#> 1 spiegelhalter_… Livin… living in sweden…                 21 gain      Demogra…
#> 2 spiegelhalter_… Livin… living in 2010 v…                 15 gain      Histori…
#> 3 spiegelhalter_… Smoki… smoking 20 cigar…                -10 loss      Smoking 
#> 4 spiegelhalter_… Smoki… smoking 10 cigar…                 -5 loss      Smoking 
#> 5 spiegelhalter_… Being… being male                        -4 loss      Demogra…
#> 6 spiegelhalter_… 5 ser… 5 servings fruit…                  4 gain      Diet    
#> # ℹ 6 more variables: description <chr>, annual_effect_days <dbl>,
#> #   source_id <chr>, source_url <chr>, confidence <chr>, last_accessed <date>

# Factors that reduce life expectancy
chronic |> dplyr::filter(direction == "loss")
#> # A tibble: 15 × 12
#>    record_id      factor factor_normalized microlives_per_day direction category
#>    <chr>          <chr>  <chr>                          <dbl> <chr>     <chr>   
#>  1 spiegelhalter… Smoki… smoking 20 cigar…                -10 loss      Smoking 
#>  2 spiegelhalter… Smoki… smoking 10 cigar…                 -5 loss      Smoking 
#>  3 spiegelhalter… Being… being male                        -4 loss      Demogra…
#>  4 spiegelhalter… Being… being 15 kg over…                 -3 loss      Weight  
#>  5 spiegelhalter… Being… being 10 kg over…                 -2 loss      Weight  
#>  6 spiegelhalter… 4th-5… 4th-5th alcoholi…                 -2 loss      Alcohol 
#>  7 spiegelhalter… Smoki… smoking 2 cigare…                 -1 loss      Smoking 
#>  8 spiegelhalter… Being… being 5 kg overw…                 -1 loss      Weight  
#>  9 spiegelhalter… 2nd-3… 2nd-3rd alcoholi…                 -1 loss      Alcohol 
#> 10 spiegelhalter… Red m… red meat                          -1 loss      Diet    
#> 11 spiegelhalter… Proce… processed meat                    -1 loss      Diet    
#> 12 spiegelhalter… 2 hou… 2 hours tv watch…                 -1 loss      Sedenta…
#> 13 spiegelhalter… Livin… living with a sm…                 -1 loss      Environ…
#> 14 spiegelhalter… 2-3 c… 2-3 cups coffee                   -1 loss      Diet    
#> 15 spiegelhalter… Air p… air pollution                     -1 loss      Environ…
#> # ℹ 6 more variables: description <chr>, annual_effect_days <dbl>,
#> #   source_id <chr>, source_url <chr>, confidence <chr>, last_accessed <date>

# Factors that increase life expectancy
chronic |> dplyr::filter(direction == "gain")
#> # A tibble: 7 × 12
#>   record_id       factor factor_normalized microlives_per_day direction category
#>   <chr>           <chr>  <chr>                          <dbl> <chr>     <chr>   
#> 1 spiegelhalter_… Livin… living in sweden…                 21 gain      Demogra…
#> 2 spiegelhalter_… Livin… living in 2010 v…                 15 gain      Histori…
#> 3 spiegelhalter_… 5 ser… 5 servings fruit…                  4 gain      Diet    
#> 4 spiegelhalter_… Being… being female                       4 gain      Demogra…
#> 5 spiegelhalter_… 20 mi… 20 min moderate …                  2 gain      Exercise
#> 6 spiegelhalter_… First… first alcoholic …                  1 gain      Alcohol 
#> 7 spiegelhalter_… Stati… statin therapy                     1 gain      Medical 
#> # ℹ 6 more variables: description <chr>, annual_effect_days <dbl>,
#> #   source_id <chr>, source_url <chr>, confidence <chr>, last_accessed <date>
chronic_risks()
#> # A tibble: 22 × 7
#>    factor   microlives_per_day category direction description annual_effect_days
#>    <chr>                 <dbl> <chr>    <chr>     <chr>                    <dbl>
#>  1 Smoking…                -10 Smoking  loss      Heavy smok…              -76  
#>  2 Smoking…                 -5 Smoking  loss      Moderate s…              -38  
#>  3 Smoking…                 -1 Smoking  loss      Each cigar…               -7.6
#>  4 Being 5…                 -1 Weight   loss      Per 5 kg a…               -7.6
#>  5 Being 1…                 -2 Weight   loss      Cumulative…              -15.2
#>  6 Being 1…                 -3 Weight   loss      Cumulative…              -22.8
#>  7 2nd-3rd…                 -1 Alcohol  loss      After firs…               -7.6
#>  8 4th-5th…                 -2 Alcohol  loss      Heavy drin…              -15.2
#>  9 Red mea…                 -1 Diet     loss      Daily red …               -7.6
#> 10 Process…                 -1 Diet     loss      Bacon, sau…               -7.6
#> # ℹ 12 more rows
#> # ℹ 1 more variable: source_url <chr>
chronic_risks() |> dplyr::filter(direction == "loss")
#> # A tibble: 15 × 7
#>    factor   microlives_per_day category direction description annual_effect_days
#>    <chr>                 <dbl> <chr>    <chr>     <chr>                    <dbl>
#>  1 Smoking…                -10 Smoking  loss      Heavy smok…              -76  
#>  2 Smoking…                 -5 Smoking  loss      Moderate s…              -38  
#>  3 Smoking…                 -1 Smoking  loss      Each cigar…               -7.6
#>  4 Being 5…                 -1 Weight   loss      Per 5 kg a…               -7.6
#>  5 Being 1…                 -2 Weight   loss      Cumulative…              -15.2
#>  6 Being 1…                 -3 Weight   loss      Cumulative…              -22.8
#>  7 2nd-3rd…                 -1 Alcohol  loss      After firs…               -7.6
#>  8 4th-5th…                 -2 Alcohol  loss      Heavy drin…              -15.2
#>  9 Red mea…                 -1 Diet     loss      Daily red …               -7.6
#> 10 Process…                 -1 Diet     loss      Bacon, sau…               -7.6
#> 11 2 hours…                 -1 Sedenta… loss      Prolonged …               -7.6
#> 12 Living …                 -1 Environ… loss      Second-han…               -7.6
#> 13 2-3 cup…                 -1 Diet     loss      Heavy coff…               -7.6
#> 14 Air pol…                 -1 Environ… loss      Living in …               -7.6
#> 15 Being m…                 -4 Demogra… loss      Male sex d…              -30.4
#> # ℹ 1 more variable: source_url <chr>
chronic_risks() |> dplyr::filter(category == "Exercise")
#> # A tibble: 1 × 7
#>   factor    microlives_per_day category direction description annual_effect_days
#>   <chr>                  <dbl> <chr>    <chr>     <chr>                    <dbl>
#> 1 20 min m…                  2 Exercise gain      Daily mode…               15.2
#> # ℹ 1 more variable: source_url <chr>
```
