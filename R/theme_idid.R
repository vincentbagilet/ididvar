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
  ggplot2::theme_minimal(base_family = "Helvetica") %+replace%
    ggplot2::theme(
      plot.margin = ggplot2::unit(c(0.5, 0.5, 0.5, 0.5), "cm"),
      plot.title = ggplot2::element_text(face = "bold", hjust = 0, size = ggplot2::rel(1.4)),
      plot.subtitle = ggplot2::element_text(
        hjust = 0,
        size = ggplot2::rel(1.1),
        margin = ggplot2::margin(t = 5)
      ),
      plot.caption = ggplot2::element_text(hjust = 0, size = ggplot2::rel(0.8)),
      # text = ggplot2::element_text(family = "lato"),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text = ggplot2::element_text(size = ggplot2::rel(0.75)),
      axis.title.x = ggplot2::element_text(
        hjust = 0.97,
        margin = ggplot2::margin(t = .35, unit = "cm"),
        size = ggplot2::rel(1.2)
      ),
      axis.title.y = ggplot2::element_text(
        hjust = 0.97,
        margin = ggplot2::margin(r = .35, unit = "cm"),
        size = ggplot2::rel(1.2),
        angle = 90
      ),
      #legend
      legend.position = "top",
      legend.direction = "horizontal",
      legend.justification = c("left", "top"),
      legend.location = "plot",
      legend.margin = ggplot2::margin(t = 0.4, unit = "cm"),
      legend.key.spacing.y = ggplot2::unit(0.01, "cm"),
      legend.key.height = ggplot2::unit(0.23, "cm"),
      legend.key.width = ggplot2::unit(1.3, "cm"),
      legend.title = ggplot2::element_text(size = ggplot2::rel(0.95)),
      legend.title.position = "top",
      legend.text = ggplot2::element_text(size = ggplot2::rel(0.85)),
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
