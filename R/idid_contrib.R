idid_contrib <- function(reg, var_interest) {
  df <- eval(reg$call$data)
  fml <- reg$call$formula

  df$idid_weights <- ididvar::idid_weight(reg, var_interest)

  #keep high weights
  prop_keep <- 0.1
  df_sliced <- df[order(df$idid_weights),] |>
    tail(n = nrow(df)*prop_keep)

  #compute new estimate
  reg_sliced <- lm(fml, data = df_sliced)
  coef_sliced <- reg_sliced$coefficients[[var_interest]]
  coef_full <- reg$coefficients[[var_interest]]
  var_est <- (coef_full - coef_sliced)/coef_full
}
