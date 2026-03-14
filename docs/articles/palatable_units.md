# Palatable Units: The Spiegelhalter Philosophy

**“Statistics are not just numbers; they are the way we make sense of
the world.”** — Sir David Spiegelhalter

This vignette outlines the philosophy of **“Palatable Units”**
championed by David Spiegelhalter (Winton Professor for the Public
Understanding of Risk, Cambridge). His core argument is that abstract
probabilities (e.g., “0.00004% hazard ratio”) are meaningless to most
people. To demystify risk, we must translate these into concrete,
relatable units.

## 1. The Core Philosophy: Compare Apples to Oranges

The goal of palatable units is to create a common currency for risk.
This allows us to strip away the emotional “dread factor” from
scary-sounding events and compare them rationally against mundane
activities.

### The Standard Units

- **Micromort:** 1-in-a-million chance of **acute** death (sudden
  event).
- **Microlife:** 30 minutes of life expectancy lost/gained **per day**
  (chronic **attrition**).

### What does 1-in-a-million feel like?

Abstract probabilities are hard to grasp. Spiegelhalter offers a
concrete anchor (*The Norm Chronicles*, 2013;
[plus.maths.org](https://plus.maths.org/content/os/issue55/features/risk/index)):

> **Flip a fair coin 20 times. The probability of getting 20 heads in a
> row is 1 in 1,048,576 — approximately 1 micromort.**

This is a mathematical constant ($`1/2^{20}`$), not an estimate. It
requires no denominator, no data source, and no geographic adjustment.
If you can imagine the surprise of 20 consecutive heads, you can feel
the scale of 1 micromort.

For context, Gigerenzer (*Calculated Risks*, 2002) recommends expressing
all probabilities as **natural frequencies** — counts in a defined
population rather than percentages. “1 death per 1,000,000 exposures” is
clearer than “0.0001% mortality rate.” This package follows that
convention: every micromort value has a traceable numerator (deaths) and
denominator (exposures).

## 2. Micromorts: Measuring “Stopping Living” (Hazard)

A micromort measures **acute hazard**: the immediate probability of an
event causing death.

- **Normalization:** Risk is normalized **per event** (or per unit
  distance), independent of the event’s duration.
- **Time Horizon:** The “time” is the discrete event itself.
  - **Skydiving:** The risk is ~7 micromorts *per jump*. Whether the
    freefall lasts 30 seconds or 60 seconds is secondary to the event of
    jumping.
  - **Scuba Diving:** The risk is ~5 micromorts *per dive*. A 30-minute
    dive and a 45-minute dive are treated as single “dive events” in
    broad statistics, though technically longer exposure increases risk.
  - **Anesthesia:** ~10 micromorts *per operation*.

### Comparative Risk Table

The following table uses
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md),
the package’s curated dataset of 62 acute risks with full provenance
tracking:

> **Comparison:** Riding a motorcycle for just 60 miles carries the same
> acute death risk (~10 micromorts) as undergoing general anesthesia.
> Using a standardized dataset enables apples-to-apples comparisons
> across activities.

## 3. Microlives: Measuring “Speed of Aging” (Attrition)

While micromorts measure sudden death (Hazard), **Microlives** measure
**chronic attrition**: the rate at which you are “using up” your life
expectancy.

- **Definition:** 1 Microlife = 30 minutes of life expectancy per day.
- **Normalization:** Risk is normalized **per day** of maintaining a
  habit.
- **Unit of Attrition:** The “unit” is the expected lifespan. -1
  Microlife means your expected lifespan has shrunk by 30 minutes.
- **Time Horizon:** Continuous. If you smoke 20 cigarettes a day, you
  are losing 10 microlives (5 hours) *every single day*.

### Daily Habits Table

Using
[`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md),
the package’s curated dataset of 22 chronic lifestyle factors:

> **Clarification:** A value of **-1 Microlife** is a **loss**
> (attrition). It effectively means you are aging 30 minutes faster than
> normal. The `annual_effect_days` column shows the cumulative impact
> over a year—a -1 daily deficit sums to ~7.5 days of lost life
> annually.

## 4. Visualization: The Risk Ladder

Spiegelhalter advocates for a **Logarithmic Risk Ladder**. This
visualization helps placing rare risks (like asteroid impacts or
terrorism) in context with daily risks.

- **Why Log Scale?** Because risks span vast orders of magnitude (1 in
  10 to 1 in 10 million).
- **Interpretation:** A “100% increase” in a very rare risk (e.g.,
  eating bacon increasing bowel cancer risk) might look huge in
  headlines but is often negligible on the ladder compared to the
  baseline risk of driving.

![Horizontal bar chart on log scale showing ~40 activities ordered by
micromorts. Activities span 5 orders of magnitude from 0.001 to 430
micromorts, coloured by
category.](palatable_units_files/figure-html/palatable_units-chunk-3-1.png)

Spiegelhalter’s logarithmic risk ladder placing activities from
negligible (banana dose) to extreme (BASE jumping) on a unified scale.

For interactive exploration, use
[`plot_risks_interactive()`](https://johngavin.github.io/micromort/reference/plot_risks_interactive.md)
which provides:

- Hover details showing micromorts, microlives, and period
- Click legend to show/hide categories
- Dropdown filter for COVID-19 vs Other risks

    #> Warning in RColorBrewer::brewer.pal(max(N, 3L), "Set2"): n too large, allowed maximum for palette Set2 is 8
    #> Returning the palette you asked for with that many colors
    #> Warning in RColorBrewer::brewer.pal(max(N, 3L), "Set2"): n too large, allowed maximum for palette Set2 is 8
    #> Returning the palette you asked for with that many colors

Interactive risk ladder with hover details, category filtering, and
zoom.

## 5. Media Perception vs. Actual Risk

A key motivation for palatable units is correcting the **perception
gap** between what we fear and what actually kills us.

### The Mismatch

According to [Our World in
Data](https://ourworldindata.org/does-the-news-reflect-what-we-die-from),
media coverage dramatically misrepresents actual causes of death:

| Cause of Death | Actual Deaths (%) | Media Coverage (%) | Ratio   |
|----------------|-------------------|--------------------|---------|
| Heart disease  | 29%               | ~2%                | 0.07x   |
| Cancer         | 27%               | ~5%                | 0.19x   |
| Homicide       | 0.9%              | ~39%               | 43x     |
| Terrorism      | \<0.01%           | ~18%               | \>1800x |

**Key insight:** Heart disease and cancer cause 56% of deaths but
receive only 7% of media coverage. Meanwhile, terrorism (causing 16
deaths in 2023) received 18,000× more coverage than its proportional
death rate.

### Why This Matters

Micromorts and microlives provide a standardized currency to cut through
emotional reactions:

- **Terrorism** (flying in 2001): ~0.01 micromorts per flight
- **Daily baseline** (age 40): ~2 micromorts per day
- **Driving 230 miles**: 1 micromort

The fear of flying after 9/11 led many Americans to drive instead,
resulting in an estimated 1,600 additional road deaths—far exceeding the
attack’s direct toll.

### Applying Palatable Units

When news reports a “50% increase in cancer risk,” use this framework:

1.  **Find the baseline**: What’s the absolute risk? (e.g., 1 in 10,000)
2.  **Convert to micromorts**: 1 in 10,000 = 100 micromorts
3.  **Apply the increase**: 50% more = 150 micromorts
4.  **Compare to familiar risks**: 150 micromorts ≈ driving 150 × 230 =
    34,500 miles

This contextualization reveals whether a “scary” headline represents a
meaningful risk change.

## 6. Recommended Tools

While David Spiegelhalter focuses on concepts rather than specific
software, the following R packages align with his mission of clear risk
communication:

- **`riskCommunicator`:** Designed for public health to provide
  interpretable effect measures (risk differences, number needed to
  treat) rather than abstract regression coefficients.
- **`ggplot2`:** The standard for creating custom visuals like Risk
  Ladders and icon arrays.
- **`micromort` (this package):** Specifically built to implement the
  palatable units framework.

## References

### Primary Sources

1.  Spiegelhalter, D., & Blastland, M. (2013). *The Norm Chronicles:
    Stories and numbers about danger*. Profile Books.
2.  Spiegelhalter, D. (2019). *The Art of Statistics: Learning from
    Data*. Pelican.

### Media Perception and Risk Communication

3.  [Does the news reflect what we die
    from?](https://ourworldindata.org/does-the-news-reflect-what-we-die-from) -
    Our World in Data analysis of media coverage vs actual causes of
    death.
4.  [Causes of Death](https://ourworldindata.org/causes-of-death) - Our
    World in Data global mortality statistics.
5.  [How the news changes the way we think and
    behave](https://www.bbc.com/future/article/20200512-how-the-news-changes-the-way-we-think-and-behave) -
    BBC Future on media influence.
6.  [Media Bias in Portrayals of Mortality
    Risks](https://www.researchgate.net/publication/386057693_Media_Bias_in_Portrayals_of_Mortality_Risks_Comparison_of_Newspaper_Coverage_to_Death_Rates) -
    Academic study comparing newspaper coverage to death rates.
7.  [Terrorism and You: The Real
    Odds](https://www.aei.org/articles/terrorism-and-you-the-real-odds/) -
    American Enterprise Institute analysis of terrorism risk perception.
8.  [Risk communication in the
    news](https://researchbriefings.files.parliament.uk/documents/POST-PN-0564/POST-PN-0564.pdf) -
    UK Parliamentary Office of Science and Technology briefing.
9.  [Media Coverage and Mortality Risk
    Assessment](https://pmc.ncbi.nlm.nih.gov/articles/PMC10102679/) -
    PMC research on media effects on risk perception.

## Reproducibility

Show code

``` r
sessionInfo()
#> R version 4.5.2 (2025-10-31)
#> Platform: aarch64-apple-darwin25.2.0
#> Running under: macOS Tahoe 26.3
#> 
#> Matrix products: default
#> BLAS:   /nix/store/ab8sq4g14lg45192ykfqcklgw6fvaswh-blas-3/lib/libblas.dylib 
#> LAPACK: /nix/store/ssl6kfm7w37gz5pn57jn2x7xzw3bss24-openblas-0.3.30/lib/libopenblasp-r0.3.30.dylib;  LAPACK version 3.12.0
#> 
#> locale:
#> [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
#> 
#> time zone: Europe/Belfast
#> tzcode source: internal
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] DT_0.34.0       targets_1.11.4  micromort_0.1.0 testthat_3.3.2 
#> 
#> loaded via a namespace (and not attached):
#>  [1] gtable_0.3.6        xfun_0.56           bslib_0.10.0       
#>  [4] ggplot2_4.0.1       htmlwidgets_1.6.4   processx_3.8.6     
#>  [7] callr_3.7.6         vctrs_0.7.1         tools_4.5.2        
#> [10] crosstalk_1.2.2     ps_1.9.1            generics_0.1.4     
#> [13] base64url_1.4       tibble_3.3.1        pkgconfig_2.0.3    
#> [16] data.table_1.18.2.1 checkmate_2.3.3     secretbase_1.1.1   
#> [19] RColorBrewer_1.1-3  S7_0.2.1            desc_1.4.3         
#> [22] assertthat_0.2.1    lifecycle_1.0.5     compiler_4.5.2     
#> [25] farver_2.1.2        credentials_2.0.3   brio_1.1.5         
#> [28] codetools_0.2-20    sass_0.4.10         htmltools_0.5.9    
#> [31] sys_3.4.3           usethis_3.2.1       lazyeval_0.2.2     
#> [34] yaml_2.3.12         plotly_4.12.0       tidyr_1.3.2        
#> [37] jquerylib_0.1.4     pillar_1.11.1       openssl_2.3.4      
#> [40] cachem_1.1.0        tidyselect_1.2.1    digest_0.6.39      
#> [43] dplyr_1.1.4         purrr_1.2.1         arrow_22.0.0       
#> [46] rprojroot_2.1.1     fastmap_1.2.0       grid_4.5.2         
#> [49] cli_3.6.5           magrittr_2.0.4      pkgbuild_1.4.8     
#> [52] withr_3.0.2         prettyunits_1.2.0   scales_1.4.0       
#> [55] backports_1.5.0     bit64_4.6.0-1       httr_1.4.7         
#> [58] rmarkdown_2.30      igraph_2.2.1        bit_4.6.0          
#> [61] otel_0.2.0          askpass_1.2.1       evaluate_1.0.5     
#> [64] knitr_1.51          viridisLite_0.4.2   rlang_1.1.7        
#> [67] gert_2.3.1          glue_1.8.0          pkgload_1.4.1      
#> [70] jsonlite_2.0.0      R6_2.6.1            fs_1.6.6
```
