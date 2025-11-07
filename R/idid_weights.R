#' Compute Identifying Variation Weights
#'
#' @description
#' Compute regression weights describing the amount of variation used for
#' identification.
#'
#' @details
#' The weights correspond to the normalized leverage of each observation for
#' the variable of interest after partialling out all controls.
#'
#' They are computed by re-running the regression provided but replacing the
#' independent variable by the variable of interest (and removing it from the
#' set of regressors).
#'
#' If the nature of the independent variable and of the variable of interest
#' are different, one may want to change the estimation.
#' For instance, if the independent variable is discrete and estimated via glm
#' with the argument \code{family = "binomial"} and the dependent variable is
#' continuous, one may want to provide the argument \code{family = "gaussian"}
#' to \code{idid_weights}.
#'
#' @inheritParams idid_partial_out
#'
#' @returns
#' A numeric vector representing the identifying variation weights.
#'
#' @export
#'
#' @examples
#' reg_ex_lm <- ggplot2::txhousing |>
#'   lm(formula = log(sales) ~ median + listings + city + as.factor(date))
#'
#' idid_weights(reg_ex_lm, "median") |>
#'  head()
#'
idid_weights <- function(reg, var_interest, partial_iv = TRUE, ...) {
  if (var_interest == all.vars(reg$call[[2]])[[1]]) { #reg$call[[2]][[2]] is y in the reg
    stop("var_interest should be an explanatory variable")
  }

  x_per <-
    ididvar::idid_partial_out(
      reg,
      var_to_partial = var_interest,
      partial_iv = partial_iv,
      ...
    )

  idid_weight <- (x_per - mean(x_per, na.rm = TRUE))^2
  idid_weight <- idid_weight/sum(idid_weight, na.rm = TRUE)

  return(idid_weight)
}



