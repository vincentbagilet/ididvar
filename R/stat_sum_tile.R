#' Automatic mean aggregation for tiles
#'
#' A ggplot2 Stat that sums the values provided in z for each tile
#'
#' @keywords internal
StatSumTile <- ggplot2::ggproto(
  "StatSumTile",
  ggplot2::Stat,
  required_aes = c("x", "y", "z"),
  default_aes = ggplot2::aes(fill = ggplot2::after_stat(n_contrib)),
  compute_panel = function(data, scales, ...) {
    agg <-
      stats::aggregate(data$z, list(x = data$x, y = data$y), sum, na.rm = TRUE)
    names(agg)[3] <- "n_contrib"

    return(agg)
  }
)
