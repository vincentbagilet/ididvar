#' Compute the between-group variances in weights
#'
#' @description
#' Identify variables along which groups may contribute heterogeneously
#' to identification.
#'
#' @details
#' Identify variables for which grouping by this
#' variable yields the most heterogeneous between-groups differences in weights
#' (i.e. the largest between-groups variance).
#'
#' @inheritParams idid_weights
#' @param grouping_vars A string vector of variable names or \code{"everything"}.
#' The set of variables to group weights by. If \code{"everything"} passed,
#' group by each of the variables in the data set successively.
#'
#' @returns A dataframe with 2 columns:
#' - `grouping_var` the names of grouping var
#' - `between_var` the between-group variation in weights
#'
#' @export
#'
#' @examples
#' reg_ex <- ggplot2::txhousing |>
#'   lm(formula = volume ~ sales + listings + city + as.factor(date))
#'
#' idid_grouping_var(reg_ex, "sales", grouping_vars = c("city", "year", "month"))
#'
#' #We can now then explore the weights along the dimension with the largest
#' #variance: year
#' idid_viz_weights(reg_ex, "sales", year)
idid_grouping_var <- function(reg,
                              var_interest,
                              grouping_vars,
                              ...) {
  df <- eval(reg$call$data, envir = environment(formula(reg)))
  df[["weight"]] = idid_weights(reg, var_interest, ...)

  between_var <- NULL
  for (grouping_var in grouping_vars) {

    #compute between var
    weight_in_group <-
      stats::aggregate(
        df$weight,
        by = list(grouping_var = df[[grouping_var]]),
        FUN = sum,
        na.rm = TRUE
      )
    between_var <- append(between_var, stats::var(weight_in_group$x))
  }

  out <- data.frame(grouping_var = grouping_vars, between_var)

  return(out[order(between_var, decreasing = TRUE),])
}
