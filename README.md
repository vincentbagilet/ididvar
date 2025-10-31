
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ididvar

<!-- badges: start -->

<!-- badges: end -->

This package provides tools to easily **identify the identifying
variation in a regression**, specifically in **applied economics**
analyses.

This package is built as part of a [research
project](https://vincentbagilet.github.io/causal_exaggeration/). As
such, the [associated
paper](https://vincentbagilet.github.io/causal_exaggeration/causal_exaggeration_paper.pdf)
provides a detailed scientific description of its content and of its
underpinnings.

## Installation

You can install the development version of `ididvar` from
[GitHub](https://github.com/vincentbagilet/ididvar) with:

``` r
# install.packages("devtools")
devtools::install_github("vincentbagilet/ididvar")
```

## Usage

Most of the functions of the package take as input the output of a
regression and the name of the variable of interest. `ididvar` supports
a breadth of estimation packages (`lm`, `plm`, `fixest` for instance).

First, the package provides a straightforward function to compute
identifying variation weights.

``` r
library(ididvar)
library(ggplot2)

reg_ex_fixest <- ggplot2::txhousing |>
  dplyr::mutate(l_sales = log(sales)) |> 
  fixest::feols(fml = l_sales ~ median + listings | year + city, vcov = "twoway")

idid_weights(reg_ex_fixest, "median") |>
  head()
#> [1] 1.417497e-05 5.163932e-05 5.908480e-05 1.918702e-06 7.089139e-08
#> [6] 7.372159e-09
```

The package also allows for an effortless exploration of these weights
through visualizations.

``` r
idid_viz_weights(reg_ex_fixest, "median", year, city, order = "y") +
  ggplot2::labs(x = NULL, y = NULL) 
```

<img src="man/figures/README-plot_weights-1.png" width="70%" style="display: block; margin: auto;" />

In this particular (somehow silly) regression, most of the identifying
variation comes from a few cities: Houston, Dallas, Austin and San
Antonio.

``` r
idid_viz_cumul(reg_ex_fixest, "median")
```

<img src="man/figures/README-plot_cumul-1.png" width="80%" style="display: block; margin: auto;" />

It also provide functions to identify observations that actually
contribute to identification (in the sense that dropping the other
observations does not significantly affect the estimate obtained).

``` r
idid_viz_contrib(reg_ex_fixest, "median", var_y = city, order = "y") +
  ggplot2::labs(y = NULL)
#> Warning: The VCOV matrix is not positive semi-definite and was 'fixed' (see
#> ?vcov).
#> Warning: The VCOV matrix is not positive semi-definite and was 'fixed' (see
#> ?vcov).
#> Warning: The VCOV matrix is not positive semi-definite and was 'fixed' (see
#> ?vcov).
#> Warning: The VCOV matrix is not positive semi-definite and was 'fixed' (see
#> ?vcov).
#> Warning: The VCOV matrix is not positive semi-definite and was 'fixed' (see
#> ?vcov).
#> Warning: The VCOV matrix is not positive semi-definite and was 'fixed' (see
#> ?vcov).
```

<img src="man/figures/README-plot_contrib-1.png" width="70%" style="display: block; margin: auto;" />

The package provides a larger [set of
functions](docs/reference/index.html). The [Get started
vignette](articles/ididvar.html) introduces them in a concise manner,
while also describing a typical workflow for analysis.

[Online
appendices](https://vincentbagilet.github.io/causal_exaggeration/ididvar.html)
of the [associated
paper](https://vincentbagilet.github.io/causal_exaggeration/causal_exaggeration_paper.pdf)
complements this vignette by providing an example of a practical
implementation of an analysis using the `ididvar` package.
