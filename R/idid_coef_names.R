#' Coefficient names of the variables of interest
#'
#' @description
#' Finds the name of the coefficient corresponding to each variable of
#' interest. For instance, `x` is called `fit_x` in an IV regression estimated
#' with `fixest` and a logical variable `treat` is called `treatTRUE`.
#'
#' @inheritParams idid_partial_out
#'
#' @returns
#' A vector string. The coefficient names of the variables of interest.
#'
#' @keywords internal
idid_coef_names <- function(reg, var_interest) {
  coef_names <- names(stats::coef(reg))

  var_names <- NULL
  for (var in var_interest) {
    #var itself, instrumented in fixest (fit_var) or logical (varTRUE)
    var_name <-
      intersect(c(var, paste0("fit_", var), paste0(var, "TRUE")), coef_names)
    if (length(var_name) != 1) {
      stop(var, " is not a coefficient of the regression. Coefficients: ",
           paste(coef_names, collapse = ", "))
    }
    var_names <- append(var_names, var_name)
  }

  return(var_names)
}
