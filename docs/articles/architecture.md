# Architecture Overview

This page shows how the micromort package is organized: the data
pipeline, function hierarchy, user entry points, and development
workflow. All diagrams are auto-generated from package metadata via the
[targets pipeline](https://docs.ropensci.org/targets/).

## 1. Data Pipeline

The targets pipeline processes risk data through five stages. Target
counts update automatically when plan files change.

Show code

``` r
emit_mermaid("vig_arch_pipeline_diagram",
             "Pipeline diagram not available. Run `targets::tar_make()` first.",
             caption = "Figure 1: Data pipeline stages from raw Eurostat/CDC data through cleaning, decomposition, aggregation, and vignette output targets.",
             alt_text = "Mermaid flowchart showing five pipeline stages: ingest, clean, decompose, aggregate, and vignette outputs, with target counts at each stage.")
```

``` mermaid
```

Figure 1: Data pipeline stages from raw Eurostat/CDC data through
cleaning, decomposition, aggregation, and vignette output targets.

## 2. Function Hierarchy

All exported functions grouped by category. Click any function to view
its documentation.

Show code

``` r
emit_mermaid("vig_arch_concept_diagram",
             "Concept diagram not available. Run `targets::tar_make()` first.",
             caption = "Figure 2: Exported functions grouped by category — risk data, conversion utilities, regional analysis, visualisation, and quiz.",
             alt_text = "Mermaid diagram showing all exported functions organised into five categories with links to their documentation pages.")
```

``` mermaid
```

Figure 2: Exported functions grouped by category — risk data, conversion
utilities, regional analysis, visualisation, and quiz.

## 3. User Journey

Which function should you start with? Follow the decision tree below.

Show code

``` r
emit_mermaid("vig_arch_user_journey_diagram",
             "User journey diagram not available. Run `targets::tar_make()` first.",
             caption = "Figure 3: Decision tree guiding users from their question (compare risks, explore regions, convert units) to the appropriate function.",
             alt_text = "Mermaid decision tree flowchart with three entry points — compare risks, explore regions, convert units — leading to specific package functions.")
```

``` mermaid
```

Figure 3: Decision tree guiding users from their question (compare
risks, explore regions, convert units) to the appropriate function.

## 4. Developer Workflow

The 9-step workflow for contributing to this package. Steps 4–5 follow
the RED-GREEN TDD cycle.

Show code

``` r
emit_mermaid("vig_arch_developer_diagram",
             "Developer diagram not available. Run `targets::tar_make()` first.",
             caption = "Figure 4: Nine-step contributor workflow from issue creation through TDD (steps 4–5), documentation, CI checks, and PR merge.",
             alt_text = "Mermaid flowchart showing a nine-step development workflow: issue, branch, plan, RED test, GREEN implementation, refactor, document, check, and PR.")
```

``` mermaid
```

Figure 4: Nine-step contributor workflow from issue creation through TDD
(steps 4–5), documentation, CI checks, and PR merge.

## 5. Targets DAG

Auto-generated dependency graph of the full targets pipeline.

Show code

``` r
vis <- safe_tar_read("vig_arch_tar_visnetwork")
if (!is.null(vis)) vis
```

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
#> [28] dplyr_1.1.4         ggplot2_4.0.1       base64url_1.4      
#> [31] credentials_2.0.3   assertthat_0.2.1    vctrs_0.7.1        
#> [34] R6_2.6.1            lifecycle_1.0.5     fs_1.6.6           
#> [37] bit_4.6.0           usethis_3.2.1       targets_1.11.4     
#> [40] arrow_22.0.0        callr_3.7.6         pkgconfig_2.0.3    
#> [43] desc_1.4.3          pillar_1.11.1       gtable_0.3.6       
#> [46] data.table_1.18.2.1 glue_1.8.0          gert_2.3.1         
#> [49] xfun_0.56           tibble_3.3.1        tidyselect_1.2.1   
#> [52] sys_3.4.3           knitr_1.51          farver_2.1.2       
#> [55] igraph_2.2.1        htmltools_0.5.9     rmarkdown_2.30     
#> [58] compiler_4.5.2      prettyunits_1.2.0   S7_0.2.1           
#> [61] askpass_1.2.1       openssl_2.3.4
```
