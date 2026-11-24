#' Compute Identifying Variation Weights
#'
#' @description
#' Compute regression weights describing the amount of variation used for
#' identification.
#'
#' @details
#' The weights correspond to the normalized leverage of each observation for
#' the variables of interest after partialling out all controls.
#'
#' The partialled out version of the variables of interest is computed with
#' \code{idid_partial_out}, on the control form of the regression (see
#' \code{idid_to_cf}). For weighted regressions (and GLMs), observations are
#' weighted by the regression weights.
#'
#' @inheritParams idid_partial_out
#' @param tol A numeric. Passed to the \code{qr} function. The tolerance for
#' detecting linear dependencies in the columns of x_partialled.
#'
#' @returns
#' A numeric vector of the identifying variation weights for each observation.
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
idid_weights <- function(reg,
                         var_interest,
                         partial_iv = TRUE,
                         tol = 1e-7,
                         ...) {
  if (length(var_interest) == 0) {
    stop("var_interest must contain at least one variable")
  }
  if (!is.numeric(tol)) {
    stop("tol must be a number")
  }

  reg_cf <- idid_to_cf(reg)

  x_partialled <- sapply(var_interest, function(var) {
    idid_partial_out(reg_cf, var, var_interest, partial_iv = partial_iv)
  })

  #only keep the estimation sample (idid_partial_out pads dropped rows with NA)
  #and weight observations for weighted regressions
  x_partialled <- x_partialled[reg_cf$obs, , drop = FALSE] * sqrt(reg_cf$weights)

  #decompose the residualised block
  qr_partialled <- qr(x_partialled, tol = tol)

  if (qr_partialled$rank < length(var_interest)) {
    warning("Rank ", qr_partialled$rank, " of ", length(var_interest),
            ": variable(s) of interest collinear with the controls.")
  }

  #leverage of each observation (hat() only keeps the leading `rank` columns of
  #Q, as qr() shifts columns with no variation left to the end)
  idid_weights <- rep(NA, reg_cf$nobs_origin)
  idid_weights[reg_cf$obs] <- stats::hat(qr_partialled)
  idid_weights <- idid_weights/sum(idid_weights, na.rm = TRUE)

  return(idid_weights)
}
