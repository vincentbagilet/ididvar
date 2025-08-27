#' Compute Identifying Variation Weights
#'
#' @description
#' Compute regression weights describing the amount of variation used for
#' identification.
#'
#' @details
#' The weights correspond to the normalized leverage of each observation for
#' the variable of interest after partialling out all controls.
#'
#' The function invokes particular methods which depend on the class of the
#' first argument.
#'
#' @param reg A regression object.
#' @param var_interest A string. The name of the main variable of interest.
#'
#' @returns
#' A numeric vector representing the identifying variation weights.
#'
#' @export
#'
#' @examples
#' # example with a lm regression
#' reg_ex_lm <- ggplot2::txhousing |>
#'   lm(formula = volume ~ sales + listings + city + as.factor(date))
#'
#' idid_weights(reg_ex_lm, "sales") |>
#'  head()
#'
#' # example with a fixest regression
#' reg_ex_fixest <- ggplot2::txhousing  |>
#'   fixest::feols(fml = volume ~ sales + listings |  as.factor(date) + city)
#'
#' idid_weights(reg_ex_fixest, "sales") |>
#'   head()
#'
#' # example with a plm regression
#' reg_ex_plm <- ggplot2::txhousing  |>
#'   plm::plm(
#'     formula = volume ~ sales + listings,
#'     index = c("date", "city"),
#'     model = "within",
#'     effect = "twoways"
#'   )
#'
#' idid_weights(reg_ex_plm, "sales") |>
#'   head()
idid_weights <- function(reg, var_interest) {
  x_per <-
    update(
      reg,
      stats::as.formula(paste(var_interest, "~ . -", var_interest)),
      na.action = na.exclude
    ) |>
    residuals(na.rm = FALSE) |>
    #handle warning when using feols for instance:
    #feols does not have a 'na.action' argument
    withCallingHandlers(
      warning = function(w) {
        if (grepl("na.action is not a valid argument for function",
                  conditionMessage(w))) {
          invokeRestart("muffleWarning")
        }
      }
    )

  weight <- (x_per - mean(x_per, na.rm = TRUE))^2
  weight <- weight/sum(weight, na.rm = TRUE)

  return(weight)
}



