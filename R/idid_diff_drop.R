#' Difference drop regression output
#'
#' @description
#' Compute a difference in coefficients and their standard errors for an item of interest.
#' If these are not "small," i.e. below the threshold, drop it.
#'
#' @param reg A regression result object.
#' @param var_interest The variable to examine on `reg`.
#' @param prop_keep Proportion (as a proportion, e.g., 0.2 for 20%) of "largest" values to keep.
#' @param threshold_diff What constitutes an implausible difference or uncertainty? Optional.
#'
#+
#' If the differences or standard errors are large, drop their corresponding observation from the dataset.
#' The function uses these in `ididvar::idid_weights`.
#'
#' @returns
#' A dataframe of interest:
#' - `prop_keep`: the proportion (of total data) kept by calling this method.
#' - `var_est`: relative change between \code{est} with and without large values
#' - `var_see`: relative change between their standard errors
#' @export
idid_diff_drop <- function(reg,
                           var_interest,
                           prop_keep,
                           threshold_diff = 0.05) {
  df <- eval(reg$call$data)
  fml <- reg$call$formula

  df[["idid_weights"]] <- ididvar::idid_weights(reg, var_interest)

  #keep high weights
  df_sliced <- df[order(df$idid_weights),] |>
    tail(n = nrow(df)*prop_keep)

  #compute new estimate
  reg_sliced <- lm(fml, data = df_sliced)
  coef_full <- reg$coefficients[[var_interest]]
  coef_sliced <- reg_sliced$coefficients[[var_interest]]
  se_full <- summary(reg)$coefficients[[var_interest, "Std. Error"]]
  se_sliced <- summary(reg_sliced)$coefficients[[var_interest, "Std. Error"]]

  out <- data.frame(
    prop_keep = prop_keep,
    var_est = (coef_full - coef_sliced)/coef_full,
    var_se = (se_full - se_sliced)/se_full
  )

  out[["small_diff"]] = (abs(out$var_est) < threshold_diff &
                         abs(out$var_se) < threshold_diff)

  return(out)
}
