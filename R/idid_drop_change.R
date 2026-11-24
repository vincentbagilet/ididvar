#' Variation in estimate when dropping low weight observations
#'
#' @description
#' Computes a variation of the point estimate and standard errors of the
#' coefficient of interest when dropping low weight observations.
#'
#' @details
#' Standard errors are retrieved with \code{vcov}. For \code{fixest} models,
#' both standard errors use the variance of \code{reg} (eg clustering set in
#' \code{summary}), without small sample correction, as this correction changes
#' mechanically when dropping observations.
#'
#' @inheritParams idid_drop_reg
#' @param vcov A function (optional). Computes the variance-covariance matrix
#' of a regression, eg \code{sandwich::vcovHC}. Used for both the full sample
#' and the dropped regressions. If NULL, the variance described in Details.
#'
#' @returns
#' A dataframe with one row per variable of interest and 4 columns:
#' - `prop_drop`: the proportion of data dropped
#' - `var_interest`: the name of the coefficient
#' - `prop_change_est`: the relative change between the full sample and
#' droped estimates
#' - `prop_change_se`: the relative change between the full sample and
#' droped s.e.
#'
#' The changes are NA if the coefficient cannot be estimated without the
#' dropped observations.
#'
#' @export
#'
#' @examples
#' reg_ex <- ggplot2::economics |>
#'   lm(formula = unemploy ~ pce + uempmed + psavert + pop)
#'
#' idid_drop_change(reg_ex, "pce", prop_drop = 0.1)
#'
#' #robust standard errors
#' idid_drop_change(reg_ex, "pce", prop_drop = 0.1, vcov = sandwich::vcovHC)
idid_drop_change <- function(reg,
                             var_interest,
                             prop_drop,
                             vcov = NULL,
                             ...) {
  if (!isTRUE(is.numeric(prop_drop) & prop_drop >= 0 & prop_drop < 1)) {
    stop("prop_drop must be a number between 0 and 1")
  }
  if (!is.null(vcov) && !is.function(vcov)) {
    stop("vcov must be a function, eg sandwich::vcovHC")
  }

  #some regression function "change" the name of the variable of interest
  #for instance for a boolean var "treated", in the coef table the name will be
  #treatedTRUE. Take that into account with var_interest_robust
  var_interest_robust <- idid_coef_names(reg, var_interest)

  #retrieve pt estimate and se (vcov rather than the coef table, whose column
  #names vary across packages)
  est_se <- function(reg_x) {
    if (!is.null(vcov)) {
      vcov_x <- vcov(reg_x)
    } else if (inherits(reg, "fixest")) {
      vcov_x <- stats::vcov(
        reg_x,
        vcov = reg$summary_flags$vcov,
        ssc = fixest::ssc(K.adj = FALSE, G.adj = FALSE)
      )
    } else {
      vcov_x <- stats::vcov(reg_x)
    }

    data.frame(
      est = stats::coef(reg_x)[var_interest_robust],
      se = sqrt(diag(vcov_x))[var_interest_robust]
    )
  }

  est_se_full <- est_se(reg)
  #NA if the regression fails without the dropped observations (eg no
  #variation left in the variable of interest)
  est_se_sliced <- tryCatch(
    est_se(ididvar::idid_drop_reg(reg, var_interest, prop_drop, ...)),
    error = function(e) data.frame(est = NA, se = NA)
  )

  out <- data.frame(
    prop_drop = prop_drop,
    var_interest = var_interest_robust,
    prop_change_est = (est_se_full$est - est_se_sliced$est)/est_se_full$est,
    prop_change_se = (est_se_full$se - est_se_sliced$se)/est_se_full$se
  )

  return(out)
}
