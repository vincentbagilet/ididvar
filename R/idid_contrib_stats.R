#' Compute quick descriptive statistics on the effective sample
#'
#' @description
#' Reports the total, nominal and effective sample size, as well as the
#' proportion of observations from the nominal sample that are part of the
#' effective one.
#'
#' @inheritParams idid_viz_weights
#' @inheritParams idid_viz_contrib
#'
#' @returns
#' A list with 4 entries:
#' - `n_total`: the total sample size, before dropping observations with
#' missing values
#' - `n_nominal`: the nominal sample size, ie the number of observations in the
#' regression
#' - `n_effective`: the effective sample size, after removing non contributing
#' observations
#' - `prop_effective`: the ratio of the effective to the nominal sample sizes
#'
#' @export
#'
#' @examples
#' reg_ex <- ggplot2::txhousing |>
#'   lm(formula = volume ~ sales + listings + city + as.factor(date))
#'
#' idid_contrib_stats(reg_ex, "sales")
idid_contrib_stats <- function(reg,
                               var_interest,
                               contrib_threshold,
                               threshold_change = 0.05,
                               ...) {
  if (missing(contrib_threshold)) {
    message("Searching for the contribution threshold")
    contrib_threshold <- ididvar::idid_contrib_threshold(
      reg,
      var_interest,
      threshold_change = threshold_change,
      ...
    )
  }

  weights <- ididvar::idid_weights(reg, var_interest, ...)
  contrib <- (weights > contrib_threshold)

  out <- list(
    reg = deparse(substitute(reg)),
    n_initial = length(weights),
    n_nominal = sum(!is.na(weights)),
    n_effective = sum(contrib, na.rm = TRUE),
    prop_effective = mean(contrib, na.rm = TRUE)
  )

  return(out)
}
