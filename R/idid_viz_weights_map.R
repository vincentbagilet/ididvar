#' Plot a map of identifying variation weights
#'
#' @description
#' Displaying weights as fill color and scale for
#' each region, or nothing. If there are no overlapping polygons,
#' an error will occur, while if `...` is supplied (see below) it will
#' be passed onto the subsequent geom_sf(), otherwise a warning will be raised.
#'
#' @inheritParams idid_weights
#' @inheritParams scale_fill_idid
#' @param shape_file An \code{sf} object. The shape file to map the weights on.
#' @param join_by A character string. The name of the variable in the original
#' data and in `shape_file` and along which the matching should be performed.
#' @param facet A character string. The name of the variable in the original
#' data to facet the data graphs by.
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
                                 facet,
                                 colors = c("#C25807", "#FBE2C5", "#300D49"),
                                 ...) {
  df <- eval(reg$call$data)
  df[["weight"]] <- ididvar::idid_weights(reg, var_interest)

  #define what to aggregate by, depending on whether use facet or not
  if (missing(facet)) {
    list_join <- list(dim_1 = df[[join_by]])
    vect_names <- c(join_by, "weight")
  } else {
    list_join <- list(dim_1 = df[[join_by]], dim_2 = df[[facet]])
    vect_names <- c(join_by, facet, "weight")
  }

  #compute shape level weights
  aggr_df <- stats::aggregate(
    df$weight,
    by = list_join,
    FUN = sum,
    na.rm = TRUE
  )
  names(aggr_df) <- vect_names

  # print(aggr_df)

  #merge with shapefile
  merged <- base::merge(shape_file, aggr_df, by = join_by, all = TRUE)
  merged[["weight_log"]] <- log10(merged$weight * nrow(aggr_df))

  #make graph
  graph <- merged |>
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

  if (missing(facet)) {
    graph
  } else {
    graph +
      ggplot2::facet_wrap(stats::as.formula(paste("~", facet)))
  }
}
