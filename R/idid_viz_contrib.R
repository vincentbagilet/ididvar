#' Compute heatmap contribution weights
#'
#' @description Create a heatmap showing which observations contribute to the identification of certain variables.
#'
#' @inheritParams idid_viz_weights
#' @param threshold_diff (Optional) A numeric value between 0 and 1 representing the maximum proportion of data points that can be removed before we suspect that our estimate is changing more than by a `threshold_diff` percentage.
#'
#' @returns
#' A ggplot object representing contribution heatmap. The function will print a warning message if `threshold_diff` is too low and not enough data would remain by dropping non-contributing cases.
#' @export
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
  df[["weights"]] <- ididvar::idid_weights(reg, var_interest)
  df[["contrib"]] <- (df[["weights"]] > contrib_threshold)
  df[["contrib_name"]] <- ifelse(df[["contrib"]], "Contributes", "Does not contribute")

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
