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
#' @param reg A regression object.
#' @param var_to_partial A string. The name of the variable to partial out.
#' @param ... Additional elements to pass to the regression function when
#' partialling out controls.
#'
#' @returns
#' A vector of the partialled out version of `var_to_partial`
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
#' idid_partial_out(reg_ex_lm, "volume") |>
#'  head()
#'
#' # example with a fixest regression
#' reg_ex_fixest <- ggplot2::txhousing  |>
#'   fixest::feols(fml = volume ~ sales + listings |  as.factor(date) + city)
#'
#' idid_partial_out(reg_ex_fixest, "sales") |>
#'   head()
#'
#' idid_partial_out(reg_ex_fixest, "volume") |>
#'   head()
idid_partial_out <- function(reg, var_to_partial, ...) {
  #additional arguments to the regression
  # other_args <- list(
  #   na.action = na.exclude #add NAs to the weights when values missing for some regressors
  # )
  # if (inherits(reg, "fixest")) other_args$na.action <- NULL

  #define partial out formula if x or y
  if (var_to_partial == reg$call[[2]][[2]]) { #reg$call[[2]][[2]] = y in the reg
    formula_partial <- stats::as.formula(paste(". ~ . -", var_to_partial))
  } else if (var_to_partial %in% names(reg$coefficients)) {
    formula_partial <-
      stats::as.formula(paste(var_to_partial, "~ . -", var_to_partial))
  } else {
    stop(var_to_partial, "is not a variable in the regression")
  }

  partialled_out <- update(reg, formula_partial, na.action = na.exclude, ...) |>
    residuals(na.rm = FALSE) |>
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
