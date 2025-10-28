#' Partial out controls
#'
#' @description
#' Compute the partialled out version of a variable based on the regression
#' model provided.
#'
#' @details
#' The partialling out procedure is implemented using the same estimation
#' method as the one used in `reg`.
#'
#' If `var_interest` is specified (and different from `var_to_partial`),
#' `var_interest` is not partialled out. This is espetially interesting if one
#' wants to partial out controls but not the variable of interest.
#'
#' @inheritParams idid_weights
#' @param var_to_partial A string. The name of the variable for which to
#' compute a partialled out version.
#' @param ... Additional elements to pass to the regression function when
#' partialling out controls.
#'
#' @returns
#' A vector of the partialled out version of `var_to_partial`.
#'
#' @export
#'
#' @examples
#' # example with a lm regression
#' reg_ex_lm <- ggplot2::txhousing |>
#'   lm(formula = volume ~ sales + listings + city + as.factor(date))
#'
#' idid_partial_out(reg_ex_lm, "sales") |>
#'  head()
#'
#' idid_partial_out(reg_ex_lm, "volume", "sales") |>
#'  head()
#'
#' # example with a fixest regression
#' reg_ex_fixest <- ggplot2::txhousing  |>
#'   fixest::feols(fml = volume ~ sales + listings |  as.factor(date) + city)
#'
#' idid_partial_out(reg_ex_fixest, "sales") |>
#'   head()
#'
#' idid_partial_out(reg_ex_fixest, "volume", "sales") |>
#'   head()
idid_partial_out <- function(reg,
                             var_to_partial,
                             var_interest = var_to_partial,
                             ...) {
  #additional arguments to the regression
  # other_args <- list(
  #   na.action = na.exclude #add NAs to the weights when values missing for some regressors
  # )
  # if (inherits(reg, "fixest")) other_args$na.action <- NULL

  #define partial out formula if x or y
  if (var_to_partial == reg$call[[2]][[2]]) { #reg$call[[2]][[2]] = y in the reg
    formula_partial <- stats::as.formula(paste(". ~ . -", var_interest))
  } else {#if (var_to_partial %in% names(reg$coefficients)) {
    formula_partial <-
      stats::as.formula(
        paste(var_to_partial, "~ . -", var_to_partial, "-", var_interest)
      )
  }# else {
  #   stop(var_to_partial, " is not a variable in the regression")
  # }

  partialled_out <- stats::update(reg, formula_partial, na.action = stats::na.exclude, ...) |>
    stats::residuals(na.rm = FALSE) |>
    #handle warning when using feols for instance:
    #feols does not have a 'na.action' argument
    withCallingHandlers(
      warning = function(w) {
        if (grepl("na.action is not a valid argument for function",
                  conditionMessage(w))) {
          invokeRestart("muffleWarning")
        }
      }
    )

  #add NAs back for plm (because na.action not fully supported by plm)
  if (inherits(reg, "plm")) {
    miss_val <- rep(NA, nrow(eval(reg$call$data)))
    miss_val[as.numeric(rownames(reg$model))] <- partialled_out
    partialled_out <- miss_val
  }

  return(partialled_out)
}
