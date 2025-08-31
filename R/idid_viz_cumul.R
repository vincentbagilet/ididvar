#' Visualization of the cumulative distribution of weights
#'
#' @param weights A numeric vector of weights
#' @param prop_weights A numeric (between 0 and 1). A proportion of weights
#' that to consider as contributing the most to identification.
#' Used to build the subtitle.
#'
#' @returns
#' A ggplot2 graph of the cumulative distribution of weights.
#'
#' @export
#'
#' @examples
#' reg_ex <- ggplot2::txhousing |>
#'   lm(formula = volume ~ sales + listings + city + as.factor(date))
#'
#' idid_weights(reg_ex, "sales") |>
#'   idid_viz_cumul()
idid_viz_cumul <- function(weights, prop_weights = 0.2) {
  weights_sorted <- sort(weights)
  cum_sum <- cumsum(weights_sorted)
  lorenz <- cum_sum/max(cum_sum)

  df <- data.frame(obs_nb = 1:length(lorenz), lorenz)

  df_contrib <- subset(df, lorenz > prop_weights)
  n_contrib <- nrow(df) - df_contrib[[1, "obs_nb"]]
  prop_contrib <- n_contrib/nrow(df)

  df |>
    ggplot2::ggplot(ggplot2::aes(x = obs_nb, y = lorenz)) +
    ggplot2::geom_line(linewidth = 1.4, color = "#300D49") +
    ggplot2::geom_area(fill = "#300D49", alpha = 0.2) +
    ggplot2::annotate(
      geom = "segment",
      x = 0, y = 0, xend = nrow(df), yend = 1,
      linetype = "dashed",
      linewidth = 0.5,
      color = "#300D49"
    ) +
    ididvar::theme_idid(aspect.ratio = 1) +
    #the next chunck is optional
    ggplot2::theme(
      axis.title.y = ggplot2::element_text(
        vjust = 1,
        margin = ggplot2::margin(r = -4.9, unit = "cm"),
        size = ggplot2::rel(1),
        angle = 0
      ),
      axis.title.x = ggplot2::element_text(size = ggplot2::rel(1)),
      plot.subtitle = ggplot2::element_text(
        margin = ggplot2::margin(b = 0.6, unit = "cm"))
    ) +
    ggplot2::labs(
      title = "Cumulative distribution of weights",
      subtitle = paste0(round(prop_contrib, 3)*100, "% of the observations (",
                        n_contrib,  " obs.) account for ",
                        (1 - prop_weights)*100, "% of the weights"),
      x = "Observation index\n(smallest to largest weight)",
      y = "Cummulative sum of weights"
    )
}
