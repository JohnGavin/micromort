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
             "Pipeline diagram requires `tar_make()` to render.",
             caption = "Figure 1: Data pipeline showing five processing stages from raw risk data through targets to vignette outputs.",
             alt_text = "Mermaid flowchart showing the five-stage targets data pipeline: raw data ingestion, cleaning, aggregation, modelling, and vignette export.")
```

``` mermaid
```

Figure 1: Data pipeline showing five processing stages from raw risk
data through targets to vignette outputs.

## 2. Function Hierarchy

All exported functions grouped by category. Click any function to view
its documentation.

Show code

``` r
emit_mermaid("vig_arch_concept_diagram",
             "Concept diagram requires `tar_make()` to render.",
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
             "User journey diagram requires `tar_make()` to render.",
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
             "Developer diagram requires `tar_make()` to render.",
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
show_target("vig_arch_tar_visnetwork")
Target 'vig_arch_tar_visnetwork' requires tar_make() to build.
*`vig_arch_tar_visnetwork` requires `tar_make()` to render.*
```

## Pipeline Telemetry

### Dependency Graph

%%{init: {‘theme’: ‘dark’, ‘themeVariables’: {‘primaryColor’: ‘#999999’,
‘primaryTextColor’: ‘#000000’, ‘primaryBorderColor’: ‘#CC0000’,
‘lineColor’: ‘#CC0000’, ‘secondaryColor’: ‘#999999’, ‘tertiaryColor’:
‘#999999’, ‘background’: ‘#000000’, ‘mainBkg’: ‘#999999’, ‘nodeBorder’:
‘#CC0000’, ‘clusterBkg’: ‘#333333’, ‘clusterBorder’: ‘#CC0000’,
‘titleColor’: ‘#000000’, ‘edgeLabelBackground’: ‘#999999’}}}%% graph LR
acute_risks_merged –\> pipeline_log acute_risks_merged –\>
dataset_summary acute_risks_merged –\> export_acute chronic_risks_merged
–\> pipeline_log chronic_risks_merged –\> export_chronic
chronic_risks_merged –\> dataset_summary export_acute –\>
export_validation export_acute –\> pipeline_log export_chronic –\>
export_validation export_chronic –\> pipeline_log export_sources –\>
export_validation export_sources –\> pipeline_log leaderboard_raw –\>
leaderboard_stats_json leaderboard_stats_json –\> site_verify
parsed_acute_base –\> acute_risks_merged parsed_chronic_base –\>
chronic_risks_merged parsed_sources –\> risk_sources_merged pkgctx_audit
–\> pkgctx_sync pkgdown_build –\> pkgdown_staged pkgdown_inputs –\>
pkgdown_build project_dirs_hash –\> project_tree project_tree –\>
project_tree_formatted qa_coverage –\> qa_quality_gate qa_no_raw_sql –\>
qa_quality_gate qa_self_review –\> qa_quality_gate qa_test_results –\>
qa_quality_gate qa_vignette_compliance –\> qa_quality_gate
risk_sources_merged –\> pipeline_log risk_sources_merged –\>
export_sources risk_sources_merged –\> dataset_summary
site_chronic_shinylive –\> site_deploy_shinylive site_closeread –\>
site_verify site_deploy_shinylive –\> site_verify site_document –\>
site_pkgdown site_pkgdown –\> site_closeread site_pkgdown –\>
site_chronic_shinylive site_pkgdown –\> site_quiz_shinylive site_pkgdown
–\> site_ranking_shinylive site_quiz_csv_export –\> site_pkgdown
site_quiz_shinylive –\> site_deploy_shinylive site_ranking_shinylive –\>
site_deploy_shinylive site_rds_export –\> site_pkgdown site_readme –\>
site_pkgdown site_source_hash –\> site_document site_source_hash –\>
site_pkgdown src_acute_base –\> parsed_acute_base src_chronic_base –\>
parsed_chronic_base src_covid_vaccine –\> parsed_covid src_demographic
–\> parsed_demographic src_risk_sources –\> parsed_sources
vig_chronic_acute_country_shift –\> vig_chronic_acute_country_display
vig_chronic_acute_equivalences –\> vig_chronic_acute_heroin_table
vig_chronic_acute_waterfall –\> vig_chronic_acute_waterfall_chronic
vig_chronic_acute_waterfall –\> vig_chronic_acute_waterfall_acute
vig_chronic_csv_check –\> qa_chronic_csv_gate vig_chronic_pairs –\>
vig_chronic_quiz_json_script vig_chronic_pairs –\> vig_chronic_csv_check
vig_equiv_everyday –\> vig_equiv_everyday_chart
vig_equiv_flight_duration –\> vig_equiv_hedgeable_chart
vig_equiv_flight_duration –\> vig_equiv_flight_duration_chart
vig_equiv_medical_focus –\> vig_equiv_medical_exchange_chart
vig_pipeline_summary –\> vig_telemetry_top_by_time vig_pipeline_summary
–\> vig_telemetry_top_by_size vig_quiz_pairs –\> vig_quiz_json_script
vig_quiz_pairs –\> vig_quiz_csv_check vig_quiz_pairs –\>
site_quiz_csv_export vig_radiation_timeline_data –\>
vig_equiv_radiation_timeline_chart vig_ranking_questions –\>
vig_ranking_csv_check vig_ranking_questions –\>
vig_ranking_quiz_json_script vig_regional_le_gap –\>
vig_regional_le_gap_text

### Plans and Targets

### Top 5 Targets by Storage Size

### Top 5 Targets by Compute Time

### Commit Velocity

Weekly commit frequency over the last 26 weeks. Each bar represents
commits merged in a calendar week. Source: gert::git_log().

### Issues and Pull Requests

### Codebase Metrics

## Reproducibility

Show code

``` r
sessionInfo()
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
```
