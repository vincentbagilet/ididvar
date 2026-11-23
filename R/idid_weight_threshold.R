#' Weight threshold when dropping low weight observations
#'
#' @description
#' Finds the lowest weight kept when dropping a proportion of the observations
#' of the estimation sample, lowest weights first.
#'
#' @details
#' Observations with the same weight are all kept or all dropped: observations
#' with a weight equal to the threshold are kept. The proportion of observations
#' dropped can therefore be lower than \code{prop_drop}.
#'
#' @param weights A numeric vector. The identifying variation weights, NA
#' outside the estimation sample.
#' @inheritParams idid_drop_reg
#'
#' @returns
#' A numeric. Observations with a lower weight are dropped.
#'
#' @keywords internal
idid_weight_threshold <- function(weights, prop_drop) {
  #sort drops NAs, ie observations outside the estimation sample
  weights_sorted <- sort(weights)
  weight_threshold <-
    weights_sorted[[floor(prop_drop * length(weights_sorted)) + 1]]

  return(weight_threshold)
}
