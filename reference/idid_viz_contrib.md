# Visualization of observations contributing (or not) to estimation

Make a graph to visualize observations that can be dropped without
changing the point estimate or the standard error of the estimate of
interest by more than a given proportion (`threshold_change`).

Makes a heatmap or a bar chart, depending on the number of dimensions
specified.

## Usage

``` r
idid_viz_contrib(
  reg,
  var_interest,
  var_x,
  var_y,
  contrib_threshold,
  threshold_change = 0.05,
  order = "",
  colors = c("#C25807", "#FBE2C5", "#300D49"),
  keep_labels = TRUE,
  ...
)
```

## Arguments

- reg:

  A regression object.

- var_interest:

  A string. The name of the main variable of interest.

- var_x:

  A variable in the data set used in `reg` to plot on the x-axis.

- var_y:

  A variable in the data set used in `reg` to plot on the y-axis
  (optional). If not specified, produces a bar chart.

- contrib_threshold:

  A numeric (optional). Weight below which observations are deemed to be
  non-contributing. If not provided, will be determined by running
  [`ididvar::idid_contrib_threshold`](https://vincentbagilet.github.io/ididvar/reference/idid_contrib_threshold.md)

- threshold_change:

  A double (between 0 and 1). The change threshold in estimate and s.e.
  when dropping observations.

- order:

  A string (either "x", "y" or "xy") describing whether the graph should
  be order, along the x or y axis or both. If anything else is
  specified, no specific ordering will be applied.

- colors:

  A string vector of colors for the palette. I recommend to pass a
  vector of 3 distinct colors, with a lighter color in the middle,
  constituting a diverging scale. It allows a clear distinction between
  contributing and non contributing observations.

- keep_labels:

  A boolean (optional). If FALSE, removes y labels and ticks. This
  option is useful for panels with a large number of individuals.

- ...:

  Additional elements to pass to the regression function when
  partialling out controls.

## Value

A ggplot2 graph of observations contributing to estimation.

If var_y is specified, returns a heatmap whose color describes whether a
given observation does not contribute (i.e. can be dropped, along with
all lower weight observations, without substantially altering the
estimate)

If var_y is not specified, returns a bar chart representing the number
of observations that can be dropped in each group.

## Examples

``` r
reg_ex <- ggplot2::txhousing |>
  lm(formula = log(sales) ~ median + listings + city + as.factor(date))

idid_viz_contrib(reg_ex, "median", year, city, order = "y") +
  ggplot2::labs(x = NULL, y = NULL)
#> Warning: Removed 1434 rows containing non-finite outside the scale range
#> (`stat_sum_tile()`).


idid_viz_contrib(reg_ex, "median", var_y = city, order = "y") +
  ggplot2::labs(x = NULL)
```
