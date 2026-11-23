# Create an idid_cf object

Creates the control form of a regression, returned by `idid_to_cf`.

## Usage

``` r
new_idid_cf(
  reg,
  x,
  y,
  weights = NULL,
  fixef_id = NULL,
  offset = NULL,
  obs = NULL,
  nobs_origin = NULL,
  cf_names = NULL
)
```

## Arguments

- reg:

  A regression object. Currently supported classes are `lm`, `glm`,
  `fixest`, `ivreg` (AER), `plm` and `felm`.

- x, y, weights, fixef_id, offset:

  The regressors, outcome, regression weights, fixed effects and offset
  of the control form.

- obs, nobs_origin:

  The rows of the data used for estimation and the number of rows of the
  data. If NULL, retrieved from the model frame.

- cf_names:

  A vector string. The names of the control function variables.

## Value

An `idid_cf` object.
