#' Visualization of Identifying Variation Weights
#'
#' @description
#' Makes a graph to visualize the identifying variation weights (a heatmap or
#' a bar chart, depending on the number of dimensions specified)
#'
#' @details
#' If there is more than on observation by group (i.e. for one category in
#' var_x or in var_x x var_y), individual weights are added for that group,
#' removing missing values.
#'
#' @inheritParams idid_weights
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
                             keep_labels = TRUE,
                             ...) {
  df <- eval(reg$call$data)
  df[["weight"]] <- ididvar::idid_weights(reg, var_interest, ...)
  # df <- df[!is.na(df$weight), ]

  if (missing(var_y)) {
    graph <- df |>
      ggplot2::ggplot(ggplot2::aes(x = {{ var_x }}, weight = weight)) +
      ggplot2::geom_bar(fill = "#1E383A") +
      ggplot2::labs(y = "Weight")
      # ggplot2::coord_flip()
  } else {
    # df[["bin"]] <- ididvar::idid_weights_cat(df[["weight"]])
    sum_df <-
      stats::aggregate(
        df$weight,
        by = list(var_x_name = df[[substitute(var_x)]],
                  var_y_name = df[[substitute(var_y)]]),
        FUN = sum,
        na.rm = TRUE
      )

    names(sum_df)[3] <- "weight"

    #if each group weighted the same, their weight would be 1/nrow(sum_df), ie
    #the average weight. I compare each weight to that average and then
    #take the log to avoid squeezing the scale.
    #I later also take the logs to define the breaks in the scale
    sum_df[["log_weight"]] <- log10(sum_df[["weight"]]  * nrow(sum_df))
    # sum_df[["log_weight_trunc"]] <-
    #   ifelse(sum_df[["log_weight"]] < log10(1/50), -2,
    #     ifelse(sum_df[["log_weight"]] > log10(50), 2, sum_df[["log_weight"]]))

    graph <- sum_df |>
      ggplot2::ggplot(ggplot2::aes(
        x = var_x_name,
        y = var_y_name,
        fill = log_weight
        # label = round(weight, 3)
      )) +
      ggplot2::geom_tile() +
      # ggplot2::geom_text() +
      ididvar::scale_fill_idid() +
      ggplot2::labs(
        fill = "Weight, compared to the average weight",
        x = substitute(var_x),
        y = substitute(var_y)
      )
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
