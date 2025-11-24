# Visualize changes in point estimate and s.e. when dropping observations

Make a faceted line graph describing the percentage variation of the
point estimate and s.e. of interest as a function of the proportion of
observations dropped.

## Usage

``` r
idid_viz_drop_change(
  reg,
  var_interest,
  threshold_change = 0.05,
  search_step = 0.05,
  search_start = search_step,
  search_end = 1 - search_step,
  color = "#300D49",
  ...
)
```

## Arguments

- reg:

  A regression object.

- var_interest:

  A string. The name of the main variable of interest.

- threshold_change:

  A double (between 0 and 1). The change threshold in estimate and s.e.
  when dropping observations.

- search_step:

  A double (between 0 and 1). The additional proportion of observations
  to drop in each iteration of the loop.

- search_start:

  A numeric (between 0 and 1). Proportion of observation to drop in the
  first step of the loop in `idid_contrib_threshold`.

- search_end:

  A numeric (between 0 and 1). Proportion of observation to drop in the
  last step of the loop in `idid_contrib_threshold`.

- color:

  A string. Color of the graph.

- ...:

  Additional elements to pass to the regression function when
  partialling out controls.

## Value

A ggplot2 object.

The name of the facet variable is `measure`.

## Examples

``` r
reg_ex <- ggplot2::txhousing |>
  lm(formula = log(sales) ~ median + listings + city + as.factor(date))

idid_viz_drop_change(reg_ex, "median", search_end = 0.6)
```
