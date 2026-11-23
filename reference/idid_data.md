# Retrieve the data used for estimation

Retrieves the data set used for estimation and checks that it still
matches the regression.

## Usage

``` r
idid_data(reg)
```

## Arguments

- reg:

  A regression object (or its control form, returned by `idid_to_cf`).

## Value

The data frame used to estimate `reg`.

## Details

For `fixest` objects, the data is retrieved with
[`fixest::fixest_data`](https://lrberge.github.io/fixest/reference/fixest_data.html).
If the regression was estimated with `data.save = TRUE`, this is the
data saved in `reg`, which remains valid even if the data has been
modified since. For other objects, the data is evaluated in the
environment of the formula. In both cases, the data is found even when
the regression was estimated inside a function.

The function returns an error if the data cannot be found or if it does
not match the regression anymore, for instance if rows have been dropped
after estimation. For `fixest` objects, the number of rows of the data
must be equal to the number of observations before any is removed
(`reg$nobs_origin`). For other objects, all the row names of the model
frame must be row names of the data.
