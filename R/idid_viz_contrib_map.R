#' Plot a map of the effective sample
#'
#' @description
#' Makes a map to visualize observations that can be dropped without
#' changing the point estimate or the standard error of the estimate of
#' interest by more than a given proportion (\code{threshold_change}).
#'
#'
#' @inheritParams idid_viz_weights_map
#' @inheritParams idid_viz_contrib
#'
#' @returns
#' A ggplot object.
#'
#' @export
#'
#' @examples
#' reg <- state.x77 |>
#'   dplyr::as_tibble() |>
#'   dplyr::mutate(NAME = rownames(state.x77)) |>
#'   lm(formula = Illiteracy ~  Income + Population + `Life Exp` + Frost)
#'
#' states_sf <- tigris::states(
#'     cb = TRUE, resolution = "20m", year = 2024, progress_bar = FALSE) |>
#'   tigris::shift_geometry()
#'
#' idid_viz_contrib_map(reg, "Income", states_sf, "NAME")
idid_viz_contrib_map <- function(reg,
                                 var_interest,
                                 shape_file,
                                 join_by,
                                 colors = c("#C25807", "#FBE2C5", "#300D49"),
                                 ...) {
  df <- eval(reg$call$data)
  df[["weight"]] <- ididvar::idid_weights(reg, var_interest)

  #compute shape level weights
  aggr_df <- stats::aggregate(
    df$weight,
    by = list(join_by = df[[join_by]]),
    FUN = sum,
    na.rm = TRUE
  )
  names(aggr_df) <- c(join_by, "weight")

  #merge with shapefile
  merged <- base::merge(shape_file, aggr_df, by = join_by, all = TRUE)
  merged[["weight_log"]] <- log10(merged$weight * nrow(merged))

  merged |>
    ggplot2::ggplot() +
    ggplot2::geom_sf(
      ggplot2::aes(fill = weight_log),
      color = "white",
      linewidth = 0.1
    ) +
    ididvar::theme_idid() +
    ididvar::scale_fill_idid(colors = colors) +
    ggplot2::labs(
      title = "Distribution of Identifying Variation Weights",
      fill = "Weight, compared to the average weight"
    ) +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_blank()
    )
}
