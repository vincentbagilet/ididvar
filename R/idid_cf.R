#' Create an idid_cf object
#'
#' @description
#' Creates the control form of a regression, returned by \code{idid_to_cf}.
#'
#' @inheritParams idid_to_cf
#' @param x,y,weights,fixef_id,offset The regressors, outcome, regression
#' weights, fixed effects and offset of the control form.
#' @param obs,nobs_origin The rows of the data used for estimation and the
#' number of rows of the data. If NULL, retrieved from the model frame.
#' @param cf_names A vector string. The names of the control function variables.
#'
#' @returns
#' An \code{idid_cf} object.
#'
#' @keywords internal
new_idid_cf <- function(reg,
                        x,
                        y,
                        weights = NULL,
                        fixef_id = NULL,
                        offset = NULL,
                        obs = NULL,
                        nobs_origin = NULL,
                        cf_names = NULL) {
  coefs <- stats::coef(reg)
  coefs <- coefs[!is.na(coefs)]

  if (is.null(obs)) {
    df <- idid_data(reg)
    obs <- match(rownames(stats::model.frame(reg)), rownames(df))
    nobs_origin <- nrow(df)
  }
  if (anyNA(obs)) {
    stop("Cannot match the observations of the regression with the data")
  }

  if (inherits(reg, "fixest")) {
    y_name <- deparse1(reg$fml[[2]])
  } else {
    y_name <- deparse1(stats::formula(reg)[[2]])
  }

  reg_cf <- list(
    x = x[, c(names(coefs), cf_names), drop = FALSE],
    y = as.numeric(y) - if (is.null(offset)) 0 else offset,
    weights = if (is.null(weights)) rep(1, length(obs)) else as.numeric(weights),
    fixef_id = fixef_id,
    obs = obs,
    nobs_origin = nobs_origin,
    coefficients = coefs,
    y_name = y_name,
    cf_names = cf_names,
    model_class = class(reg)[1]
  )
  class(reg_cf) <- "idid_cf"

  return(reg_cf)
}

#' Coefficient names of the variables of interest
#'
#' @description
#' Matches each variable of interest with a coefficient of the control form.
#'
#' @param reg_cf An \code{idid_cf} object.
#' @inheritParams idid_partial_out
#'
#' @returns
#' A vector string of coefficient names.
#'
#' @keywords internal
idid_coef_names <- function(reg_cf, var_interest) {
  sapply(var_interest, function(var) {
    #var itself, instrumented in fixest (fit_var) or logical (varTRUE)
    coef_name <-
      intersect(c(var, paste0("fit_", var), paste0(var, "TRUE")), colnames(reg_cf$x))
    if (length(coef_name) != 1) {
      stop(var, " is not a coefficient of the regression. Coefficients: ",
           paste(names(reg_cf$coefficients), collapse = ", "))
    }
    coef_name
  }, USE.NAMES = FALSE)
}

#' @export
#' @noRd
print.idid_cf <- function(x, ...) {
  cat("Control form of a", x$model_class, "regression:",
      length(x$obs), "observations,", length(x$coefficients), "coefficients\n")
  if (!is.null(x$fixef_id)) {
    cat("Fixed effects:", paste(names(x$fixef_id), collapse = ", "), "\n")
  }
  if (!is.null(x$cf_names)) {
    cat("Control function:", paste(x$cf_names, collapse = ", "), "\n")
  }

  invisible(x)
}

#' @exportS3Method stats::model.matrix
#' @noRd
model.matrix.idid_cf <- function(object, ...) {
  object$x
}

#' @exportS3Method stats::weights
#' @noRd
weights.idid_cf <- function(object, ...) {
  object$weights
}

#' @exportS3Method stats::coef
#' @noRd
coef.idid_cf <- function(object, ...) {
  object$coefficients
}

#' @exportS3Method stats::nobs
#' @noRd
nobs.idid_cf <- function(object, ...) {
  length(object$obs)
}
