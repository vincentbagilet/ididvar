# Ordering axes

Orders axes depending on the order desired Used in `idid_viz_weights`
and `idid_viz_contrib`.

## Usage

``` r
order_axes(df, name_var_x, name_var_y, order, by = "idid_weight")
```

## Arguments

- df:

  A dataframe to order

- order:

  A string (either "x", "y" or "xy") describing whether the graph should
  be order, along the x or y axis or both. If anything else is
  specified, no specific ordering will be applied.

## Value

`df` but ordered along the `order` axis and according to the value of
`by`
