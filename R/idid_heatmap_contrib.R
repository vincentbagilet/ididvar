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
idid_heatmap_contrib <- function(reg,
                                 var_interest,
                                 threshold_diff = 0.05,
                                 var_1,
                                 var_2,
                                 keep_labels = TRUE) {
  df <- eval(reg$call$data)
  df[["weights"]] <- ididvar::idid_weights(reg, var_interest)
  cross_section <- missing(var_2)

  #compute the prop of obs to keep/drop without changing the estimates
  #by more than threshold_diff
  small_diff <- TRUE
  prop_keep <- 1
  while (small_diff) {
    prop_keep <- prop_keep - 0.01
    small_diff <- ididvar::idid_drop_change(reg, var_interest, prop_keep = prop_keep, threshold_diff = threshold_diff)$small_diff
  }

  weight_threshold <- df[[floor(prop_keep*nrow(df)), "weights"]]

  message(paste("The weight threshold is", round(weight_threshold, 4)))

  df[["contrib"]] <- (df[["weights"]] < weight_threshold)
  df[["contrib_name"]] <- ifelse(df[["contrib"]], "Contributing", "Non-contributing")

  # make plot
  graph <- df |>
    ggplot2::ggplot(ggplot2::aes(
      x = {{ var_1 }},
      y = if(cross_section) 1 else {{ var_2 }},
      fill = contrib_name)
    ) +
    ggplot2::geom_tile() +
    ggplot2::labs(
      title = 'Observations "containing enough variation" for identification',
      subtitle = paste('Without the "non-contributing" observations, point estimate and s.e. would vary by less than ', round(threshold_diff*100, 2), "%", sep = ""),
      fill = NULL,
      y = NULL,
      x = NULL
    ) +
    # theme and palette
    ididvar::theme_idid() +
    ggplot2::scale_fill_manual(
      values = c("#1C6669", "#E5C38A")
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
