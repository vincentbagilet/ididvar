# Variation in estimate when dropping low weight observations

Computes a variation of the point estimate and standard errors of the
coefficient of interest when dropping low weight observations.

## Usage

``` r
idid_drop_change(reg, var_interest, prop_drop, ...)
```

## Arguments

- reg:

  A regression object.

- var_interest:

  A string. The name of the main variable of interest.

- prop_drop:

  Proportion of observations to drop

- ...:

  Additional elements to pass to the regression function when
  partialling out controls.

## Value

A dataframe with one row and 3 columns:

- `prop_drop`: the proportion of data dropped

- `prop_change_est`: the relative change between the full sample and
  droped estimates

- `prop_change_se`: the relative change between the full sample and
  droped s.e.

## Examples

``` r
reg_ex <- ggplot2::economics |>
  lm(formula = unemploy ~ pce + uempmed + psavert + pop)

idid_drop_change(reg_ex, "pce", prop_drop = 0.1)
#>   prop_drop prop_change_est prop_change_se
#> 1       0.1     0.002222509    -0.00399835
```
