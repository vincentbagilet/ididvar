# Visualization of the cumulative distribution of weights

Visualization of the cumulative distribution of weights

## Usage

``` r
idid_viz_cumul(reg, var_interest, prop_weights = 0.2, color = "#300D49", ...)
```

## Arguments

- reg:

  A regression object.

- var_interest:

  A string. The name of the main variable of interest.

- prop_weights:

  A numeric (between 0 and 1). A proportion of weights that to consider
  as contributing the most to identification. Used to build the
  subtitle.

- color:

  A string. Color of the graph.

- ...:

  Additional elements to pass to the regression function when
  partialling out controls.

## Value

A ggplot2 graph of the cumulative distribution of weights.

## Examples

``` r
reg_ex <- ggplot2::txhousing |>
  lm(formula = log(sales) ~ median + listings + city + as.factor(date))

idid_viz_cumul(reg_ex, "median")
```
