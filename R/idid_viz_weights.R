#' Visualization of Identifying Variation Weights
#'
#' @description
#' Makes a graph to visualize the identifying variation weights (a heatmap or
#' a bar chart, depending on the number of dimensions specified)
#'
#' @details
#' If there is more than on observation by group (i.e. for one category in
#' var_x or in var_x x var_y), the weight of the group is computed by summing
#' individual weights in that group, removing missing values.
#'
#' @inheritParams idid_weights
#' @inheritParams scale_fill_idid
#' @param var_x A variable in the data set used in \code{reg} to plot on the
#' x-axis.
#' @param var_y A variable in the data set used in \code{reg} to plot on the
#' y-axis (optional). If not specified, produces a bar chart.
#' @param order A string (either "x", "y" or "xy") describing whether the
#' graph should be order, along the x or y axis or both.
#' If anything else is specified, no specific ordering will be applied.
#' @param keep_labels A boolean (optional). If FALSE, removes y labels and ticks.
#' This option is useful for panels with a large number of individuals.
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
#'
#' @examples
#' # example one dimension
#' reg_ex_one_dim <- ggplot2::economics |>
#'   transform(year = substr(date, 1, 4) |> as.numeric()) |>
#'   lm(formula = unemploy ~ pce + uempmed + psavert + pop + year)
#'
#' idid_viz_weights(reg_ex_one_dim, "pce", var_x = year) +
#'   ggplot2::labs(x = NULL)
#'
#' # example with two dimensions
#' reg_ex_two_dim <- ggplot2::txhousing |>
#'   lm(formula = log(sales) ~ median + listings + as.factor(date) + city)
#'
#' idid_viz_weights(reg_ex_two_dim, "median", year, city, order = "y") +
#'   ggplot2::labs(x = NULL, y = NULL)
#'
idid_viz_weights <- function(reg,
                             var_interest,
                             var_x,
                             var_y,
                             order = "",
                             colors = c("#C25807", "#FBE2C5", "#300D49"),
                             keep_labels = TRUE,
                             ...) {
  df <- eval(reg$call$data, envir = environment(stats::formula(reg)))
  df[["idid_weight"]] <- ididvar::idid_weights(reg, var_interest, ...)
  df <- order_axes(df,
                   deparse(substitute(var_x)),
                   deparse(substitute(var_y)),
                   order,
                   by = "idid_weight")

  #GRAPHS
  if (missing(var_y)) {

    graph <- df |>
      ggplot2::ggplot(ggplot2::aes(x = {{ var_x }}, weight = .data$idid_weight)) +
      ggplot2::geom_bar(fill = colors[length(colors)]) +
      ggplot2::labs(y = "Weight")

  } else if (missing(var_x)) {

    graph <- df |>
      ggplot2::ggplot(ggplot2::aes(y = {{ var_y }}, weight = .data$idid_weight)) +
      ggplot2::geom_bar(fill = colors[length(colors)]) +
      ggplot2::labs(x = "Weight")

  } else {

    n_cat_x <- unique(df[[deparse(substitute(var_x))]]) |> length()
    n_cat_y <- unique(df[[deparse(substitute(var_y))]]) |> length()
    df[["idid_weight_scaled"]] <- df[["idid_weight"]] * n_cat_x * n_cat_y

    graph <- df |>
      ggplot2::ggplot(ggplot2::aes(
        x = {{ var_x }},
        y = {{ var_y }},
        z = .data$idid_weight_scaled
      )) +
      ggplot2::geom_tile(stat = StatLogWeight) +
      ididvar::scale_fill_idid(colors = colors) +
      ggplot2::labs(fill = "Weight, compared to 1/n, the average weight")
  }

  graph <- graph +
    ggplot2::labs(title = "Distribution of Identifying Variation Weights") +
    ididvar::theme_idid()

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
