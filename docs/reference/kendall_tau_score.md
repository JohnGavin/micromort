# Kendall Tau Score for Ranking Quiz

Computes how well a user's ranking matches the correct ranking using the
Kendall tau distance. Counts concordant pairs (user agrees with correct
order) vs discordant pairs (user disagrees).

## Usage

``` r
kendall_tau_score(user_order, correct_order)
```

## Arguments

- user_order:

  Integer vector of item indices in the user's order (first element =
  user's \#1 pick, i.e. most risky).

- correct_order:

  Integer vector of item indices in the correct order.

## Value

A list with:

- `score`: number of concordant pairs

- `max_score`: total number of pairs = k\*(k-1)/2

- `n_concordant`: same as score

- `n_discordant`: pairs where user and correct order disagree

- `pct`: percentage score (0-100)

## Examples

``` r
# Perfect score
kendall_tau_score(c(1, 2, 3), c(1, 2, 3))
#> $score
#> [1] 3
#> 
#> $max_score
#> [1] 3
#> 
#> $n_concordant
#> [1] 3
#> 
#> $n_discordant
#> [1] 0
#> 
#> $pct
#> [1] 100
#> 

# Completely reversed
kendall_tau_score(c(3, 2, 1), c(1, 2, 3))
#> $score
#> [1] 0
#> 
#> $max_score
#> [1] 3
#> 
#> $n_concordant
#> [1] 0
#> 
#> $n_discordant
#> [1] 3
#> 
#> $pct
#> [1] 0
#> 

# One swap
kendall_tau_score(c(2, 1, 3), c(1, 2, 3))
#> $score
#> [1] 2
#> 
#> $max_score
#> [1] 3
#> 
#> $n_concordant
#> [1] 2
#> 
#> $n_discordant
#> [1] 1
#> 
#> $pct
#> [1] 66.7
#> 
```
