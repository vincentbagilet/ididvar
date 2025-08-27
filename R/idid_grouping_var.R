#' Computes the within-group and between-group weight variances
#'
#' @description
#' Groups weights by each of the variables listed in \code{grouping_vars},
#' and computes the within-group variances and between-group variances.
#'
#' This function allows to identify variables for which grouping by this
#' variable yields the most homogeneous within group variance in weights or the
#' most heterogeneous between groups variance
#'
#' @inheritParams idid_weights
#' @param grouping_vars A string vector of variable names or \code{"everything"}.
#' The set of variables to group weights by. If \code{"everything"} passed,
#' group by each of the variables in the data set successively.
#'
#' @returns A dataframe with 3 columns:
#' - `grouping_var` the names of grouping var
#' - `within_var` the within-group variation in weights
#' - `between_var` the between-group variation in weights
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
      stats::aggregate(
        df$weight,
        by = list(grouping_var = df[[grouping_var]]),
        FUN = sum
      )
    betwen_var <- append(betwen_var, stats::var(weight_in_group$x))
  }

  # grouping_vars[(mean_var == min(mean_var, na.rm = TRUE))]

  out <- data.frame(grouping_var = grouping_vars, within_var, betwen_var)

  return(out[order(within_var),])
}
