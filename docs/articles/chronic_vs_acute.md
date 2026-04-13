# 

# The Invisible Risk

Why chronic daily disease dwarfs the dangers you worry about

## One skydive

A heroin dose carries **30 micromorts**. Base jumping: **430**. These
feel dangerous because they’re *chosen* and *visible*.

But what if the bigger risk is something you can’t see, can’t feel, and
can’t opt out of?

**9 days.** That’s how long it takes for background cardiovascular
disease risk in the UK to accumulate the same 30 micromorts as a single
dose of heroin.

Every 9 days, your heart silently rolls the same dice as a heroin user —
but nobody stages an intervention.

| Chronic daily risk                  | Daily mm | Days to equal one heroin dose |
|:------------------------------------|---------:|------------------------------:|
| Daily cancer mortality risk (UK)    |      4.0 |                           7.6 |
| Daily CVD mortality risk (UK)       |      3.2 |                           9.3 |
| Daily LRI mortality risk (UK)       |      0.5 |                          56.6 |
| Daily diarrheal mortality risk (UK) |      0.0 |                        1500.0 |

## The annual picture

Over a full year, chronic disease risk dwarfs any one-off activity.
Here’s the UK annual chronic disease burden alongside the acute
activities that make headlines:

UK cancer alone accumulates over **1,400 micromorts per year**. CVD adds
another **1,200**. Together, that’s the equivalent of climbing the
Matterhorn — every single year.

Yet we fear the mountain, not the mundane.

    #> ### UK annual chronic disease risk (micromorts/year)
    #>
    #>
    #> ### Acute one-off risks for comparison

| cause                             | one_off_mm |
|:----------------------------------|-----------:|
| Mt. Everest ascent                |      37932 |
| Himalayan mountaineering          |      12000 |
| COVID-19 infection (unvaccinated) |      10000 |
| Spanish flu infection             |       3000 |
| Matterhorn ascent                 |       2840 |
| Base jumping (per jump)           |        430 |
| Caesarean birth (mother)          |        170 |
| Vaginal birth (mother)            |        120 |

The chronic burden is not fixed — it depends enormously on where you
live. Switching from a UK to Nigerian profile changes everything:

**Diarrheal disease** jumps from 0.02 mm/day in the UK to 0.88 mm/day in
Nigeria — a 44x difference driven by clean water and sanitation
infrastructure.

**CVD** doubles from 3.2 to 7.3 mm/day. The same organ, the same
biology, but vastly different outcomes depending on healthcare access,
diet, and environmental factors.

These are the confounders that population-average micromort tables hide.
See the [confounding
vignette](https://johngavin.github.io/micromort/articles/confounding.md)
for the full geographic and demographic analysis.

## Country matters

| Cause                          | UK (mm/day) | Nigeria (mm/day) | Ratio (NG/UK) |
|:-------------------------------|------------:|-----------------:|--------------:|
| Daily diarrheal mortality risk |        0.02 |             0.88 |          44.0 |
| Daily LRI mortality risk       |        0.53 |             1.77 |           3.3 |
| Daily CVD mortality risk       |        3.24 |             7.33 |           2.3 |
| Daily cancer mortality risk    |        3.95 |             2.79 |           0.7 |

## The takeaway

The risks we *choose* (skydiving, motorcycling, mountaineering) are
visible, voluntary, and bounded. The risks we *inherit* (cardiovascular
disease, cancer, respiratory infections) are invisible, involuntary, and
cumulative.

The micromort framework makes them commensurable — you can compare a
skydive to a week of heart disease, a flight to a month of air
pollution, a surgery to a year of background cancer risk.

Explore the data yourself:

- `common_risks(profile = list(country = "UK"))` — your country’s
  disease burden
- [`geography_quiz_pairs()`](https://johngavin.github.io/micromort/reference/geography_quiz_pairs.md)
  — quiz comparing risks across countries
- [`risk_equivalence()`](https://johngavin.github.io/micromort/reference/risk_equivalence.md)
  — formal equivalence calculations

    #> R version 4.5.2 (2025-10-31)
    #> Platform: aarch64-apple-darwin25.2.0
    #> Running under: macOS Tahoe 26.3.1
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
    #> [1] micromort_0.1.0 testthat_3.3.2
    #>
    #> loaded via a namespace (and not attached):
    #>  [1] generics_0.1.4      digest_0.6.39       magrittr_2.0.4
    #>  [4] evaluate_1.0.5      grid_4.5.2          RColorBrewer_1.1-3
    #>  [7] pkgload_1.4.1       fastmap_1.2.0       rprojroot_2.1.1
    #> [10] jsonlite_2.0.0      processx_3.8.6      pkgbuild_1.4.8
    #> [13] backports_1.5.0     brio_1.1.5          secretbase_1.1.1
    #> [16] ps_1.9.1            purrr_1.2.1         scales_1.4.0
    #> [19] codetools_0.2-20    cli_3.6.5           rlang_1.1.7
    #> [22] bit64_4.6.0-1       withr_3.0.2         yaml_2.3.12
    #> [25] otel_0.2.0          tools_4.5.2         checkmate_2.3.3
    #> [28] dplyr_1.1.4         base64url_1.4       ggplot2_4.0.1
    #> [31] credentials_2.0.3   assertthat_0.2.1    vctrs_0.7.1
    #> [34] R6_2.6.1            lifecycle_1.0.5     fs_1.6.6
    #> [37] htmlwidgets_1.6.4   bit_4.6.0           usethis_3.2.1
    #> [40] targets_1.11.4      arrow_22.0.0        callr_3.7.6
    #> [43] pkgconfig_2.0.3     desc_1.4.3          pillar_1.11.1
    #> [46] gtable_0.3.6        data.table_1.18.2.1 glue_1.8.0
    #> [49] gert_2.3.1          xfun_0.56           tibble_3.3.1
    #> [52] tidyselect_1.2.1    sys_3.4.3           knitr_1.51
    #> [55] farver_2.1.2        igraph_2.2.1        htmltools_0.5.9
    #> [58] rmarkdown_2.30      compiler_4.5.2      prettyunits_1.2.0
    #> [61] S7_0.2.1            askpass_1.2.1       openssl_2.3.4
