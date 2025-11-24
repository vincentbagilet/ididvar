#' Transform an IV regression into its control function equivalent
#'
#' @description
#' Takes an instrumental variables (IV) regression estimated
#' with either \code{fixest::feols} or \code{AER::ivreg} and refits it
#' as a *control function* (CF) specification.
#'
#' @details
#' The resulting model reproduces the second-stage regression where the
#' residuals from each first-stage (for endogenous regressors) are added as
#' additional controls. These residuals are appended to the data as
#' `<var>_first` and added as regressors in the updated model.
#'
#' This function allows to explore the identifying variation of
#' IV estimates using the other functions of the `ididvar` package.
#'
#' The function ensures that covariance options (e.g., clustering, weights)
#' and other model arguments are preserved from the original regression where
#' possible. If none are provided, the standard errors will be incorrect.
#'
#' @param reg An IV regression object. Currently supported classes are
#'   \code{fixest::fixest} and \code{AER::ivreg}.
#' @param ... Additional arguments passed to \code{stats::update} when refitting
#'   the model.
#'
#' @return A model object of the same class as `reg` (`fixest` or `ivreg`),
#'   representing the equivalent control-function specification. The returned
#'   model uses the same data, controls, and variance specification as the
#'   original regression.
#'
#' @examples
#' \dontrun{
#' library(fixest)
#' library(AER)
#'
#' # feols example
#' data(trade)
#' reg_feols <- feols(Euros ~ log(dist) | log(dist) ~ log(air) + log(dist), data = trade)
#' reg_feols_cf <- idid_to_cf(reg_feols)
#'
#' # ivreg example
#' data("CigarettesSW")
#' reg_ivreg <- ivreg(log(packs) ~ log(rprice) + log(rincome) | log(rtax) + log(rincome),
#'                 data = CigarettesSW)
#' reg_ivreg_cf <- idid_to_cf(reg_ivreg)
#' }
#'
#' @seealso [fixest::feols], [AER::ivreg], [stats::update]
#'
#' @export
idid_to_cf <- function(reg, ...) {
  UseMethod("idid_to_cf")
}

#' @describeIn idid_to_cf Method for `fixest` (feols) objects
#' @family idid_methods
#' @export
#' @exportS3Method
idid_to_cf.fixest <- function(reg, ...) {
  dat <- eval(reg$call$data, envir = environment(stats::formula(reg)))
  endo_vars <- reg$iv_endo_names

  #compute residuals from first stage
  for (endo_var in endo_vars) {
    dat[[paste0(endo_var, "_first")]] <-
      reg$iv_first_stage[[endo_var]] |> stats::residuals()
  }

  formula_second_stage <-
    stats::as.formula(paste(
      ". ~ . + ",
      paste(endo_vars, collapse = " + "),
      " + ",
      paste0(endo_vars, "_first", collapse = " + "),
      " | . | 0"
    ))

  reg_cf <-
    stats::update(
      reg,
      formula_second_stage,
      data = dat,
      na.action = stats::na.exclude,
      use_calling_env = FALSE,
      ...
    ) |>
    #handle warning when using feols for instance:
    #feols does not have a 'na.action' argument and there is a weird warning
    #for use_calling_env (likely a update.feols bug)
    withCallingHandlers(
      warning = function(w) {
        if (grepl("use_calling_env and na.action are not valid",
                  conditionMessage(w))) {
          invokeRestart("muffleWarning")
        }
      }
    )

  return(reg_cf)
}

#' @describeIn idid_to_cf Method for `ivreg` objects
#' @family idid_methods
#' @export
#' @exportS3Method
idid_to_cf.ivreg <- function(reg, ...) {
  dat <- eval(reg$call$data, envir = environment(stats::formula(reg)))

  rhs_vars <- all.vars(reg$terms$regressors)[-1]
  lhs_var <- all.vars(reg$terms$regressors)[1]
  instru <- all.vars(reg$terms$instruments)
  endo_vars <- rhs_vars[!(rhs_vars %in% instru)]

  for (endo_var in endo_vars) {
    formula_first_stage <-
      stats::as.formula(paste(
        endo_var,
        "~",
        paste(setdiff(instru, endo_vars), collapse = " + ")
      ))

    dat[[paste0(endo_var, "_first")]] <-
      stats::update(reg, formula_first_stage, ...) |>
      stats::residuals()
  }

  formula_second_stage <-
    stats::as.formula(paste(
      lhs_var, "~",
      paste0(rhs_vars, collapse = " + "),
      " + ",
      paste0(endo_vars, "_first", collapse = " + ")
    ))

  new_call <- reg$call
  new_call$formula <- formula_second_stage
  new_call$data <- quote(dat)

  reg_cf <- eval(new_call, envir = environment())

  return(reg_cf)
}

#' @describeIn idid_to_cf Default method (unsupported model types)
#' @family idid_methods
#' @export
#' @exportS3Method
idid_to_cf.default <- function(reg, ...) {
  stop("idid_to_cf only supports fixest::feols or AER::ivreg regressions")
}
