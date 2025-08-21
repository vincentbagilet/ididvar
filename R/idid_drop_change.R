#' Variation in estimate when dropping low weight observations
#'
#' @description
#' Computes a variation of the point estimate and standard errors of the variable
#' of interest when dropping low weight observations.
#'
#' @param reg A regression result object.
#' @param var_interest The variable to examine on `reg`.
#' @param prop_drop Proportion of observations to drop
#' @param threshold_change What constitutes an implausible difference or uncertainty? Optional.
#'
#+
#' If the differences or standard errors are large, drop their corresponding observation from the dataset.
#' The function uses these in `ididvar::idid_weights`.
#'
#' @returns
#' A dataframe of interest:
#' - `prop_drop`: the proportion (of total data) dropped by calling this method.
#' - `var_est`: relative change between \code{est} with and without large values
#' - `var_se`: relative change between their standard errors
#' @export
idid_drop_change <- function(reg,
                             var_interest,
                             prop_drop,
                             threshold_change = 0.05) {
  df <- eval(reg$call$data)
  # fml <- reg$call$formula

  df[["idid_weights"]] <- ididvar::idid_weights(reg, var_interest)

  #keep high weights
  df_sliced <- df[order(df$idid_weights, decreasing = TRUE),] |>
    head(n = nrow(df)*(1 - prop_drop))

  #compute new estimate
  reg_sliced <- stats::update(reg, data = df_sliced)

  #retrieve point estimates and se
  if (class(reg) == "lm") {
    coef_table <- summary(reg)$coefficients
    coef_table_sliced <- summary(reg_sliced)$coefficients
  } else if (class(reg) == "fixest") {
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

  out[["small_change"]] = (abs(out$prop_change_est) < threshold_change &
                           abs(out$prop_change_se) < threshold_change)

  return(out)
}
