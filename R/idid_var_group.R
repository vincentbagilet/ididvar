

idid_var_group <- function(reg, var_interest, group_vars) {
  df <- eval(reg$call$data)
  df[["weight"]] = idid_weights(reg, var_interest)

  mean_var <- NULL
  for (group_var in group_vars) {
    var_in_group <- tapply(df[["weight"]], df[[group_var]], var)
    var_in_group <- replace(var_in_group, is.na(var_in_group), 0)

    mean_var <- append(mean_var, mean(var_in_group))
  }

  # group_vars[(mean_var == min(mean_var, na.rm = TRUE))]

  out <- data.frame(group_vars, mean_var)

  return(out[order(mean_var),])
}
