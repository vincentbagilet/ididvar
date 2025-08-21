idid_contrib <- function(reg,
                         var_interest,
                         threshold_change = 0.05,
                         step_drop = 0.1) {

  df <- eval(reg$call$data)
  df[["weights"]] <- ididvar::idid_weights(reg, var_interest)
  cross_section <- missing(var_2)

  #compute the prop of obs to keep/drop without changing the estimates
  #by more than threshold_change
  small_change <- TRUE
  prop_drop <- 0
  while (small_change) {
    prop_drop <- prop_drop + step_drop
    small_change <- ididvar::idid_drop_change(reg, var_interest, prop_drop = prop_drop, threshold_change = threshold_change)$small_change
  }

  weight_threshold <- df[[floor(prop_drop*nrow(df)), "weights"]]

  message(paste("The weight threshold is", round(weight_threshold, 4)))

  df[["contrib"]] <- (df[["weights"]] < weight_threshold)
  df[["contrib_name"]] <- ifelse(df[["contrib"]], "Contributing", "Non-contributing")

}
