#' Visualization of the cumulative distribution of weights
#'
#' @param weights A numeric vector (e.g., weights or probabilities).
#' @param prop_weights Optional. One of `0`, `1`, or values in-between. The contribution threshold above which to display contributions ("tail") individually.
#'
#' @returns
#' An idiD Lörentz plot
#'
#' @export
idid_viz_cumul <- function(weights, prop_weights = 0.25) {
  weights_sorted <- sort(weights)
  cum_sum <- cumsum(weights_sorted)
  lorenz <- cum_sum/max(cum_sum)

  df <- data.frame(obs_nb = 1:length(lorenz), lorenz)

  df_contrib <- subset(df, lorenz > prop_weights)
  n_contrib <- nrow(df) - df_contrib[[1, "obs_nb"]]
  prop_contrib <- n_contrib/nrow(df)

  df |>
    ggplot2::ggplot(ggplot2::aes(x = obs_nb, y = lorenz)) +
    ggplot2::geom_line(linewidth = 1.2, color = "#300D49") +
    ggplot2::geom_segment(
      ggplot2::aes(x = 0, y = 0, xend = nrow(df), yend = 1),
      linetype = "dashed",
      linewidth = 0.2,
      color = "#300D49"
    ) +
    ididvar::theme_idid() +
    ggplot2::labs(
      title = "Lorenz curve of weights",
      subtitle = paste0(n_contrib, " observations (", round(prop_contrib, 3)*100, "%) account for ", (1 - prop_weights)*100, "% of the weights"),
      x = "Observation index",
      y = "Cummulative sum of weights"
    )
}
