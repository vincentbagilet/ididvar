# Create a custom theme for `ididvar` visualizations

A function to return a custom ggplot2 theme.

## Usage

``` r
theme_idid(...)
```

## Arguments

- ...:

  Additional arguments to be passed to the `theme` function

## Value

The specified `theme` object.

## Examples

``` r
ggplot2::mpg |>
  ggplot2::ggplot(ggplot2::aes(x = displ, hwy, color = cyl)) +
  ggplot2::geom_point() +
  ggplot2::labs(
    title = "A wonderful title",
    subtitle = "Something to add"
  ) +
  theme_idid()
```
