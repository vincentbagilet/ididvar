#' Run the regression with low weight observations dropped
#'
#' @description
#' Re-run the regression but dropping low weight observations.
#'
#' @details
#' This function recomputes the weights
#'
#' @inheritParams idid_weights
#' @param prop_drop Proportion of observations to drop
#'
#' @returns
#' A regression object
#'
#' @export
#'
#' @examples
#' reg_ex <- ggplot2::economics |>
#'   lm(formula = unemploy ~ pce + uempmed + psavert + pop)
#'
#' idid_drop_reg(reg_ex, "pce", prop_drop = 0.1)
idid_drop_reg <- function(reg,
                          var_interest,
                          prop_drop,
                          ...) {
  df <- eval(reg$call$data, envir = environment(stats::formula(reg)))

  df[["idid_weight"]] <- ididvar::idid_weights(reg, var_interest, ...)

  #keep high weights
  df_sliced <- df[order(df$idid_weight, decreasing = TRUE),] |>
    utils::head(n = nrow(df)*(1 - prop_drop))

  #compute new estimate
  reg_sliced <- stats::update(reg, data = df_sliced, use_calling_env = FALSE) |>
    #handle warning linked to the use of use_calling_env
    #this parameter is necessary for fixest
    withCallingHandlers(
      warning = function(w) {
        if (grepl("use_calling_env",
                  conditionMessage(w))) {
          invokeRestart("muffleWarning")
        }
      }
    )

  return(reg_sliced)
}
