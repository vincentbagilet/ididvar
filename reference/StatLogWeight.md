# Automatic aggregation and log-transform for tiles

A ggplot2 Stat that behaves like stat_summary_2d but automatically:

1.  Sums z-values per (x, y)

2.  Applies the transformation log10(sum(z) \* n_x \* n_y)

## Usage

``` r
StatLogWeight
```

## Format

An object of class `StatLogWeight` (inherits from `Stat`, `ggproto`,
`gg`) of length 4.

## Details

summarise the weights by var_x*vary_y groups (summing their values),
take the ratio of the weight of each group over the average weight
across groups (1/(n_x*n_y)) and then takes its log10
