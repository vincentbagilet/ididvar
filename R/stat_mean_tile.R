#' Automatic mean aggregation for tiles
#'
#' A ggplot2 Stat that behaves like stat_summary_2d but automatically:
#'   1. Sums fill-values per (x, y)
#'   2. Applies the transformation log10(sum(z) * n_x * n_y)
#'
#'    summarise the weights by var_x*vary_y groups (summing their values),
#'    take the ratio of the weight of each group over
#'    the average weight across groups (1/(n_x*n_y)) and then takes its log10
#'
#' @keywords internal
StatMeanTile <- ggplot2::ggproto(
  "StatMeanTile",
  ggplot2::Stat,
  required_aes = c("x", "y", "z"),
  default_aes = ggplot2::aes(fill = ggplot2::after_stat(share_contrib)),
  compute_panel = function(data, scales, ...) {
    agg <-
      stats::aggregate(data$z, list(x = data$x, y = data$y), mean, na.rm = TRUE)
    names(agg)[3] <- "share_contrib"

    return(agg)
  }
)
