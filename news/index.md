# Changelog

## ididvar (development version)

### Breaking changes

- [`idid_to_cf()`](https://vincentbagilet.github.io/ididvar/reference/idid_to_cf.md)
  (“idid to control form”) now returns the control form of a regression
  (an `idid_cf` object), an equivalent linear regression, instead of a
  re-estimated model. It supports `lm`, `glm`, `fixest`,
  [`AER::ivreg`](https://rdrr.io/pkg/AER/man/ivreg.html), `plm` and
  `felm`. The regression can be refitted from it, which gives back its
  coefficients but not its standard errors:

  ``` r

  reg_cf <- idid_to_cf(reg)
  stats::lm.wfit(reg_cf$x, reg_cf$y, reg_cf$weights)$coefficients

  # with fixed effects
  fixest::feols.fit(reg_cf$y, reg_cf$x,
    fixef_df = as.data.frame(reg_cf$fixef_id), weights = reg_cf$weights)
  ```

- Variables of interest must be coefficients of the regression (eg
  `"treat:post"`), or variables matching one (eg `"x"` for `"fit_x"` in
  a `fixest` IV).

- [`idid_partial_out()`](https://vincentbagilet.github.io/ididvar/reference/idid_partial_out.md)
  and
  [`idid_weights()`](https://vincentbagilet.github.io/ididvar/reference/idid_weights.md)
  no longer re-estimate the model, so `...` is not used anymore.

### New features

- [`idid_share_var()`](https://vincentbagilet.github.io/ididvar/reference/idid_share_var.md)
  returns the share of the variance of a variable (the outcome or a
  variable of interest) removed by partialling out the controls.

### Bug fixes

- [`idid_partial_out()`](https://vincentbagilet.github.io/ididvar/reference/idid_partial_out.md)
  partials out the controls of the regression as estimated. Controls
  dropped by the regression are no longer partialled out, and GLMs, IVs
  with transformed variables or missing values, `plm` models estimated
  on unsorted data, interactions and weighted regressions work.
- Models estimated inside a function now work. An error is raised if the
  data has been modified since estimation.
- [`idid_drop_change()`](https://vincentbagilet.github.io/ididvar/reference/idid_drop_change.md)
  now works with an exogenous variable of interest in an IV and with
  coefficient names containing parentheses or dots (eg `log(x)`).
- Effective sample
  ([`idid_drop_reg()`](https://vincentbagilet.github.io/ididvar/reference/idid_drop_reg.md),
  [`idid_drop_change()`](https://vincentbagilet.github.io/ididvar/reference/idid_drop_change.md),
  [`idid_contrib_threshold()`](https://vincentbagilet.github.io/ididvar/reference/idid_contrib_threshold.md)
  and the functions using them):
  - the threshold corresponds to the last step that does not change the
    estimate by more than `threshold_change`, not the first one that
    does. Observations with a weight equal to the threshold now
    contribute.
  - only observations of the estimation sample are dropped, and
    observations with the same weight are all dropped or all kept.
  - [`idid_drop_change()`](https://vincentbagilet.github.io/ididvar/reference/idid_drop_change.md)
    returns one row per variable of interest. The search requires every
    one of them to pass.
  - a regression that fails after dropping observations counts as a
    large change instead of stopping the search.
  - standard errors come from
    [`vcov()`](https://rdrr.io/r/stats/vcov.html). For `fixest`, both
    use the variance of the regression passed (eg clustering set in
    [`summary()`](https://rdrr.io/r/base/summary.html)) and no small
    sample correction.
  - [`idid_drop_change()`](https://vincentbagilet.github.io/ididvar/reference/idid_drop_change.md)
    gains a `vcov` argument, a function computing the variance of both
    regressions (eg
    [`sandwich::vcovHC`](https://zeileis.codeberg.page/sandwich/reference/vcovHC.html)).
    It can be passed to the other functions through `...`.
  - `felm` and `glm` work, and `fixest` notes are not repeated.
  - [`idid_viz_drop_change()`](https://vincentbagilet.github.io/ididvar/reference/idid_viz_drop_change.md)
    uses `search_step`.
