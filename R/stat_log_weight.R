#' StatLogWeight: automatic aggregation and log-transform for tiles
#'
#' A ggplot2 Stat that behaves like stat_summary_2d but automatically:
#'   1. Sums z-values per (x, y)
#'   2. Applies the transformation log10(sum(z) * n_x * n_y)
#'
#'    summarise the weights by var_x*vary_y groups (summing their values),
#'    take the ratio of the weight of each group over
#'    the average weight across groups (1/(n_x*n_y)) and then takes its log10
#'
#' @keywords internal
StatLogWeight <- ggplot2::ggproto("StatLogWeight", ggplot2::Stat,
  required_aes = c("x", "y", "z"),
  default_aes = ggplot2::aes(fill = ggplot2::after_stat(fill)),
  compute_panel = function(data, scales, ...) {
    # unique x and y values
    x_vals <- unique(data$x)
    y_vals <- unique(data$y)
    n_cat_x <- length(x_vals)
    n_cat_y <- length(y_vals)

    # aggregate z by (x, y)
    agg <- stats::aggregate(
      data$z,
      by = list(x = data$x, y = data$y),
      FUN = \(z) sum(z, na.rm = TRUE)
    )
    names(agg)[3] <- "weight"

    # full_grid <- expand.grid(x = x_vals, y = y_vals)
    # merged <- merge(full_grid, agg, by = c("x", "y"), all.x = TRUE)
    # merged$z_sum[is.na(merged$z_sum)] <- 0
    # merged$fill <- log10(merged$z_sum * n_cat_x * n_cat_y)

    agg$fill <- log10(agg$weight * n_cat_x * n_cat_y)

    agg
  }
)
