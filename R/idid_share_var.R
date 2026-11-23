#' Share of the variance removed by partialling out
#'
#' @description
#' Computes the share of the variance of a variable that is removed by
#' partialling out the controls.
#'
#' @details
#' The variable is partialled out with \code{idid_partial_out}. The share of
#' the variance removed is the R² of the regression of the variable on the fixed
#' effects and controls. For weighted regressions, observations are weighted by
#' the regression weights.
#'
#' @inheritParams idid_partial_out
#'
#' @returns
#' A numeric. The share of the variance of `var_to_partial` removed by
#' partialling out.
#'
#' @export
#'
#' @examples
#' reg_ex <- ggplot2::txhousing |>
#'   lm(formula = log(sales) ~ median + listings + city + as.factor(date))
#'
#' idid_share_var(reg_ex, "median")
idid_share_var <- function(reg,
                           var_to_partial,
                           var_interest = var_to_partial,
                           partial_iv = TRUE,
                           ...) {
  reg_cf <- idid_to_cf(reg)
  weights <- reg_cf$weights

  #y or one of the x
  if (var_to_partial %in% c(reg_cf$y_name, all.vars(str2lang(reg_cf$y_name)))) {
    var_initial <- reg_cf$y
  } else {
    var_initial <- reg_cf$x[, idid_coef_names(reg_cf, var_to_partial)]
  }
  var_initial <- var_initial - stats::weighted.mean(var_initial, weights)

  partialled_out <-
    idid_partial_out(reg_cf, var_to_partial, var_interest, partial_iv = partial_iv)
  partialled_out <- partialled_out[reg_cf$obs]

  share_var <- 1 - sum(weights*partialled_out^2)/sum(weights*var_initial^2)

  return(share_var)
}
