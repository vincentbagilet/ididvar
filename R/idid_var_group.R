#' Find the variable along which the weights are the most homogeneous
#' within groups formed by this variable
#'
#'
#' @description
#' For now, I
#'
#' @param reg An object describing the model (e.g. `lm()` or `glm()`) fit.
#' @param var_interest The variable of interest.
#' @param grouping_vars A list or vector of variables to use as the grouping factor.
#'
#' @returns
#' Data frame where each row is a unique group and contains its mean variance,
#' ordered from lowest to highest. Currently unused arguments are passed on to
#' `idid_weights`.
#'
#' @export
idid_grouping_var <- function(reg, var_interest, grouping_vars = "everything") {
  df <- eval(reg$call$data)
  df[["weight"]] = idid_weights(reg, var_interest)
  grouping_vars <- if ("everything" %in% grouping_vars) names(df) else grouping_vars
  grouping_vars <- grouping_vars[-which(grouping_vars == var_interest)]

  within_var <- NULL
  betwen_var <- NULL
  for (grouping_var in grouping_vars) {
    #compute within var
    var_in_group <- tapply(df[["weight"]], df[[grouping_var]], var)
    var_in_group <- replace(var_in_group, is.na(var_in_group), 0)
    within_var <- append(within_var, mean(var_in_group))

    #compute between var
    weight_in_group <-
      aggregate(
        df$weight,
        by = list(grouping_var = df[[grouping_var]]),
        FUN = sum
      )
    betwen_var <- append(betwen_var, var(weight_in_group$x))
  }

  # grouping_vars[(mean_var == min(mean_var, na.rm = TRUE))]

  out <- data.frame(grouping_vars, within_var, betwen_var)

  return(out[order(within_var),])
}
