#' Create categories for identifying variation weights
#'
#' @description
#' Categorize weights based on their size relative to the average weight.
#'
#' @param weights A numeric vector of identifying variation weights.
#' Generally produced by the \code{ididvar::idid_weights} function.
#'
#' @returns
#' A factor with levels "More than 50x smaller", "Between 10x and 50x smaller",
#' "Between 2x and 10x smaller", "Between 2x smaller and 2x larger",
#' "Between 2x and 10x larger", "Between 10x and 50x larger", and
#' "More than 50x larger", indicating the relative size of each element.
#'
#' @export
idid_weights_cat <- function(weights) {
    cut(
      log10(weights * length(weights)),
      breaks = log10(c(0, 1/50, 1/10, 1/2, 2, 10, 50, Inf)),
      labels =
        c("More than 50x smaller",
          "Between 10x and 50x smaller",
          "Between 2x and 10x smaller",
          "Between 2x smaller and 2x larger",
          "Between 2x and 10x larger",
          "Between 10x and 50x larger",
          "More than 50x larger"),
      include.lowest = TRUE
    )
}
