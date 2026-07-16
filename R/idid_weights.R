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
#' The partailled out version of the design matrix (ie, of the set of variables
#' of interest) is computed by re-running the regression provided in \code{reg}
#' but sequentially replacing the independent variable by each of the variables
#' of interest (and removing them from the set of regressors).
#'
#' If the nature of the independent variable and of the variable of interest
#' are different, one may want to change the estimation.
#' For instance, if the independent variable is discrete and estimated via glm
#' with the argument \code{family = "binomial"} and the dependent variable is
#' continuous, one may want to provide the argument \code{family = "gaussian"}
#' to \code{idid_weights}.
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

  if (all.vars(reg$call[[2]])[[1]] %in% var_interest) {
    #all.vars(reg$call[[2]])[[1]] is y in the reg
    stop("var_interest should only contain explanatory variables")
  }

  block_terms <- paste(var_interest, collapse = " - ")

  x_partialled <- sapply(var_interest, function(var) {
    idid_partial_out(
      reg,
      var,
      var_interest = block_terms,
      partial_iv = partial_iv,
      ...
    )
  })

  #note the estimation sample: idid_partial_out pads dropped rows with NA,
  #which qr() errors on
  complete_rows <- stats::complete.cases(x_partialled)

  #decompose the residualised block; `tol` sets how much variation a variable
  #must retain to count as identified rather than collinear
  qr_partialled <- qr(x_partialled[complete_rows, , drop = FALSE], tol = tol)

  if (qr_partialled$rank < length(var_interest)) {
    warning("Rank ", qr_partialled$rank, " of ", length(var_interest),
            ": variable(s) of interest collinear with the controls.")
  }

  #qr() shifts columns with no variation left to the end. We only keep the
  #leading `rank` ones
  q_identified <- qr.Q(qr_partialled)[, seq_len(qr_partialled$rank), drop = FALSE]

  #leverage = squared length of each row
  idid_weights <- rep(NA, nrow(x_partialled))
  idid_weights[complete_rows] <- rowSums(q_identified^2)
  idid_weights <- idid_weights/sum(idid_weights, na.rm = TRUE)

  return(idid_weights)
}



