#' Variation in estimate when dropping low weight observations
#'
#' @description
#' Computes a variation of the point estimate and standard errors of the
#' coefficient of interest when dropping low weight observations.
#'
#' @inheritParams idid_drop_reg
#'
#' @returns
#' A dataframe with one row and 3 columns:
#' - `prop_drop`: the proportion of data dropped
#' - `prop_change_est`: the relative change between the full sample and
#' droped estimates
#' - `prop_change_se`: the relative change between the full sample and
#' droped s.e.
#'
#' @export
#'
#' @examples
#' reg_ex <- ggplot2::economics |>
#'   lm(formula = unemploy ~ pce + uempmed + psavert + pop)
#'
#' idid_drop_change(reg_ex, "pce", prop_drop = 0.1)
idid_drop_change <- function(reg,
                             var_interest,
                             prop_drop,
                             ...) {
  reg_sliced <- ididvar::idid_drop_reg(reg, var_interest, prop_drop, ...)
  #some regression function "change" the name of the variable of interest
  #for instance for a boolean var "treated", in the coef table the name will be
  #treatedTRUE. Take that into account with var_interest_robust
  var_interest_robust <- var_interest

  #retrieve the coeff table
  if (inherits(reg, "fixest")) {
    coef_table <- reg$coeftable
    coef_table_sliced <- reg_sliced$coeftable

    if (!is.null(reg$iv)) {
      #in IVs feols renames the instrumented variable by adding "fit_" in front
      var_interest_robust <- paste("fit", var_interest, sep = "_")
    }
  } else {
    coef_table <- summary(reg)$coefficients
    coef_table_sliced <- summary(reg_sliced)$coefficients
  }

  #when the variable of interest is a boolean, "TRUE" is added behind its name
  var_interest_robust <-
    grep(paste0(var_interest_robust, "(TRUE)*"), rownames(coef_table), value = TRUE)

  #retrieve pt estimate and se
  est_full <- coef_table[[var_interest_robust, "Estimate"]]
  est_sliced <- coef_table_sliced[[var_interest_robust, "Estimate"]]
  se_full <- coef_table[[var_interest_robust, "Std. Error"]]
  se_sliced <- coef_table_sliced[[var_interest_robust, "Std. Error"]]

  out <- data.frame(
    prop_drop = prop_drop,
    prop_change_est = (est_full - est_sliced)/est_full,
    prop_change_se = (se_full - se_sliced)/se_full
  )

  return(out)
}
