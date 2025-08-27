#' Visualize changes in point estimate and s.e. when dropping observations
#'
#' @description
#' Make a faceted line graph describing the percentage variation of the point
#' estimate and s.e. of interest as a function of the proportion of
#' observations dropped.
#'
#' @inheritParams idid_drop_change
#' @inheritParams idid_contrib_threshold
#' @param search_start A numeric (between 0 and 1). Proportion of observation to
#' drop in the first step of the loop in \code{idid_contrib_threshold}.
#' @param search_end A numeric (between 0 and 1). Proportion of observation to
#' drop in the last step of the loop in \code{idid_contrib_threshold}.
#'
#' @returns
#' A ggplot2 object.
#'
#' The name of the facet variable is \code{measure}.
#'
#' @importFrom ggplot2 %+replace%
#'
#' @export
#'
#' @examples
#' reg_ex <- ggplot2::txhousing |>
#'   lm(formula = volume ~ sales + listings + city + as.factor(date))
#'
#' idid_viz_drop_change(reg_ex, "sales") +
#'   ggplot2::facet_wrap(~ measure, nrow = 2)
idid_viz_drop_change <- function(reg,
                                 var_interest,
                                 threshold_change = 0.05,
                                 search_step = 0.05,
                                 search_start = search_step,
                                 search_end = 1 - search_step) {
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
    ggplot2::geom_line(linewidth = 1.4, color = "#300D49") +
    ggplot2::geom_hline(
      yintercept = threshold_change*100,
      linetype = "dashed",
      color = "#300D49"
    ) +
    ggplot2::facet_wrap(~ measure) +
    ididvar::theme_idid() +
    ggplot2::theme(
      # text = ggplot2::element_text(family = "lato"),
      panel.grid.major.y = ggplot2::element_line()
    ) +
    ggplot2::labs(
      title = "Variation of the estimate when dropping observations",
      x = "Proportion of observations dropped",
      y = "Variation (in %)\nas compared to the full sample estimate "
    )
}
