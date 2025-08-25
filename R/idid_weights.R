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
#'
#' @examples
#' reg_test <- ggplot2::economics |>
#'  lm(formula = unemploy ~ pce + uempmed + psavert + pop)
#'
#' idid_weights(reg_test, "pce")
idid_weights <- function(reg, var_interest) {
  x_per <-
    update(reg, as.formula(paste(var_interest, "~ . -", var_interest))) |>
    residuals()

  weight <- (x_per - mean(x_per, na.rm = TRUE))^2
  weight <- weight/sum(weight)

  return(weight)
}



