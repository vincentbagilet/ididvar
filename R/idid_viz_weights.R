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
#' @param keep_labels A boolean (optional). If FALSE, remove y labels and ticks.
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
#' # example with a lm regression and one dimension
#' reg_ex_lm <- ggplot2::economics |>
#'   transform(year = substr(date, 1, 4) |> as.numeric()) |>
#'   lm(formula = unemploy ~ pce + uempmed + psavert + pop + year)
#'
#' idid_viz_weights(reg_ex_lm, "pce", var_x = year) +
#'   ggplot2::labs(x = NULL)
#'
#' # example with a fixest regression and two dimensions
#' reg_ex_fixest <- ggplot2::txhousing |>
#'   fixest::feols(fml = volume ~ sales + listings |  as.factor(date) + city)
#'
#' idid_viz_weights(reg_ex_fixest, "sales", date, city) +
#'   ggplot2::labs(x = NULL, y = NULL)
idid_viz_weights <- function(reg,
                             var_interest,
                             var_x,
                             var_y,
                             colors = c("#C25807", "#FBE2C5", "#300D49"),
                             keep_labels = TRUE,
                             ...) {
  df <- eval(reg$call$data)
  df[["weight"]] <- ididvar::idid_weights(reg, var_interest, ...)

  if (missing(var_y)) {
    graph <- df |>
      ggplot2::ggplot(ggplot2::aes(x = {{ var_x }}, weight = weight)) +
      ggplot2::geom_bar(fill = colors[length(colors)]) +
      ggplot2::labs(y = "Weight")
  } else {

    name_var_x <- deparse(substitute(var_x))
    name_var_y <- deparse(substitute(var_y))
    n_cat_x <- unique(df[[name_var_x]]) |> length()
    n_cat_y <- unique(df[[name_var_y]]) |> length()
    # if (n_cat_x < 5) df[[name_var_x]] <- as.factor(df[[name_var_x]])
    # if (n_cat_y < 10) df[[name_var_y]] <- as.factor(df[[name_var_y]])

    graph <- df |>
      ggplot2::ggplot(ggplot2::aes(
        x = {{ var_x }},
        y = {{ var_y }},
        z = weight
        # label = round(weight, 3)
      )) +
      #summarise the weights by var_x*vary_y groups (summing their values),
      #take the ratio of the weight of each group over
      #the average weight across groups (1/(n_x*n_y)) and then takes its log10
      ggplot2::stat_summary_2d(
        fun = \(x) log10(sum(x, na.rm = TRUE)*n_cat_x*n_cat_y),
        bins = c(n_cat_x, n_cat_y),
        drop = FALSE
      ) +
      #break the log10 values into categories
      ididvar::scale_fill_idid(colors = colors) +
      ggplot2::labs(fill = "Weight, compared to 1/n, the average weight")
  }

  graph <- graph +
    ggplot2::labs(
      title = "Distribution of Identifying Variation Weights"
    ) +
    # theme and palette
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
