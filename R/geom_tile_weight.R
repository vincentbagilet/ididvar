#' geom_tile_complete: Draw a tile heatmap with automatic aggregation and log-transform
#'
#' @param mapping, data, stat, position Standard ggplot2 arguments
#' @param ... Additional arguments passed to layer()
#' @export
geom_tile_weight <- function(mapping = NULL,
                               data = NULL,
                               position = "identity",
                               ...) {
  layer(
    data = data,
    mapping = mapping,
    stat = StatLogWeight,
    geom = ggplot2::GeomTile,
    position = position,
    inherit.aes = TRUE,
    ...
  )
}
