# Transform a regression into its control form

Rewrites a regression as an equivalent linear regression, its control
form, without re-estimating it.

## Usage

``` r
idid_to_cf(reg, ...)

# S3 method for class 'fixest'
idid_to_cf(reg, ...)

# S3 method for class 'ivreg'
idid_to_cf(reg, ...)

# S3 method for class 'lm'
idid_to_cf(reg, ...)

# S3 method for class 'glm'
idid_to_cf(reg, ...)

# S3 method for class 'plm'
idid_to_cf(reg, ...)

# S3 method for class 'felm'
idid_to_cf(reg, ...)

# Default S3 method
idid_to_cf(reg, ...)
```

## Arguments

- reg:

  A regression object. Currently supported classes are `lm`, `glm`,
  `fixest`, `ivreg` (AER), `plm` and `felm`.

- ...:

  Not used.

## Value

An `idid_cf` object, a list with:

- `x`: the regressors

- `y`: the outcome

- `weights`: the regression weights (1 if none)

- `fixef_id`: the fixed effects (NULL if none)

- `obs`: the rows of the data used for estimation

- `nobs_origin`: the number of rows of the data

- `coefficients`, `y_name`, `cf_names` (the control function variables)
  and `model_class`

## Details

The control form has the same coefficients as `reg`. The other functions
of the package work on it, to handle all models the same way:

- linear models (`lm`, `feols`, `felm`): the regression itself.

- IV (`ivreg`, `feols`): first stage residuals are added as controls
  (control function).

- GLM (`glm`, `feglm`, `fepois`): the working response, with the IRLS
  weights (R estimates GLMs by iterating weighted linear regressions of
  this working response).

- `plm`: the data as transformed by `plm` (eg demeaned for a within
  model).

The regression can be refitted from its control form. This gives back
its coefficients but not its standard errors:

    reg_cf <- idid_to_cf(reg)
    stats::lm.wfit(reg_cf$x, reg_cf$y, reg_cf$weights)$coefficients

    # with fixed effects
    fixest::feols.fit(reg_cf$y, reg_cf$x,
      fixef_df = as.data.frame(reg_cf$fixef_id), weights = reg_cf$weights)

## Methods (by class)

- `idid_to_cf(fixest)`: Method for `fixest` objects

- `idid_to_cf(ivreg)`: Method for `ivreg` objects

- `idid_to_cf(lm)`: Method for `lm` objects

- `idid_to_cf(glm)`: Method for `glm` objects

- `idid_to_cf(plm)`: Method for `plm` objects

- `idid_to_cf(felm)`: Method for `felm` objects

- `idid_to_cf(default)`: Default method (unsupported model types)

## Examples

``` r
reg_ex <- ggplot2::txhousing |>
  lm(formula = log(sales) ~ median + listings + city)

reg_cf <- idid_to_cf(reg_ex)
reg_cf
#> Control form of a lm regression: 7168 observations, 48 coefficients

stats::lm.wfit(reg_cf$x, reg_cf$y, reg_cf$weights)$coefficients |>
  head()
#>   (Intercept)        median      listings  cityAmarillo cityArlington 
#>  4.520955e+00  4.552992e-06  1.208372e-05  3.802365e-01  8.874377e-01 
#>    cityAustin 
#>  2.102869e+00 

# IV
reg_iv <- fixest::feols(mpg ~ wt | hp ~ qsec, data = mtcars)
idid_to_cf(reg_iv)
#> Control form of a fixest regression: 32 observations, 3 coefficients
#> Control function: hp_first 
```
