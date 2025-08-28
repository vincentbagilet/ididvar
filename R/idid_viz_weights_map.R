#' Plot a map of identifying variation weights
#'
#' @description
#' A short description...
#' displaying weights as fill color and scale for
#' each region, or nothing. If there are no overlapping polygons,
#' an error will occur, while if `...` is supplied (see below) it will
#' be passed onto the subsequent geom_sf(), otherwise a warning will be raised.
#'
#' @inheritParams idid_weights
#' @param shape_file An \code{sf} object. The shape file to map the weights on.
#' @param join_by A character string. The name of the variable in the original
#' data and in `shape_file` and along which the matching should be performed.
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
#' idid_viz_weights_map(reg, "Income", states_sf, "NAME")
idid_viz_weights_map <- function(reg,
                                 var_interest,
                                 shape_file,
                                 join_by,
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
  merged[["weight_norm"]] <- log10(merged$weight * nrow(merged))

  merged |>
    ggplot2::ggplot() +
    ggplot2::geom_sf(
      ggplot2::aes(fill = weight_norm),
      color = "white",
      linewidth = 0.1
    ) +
    ididvar::theme_idid() +
    ididvar::scale_fill_idid() +
    ggplot2::labs(
      title = "Distribution of Identifying Variation Weights",
      fill = "Weight, compared to the average weight"
    ) +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_blank()
    )
}
