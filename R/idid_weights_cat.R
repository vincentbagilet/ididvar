#' Convert numeric vector of weights to categorical label
#'
#' @description
#' Categorize weights based on their size relative to the total weight.
#'
#' @param weights A numeric (positive) vector.
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
      breaks = c(-Inf, -1.7, -1, -0.3, 0.3, 1, 1.7, Inf),
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
