#' Compute heatmap contribution weights
#'
#' @description Create a heatmap showing which observations contribute to the identification of certain variables.
#'
#' @param reg A regression object created from `ididvar::create_regression()` function.
#' @param var_interest The variable that we are identifying using the idid method. This is typically one of the dependent variables in the regression.
#' @param threshold_diff (Optional) A numeric value between 0 and 1 representing the maximum proportion of data points that can be removed before we suspect that our estimate is changing more than by a `threshold_diff` percentage.
#' @param var_1 The first variable shown on the x-axis. This argument represents a set of characteristics for "all" observations in an area.
#' @param var_2 (Optional) A second binary or continuous variable to be shown on the y-axis, with values indicating the number of times each value appears within `var_interest`.
#' @param keep_labels (Optional) If this is set to TRUE, we will include labels for all relevant areas; otherwise we only display a plot.
#'
#' @returns
#' A ggplot object representing contribution heatmap. The function will print a warning message if `threshold_diff` is too low and not enough data would remain by dropping non-contributing cases.
#' @export
idid_contrib_viz <- function(reg,
                             var_interest,
                             var_1,
                             var_2,
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
  df[["weights"]] <- ididvar::idid_weights(reg, var_interest)
  df[["contrib"]] <- (df[["weights"]] > contrib_threshold)
  df[["contrib_name"]] <- ifelse(df[["contrib"]], "Contributing", "Non-contributing")

  if (missing(var_2)) {
    graph <- df |>
      ggplot2::ggplot(ggplot2::aes(x = {{ var_1 }}, fill = contrib_name)) +
      ggplot2::geom_bar() +
      ggplot2::coord_flip() +
      ggplot2::labs(y = "Number of observations")
  } else {
    graph <- df |>
      ggplot2::ggplot(ggplot2::aes(
        x = {{ var_1 }},
        y = {{ var_2 }},
        fill = contrib_name)
      ) +
      ggplot2::geom_tile()
  }

  graph <- graph +
    ggplot2::labs(
      title = "Set of observations contributing to identification",
      subtitle = paste('Without the "non-contributing" observations, point estimate and s.e. would vary by less than ', round(threshold_change*100, 2), "%", sep = ""),
      fill = NULL
    ) +
    # theme and palette
    ididvar::theme_idid() +
    ggplot2::scale_fill_manual(
      values = c("#1C6669", "#E5C38A")
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
