# Compute quick descriptive statistics on the effective sample

Reports the total, nominal and effective sample size, as well as the
proportion of observations from the nominal sample that are part of the
effective one.

## Usage

``` r
idid_contrib_stats(
  reg,
  var_interest,
  contrib_threshold,
  threshold_change = 0.05,
  ...
)
```

## Arguments

- reg:

  A regression object.

- var_interest:

  A string. The name of the main variable of interest.

- contrib_threshold:

  A numeric (optional). Weight below which observations are deemed to be
  non-contributing. If not provided, will be determined by running
  [`ididvar::idid_contrib_threshold`](https://vincentbagilet.github.io/ididvar/reference/idid_contrib_threshold.md)

- threshold_change:

  A double (between 0 and 1). The change threshold in estimate and s.e.
  when dropping observations.

- ...:

  Additional elements to pass to the regression function when
  partialling out controls.

## Value

A dataframe with 4 columns:

- `n_total`: the total sample size, before dropping observations with
  missing values

- `n_nominal`: the nominal sample size, ie the number of observations in
  the regression

- `n_effective`: the effective sample size, after removing non
  contributing observations

- `prop_effective`: the ratio of the effective to the nominal sample
  sizes

## Examples

``` r
reg_ex <- ggplot2::txhousing |>
  lm(formula = log(sales) ~ median + listings + city + as.factor(date))

idid_contrib_stats(reg_ex, "median")
#>   n_initial n_nominal n_effective prop_effective
#> 1      8602      7168        3943      0.5500837
```
