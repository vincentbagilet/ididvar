# Coefficient names of the variables of interest

Finds the name of the coefficient corresponding to each variable of
interest. For instance, `x` is called `fit_x` in an IV regression
estimated with `fixest` and a logical variable `treat` is called
`treatTRUE`.

## Usage

``` r
idid_coef_names(reg, var_interest)
```

## Arguments

- reg:

  A regression object (or its control form, returned by `idid_to_cf`).

- var_interest:

  A vector string. The name of the variables of interest (coefficient
  names, eg `treat:post`, or variable names, eg `x` for `fit_x`).

## Value

A vector string. The coefficient names of the variables of interest.
