#' Run the regression with low weight observations dropped
#'
#' @description
#' Re-run the regression but dropping low weight observations.
#'
#' @details
#' This function recomputes the weights. Observations outside the estimation
#' sample are dropped. Observations with the same weight are all kept or all
#' dropped, so the proportion of observations dropped can be lower than
#' \code{prop_drop}.
#'
#' @inheritParams idid_weights
#' @param prop_drop Proportion of observations of the estimation sample to drop
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
  df <- idid_data(reg)

  df[["idid_weight"]] <- ididvar::idid_weights(reg, var_interest, ...)

  #keep high weights (which() drops observations outside the estimation sample)
  weight_threshold <- idid_weight_threshold(df$idid_weight, prop_drop)
  df_sliced <- df[which(df$idid_weight >= weight_threshold), ]

  #compute new estimate
  #use_calling_env is necessary for fixest and notes avoids repeating notes
  #shown at estimation. Both are fixest arguments only
  if (inherits(reg, "fixest")) {
    reg_sliced <- stats::update(
      reg,
      data = df_sliced,
      use_calling_env = FALSE,
      notes = FALSE
    )
  } else {
    reg_sliced <- stats::update(reg, data = df_sliced)
  }

  return(reg_sliced)
}
