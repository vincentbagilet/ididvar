#' Heatmap of Identifying Variation Weights
#'
#' @description
#' Makes a heatmap to visualize the identifying variation weights
#'
#' @param data A regression object.
#' @param weights_vect A single string. Optional.
#' @param indiv_name One of the columns in `reg$model`,
#' representing the individual dimension
#' @param time_name One of the columns in `reg$model`,
#' representing the time dimension (if have a panel). Optional.
#'
#' @returns
#' An invisibly returned object using ggplot2. The function will error if
#' any of the provided variables are unavailable in `reg$model`.
#' @export
idid_heatmap <- function(data,
                         var_weight,
                         var_1,
                         var_2,
                         keep_labels = TRUE) {
  cross_section <- missing(var_2)

  graph <- data |>
    ggplot2::ggplot(ggplot2::aes(
      x = {{ var_1 }},
      y = if(cross_section) 1 else {{ var_2 }},
      fill = {{ var_weight }})
    ) +
    ggplot2::geom_tile() +
    ggplot2::labs(
      title = "Identifying Variation Weights",
      fill = "Identifying Variation Weights",
      y = NULL,
      x = NULL
    ) +
    # theme
    ggplot2::theme_minimal() +
    ggplot2::theme(
      # text = ggplot2::element_text(family = "mono"),
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
    ) +
    #palette
    ggplot2::scale_fill_gradientn(colors = c("#FBE2C5", "#d46c76", "#3e196e"))
    # ggplot2::scale_fill_gradientn(colors = c("#FAF7F5", "#CDC6CC", "#041258"))
    # ggplot2::scale_fill_gradientn(colors = c("#FEF5EC", "#E14144", "#041258"))


  # if (!cross_section) graph <- graph + ggplot2::coord_fixed()

  # if (length(unique(data[[deparse(substitute(var_2))]])) > 60 & !keep_labels) {
  if (!keep_labels) {
    graph <- graph +
      ggplot2::theme(
        axis.text.y = ggplot2::element_blank(),
        axis.ticks.y = ggplot2::element_blank()
      )
  }


  return(graph)
}
