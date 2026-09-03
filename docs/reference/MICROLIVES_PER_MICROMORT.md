# Microlives per Micromort Conversion Factor

The single conversion factor used throughout this package to translate
an acute risk expressed in micromorts into the equivalent chronic risk
expressed in microlives.

## Usage

``` r
MICROLIVES_PER_MICROMORT
```

## Format

A single numeric value: `0.7`.

## Details

### Unit definitions

- 1 micromort = a 1-in-1,000,000 (1e-6) probability of death from a
  specific acute exposure.

- 1 microlife = 30 minutes of life expectancy.

### Derivation

Following the life-expectancy framework introduced by Spiegelhalter
(2012), a micromort's expected cost in life expectancy ("loss of life
expectancy", LLE) is the exposure probability multiplied by the life
expectancy remaining at the time of exposure. This package follows the
common convention (matching the derivation already used internally by
[`combined_quiz_pairs()`](https://johngavin.github.io/micromort/reference/combined_quiz_pairs.md))
of assuming **40 years of remaining life expectancy** for an "average"
adult:

    LLE_minutes  = 1e-6 * 40 years * 365 days/year * 24 hours/day * 60 min/hour
                 = 1e-6 * 21,024,000 minutes
                 = 21.024 minutes
    microlives   = LLE_minutes / 30 minutes-per-microlife
                 = 21.024 / 30
                 = 0.7008 -> rounds to 0.7

i.e. `MICROLIVES_PER_MICROMORT = (40 * 365 * 24 * 60 * 1e-6) / 30`,
which evaluates to `0.7008` and is stored rounded to one decimal place
as `0.7`.

### Caveat

The 40-year remaining-life-expectancy assumption is a simplification:
the true conversion factor varies by age (a micromort taken late in life
converts to fewer microlives than one taken early in life, because there
is less remaining life expectancy to lose). `0.7` is therefore a
population-average approximation, not an individually-calibrated value.
This package has not been able to trace the exact `0.7` figure to a
verbatim formula in Spiegelhalter's original BMJ paper (the derivation
above is this package's own reconstruction, cross-checked against
independent secondary sources that report the same 40-year assumption
and arithmetic); the general micromort/microlife framework itself,
however, is directly attributable to that paper.

## References

Spiegelhalter D (2012). "Using speed of ageing and 'microlives' to
communicate the effects of lifetime habits and environment." BMJ
2012;345:e8223.
[doi:10.1136/bmj.e8223](https://doi.org/10.1136/bmj.e8223)
<https://en.wikipedia.org/wiki/Micromort>
<https://en.wikipedia.org/wiki/Microlife>
