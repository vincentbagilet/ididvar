#' Visualization of observations contributing (or not) to estimation
#'
#' @description
#' Make a graph to visualize observations that can be dropped without
#' changing the point estimate or the standard error of the estimate of
#' interest by more than a given proportion (\code{threshold_change}).
#'
#' Makes a heatmap or a bar chart, depending on the number of dimensions
#' specified.
#'
#' @inheritParams idid_viz_weights
#' @inheritParams idid_contrib_threshold
#' @param contrib_threshold A numeric (optional). Weight below which
#' observations are deemed to be non-contributing.
#' If not provided, will be determined by running
#' \code{ididvar::idid_contrib_threshold}
#'
#' @returns
#' A ggplot2 graph of observations contributing to estimation.
#'
#' If var_y is specified, returns a heatmap whose color describes whether a
#' given observation does not contribute (i.e. can be dropped, along with all
#' lower weight observations, without substantially altering the estimate)
#'
#' If var_y is not specified, returns a bar chart representing the number of
#' observations that can be dropped in each group.
#'
#' @export
#'
#' @examples
#' reg_ex <- ggplot2::txhousing |>
#'   lm(formula = volume ~ sales + listings + city + as.factor(date))
#'
#' idid_viz_contrib(reg_ex, "sales", date, city) +
#'   ggplot2::labs(x = NULL, y = NULL)
#'
#' idid_viz_contrib(reg_ex, "sales", city) +
#'   ggplot2::labs(x = NULL) +
#'   ggplot2::coord_flip()
idid_viz_contrib <- function(reg,
                             var_interest,
                             var_x,
                             var_y,
                             contrib_threshold,
                             threshold_change = 0.05,
                             keep_labels = TRUE,
                             ...) {

  if (missing(contrib_threshold)) {
    message("Searching for the contribution threshold")
    contrib_threshold <- ididvar::idid_contrib_threshold(
      reg,
      var_interest,
      threshold_change = threshold_change,
      ...
    )
  }

  df <- eval(reg$call$data)
  df[["weights"]] <- ididvar::idid_weights(reg, var_interest, ...)
  df[["contrib"]] <- (df[["weights"]] > contrib_threshold)
  df[["contrib_name"]] <-
    ifelse(df[["contrib"]],
           "In the effective sample",
           "Outside the effective sample")

  if (missing(var_y)) {
    graph <- df |>
      ggplot2::ggplot(ggplot2::aes(x = {{ var_x }}, fill = contrib_name)) +
      ggplot2::geom_bar(position = ggplot2::position_stack(reverse = TRUE)) +
      # ggplot2::coord_flip() +
      ggplot2::labs(y = "Number of observations")
  } else {
    graph <- df |>
      ggplot2::ggplot(ggplot2::aes(
        x = {{ var_x }},
        y = {{ var_y }},
        fill = contrib_name)
      ) +
      ggplot2::geom_tile()
  }

  graph <- graph +
    ggplot2::labs(
      title = "Set of observations contributing to identification",
      subtitle =
        paste(
          'Removing observations outside the "effective sample"
would change the point estimate and s.e. by less than ',
          round(threshold_change*100, 2),
          "%",
          sep = ""
        ),
      fill = NULL
    ) +
    # theme and palette
    ididvar::theme_idid() +
    ggplot2::scale_fill_manual(
      values = c("#562A62", "#E79232"),
      na.value = "gray88"
    )

  if (!keep_labels) {
    graph <- graph +
      ggplot2::theme(
        axis.text.y = ggplot2::element_blank(),
        axis.ticks.y = ggplot2::element_blank()
      )
  }

  return(graph)
}
