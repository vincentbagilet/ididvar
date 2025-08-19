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
idid_barchart <- function(reg,
                         var_interest,
                         var_1,
                         var_2,
                         keep_labels = TRUE) {
  df <- eval(reg$call$data)
  df[["weights"]] <- ididvar::idid_weights(reg, var_interest)

  cross_section <- missing(var_2)

  df[["bin"]] <-
    cut(
      log10(df[["weights"]] * nrow(df)),
      breaks = c(-Inf, -1.7, -1, -0.3, 0.3, 1, 1.7, Inf),
      labels =
        c("More than 50x smaller",
          "Between 10x and 50x smaller",
          "Between 2x and 10x smaller",
          "Between 2x smaller and 2x larger",
          "Between 2x and 10x larger",
          "Between 10x and 50x larger",
          "More than 50x larger"),
      include.lowest = TRUE
    )

  if (cross_section) {
    graph <- df |>
      ggplot2::ggplot(ggplot2::aes(x = {{ var_1 }}, fill = bin)) +
      ggplot2::geom_bar() +
      ggplot2::coord_flip()
  } else {
    graph <- df |>
      ggplot2::ggplot(ggplot2::aes(
        x = {{ var_1 }},
        y = {{ var_2 }},
        fill = bin)
      ) +
      ggplot2::geom_tile()
  }

  graph <- graph +
    ggplot2::labs(
      title = "Identifying Variation Weights",
      fill = "Identifying Variation Weights",
      y = NULL,
      x = NULL
    ) +
    # theme and palette
    ididvar::theme_idid() +
    ggplot2::scale_fill_manual(
      values = c("#1E383A", "#2B5558", "#62A89C", "#E5E0C6", "#DB8950", "#A13D27", "#612214")
    )

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
