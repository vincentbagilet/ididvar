#' Automatic mean aggregation for sf
#'
#' A ggplot2 Stat that sums the values provided in z for each geometry
#'
#' @keywords internal
StatSumSf <- ggplot2::ggproto(
  "StatSumSf",
  ggplot2::StatSf,
  required_aes = c("geometry", "z"),
  default_aes = ggplot2::aes(fill = ggplot2::after_stat(z)),
  compute_group = function(data, scales) {
    # df <- data
    # df[["groupin"]] <- match(df$geometry, unique(df$geometry)) |> as.factor()
    # gr_geom <- unique(df[c("groupin", "geometry")])
    print(data)
#
#     agg <-
#       aggregate(df$z, list(groupin = df$groupin), sum, na.rm = TRUE)
#     merged <- base::merge(agg, gr_geom, by = "groupin", all = TRUE)
#     names(merged) <- c("groupin", "z", "geometry")
#     #
#     # merged <- st_as_sf(merged)
#     print(merged)

    return(merged)
  }
)
