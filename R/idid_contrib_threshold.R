#' Compute a threshold for the weights used in inverse probability weighting (IPW)
#'
#' @description
#' A short description...
#'
#' @param reg A regression object.
#' @param var_interest A single string or constant indicating the variable of interest, e.g. a character vector with names matching columns in your data.
#' @param threshold_change The maximum size of change in predictions allowed after dropping participants (i.e., weighting participants 0). Optional. Default is `0.05`, which means up to 5% of observations can be dropped without exceeding the threshold change.
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

  weights_ordered <- weights[order(weights)]
  weight_threshold <- weights_ordered[[floor(prop_drop * length(weights_ordered))]]

  return(weight_threshold)
}
