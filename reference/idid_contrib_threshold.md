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

  A regression object.

- var_interest:

  A string. The name of the main variable of interest.

- threshold_change:

  A double (between 0 and 1). The change threshold in estimate and s.e.
  when dropping observations.

- search_step:

  A double (between 0 and 1). The additional proportion of observations
  to drop in each iteration of the loop.

- ...:

  Additional elements to pass to the regression function when
  partialling out controls.

## Value

A numeric. The largest weight below which one can drop observations
without altering the estimate by more than a proportion of
`threshold_change`.

## Details

This function applies
[`ididvar::idid_drop_change`](https://vincentbagilet.github.io/ididvar/reference/idid_drop_change.md)
for a series of proportions of observations removed, increasing this
proportion by `search_step` while the variation in the estimate and s.e.
as compared to the full sample is less than `threshold_change`.

## Examples

``` r
reg_ex <- ggplot2::economics |>
  lm(formula = unemploy ~ pce + uempmed + psavert + pop)

idid_contrib_threshold(reg_ex, "pce")
#> [1] 0.0005871943
```
