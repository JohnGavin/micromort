# Introduction to Micromorts and Risk Visualization

``` r
library(micromort)
library(ggplot2)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
```

This vignette introduces the **micromort** package, which provides tools
for understanding and visualizing risks.

## 1. Micromorts (Acute Risk)

A **micromort** is a unit of risk representing a one-in-a-million chance
of death. It is used to measure acute risks—risks that can kill you
immediately (e.g., skydiving, driving).

``` r
# 1 in 10,000 chance of death = 100 micromorts
prob <- 1/10000
as_micromort(prob)
#> [1] 100

# Compare common risks
risks <- common_risks()
print(risks)
#> # A tibble: 62 × 6
#>    activity                     micromorts microlives category period source_url
#>    <chr>                             <dbl>      <dbl> <chr>    <chr>  <chr>     
#>  1 Mt. Everest ascent                37932     26552. Mountai… per a… https://m…
#>  2 Himalayan mountaineering          12000      8400  Mountai… per e… https://m…
#>  3 COVID-19 infection (unvacci…      10000      7000  Disease  per i… https://m…
#>  4 Spanish flu infection              3000      2100  Disease  per i… https://m…
#>  5 Matterhorn ascent                  2840      1988  Mountai… per a… https://m…
#>  6 Living in US during COVID-1…        500       350  Disease  per m… https://m…
#>  7 Living (one day, age 90)            463       324. Daily L… per d… https://m…
#>  8 Base jumping (per jump)             430       301  Sport    per e… https://m…
#>  9 First day of life (newborn)         430       301  Daily L… per d… https://m…
#> 10 COVID-19 unvaccinated (age …        234       164. COVID-19 11 we… https://w…
#> # ℹ 52 more rows
```

### Visualizing Risks

Using
[`plot_risks()`](https://johngavin.github.io/micromort/reference/plot_risks.md),
we can see the relative magnitude of different activities on a
logarithmic scale.

``` r
plot_risks()
```

![](introduction_files/figure-html/unnamed-chunk-3-1.png)

## 2. Microlives (Chronic Risk)

While micromorts measure sudden death, **microlives** measure the impact
of chronic habits on your life expectancy. A microlife represents a
30-minute change in life expectancy.

Common chronic risks: \* Smoking 1 cigarette: -1 microlife (approx 1
micromort equivalent risk) \* Being 5kg overweight: -1 microlife per day
\* First 20 mins moderate exercise: +2 microlives

``` r
# If smoking 20 cigarettes a day costs 1 microlife each (approx 30 mins)
daily_loss_minutes <- 20 * 30
daily_loss_microlives <- as_microlife(daily_loss_minutes)
print(daily_loss_microlives) # 20 microlives lost per day
#> [1] 20
```

## 3. Value of Statistical Life (VSL)

The **Value of a Statistical Life (VSL)** is the monetary value used to
justify safety spending. It is NOT the value of an individual life, but
the aggregate willingness to pay for small risk reductions.

Example: If a safety feature costs \$50 and saves 1 life in 100,000
people (10 micromorts), is it worth it? Cost per micromort saved = \$50
/ 10 = \$5. If VSL = \$10M, then 1 micromort = \$10. Since \$5 \< \$10,
it is cost-effective.

``` r
# Standard VSL of $10M implies $10 per micromort
value_of_micromort(vsl = 10000000)
#> [1] 10

# Higher VSL implies higher safety spending
value_of_micromort(vsl = 15000000)
#> [1] 15
```

## 4. Loss of Life Expectancy (LLE)

**LLE** estimates the average time lost from a lifespan due to a
specific risk. For a 1-in-a-million risk (1 micromort), the LLE is tiny.

``` r
# Loss of life expectancy from 1 micromort (assuming 40 years remaining)
lle_minutes <- lle(prob = 1/1e6, life_expectancy = 40)
print(lle_minutes)
#> [1] 21.0384
#> attr(,"class")
#> [1] "micromort_lle" "numeric"      
#> attr(,"units")
#> [1] "minutes"
# Result is in minutes. 1 micromort ~ 21 minutes lost?
# No, 1 micromort = 1e-6 * 40 years = 40e-6 years = ~21 minutes
# Wait, check calculation:
# 40 years * 365.25 days * 24 hours * 60 minutes = ~21 million minutes
# 1e-6 * 21 million = ~21 minutes
```

## 5. QALY / DALY (Brief Overview)

- **QALY (Quality-Adjusted Life Year):** Measures years of life adjusted
  for quality. 1 QALY = 1 year of perfect health. Used to assess medical
  interventions.
- **DALY (Disability-Adjusted Life Year):** Measures years of life lost
  due to premature death + years lived with disability. Used to assess
  disease burden.

These metrics go beyond simple mortality risk to capture morbidity and
quality of life.

## Conclusion

The `micromort` package helps translate abstract probabilities into
concrete units for better decision-making. By comparing acute risks
(micromorts) and chronic risks (microlives), individuals and
policymakers can make more informed choices.
