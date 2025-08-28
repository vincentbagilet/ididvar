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
#' They are computed by re-running the regression provided but replacing the
#' independent variable by the variable of interest (and removing it from the
#' set of regressors).
#'
#' If the nature of the independent variable and of the variable of interest
#' are different, one may want to change the estimation.
#' For instance, if the independent variable is discrete and estimated via glm
#' with the argument \code{family = "binomial"} and the dependent variable is
#' continuous, one may want to provide the argument \code{family = "gaussian"}
#' to \code{idid_weights}.
#'
#' @param reg A regression object.
#' @param var_interest A string. The name of the main variable of interest.
#' @param ... Additional elements to pass to the regression function when
#' partialling out controls.
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
idid_weights <- function(reg, var_interest, ...) {
  #additional arguments to the regression
  # other_args <- list(
  #   na.action = na.exclude #add NAs to the weights when values missing for some regressors
  # )
  # if (inherits(reg, "fixest")) other_args$na.action <- NULL

  x_per <-
    update(
      reg,
      stats::as.formula(paste(var_interest, "~ . -", var_interest)),
      na.action = na.exclude,
      ...
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



