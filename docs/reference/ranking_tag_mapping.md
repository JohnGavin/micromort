# Tag-to-Category Mapping for Ranking Quiz

Returns the mapping between user-facing quiz tags and dataset
categories. Tags group related risks across both acute (micromort) and
chronic (microlife) datasets for the ranking quiz.

## Usage

``` r
ranking_tag_mapping()
```

## Value

A tibble with columns `tag`, `source` ("acute"/"chronic"), `category`,
and optionally `pattern` (regex for activity-level filtering).

## Examples

``` r
ranking_tag_mapping()
#> # A tibble: 27 × 4
#>    tag          source  category    pattern                                     
#>    <chr>        <chr>   <chr>       <chr>                                       
#>  1 Radiation    acute   Medical     radiation|X-ray|CT scan|Mammogram|angiogram…
#>  2 Radiation    acute   Occupation  radiation|pilot                             
#>  3 Radiation    acute   Environment radon|cosmic|background                     
#>  4 Radiation    acute   Travel      cosmic                                      
#>  5 Travel       acute   Travel      NA                                          
#>  6 Medical      acute   Medical     NA                                          
#>  7 Medical      chronic Medical     NA                                          
#>  8 Diet & Drink acute   Diet        NA                                          
#>  9 Diet & Drink acute   Daily Life  coffee|wine                                 
#> 10 Diet & Drink chronic Diet        NA                                          
#> # ℹ 17 more rows
```
