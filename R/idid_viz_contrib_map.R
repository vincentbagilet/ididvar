#' Plot a map of the effective sample
#'
#' @description
#' Makes a map to visualize observations that can be dropped without
#' changing the point estimate or the standard error of the estimate of
#' interest by more than a given proportion (\code{threshold_change}).
#'
#'
#' @inheritParams idid_viz_weights_map
#' @inheritParams idid_viz_contrib
#'
#' @returns
#' A ggplot object.
#'
#' @export
#'
#' @examples
#' reg <- state.x77 |>
#'   dplyr::as_tibble() |>
#'   dplyr::mutate(NAME = rownames(state.x77)) |>
#'   lm(formula = Illiteracy ~  Income + Population + `Life Exp` + Frost)
#'
#' states_sf <- tigris::states(
#'     cb = TRUE, resolution = "20m", year = 2024, progress_bar = FALSE) |>
#'   tigris::shift_geometry()
#'
#' idid_viz_contrib_map(reg, "Income", states_sf, "NAME")
idid_viz_contrib_map <- function(reg,
                                 var_interest,
                                 shape_file,
                                 join_by,
                                 contrib_threshold,
                                 threshold_change = 0.05,
                                 colors = c("#C25807", "#FBE2C5", "#300D49"),
                                 ...) {
  if (missing(contrib_threshold)) {
    message("Searching for the contribution threshold")
    contrib_threshold <- ididvar::idid_contrib_threshold(
      reg,
      var_interest,
      threshold_change = threshold_change,
      ...
    )
  }

  df <- eval(reg$call$data, envir = environment(formula(reg)))
  df[["weights"]] <- ididvar::idid_weights(reg, var_interest, ...)
  df[["contrib"]] <- (df[["weights"]] > contrib_threshold)
  df[["contrib"]] <- as.integer(df[["contrib"]])

  #compute shape level weights
  agg_df <- stats::aggregate(
    df$contrib,
    by = list(join_by = df[[join_by]]),
    FUN = sum,
    na.rm = TRUE
  )
  names(agg_df) <- c(join_by, "n_contrib")

  #merge with shapefile
  merged <- base::merge(shape_file, agg_df, by = join_by, all = TRUE)

  merged |>
    ggplot2::ggplot() +
    ggplot2::geom_sf(
      ggplot2::aes(fill = .data$n_contrib),
      color = "white",
      linewidth = 0.1
    ) +
    ididvar::theme_idid() +
    ggplot2::scale_fill_gradient(
      high = colors[length(colors)],
      low = colors[round(length(colors)/2)],
      na.value = "gray88"
    ) +
    ggplot2::labs(
      title = "Set of observations contributing to identification",
      subtitle = paste('Without the "non-contributing" observations,
point est. and s.e. would vary by less than ', round(threshold_change*100, 2), "%", sep = ""),
      fill =  "Number of contributing observations"
    ) +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_blank()
    )
}
