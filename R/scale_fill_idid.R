#' Create a custom color scale for \code{ididvar} visualizations
#'
#' @description
#' A function that makes a custom color scale and ensures that breaks in terms
#' of weight size (relative to the average) are consistent across users.
#'
#' This scale has fixed limits and even if there are no very small or very
#' large weights, the scale remains the same and some color do not appear on
#' the graph (see the second example graph). Note that the labels of the scale
#' are specific to ididvar application and built with weights whose sum equals
#' 1 in mind (and thus whose average is equal to 1/n_obs).
#'
#' @param colors A string vector of colors for the palette.
#' I recommend to pass a vector of 3 distinct colors, with a lighter color in
#' the middle, constituting a diverging scale. It allows a clear distinction
#' between contributing and non contributing observations.
#' @param ... Additional arguments to be passed to the
#' \code{ggplot2::scale_fill_stepsn} or  \code{ggplot2::scale_color_stepsn}
#' function
#'
#' @export
#'
#' @examples
#' reg_ex_fixest <- ggplot2::txhousing |>
#'   fixest::feols(fml = log(sales) ~ median + listings |  as.factor(date) + city)
#'
#' idid_viz_weights(reg_ex_fixest, "median", year, city) +
#'   ggplot2::labs(x = NULL, y = NULL) +
#'   scale_fill_idid(colors = c("#19304d", "#fae7d3", "#84141e"))
#'
#' ggplot2::mpg |>
#'   ggplot2::ggplot(ggplot2::aes(x = displ, hwy, color = cyl)) +
#'   ggplot2::geom_point() +
#'   ggplot2::labs(
#'     title = "The scale has fixed limits",
#'     subtitle = "This scale is built for values between 0 and 1",
#'     color = "Value, as compared to 1/n_obs"
#'   ) +
#'   theme_idid() +
#'   scale_color_idid()
scale_fill_idid <- function(colors = c("#C25807", "#FBE2C5", "#300D49"),
                            ...) {
  ggplot2::scale_fill_stepsn(
    colors = colors,
    breaks = log10(c(1/100, 1/50, 1/10, 1/2, 2, 10, 50, 100)),
    labels = c("0", "1/50x", "1/10x", "1/2x", "2x", "10x", "50x", "Inf"),
    limits = c(-2, 2),
    na.value = "gray88",
    ...
  )
}

#' @export
#' @rdname scale_fill_idid
scale_color_idid <- function(colors = c("#C25807", "#FBE2C5", "#300D49"),
                                   ...) {
  ggplot2::scale_color_stepsn(
    colors = colors,
    breaks = log10(c(1/100, 1/50, 1/10, 1/2, 2, 10, 50, 100)),
    labels = c("0", "1/50x", "1/10x", "1/2x", "2x", "10x", "50x", "Inf"),
    limits = c(-2, 2),
    na.value = "gray70",
    ...
  )
}
