#' Retrieve the data used to estimate a regression
#'
#' @description
#' Retrieves the data set used to estimate a regression and checks that it
#' still matches the regression.
#'
#' @details
#' For \code{fixest} objects, the data is retrieved with
#' \code{fixest::fixest_data}. If the regression was estimated with
#' \code{data.save = TRUE}, this is the data saved in \code{reg}, which remains
#' valid even if the data has been modified since. For other objects, the data
#' is evaluated in the environment of the formula. In both cases, the data is
#' found even when the regression was estimated inside a function.
#'
#' The function returns an error if the data cannot be found or if it does not
#' match the regression anymore, for instance if rows have been dropped after
#' estimation. For \code{fixest} objects, the number of rows of the data must be
#' equal to the number of observations before any is removed
#' (\code{reg$nobs_origin}). For other objects, all the row names of the model
#' frame must be row names of the data.
#'
#' @inheritParams idid_partial_out
#'
#' @returns
#' The data frame used to estimate \code{reg}.
#'
#' @keywords internal
idid_data <- function(reg) {
  if (inherits(reg, "fixest")) {
    #returns the data saved in reg if estimated with data.save = TRUE
    df <- tryCatch(fixest::fixest_data(reg), error = function(e) NULL)
  } else {
    df <- tryCatch(
      eval(reg$call$data, envir = environment(stats::formula(reg))),
      error = function(e) NULL
    )
  }

  #check is.data.frame rather than is.null: if the data is called df but cannot
  #be found, R does not fail, it returns the function stats::df
  if (!is.data.frame(df)) {
    stop("Cannot find the data used to estimate reg")
  }

  #check that the data has not been modified since the estimation
  if (inherits(reg, "fixest")) {
    data_match <- reg$nobs_origin == nrow(df)
  } else {
    data_match <- all(rownames(stats::model.frame(reg)) %in% rownames(df))
  }

  if (!data_match) {
    stop("The data does not match the one used to estimate reg. It may have been modified after estimation")
  }

  return(df)
}
