# Run the regression with low weight observations dropped

Re-run the regression but dropping low weight observations.

## Usage

``` r
idid_drop_reg(reg, var_interest, prop_drop, ...)
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

A regression object

## Details

This function recomputes the weights

## Examples

``` r
reg_ex <- ggplot2::economics |>
  lm(formula = unemploy ~ pce + uempmed + psavert + pop)

idid_drop_reg(reg_ex, "pce", prop_drop = 0.1)
#> 
#> Call:
#> lm(formula = unemploy ~ pce + uempmed + psavert + pop, data = df_sliced, 
#>     use_calling_env = FALSE)
#> 
#> Coefficients:
#> (Intercept)          pce      uempmed      psavert          pop  
#>  -3.424e+04   -1.591e+00    5.742e+02    2.002e+02    1.673e-01  
#> 
```
