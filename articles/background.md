# Background on the weights

This document very quickly introduces the maths and theory behind the
weights. More detail is available in the [associated research
paper](https://vincentbagilet.github.io/causal_exaggeration/causal_exaggeration_paper.pdf).

## Intuition

These weights **represent how much each observation contributes to the
identification**. They correspond to the leverage of each observation in
the bivariate regression of the independent variable on the treatment or
main variable of interest, after partialling out the controls.They are
equivalent–up to a normalization to one–to the multiple regression
weights defined by [Aronow and Samii
(2016)](https://onlinelibrary.wiley.com/doi/abs/10.1111/ajps.12185) and
previously discussed in [Angrist and Pischke
(2009)](https://www.jstor.org/stable/j.ctvcm4j72). Observations for
which the main variable of interest is well explained by controls only
contribute little to identification; the controls or fixed effects
absorb most of the variation.

A range of existing tools from the statistics literature, such as
leverage and Cook’s distance, already measure the influence of
individual observations on regression parameters. These measures,
however, assess influence on the parameter vector and are not directly
suited for applied economics where interest is typically confined to a
single parameter: the coefficient of the treatment variable. To get to a
more suited measure, the present procedure consists in first applying
the Frisch-Waugh-Lovell theorem and then computing leverage for the
regression of the residualized outcome on the residualized treatment.
The residuals are obtained from regressions on the full set of controls,
including fixed effects and other identification-related controls such
as control functions. This produces observation-specific weights
describing the extent to which each observation contributes to the
estimation of the treatment effect.

The weight of each observation $i \in \{ 1,...,N\}$ is:

$$w_{i} = \frac{\left( x_{i} - {\mathbb{E}}\left\lbrack x_{i}|C_{i} \right\rbrack \right)^{2}}{\sum\limits_{j}w_{j}}$$
where $x$ is the variable of interest and $C$ the vector of controls and
fixed effects. These weights are therefore the normalized squared
residuals of the regression of $x$ on the full set of controls.

In the package, they are computed using the same estimation procedure as
the one used in the main regression, just replacing the outcome variable
with the dependent variable of interest. The following example
illustrates how the `idid_partial_out` function works on an example
model describing the relationship between median price and number of
housing sales in Texas:

``` r
library(ididvar)
library(ggplot2)
library(dplyr)
library(fixest)

reg_ex_fixest <- ggplot2::txhousing |>
  mutate(l_sales = log(sales)) |> 
  fixest::feols(fml = l_sales ~ median + listings | year + city, vcov = "twoway")

idid_partial_out(reg_ex_fixest, "median") |> 
  head()
#> [1]  4357.90243 -8317.76671 -8897.22065  1603.32003   308.18621   -99.38339

txhousing |> 
  feols(fml = median ~ listings | year + city, vcov = "twoway") |> 
  residuals() |> 
  head()
#> [1]  4357.90243 -8317.76671 -8897.22065  1603.32003   308.18621   -99.38339
```

## Group level weights

One can compute group level weights by summing the weights of
observations within that group. This allows for a quick computation and
interpretation of weights at higher aggregation levels. These
group-level weights correspond to the within-group variance of the
conditional treatment status.

In low weight groups, there is only a little amount of variation in the
dependent variable to estimate an effect. Considering an extreme case
gives a clear intuition: when using group level fixed effects, if there
is no variation in $x$ for that group, this group does not contribute to
the estimation of the parameter for $x$ at all. For instance, in the
previous example, if all prices are the same in a given city, it will
not be possible to estimate how variations in prices are related with
variation in sales in that city.

## What do they represent, really?

By definition, in the partialled out regression, these weights represent
the squared-distance to the center of the distribution of the variable
of interest, after partialling out the controls. The following example,
describing the relationship between x and y partialled out and the
weights illustrates this:

![](background_files/figure-html/bivar_partial-1.png)

While this pattern clearly appears in the partialled out regression, it
is much less visible when plotting the raw relationship, hence the
importance of analysing those weights and plotting the partialled out
regression:

![](background_files/figure-html/bivar_raw-1.png)
