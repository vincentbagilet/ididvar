#' Find a weight threshold below which observations "do not contribute"
#'
#' @description
#' Find a weight threshold below which removing observations does not change
#' the point estimate or the standard error of the estimate of interest by more
#' than a given proportion.
#'
#' @details
#' This function applies \code{ididvar::idid_drop_change} for a series of
#' proportions of observations removed, increasing this proportion by
#' \code{search_step} while the variation in the estimate and s.e. as compared
#' to the full sample is less than \code{threshold_change}.
#'
#' @inheritParams idid_drop_change
#' @param threshold_change A double (between 0 and 1). The change threshold in
#' estimate and s.e. when dropping observations.
#' @param search_step A double (between 0 and 1). The additional proportion of
#' observations to drop in each iteration of the loop.
#'
#' @returns A numeric. The largest weight below which one can drop observations
#' without altering the estimate by more than a proportion of
#' \code{threshold_change}.
#'
#' @export
idid_contrib_threshold <- function(reg,
                                   var_interest,
                                   threshold_change = 0.05,
                                   search_step = 0.05) {
  weights <- ididvar::idid_weights(reg, var_interest)

  #compute the prop of obs to keep/drop without changing the estimates
  #by more than threshold_change
  small_change <- TRUE
  prop_drop <- 0
  while (small_change) {
    prop_drop <- prop_drop + search_step
    drop_change <- ididvar::idid_drop_change(
      reg,
      var_interest,
      prop_drop = prop_drop
    )

    small_change <- (abs(drop_change$prop_change_est) < threshold_change &
                     abs(drop_change$prop_change_se) < threshold_change)
  }

  weights_sorted <- sort(weights)
  weight_threshold <- weights_sorted[[floor(prop_drop * length(weights_sorted))]]

  return(weight_threshold)
}
