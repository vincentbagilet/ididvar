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
#' to the full sample is less than \code{threshold_change} (for every variable
#' of interest). The threshold corresponds to the last step that passes and no
#' observation is dropped if the first step fails.
#'
#' @inheritParams idid_drop_change
#' @param threshold_change A double (between 0 and 1). The change threshold in
#' estimate and s.e. when dropping observations.
#' @param search_step A double (between 0 and 1). The additional proportion of
#' observations to drop in each iteration of the loop.
#' @param ... Passed to \code{idid_drop_change}, eg \code{vcov}.
#'
#' @returns A numeric. The weight below which one can drop observations
#' without altering the estimate by more than a proportion of
#' \code{threshold_change}. Observations with this weight are kept.
#'
#' @export
#'
#' @examples
#' reg_ex <- ggplot2::economics |>
#'   lm(formula = unemploy ~ pce + uempmed + psavert + pop)
#'
#' idid_contrib_threshold(reg_ex, "pce")
idid_contrib_threshold <- function(reg,
                                   var_interest,
                                   threshold_change = 0.05,
                                   search_step = 0.05,
                                   ...) {
  if (!isTRUE(is.numeric(c(search_step, threshold_change)) &
              search_step > 0 & search_step < 1 &
              threshold_change > 0 & threshold_change < 1)) {
    stop("search_step and threshold_change must be between 0 and 1 (eg 0.05 for 5%)")
  }

  weights <- ididvar::idid_weights(reg, var_interest, ...)

  #compute the prop of obs to keep/drop without changing the estimates
  #by more than threshold_change
  #stop before dropping all observations
  small_change <- TRUE
  prop_drop <- 0
  while (small_change && prop_drop + search_step < 1) {
    prop_drop <- prop_drop + search_step
    drop_change <- ididvar::idid_drop_change(
      reg,
      var_interest,
      prop_drop = prop_drop,
      ...
    )

    #for all variables of interest. NA (regression failed) is a large change
    small_change <- isTRUE(all(
      abs(drop_change$prop_change_est) < threshold_change &
        abs(drop_change$prop_change_se) < threshold_change
    ))
  }

  #last step that passed
  if (!small_change) {
    prop_drop <- prop_drop - search_step
  }

  weight_threshold <- idid_weight_threshold(weights, prop_drop)

  return(weight_threshold)
}
