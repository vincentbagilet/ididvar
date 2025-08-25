#' Drop change
#'
#' @description
#' A short description...
#'
#' @param reg A linear model. Optional.
#' @param var_interest A single variable. Optionally, a vector of variables if `reg_is_poly` is TRUE in the linear model used for prediction.
#' @param search_step One of `0`, `'0'`, `Inf` or `.Machine$double.xmax`. Currently unused; must be specified if it isn't one of these values or an error will occur. Optional.
#' @param search_start A positive number between 0 and .99 (inclusive). Optional.
#' @param search_end A positive number between 1 and .9999 (inclusive) and different from `search_start`. Currently unused; must not be equal to `.Machine$double.xmax` or an error will occur. Optional.
#'
#' @returns
#' If successful, a plot is made with lines representing the proportion of change in the measure(s) of interest at various drop thresholds as compared to the full sample from one end to the other. Invisible otherwise.
#'
#' @importFrom ggplot2 %+replace%
#'
#' @export
idid_drop_change_viz <- function(reg,
                                 var_interest,
                                 search_step = 0.05,
                                 search_start = search_step,
                                 search_end = 1 - search_step,
                                 threshold_change = 0.05) {
  drop_change_df <- seq(search_start, search_end, 0.05) |>
    lapply(
      idid_drop_change,
      reg = reg,
      var_interest = var_interest
    ) |>
    do.call(what = rbind)

  drop_change_est <- drop_change_df[, c("prop_drop", "prop_change_est")]
  names(drop_change_est) <- c("prop_drop", "prop_change")
  drop_change_est[["measure"]] <- "Estimate"

  drop_change_se <- drop_change_df[, c("prop_drop", "prop_change_se")]
  names(drop_change_se) <- c("prop_drop", "prop_change")
  drop_change_se[["measure"]] <- "Std. Error"

  rbind(drop_change_est, drop_change_se) |>
    ggplot2::ggplot(ggplot2::aes(x = prop_drop, y = abs(prop_change*100))) +
    ggplot2::geom_line(size = 0.8) +
    ggplot2::geom_hline(yintercept = threshold_change*100, linetype = "dashed") +
    ggplot2::facet_wrap(~ measure) +
    ididvar::theme_idid()  %+replace%
    ggplot2::theme(
      # text = ggplot2::element_text(family = "lato"),
      panel.grid.major.y = ggplot2::element_line()
    ) +
    ggplot2::labs(
      x = "Proportion of observations dropped",
      y = "Change as compared to the full sample (in %)"
    )
}
