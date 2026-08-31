# Generate cross-domain quiz pairs comparing acute and chronic risks

Creates candidate question pairs mixing acute risks from
[`common_risks()`](https://johngavin.github.io/micromort/reference/common_risks.md)
(micromorts per event) with chronic risks from
[`chronic_risks()`](https://johngavin.github.io/micromort/reference/chronic_risks.md)
(microlives per day), converting both to a common microlife scale so
they can be directly compared. Each pair pits one acute activity against
one chronic lifestyle factor and asks which has a larger total impact
over `time_period_days`.

## Usage

``` r
combined_quiz_pairs(n = 10, time_period_days = 365, seed = NULL)
```

## Arguments

- n:

  Integer. Number of pairs to generate. Default `10`.

- time_period_days:

  Numeric. Time period for chronic risk accumulation. Default `365` (1
  year). For chronic risks, the cumulative impact is
  `abs(microlives_per_day) × time_period_days`.

- seed:

  Integer or `NULL`. Random seed for reproducibility. Default `NULL`
  (random each call). Acute risks with `period_type == "event"` (true
  one-off events such as one expedition or one base jump) keep their raw
  micromort value. Acute risks with period type day/hour/month/year
  represent a repeatable rate of exposure and are projected to
  `time_period_days` via `micromorts_per_day_raw × time_period_days`
  before conversion to microlives. `period_type == "period"` rows are
  split by their `period` string: a plain "N weeks (YEAR)"
  surveillance-rate phrasing (e.g. "11 weeks (2022)") scales the same as
  day/hour/month/year, while a "per N weeks"/"per N months"
  bounded-window phrasing (e.g. "per 8 weeks" for a specific historical
  interval) keeps its raw micromort value like an event row. The
  unrounded column (`micromorts_per_day_raw`) is used rather than the
  display-rounded `micromorts_per_day` to prevent low-rate
  annual/monthly rows from collapsing to zero after rounding (e.g. 0.003
  µm/day rounds to 0.00).

## Value

A tibble with columns:

- `activity_a`, `type_a` ("acute"), `value_a` (raw micromorts as
  stored), `unit_a` ("micromorts"), `category_a`, `period_a`,
  `period_type_a` (one of "event", "day", "hour", "month", "year",
  "period"), `effective_micromorts_a` (raw value for "event" rows and
  bounded-window "period" rows;
  `micromorts_per_day_raw × time_period_days` otherwise)

- `factor_b`, `type_b` ("chronic"), `value_b`, `unit_b`
  ("microlives/day"), `category_b`, `direction_b`

- `common_unit` ("microlives"), `common_value_a`
  (`effective_micromorts_a × 0.7`), `common_value_b`

- `correct_answer` ("a" or "b" — whichever has higher impact in common
  unit)

- `ratio` (larger / smaller common value)

- `explanation` describing both values and the conversion

## Details

The conversion from micromorts to microlives uses the factor `0.7` (1
micromort ≈ 0.7 microlives at age 40). Chronic impact over the time
period is `abs(microlives_per_day) × time_period_days`.

## Examples

``` r
pairs <- combined_quiz_pairs(n = 5, seed = 42)
pairs[, c("activity_a", "factor_b", "correct_answer", "ratio")]
#> # A tibble: 5 × 4
#>   activity_a                              factor_b          correct_answer ratio
#>   <chr>                                   <chr>             <chr>          <dbl>
#> 1 Matterhorn ascent                       Average cancer d… b               1.10
#> 2 Logging (per work day)                  Sitting 8+ hours… a               1.16
#> 3 Logging (per work day)                  4th-5th alcoholi… a               1.16
#> 4 Spanish flu infection                   Smoking 10 cigar… a               1.15
#> 5 Living in US during COVID-19 (Jul 2020) Smoking 20 cigar… a               1.17

# One year time period (default)
pairs_year <- combined_quiz_pairs(n = 10, time_period_days = 365, seed = 1)
```
