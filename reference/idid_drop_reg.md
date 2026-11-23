# Run the regression with low weight observations dropped

Re-run the regression but dropping low weight observations.

## Usage

``` r
idid_drop_reg(reg, var_interest, prop_drop, ...)
```

## Arguments

- reg:

  A regression object (or its control form, returned by `idid_to_cf`).

- var_interest:

  A vector string. The name of the variables of interest (coefficient
  names, eg `treat:post`, or variable names, eg `x` for `fit_x`).

- prop_drop:

  Proportion of observations of the estimation sample to drop

- ...:

  Not used.

## Value

A regression object

## Details

This function recomputes the weights. Observations outside the
estimation sample are dropped. Observations with the same weight are all
kept or all dropped, so the proportion of observations dropped can be
lower than `prop_drop`.

## Examples

``` r
reg_ex <- ggplot2::economics |>
  lm(formula = unemploy ~ pce + uempmed + psavert + pop)

idid_drop_reg(reg_ex, "pce", prop_drop = 0.1)
#> 
#> Call:
#> lm(formula = unemploy ~ pce + uempmed + psavert + pop, data = df_sliced)
#> 
#> Coefficients:
#> (Intercept)          pce      uempmed      psavert          pop  
#>  -3.423e+04   -1.592e+00    5.742e+02    1.999e+02    1.672e-01  
#> 
```
