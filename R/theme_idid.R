#' Create a custom theme for \code{ididvar} visualizations
#'
#' @description
#' A function to return a custom ggplot2 theme.
#'
#' @importFrom ggplot2 %+replace%
#' @param ... Additional arguments to be passed to the \code{theme} function
#'
#' @returns
#' The specified `theme` object.
#'
#' @export
#'
#' @examples
#' ggplot2::mpg |>
#'   ggplot2::ggplot(ggplot2::aes(x = displ, hwy, color = cyl)) +
#'   ggplot2::geom_point() +
#'   ggplot2::labs(
#'     title = "A wonderful title",
#'     subtitle = "Something to add"
#'   ) +
#'   theme_idid()
theme_idid <- function(...) {
  ggplot2::theme_minimal(
    base_family = c("Helvetica")
  ) %+replace%
    ggplot2::theme(
      plot.margin = ggplot2::unit(c(0.5, 0.5, 0.5, 0.5), "cm"),
      plot.title = ggplot2::element_text(
        face = "bold",
        hjust = 0,
        size = ggplot2::rel(1.6),
        margin = ggplot2::margin(b = 8)
      ),
      plot.title.position = "plot",
      plot.subtitle = ggplot2::element_text(
        hjust = 0,
        size = ggplot2::rel(1.1),
        margin = ggplot2::margin(b = 8)
      ),
      plot.caption = ggplot2::element_text(hjust = 0, size = ggplot2::rel(0.8)),
      # text = ggplot2::element_text(family = "lato"),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text = ggplot2::element_text(size = ggplot2::rel(0.9)),
      axis.title.x = ggplot2::element_text(
        hjust = 0.98,
        margin = ggplot2::margin(t = .35, unit = "cm"),
        size = ggplot2::rel(1.2)
      ),
      axis.title.y = ggplot2::element_text(
        hjust = 0.98,
        margin = ggplot2::margin(r = .35, unit = "cm"),
        size = ggplot2::rel(1.2),
        angle = 90
      ),
      #legend
      legend.position = "top",
      legend.direction = "horizontal",
      legend.justification = c("left", "top"),
      legend.location = "plot",
      legend.margin = ggplot2::margin(t = -1, b = 8),
      legend.key.spacing.y = ggplot2::unit(0.01, "cm"),
      legend.key.height = ggplot2::unit(0.25, "cm"),
      legend.key.width = ggplot2::unit(1.3, "cm"),
      legend.title = ggplot2::element_text(size = ggplot2::rel(1.1)),
      legend.title.position = "top",
      legend.text = ggplot2::element_text(size = ggplot2::rel(0.9)),
      strip.placement = "outside",
      strip.text = ggplot2::element_text(
        size = ggplot2::rel(1.2),
        face = "bold"
      ),
      strip.text.x = ggplot2::element_text(
        hjust = 0,
        margin = ggplot2::margin(b = .3, t = 0.4, unit = "cm")
      ),
      panel.spacing.y = ggplot2::unit(1.8, "lines"),
      panel.spacing.x = ggplot2::unit(1.3, "lines"),
      ...
    )
}
