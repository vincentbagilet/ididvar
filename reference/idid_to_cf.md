# Transform an IV regression into its control function equivalent

Takes an instrumental variables (IV) regression estimated with either
[`fixest::feols`](https://lrberge.github.io/fixest/reference/feols.html)
or `AER::ivreg` and refits it as a *control function* (CF)
specification.

## Usage

``` r
idid_to_cf(reg, ...)

# S3 method for class 'fixest'
idid_to_cf(reg, ...)

# S3 method for class 'ivreg'
idid_to_cf(reg, ...)

# Default S3 method
idid_to_cf(reg, ...)
```

## Arguments

- reg:

  An IV regression object. Currently supported classes are
  [`fixest::fixest`](https://lrberge.github.io/fixest/reference/fixest-package.html)
  and `AER::ivreg`.

- ...:

  Additional arguments passed to
  [`stats::update`](https://rdrr.io/r/stats/update.html) when refitting
  the model.

## Value

A model object of the same class as `reg` (`fixest` or `ivreg`),
representing the equivalent control-function specification. The returned
model uses the same data, controls, and variance specification as the
original regression.

## Details

The resulting model reproduces the second-stage regression where the
residuals from each first-stage (for endogenous regressors) are added as
additional controls. These residuals are appended to the data as
`<var>_first` and added as regressors in the updated model.

This function allows to explore the identifying variation of IV
estimates using the other functions of the `ididvar` package.

The function ensures that covariance options (e.g., clustering, weights)
and other model arguments are preserved from the original regression
where possible. If none are provided, the standard errors will be
incorrect.

## Methods (by class)

- `idid_to_cf(fixest)`: Method for `fixest` (feols) objects

- `idid_to_cf(ivreg)`: Method for `ivreg` objects

- `idid_to_cf(default)`: Default method (unsupported model types)

## See also

[fixest::feols](https://lrberge.github.io/fixest/reference/feols.html),
AER::ivreg, [stats::update](https://rdrr.io/r/stats/update.html)

## Examples

``` r
if (FALSE) { # \dontrun{
library(fixest)
library(AER)

# feols example
data(trade)
reg_feols <- feols(Euros ~ log(dist) | log(dist) ~ log(air) + log(dist), data = trade)
reg_feols_cf <- idid_to_cf(reg_feols)

# ivreg example
data("CigarettesSW")
reg_ivreg <- ivreg(log(packs) ~ log(rprice) + log(rincome) | log(rtax) + log(rincome),
                data = CigarettesSW)
reg_ivreg_cf <- idid_to_cf(reg_ivreg)
} # }
```
