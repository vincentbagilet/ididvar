# Retrieve the estimation sample and its weights

Retrieves the data used for estimation, adds the identifying variation
weights in an `idid_weight` column and only keeps the observations used
for estimation.

## Usage

``` r
idid_estim_data(reg, var_interest, ...)
```

## Arguments

- reg:

  A regression object (or its control form, returned by `idid_to_cf`).

- var_interest:

  A vector string. The name of the variables of interest (coefficient
  names, eg `treat:post`, or variable names, eg `x` for `fit_x`).

- ...:

  Passed to `idid_weights`.

## Value

The data frame used to estimate `reg`, restricted to the estimation
sample, with an additional `idid_weight` column.
