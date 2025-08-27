#' Find a weight threshold below which observations do not contribute
#'
#' @description
#' Find a weight threshold below which removing observations does not change
#' the point estimate or the standard error of the estimate of interest by more
#' than a given proportion.
#'
#' @inheritParams idid_weights
#' @param threshold_change A number (between 0 and 1).
#' The maximum size of change in predictions allowed after dropping participants (i.e., weighting participants 0). Optional. Default is `0.05`, which means up to 5% of observations can be dropped without exceeding the threshold change.
#' @param search_step A fraction of observations or weight values. Optional. Default is `0.05`.
#'
#' @returns The last value from the weights at the point where no more participants could be "dropped" without significantly altering the estimates. It's returned invisibly, i.e., it's only visible if you call this function with `invisible()` around `idid_contrib_threshold` in your code.
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
