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
  UseMethod("idid_weights")
}

#' Identifying Variation Weights for Linear Model Fits
#'
#' @description
#' \code{idid_weights} method for class "\code{lm}".
#'
#' @param reg A fitted \code{lm} model.
#'
#' @inheritParams idid_weights
#'
#' @returns
#' A numeric vector representing the identifying variation weights.
#'
#' @family idid_methods
#' @export
#' @exportS3Method
idid_weights.lm <- function(reg, var_interest) {
  x_per <-
    update(reg, as.formula(paste(var_interest, "~ . -", var_interest))) |>
    residuals()

  # x_per <-
  #   lm(formula = as.formula(formula_x_per), data = df) |>
  #   residuals()

  # var_names <- names(reg$model)
  # controls <- ifelse(
  #   length(var_names) == 1,
  #   "1",
  #   paste(var_names[-c(1, which(var_names == var_interest))], collapse = " + ")
  # )
  #
  # x_per <-
  #   lm(formula = paste(var_interest, controls, sep = " ~ "), data = df) |>
  #   residuals()

  # y_per <-
  #   lm(formula =  paste(var_names[1], controls, sep = " ~ "), data = df) |>
  #   residuals()
  #
  # median_y_per <- median(abs(y_per))

  # weight <- residuals(lm(x_per ~ 1))^2
  weight <- (x_per - mean(x_per, na.rm = TRUE))^2
  weight <- weight/sum(weight)

  return(weight)
}

#' Identifying Variation Weights for Fixed-effects OLS Fits
#'
#' @description
#' \code{idid_weights} method for class "\code{fixest}".
#'
#' @param reg A fitted \code{fixest::feols} model.
#'
#' @inheritParams idid_weights
#'
#' @returns
#' A numeric vector representing the identifying variation weights.
#'
#' @family idid_methods
#' @export
#' @exportS3Method
idid_weights.fixest <- function(reg, var_interest) {
  # reestimate the model with adjustments
  x_per <-
    update(reg, as.formula(paste(var_interest, "~ . -", var_interest))) |>
    residuals()

  # weights: square of centered residuals
  weight <- (x_per - mean(x_per, na.rm = TRUE))^2
  weight <- weight/sum(weight)

  return(weight)
}






