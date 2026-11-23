# Weight threshold when dropping low weight observations

Finds the lowest weight kept when dropping a proportion of the
observations of the estimation sample, lowest weights first.

## Usage

``` r
idid_weight_threshold(weights, prop_drop)
```

## Arguments

- weights:

  A numeric vector. The identifying variation weights, NA outside the
  estimation sample.

- prop_drop:

  Proportion of observations of the estimation sample to drop

## Value

A numeric. Observations with a lower weight are dropped.

## Details

Observations with the same weight are all kept or all dropped:
observations with a weight equal to the threshold are kept. The
proportion of observations dropped can therefore be lower than
`prop_drop`.
