#' Visualization of the relationship between x and y, after partialling out
#'
#' @description
#' Makes a bivariate graph to visualize the data and relationship between the
#' outcome and the variable of interest, after having partialLed out controls.
#'
#' @inheritParams idid_weights
#'
#' @returns
#' A ggplot2 scatter plot and regression line of the relationship between the
#' outcome and the variable of interest, after partialling out controls.
#'
#' @export
#'
#' @examples
#' reg_few_ctrl <- ggplot2::txhousing |>
#'   lm(formula = volume ~ sales + listings)
#'
#' idid_viz_bivar(reg_few_ctrl, "sales")
#'
#' reg_more_ctrl <- ggplot2::txhousing |>
#'   lm(formula = volume ~ sales + listings + city + as.factor(date))
#'
#' idid_viz_bivar(reg_more_ctrl, "sales")
#'
idid_viz_bivar <- function(reg, var_interest) {
  df <- eval(reg$call$data)
  name_var_y <- reg$call[[2]][[2]]

  df[["y_par"]] <- ididvar::idid_partial_out(reg, name_var_y, var_interest)
  df[["x_par"]] <- ididvar::idid_partial_out(reg, var_interest)
  # df[["weight"]] <- ididvar::idid_weights(reg, var_interest)
  # df[["weight_log"]] <- log10(df$weight * nrow(df))

  df |>
    ggplot2::ggplot(ggplot2::aes(x = .data$x_par, y = .data$y_par)) +
    ggplot2::geom_point(
      color = ididvar::idid_colors_table[[1, "base"]],
      alpha = if (nrow(df) > 1000) 0.6 else 1
    ) +
    ggplot2::geom_smooth(
      method = "lm",
      formula = 'y ~ x',
      color = ididvar::idid_colors_table[[1, "complementary"]],
      fill = ididvar::idid_colors_table[[1, "complementary"]],
      alpha = 0.15
    ) +
    ididvar::theme_idid() +
    ggplot2::labs(
      title = "Relationship after partialling out controls",
      subtitle = paste("In the", substitute(reg), "model"),
      caption = paste("Full model:", deparse(reg$call[[2]])),
      x = paste(var_interest, "(residualized)"),
      y = paste(name_var_y, "(residualized)")
    )
}
