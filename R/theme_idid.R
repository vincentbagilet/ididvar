#' Create a theme with minimal background and a customized legend
#'
#' @description
#' A function to return a custom ggplot2 theme.
#'
#' @param None
#'
#' @importFrom ggplot2 %+replace%
#'
#' @returns
#' The specified `theme` object. This will error invisibly if used incorrectly.
#'
#' @export
theme_idid <- function() {
  ggplot2::theme_minimal() %+replace%
    ggplot2::theme(
      # text = ggplot2::element_text(family = "lato"),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      #legend
      legend.position = "top",
      legend.direction = "horizontal",
      legend.justification = c(0, 0),
      legend.location = "plot",
      legend.key.height = ggplot2::unit(0.23, "cm"),
      legend.key.width = ggplot2::unit(1.3, "cm"),
      legend.title = ggplot2::element_text(size = ggplot2::rel(0.88)),
      legend.title.position = "top",
      legend.text = ggplot2::element_text(size = ggplot2::rel(0.78)),
      plot.title.position = "plot",
      strip.placement = "outside",
      strip.text = ggplot2::element_text(
        size = ggplot2::rel(0.95),
        face = "bold"
      ),
      strip.text.x = ggplot2::element_text(
        hjust = 0,
        margin = ggplot2::margin(b = .3, unit = "cm")
      ),
      strip.text.y = ggplot2::element_text(hjust = 0.95),
      panel.spacing.y = ggplot2::unit(1.8, "lines"),
      panel.spacing.x = ggplot2::unit(1.3, "lines")
    )
  # ggplot2::scale_fill_gradientn(colors = c("#FBE2C5", "#d46c76", "#3e196e"))
  # ggplot2::scale_fill_gradientn(colors = c("#FAF7F5", "#CDC6CC", "#041258"))
  # ggplot2::scale_fill_gradientn(colors = c("#FEF5EC", "#E14144", "#041258"))

}
