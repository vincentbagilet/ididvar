# Find a weight threshold below which observations "do not contribute"

Find a weight threshold below which removing observations does not
change the point estimate or the standard error of the estimate of
interest by more than a given proportion.

## Usage

``` r
idid_contrib_threshold(
  reg,
  var_interest,
  threshold_change = 0.05,
  search_step = 0.05,
  ...
)
```

## Arguments

- reg:

  A regression object (or its control form, returned by `idid_to_cf`).

- var_interest:

  A vector string. The name of the variables of interest (coefficient
  names, eg `treat:post`, or variable names, eg `x` for `fit_x`).

- threshold_change:

  A double (between 0 and 1). The change threshold in estimate and s.e.
  when dropping observations.

- search_step:

  A double (between 0 and 1). The additional proportion of observations
  to drop in each iteration of the loop.

- ...:

  Passed to `idid_drop_change`, eg `vcov`.

## Value

A numeric. The weight below which one can drop observations without
altering the estimate by more than a proportion of `threshold_change`.
Observations with this weight are kept.

## Details

This function applies
[`ididvar::idid_drop_change`](https://vincentbagilet.github.io/ididvar/reference/idid_drop_change.md)
for a series of proportions of observations removed, increasing this
proportion by `search_step` while the variation in the estimate and s.e.
as compared to the full sample is less than `threshold_change` (for
every variable of interest). The threshold corresponds to the last step
that passes and no observation is dropped if the first step fails.

## Examples

``` r
reg_ex <- ggplot2::economics |>
  lm(formula = unemploy ~ pce + uempmed + psavert + pop)

idid_contrib_threshold(reg_ex, "pce")
#> [1] 0.0002853919
```
