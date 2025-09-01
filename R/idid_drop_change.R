#' Variation in estimate when dropping low weight observations
#'
#' @description
#' Computes a variation of the point estimate and standard errors of the
#' coefficient of interest when dropping low weight observations.
#'
#' @inheritParams idid_weights
#' @param prop_drop Proportion of observations to drop
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
  df <- eval(reg$call$data)
  # fml <- reg$call$formula

  df[["idid_weights"]] <- ididvar::idid_weights(reg, var_interest, ...)

  #keep high weights
  df_sliced <- df[order(df$idid_weights, decreasing = TRUE),] |>
    utils::head(n = nrow(df)*(1 - prop_drop))

  #compute new estimate
  reg_sliced <- stats::update(reg, data = df_sliced)

  #retrieve point estimates and se
  if (inherits(reg, c("lm", "plm"))) {
    coef_table <- summary(reg)$coefficients
    coef_table_sliced <- summary(reg_sliced)$coefficients
  } else if (inherits(reg, "fixest")) {
    coef_table <- reg$coeftable
    coef_table_sliced <- reg_sliced$coeftable
  }

  est_full <- coef_table[[var_interest, "Estimate"]]
  est_sliced <- coef_table_sliced[[var_interest, "Estimate"]]
  se_full <- coef_table[[var_interest, "Std. Error"]]
  se_sliced <- coef_table_sliced[[var_interest, "Std. Error"]]

  out <- data.frame(
    prop_drop = prop_drop,
    prop_change_est = (est_full - est_sliced)/est_full,
    prop_change_se = (se_full - se_sliced)/se_full
  )

  return(out)
}
