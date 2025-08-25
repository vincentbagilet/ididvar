#' Visualization of Identifying Variation Weights
#'
#' @description
#' Makes a graph to visualize the identifying variation weights (a heatmap or
#' a bar chart, depending on the number of dimensions specified)
#'
#' @inheritParams idid_weights
#' @param var_x A variable in the data set used in \code{reg}.
#' @param var_y A variable in the data set used in \code{reg}. If not specified,
#' produces a bar chart.
#'
#' @returns
#' A ggplot2 graph of identifying variation weights.
#'
#' If var_y is specified, returns a heatmap whose color represents a
#' categorized version of the identifying variation weights (the categorization
#' prevents the vizualisation from being driven by extremely large weights).
#'
#' If var_y is not specified, returns a bar chart representing the weights in
#' each group.
#'
#' @export
idid_weights_viz <- function(reg,
                             var_interest,
                             var_x,
                             var_y,
                             keep_labels = TRUE) {
  df <- eval(reg$call$data)
  df[["weight"]] <- ididvar::idid_weights(reg, var_interest)

  if (missing(var_y)) {
    graph <- df |>
      ggplot2::ggplot(ggplot2::aes(x = {{ var_x }}, weight = weight)) +
      ggplot2::geom_bar(fill = "#1E383A") +
      ggplot2::labs(y = "Weight")
      # ggplot2::coord_flip()
  } else {
    # df[["bin"]] <- ididvar::idid_weights_cat(df[["weight"]])
    sum_df <-
      aggregate(
        df$weight,
        by = list(var_x_name = df[[substitute(var_x)]], var_y_name = df[[substitute(var_y)]]),
        FUN = sum
      )

    names(sum_df)[3] <- "weight"

    #if each group weighted the same, their weight would be 1/nrow(sum_df), ie
    #the average weight. I compare each weight to that average and then
    #take the log to avoid squeezing the scale.
    #I later also take the logs to define the breaks in the scale
    sum_df[["log_weight"]] <- log10(sum_df[["weight"]]  * nrow(sum_df))
    sum_df[["log_weight_trunc"]] <-
      ifelse(sum_df[["log_weight"]] < log10(1/50), -2,
        ifelse(sum_df[["log_weight"]] > log10(50), 2, sum_df[["log_weight"]]))

    graph <- sum_df |>
      ggplot2::ggplot(ggplot2::aes(
        x = var_x_name,
        y = var_y_name,
        fill = log_weight_trunc
        # label = round(weight, 3)
      )) +
      ggplot2::geom_tile() +
      # ggplot2::geom_text() +
      ggplot2::scale_fill_stepsn(
        colours = c("#19304d", "#3f5473", "#798cad", "#fae7d3", "#c3847e", "#a75254", "#84141e"),
        # breaks = 1:7,
        breaks = log10(c(1/100, 1/50, 1/10, 1/2, 2, 10, 50, 100)),
        labels = c("0", "1/50×","1/10×","1/2×","2×","10×", "50×", "Inf"),
        limits = c(-2, 2),
        na.value = "#0f1d2e"
      ) +
      ggplot2::labs(
        fill = "Weight, compared to the average weight",
        x = substitute(var_x),
        y = substitute(var_y)
      )
  }

  graph <- graph +
    ggplot2::labs(
      title = "Distribution of Identifying Variation Weights"
      # fill = "Identifying Variation Weights"
    ) +
    # theme and palette
    ididvar::theme_idid()
    # ggplot2::scale_fill_manual(
    #   # values = c("#1E383A", "#2B5558", "#62A89C", "#E5E0C6", "#DB8950", "#A13D27", "#612214")
    #   # values = c("#fbe2c5", "#e8a79e", "#b97588", "#885075", "#562a62", "#290737", "#210124"),
    #   values = c("#1D3557", "#3f5473", "#7d8593", "#fae7d3", "#c3847e", "#a75254", "#84141e")
    # )

  # if (!cross_section) graph <- graph + ggplot2::coord_fixed()

  # if (length(unique(data[[deparse(substitute(var_y))]])) > 60 & !keep_labels) {
  if (!keep_labels) {
    graph <- graph +
      ggplot2::labs(y = NULL) +
      ggplot2::theme(
        axis.text.y = ggplot2::element_blank(),
        axis.ticks.y = ggplot2::element_blank()
      )
  }

  return(graph)
}
