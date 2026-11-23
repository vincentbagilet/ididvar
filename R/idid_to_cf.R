#' Transform a regression into its control form
#'
#' @description
#' Rewrites a regression as an equivalent linear regression, its control form,
#' without re-estimating it.
#'
#' @details
#' The control form has the same coefficients as \code{reg}. The other
#' functions of the package work on it, to handle all models the same way:
#' - linear models (`lm`, `feols`, `felm`): the regression itself.
#' - IV (`ivreg`, `feols`): first stage residuals are added as controls
#' (control function).
#' - GLM (`glm`, `feglm`, `fepois`): the working response, with the IRLS
#' weights (R estimates GLMs by iterating weighted linear regressions of this
#' working response).
#' - `plm`: the data as transformed by `plm` (eg demeaned for a within model).
#'
#' The regression can be refitted from its control form. This gives back its
#' coefficients but not its standard errors:
#' ```
#' reg_cf <- idid_to_cf(reg)
#' stats::lm.wfit(reg_cf$x, reg_cf$y, reg_cf$weights)$coefficients
#'
#' # with fixed effects
#' fixest::feols.fit(reg_cf$y, reg_cf$x,
#'   fixef_df = as.data.frame(reg_cf$fixef_id), weights = reg_cf$weights)
#' ```
#'
#' @param reg A regression object. Currently supported classes are \code{lm},
#' \code{glm}, \code{fixest}, \code{ivreg} (AER), \code{plm} and \code{felm}.
#' @param ... Not used.
#'
#' @returns
#' An \code{idid_cf} object, a list with:
#' - `x`: the regressors
#' - `y`: the outcome
#' - `weights`: the regression weights (1 if none)
#' - `fixef_id`: the fixed effects (NULL if none)
#' - `obs`: the rows of the data used for estimation
#' - `nobs_origin`: the number of rows of the data
#' - `coefficients`, `y_name`, `cf_names` (the control function variables)
#' and `model_class`
#'
#' @export
#'
#' @examples
#' reg_ex <- ggplot2::txhousing |>
#'   lm(formula = log(sales) ~ median + listings + city)
#'
#' reg_cf <- idid_to_cf(reg_ex)
#' reg_cf
#'
#' stats::lm.wfit(reg_cf$x, reg_cf$y, reg_cf$weights)$coefficients |>
#'   head()
#'
#' # IV
#' reg_iv <- fixest::feols(mpg ~ wt | hp ~ qsec, data = mtcars)
#' idid_to_cf(reg_iv)
idid_to_cf <- function(reg, ...) {
  UseMethod("idid_to_cf")
}

#' @describeIn idid_to_cf Method for `fixest` objects
#' @export
idid_to_cf.fixest <- function(reg, ...) {
  if (reg$method_type == "feNmlm") {
    stop("idid_to_cf does not support ", reg$method, " models")
  }
  if (isTRUE(any(reg$slope_flag != 0))) {
    stop("idid_to_cf does not support varying slopes")
  }

  y <- stats::model.matrix(reg, type = "lhs")
  weights <- reg$weights
  cf_names <- NULL

  if (isTRUE(reg$is_iv)) {
    #add first stage residuals (control function)
    endo <- stats::model.matrix(reg, type = "iv.endo")
    first_resid <- sapply(reg$iv_first_stage, stats::residuals)
    cf_names <- paste0(colnames(endo), "_first")
    colnames(first_resid) <- cf_names
    colnames(endo) <- paste0("fit_", colnames(endo))
    x <- cbind(stats::model.matrix(reg, type = "iv.exo"), endo, first_resid)
  } else {
    x <- stats::model.matrix(reg, type = "rhs")
  }

  #GLM: working response and IRLS weights
  if (reg$method_type == "feglm") {
    eta <- reg$linear.predictors
    mu <- reg$fitted.values
    prior_weights <- if (is.null(weights)) 1 else weights
    y <- eta + (y - mu) / reg$family$mu.eta(eta)
    weights <- prior_weights * reg$family$mu.eta(eta)^2 / reg$family$variance(mu)
  }

  new_idid_cf(
    reg,
    x = x,
    y = y,
    weights = weights,
    fixef_id = reg$fixef_id,
    offset = reg$offset,
    obs = fixest::obs(reg),
    nobs_origin = reg$nobs_origin,
    cf_names = cf_names
  )
}

#' @describeIn idid_to_cf Method for `ivreg` objects
#' @export
idid_to_cf.ivreg <- function(reg, ...) {
  x <- stats::model.matrix(reg, component = "regressors")
  instru <- stats::model.matrix(reg, component = "instruments")
  endo_vars <- setdiff(colnames(x), colnames(instru))

  #add first stage residuals (control function)
  first_resid <- x[, endo_vars, drop = FALSE] -
    stats::model.matrix(reg, component = "projected")[, endo_vars, drop = FALSE]
  colnames(first_resid) <- paste0(endo_vars, "_first")

  new_idid_cf(
    reg,
    x = cbind(x, first_resid),
    y = reg$y,
    weights = stats::weights(reg),
    cf_names = colnames(first_resid)
  )
}

#' @describeIn idid_to_cf Method for `lm` objects
#' @export
idid_to_cf.lm <- function(reg, ...) {
  new_idid_cf(
    reg,
    x = stats::model.matrix(reg),
    y = stats::model.response(stats::model.frame(reg)),
    weights = stats::weights(reg),
    offset = reg$offset
  )
}

#' @describeIn idid_to_cf Method for `glm` objects
#' @export
idid_to_cf.glm <- function(reg, ...) {
  eta <- reg$linear.predictors
  mu <- reg$fitted.values

  #working response and IRLS weights (recomputed: reg$weights are those of the
  #previous iteration)
  new_idid_cf(
    reg,
    x = stats::model.matrix(reg),
    y = eta + stats::residuals(reg, type = "working"),
    weights = reg$prior.weights * reg$family$mu.eta(eta)^2 / reg$family$variance(mu),
    offset = reg$offset
  )
}

#' @describeIn idid_to_cf Method for `plm` objects
#' @export
idid_to_cf.plm <- function(reg, ...) {
  if (!(reg$args$model %in% c("within", "random", "pooling", "fd"))) {
    stop("idid_to_cf does not support ", reg$args$model, " plm models")
  }
  df <- idid_data(reg)
  x <- stats::model.matrix(reg)

  #plm sorts the data: match its rows with those of df using the panel index
  index_x <- attr(x, "index")
  if (inherits(df, "pdata.frame")) {
    index_df <- plm::index(df)
  } else if (all(names(index_x) %in% names(df))) {
    index_df <- df[names(index_x)]
  } else {
    #time index created by plm, in the order of the data
    id <- df[[names(index_x)[1]]]
    index_df <- list(id, stats::ave(seq_along(id), id, FUN = seq_along))
  }
  #fd: no observation for the first period
  if (reg$args$model == "fd") {
    index_x <- index_x[duplicated(index_x[[1]]), ]
  }

  new_idid_cf(
    reg,
    x = x,
    y = plm::pmodel.response(reg),
    obs = match(paste(index_x[[1]], index_x[[2]]), paste(index_df[[1]], index_df[[2]])),
    nobs_origin = nrow(df)
  )
}

#' @describeIn idid_to_cf Method for `felm` objects
#' @export
idid_to_cf.felm <- function(reg, ...) {
  if (!is.null(reg$stage1)) {
    stop("idid_to_cf does not support felm IV models")
  }
  df <- idid_data(reg)

  new_idid_cf(
    reg,
    x = stats::model.matrix(reg),
    y = reg$response,
    #felm stores the square root of the weights
    weights = if (!is.null(reg$weights)) reg$weights^2,
    fixef_id = if (length(reg$fe) > 0) reg$fe,
    obs = setdiff(seq_len(nrow(df)), reg$na.action),
    nobs_origin = nrow(df)
  )
}

#' @describeIn idid_to_cf Default method (unsupported model types)
#' @export
idid_to_cf.default <- function(reg, ...) {
  stop("idid_to_cf does not support ", class(reg)[1], " objects")
}
