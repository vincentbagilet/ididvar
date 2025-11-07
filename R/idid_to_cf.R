#' Transforming an IV regression into its control function equivalent
#'
#' @description
#'
#'
#' @details
#'
#'
#' @param reg A regression object produced by \code{fixest::feols} or
#' \code{AER::ivreg}
#'
#' @returns
#' A regression output
#'
#' @export
# idid_to_cf <- function(reg, ...) {
#   UseMethod("idid_to_cf")
# }


#only works for feols for now
idid_to_cf <- function(reg, ...) {
  dat <- eval(reg$call$data, envir = environment(stats::formula(reg)))

  if (inherits(reg, "fixest")) {
    # if (is.null(reg$iv)) stop("This feols model is not an IV regression.")
    #compute residuals from first stage
    endo_vars <- reg$iv_endo_names

    for (endo_var in endo_vars) {
      dat[[paste0(endo_var, "_first")]] <-
        reg$iv_first_stage[[endo_var]] |> residuals()
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

  } else if (inherits(reg, "ivreg")) {
    rhs_vars <- all.vars(reg$terms$regressors)[-1]
    lhs_var <- all.vars(reg$terms$regressors)[1]
    instru <- all.vars(reg$terms$instruments)
    endo_vars <- rhs_vars[!(rhs_vars %in% instru)]

    for (endo_var in endo_vars) {
      formula_first_stage <-
        as.formula(paste(
          endo_var,
          "~",
          paste(setdiff(instru, endo_vars), collapse = " + ")
        ))

      dat[[paste0(endo_var, "_first")]] <-
        stats::update(reg, formula_first_stage, ...) |>
        residuals()
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

    reg_cf <- eval(new_call)
  }

  return(reg_cf)
}
