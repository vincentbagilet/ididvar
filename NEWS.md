# ididvar (development version)

## Breaking changes

* `idid_to_cf()` ("idid to control form") now returns the control form of a
  regression (an `idid_cf` object), an equivalent linear regression, instead
  of a re-estimated model. It supports `lm`, `glm`, `fixest`, `AER::ivreg`,
  `plm` and `felm`. The regression can be refitted from it, which gives back
  its coefficients but not its standard errors:

  ```r
  reg_cf <- idid_to_cf(reg)
  stats::lm.wfit(reg_cf$x, reg_cf$y, reg_cf$weights)$coefficients

  # with fixed effects
  fixest::feols.fit(reg_cf$y, reg_cf$x,
    fixef_df = as.data.frame(reg_cf$fixef_id), weights = reg_cf$weights)
  ```

* Variables of interest must be coefficients of the regression (eg
  `"treat:post"`), or variables matching one (eg `"x"` for `"fit_x"` in a
  `fixest` IV).
* `idid_partial_out()` and `idid_weights()` no longer re-estimate the model,
  so `...` is not used anymore.

## New features

* `idid_share_var()` returns the share of the variance of a variable (the
  outcome or a variable of interest) removed by partialling out the controls.

## Bug fixes

* `idid_partial_out()` partials out the controls of the regression as
  estimated. Controls dropped by the regression are no longer partialled out,
  and GLMs, IVs with transformed variables or missing values, `plm` models
  estimated on unsorted data, interactions and weighted regressions work.
* Models estimated inside a function now work. An error is raised if the data
  has been modified since estimation.
* `idid_drop_change()` now works with an exogenous variable of interest in an
  IV and with coefficient names containing parentheses or dots (eg `log(x)`).
