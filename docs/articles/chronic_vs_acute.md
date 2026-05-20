# 

# The Invisible Risk

Why chronic daily disease dwarfs the dangers you worry about

## The invisible risk

A skydive carries **8 micromorts**. A heroin dose: **30**. Base jumping:
**430**. These feel dangerous because they’re *chosen* and *visible*.

But what if the bigger risk is something you can’t see, can’t feel, and
can’t opt out of?

**9 days.** That’s how long it takes for background cardiovascular
disease risk in the UK to accumulate the same 30 micromorts as a single
dose of heroin.

Every 9 days, your heart silently rolls the same dice as a heroin user —
but nobody stages an intervention.

## The annual picture

Over a full year, chronic disease risk dwarfs any one-off activity.
Here’s the UK annual chronic disease burden alongside the acute
activities that make headlines:

UK cancer alone accumulates over **1,400 micromorts per year**.
[Cardiovascular disease
(CVD)](https://www.who.int/health-topics/cardiovascular-diseases) adds
another **1,200**. Together, that’s the equivalent of climbing the
Matterhorn — every single year.

Yet we fear the mountain, not the mundane.

### UK annual chronic disease risk (micromorts/year)

### Acute one-off risks for comparison

The chronic burden is not fixed — it depends enormously on where you
live. Switching from a UK to Nigerian profile changes everything:

**Diarrheal disease** jumps from 0.02 mm/day in the UK to 0.88 mm/day in
Nigeria — a 44x difference driven by clean water and sanitation
infrastructure.
[LRI](https://www.who.int/news-room/fact-sheets/detail/pneumonia) shows
the same geographic pattern.

**[CVD](https://www.who.int/health-topics/cardiovascular-diseases)**
doubles from 3.2 to 7.3 mm/day. The same organ, the same biology, but
vastly different outcomes depending on healthcare access, diet, and
environmental factors.

These are the confounders that population-average micromort tables hide.
See the [confounding
vignette](https://johngavin.github.io/micromort/articles/confounding.md)
for the full geographic and demographic analysis.

## Country matters

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

Session info (click to expand)

    R version 4.5.2 (2025-10-31)
    Platform: aarch64-apple-darwin25.2.0
    Running under: macOS Tahoe 26.4.1

    Matrix products: default
    BLAS:   /nix/store/ab8sq4g14lg45192ykfqcklgw6fvaswh-blas-3/lib/libblas.dylib
    LAPACK: /nix/store/ssl6kfm7w37gz5pn57jn2x7xzw3bss24-openblas-0.3.30/lib/libopenblasp-r0.3.30.dylib;  LAPACK version 3.12.0

    locale:
    [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

    time zone: Europe/Belfast
    tzcode source: internal

    attached base packages:
    [1] stats     graphics  grDevices utils     datasets  methods   base

    other attached packages:
    [1] micromort_0.2.0 testthat_3.3.2

    loaded via a namespace (and not attached):
     [1] gtable_0.3.6        bslib_0.10.0        xfun_0.56
     [4] ggplot2_4.0.1       htmlwidgets_1.6.4   processx_3.8.6
     [7] callr_3.7.6         crosstalk_1.2.2     vctrs_0.7.1
    [10] tools_4.5.2         ps_1.9.1            generics_0.1.4
    [13] base64url_1.4       tibble_3.3.1        pkgconfig_2.0.3
    [16] data.table_1.18.2.1 checkmate_2.3.3     secretbase_1.1.1
    [19] RColorBrewer_1.1-3  S7_0.2.1            desc_1.4.3
    [22] assertthat_0.2.1    lifecycle_1.0.5     compiler_4.5.2
    [25] farver_2.1.2        credentials_2.0.3   brio_1.1.5
    [28] codetools_0.2-20    sass_0.4.10         htmltools_0.5.9
    [31] sys_3.4.3           usethis_3.2.1       yaml_2.3.12
    [34] jquerylib_0.1.4     pillar_1.11.1       openssl_2.3.4
    [37] DT_0.34.0           cachem_1.1.0        tidyselect_1.2.1
    [40] digest_0.6.39       dplyr_1.1.4         purrr_1.2.1
    [43] arrow_22.0.0        rprojroot_2.1.1     fastmap_1.2.0
    [46] grid_4.5.2          cli_3.6.5           magrittr_2.0.4
    [49] pkgbuild_1.4.8      prettyunits_1.2.0   scales_1.4.0
    [52] backports_1.5.0     bit64_4.6.0-1       rmarkdown_2.30
    [55] igraph_2.2.1        bit_4.6.0           otel_0.2.0
    [58] askpass_1.2.1       evaluate_1.0.5      knitr_1.51
    [61] rlang_1.1.7         gert_2.3.1          Rcpp_1.1.1
    [64] glue_1.8.0          pkgload_1.4.1       jsonlite_2.0.0
    [67] R6_2.6.1            targets_1.11.4      fs_1.6.6
    [70] units_1.0-0        

------------------------------------------------------------------------

**micromort**
[0.1.0](https://github.com/JohnGavin/micromort/releases/tag/v0.1.0) \|
**Git**
[`94d93d2`](https://github.com/JohnGavin/micromort/commit/94d93d29c29c25f1b4833b6c65731ca9411cb15f)
\| **R**
[4.5.2](https://cran.r-project.org/doc/manuals/r-release/NEWS.html) \|
**Built** 2026-04-18 12:20:56
