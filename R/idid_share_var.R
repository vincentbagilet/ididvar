#' Share of the variance removed by partialling out
#'
#' @description
#' Computes the share of the variance of the outcome and of the variables of
#' interest that is removed by partialling out the controls.
#'
#' @details
#' Each variable is partialled out with \code{idid_partial_out}: out of the
#' fixed effects and controls, but not out of the variables of interest. The
#' share removed is the R² of the regression of the variable on the controls,
#' 1 - sum(w * x_par^2) / sum(w * (x - mean(x))^2), with w the regression
#' weights, x_par the partialled out variable and mean(x) the weighted mean.
#' For GLMs, the outcome is the working response (see \code{idid_to_cf}).
#'
#' @inheritParams idid_partial_out
#'
#' @returns
#' A dataframe with one row per variable (the outcome, then the variables of
#' interest) and 2 columns:
#' - `variable`: the name of the variable
#' - `share_var_removed`: the share of its variance removed by partialling out
#'
#' @export
#'
#' @examples
#' reg_ex <- ggplot2::txhousing |>
#'   lm(formula = log(sales) ~ median + listings + city + as.factor(date))
#'
#' idid_share_var(reg_ex, "median")
idid_share_var <- function(reg,
                           var_interest,
                           partial_iv = TRUE,
                           ...) {
  reg_cf <- idid_to_cf(reg)
  w <- reg_cf$weights
  vars <- c(reg_cf$y_name, var_interest)

  share_var_removed <- sapply(vars, function(var) {
    x_par <- idid_partial_out(reg_cf, var, var_interest, partial_iv = partial_iv)
    x_par <- x_par[reg_cf$obs]
    if (var == reg_cf$y_name) {
      x <- reg_cf$y
    } else {
      x <- reg_cf$x[, idid_coef_names(reg_cf, var)]
    }
    1 - sum(w * x_par^2) / sum(w * (x - stats::weighted.mean(x, w))^2)
  })

  out <- data.frame(
    variable = vars,
    share_var_removed = unname(share_var_removed)
  )

  return(out)
}
