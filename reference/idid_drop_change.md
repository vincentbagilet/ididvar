# Variation in estimate when dropping low weight observations

Computes a variation of the point estimate and standard errors of the
coefficient of interest when dropping low weight observations.

## Usage

``` r
idid_drop_change(reg, var_interest, prop_drop, vcov = NULL, ...)
```

## Arguments

- reg:

  A regression object (or its control form, returned by `idid_to_cf`).

- var_interest:

  A vector string. The name of the variables of interest (coefficient
  names, eg `treat:post`, or variable names, eg `x` for `fit_x`).

- prop_drop:

  Proportion of observations of the estimation sample to drop

- vcov:

  A function (optional). Computes the variance-covariance matrix of a
  regression, eg
  [`sandwich::vcovHC`](https://zeileis.codeberg.page/sandwich/reference/vcovHC.html).
  Used for both the full sample and the dropped regressions. If NULL,
  the variance described in Details.

- ...:

  Not used.

## Value

A dataframe with one row per variable of interest and 4 columns:

- `prop_drop`: the proportion of data dropped

- `var_interest`: the name of the coefficient

- `prop_change_est`: the relative change between the full sample and
  droped estimates

- `prop_change_se`: the relative change between the full sample and
  droped s.e.

The changes are NA if the coefficient cannot be estimated without the
dropped observations.

## Details

Standard errors are retrieved with `vcov`. For `fixest` models, both
standard errors use the variance of `reg` (eg clustering set in
`summary`), without small sample correction, as this correction changes
mechanically when dropping observations.

## Examples

``` r
reg_ex <- ggplot2::economics |>
  lm(formula = unemploy ~ pce + uempmed + psavert + pop)

idid_drop_change(reg_ex, "pce", prop_drop = 0.1)
#>   prop_drop var_interest prop_change_est prop_change_se
#> 1       0.1          pce     0.002134325   -0.003101196

#robust standard errors
idid_drop_change(reg_ex, "pce", prop_drop = 0.1, vcov = sandwich::vcovHC)
#>   prop_drop var_interest prop_change_est prop_change_se
#> 1       0.1          pce     0.002134325    0.008286803
```
