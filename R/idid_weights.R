#' Identifying Variation Weights
#'
#' @description
#' A generic function used to compute regression weights
#' describing the amount of variation that is used for the identification of
#' a treatment effect.
#'
#' @details
#' The weights correspond to the normalized leverage of each observation for
#' the variable of interest after partialling out all controls.
#'
#' The function invokes particular methods which depend on the class of the
#' first argument.
#'
#' @param reg A regression object.
#' @param var_interest A string. The treatment or main variable of interest.
#'
#' @returns
#' A numeric vector representing the identifying variation weights.
#'
#' @export
idid_weights <- function(reg, var_interest) {
  x_per <-
    update(reg, as.formula(paste(var_interest, "~ . -", var_interest))) |>
    residuals()

  weight <- (x_per - mean(x_per, na.rm = TRUE))^2
  weight <- weight/sum(weight)

  return(weight)
}



