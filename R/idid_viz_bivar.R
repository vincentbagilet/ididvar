#' Visualization of the relationship, after partialling out
#'
#' @description
#' Makes a bivariate graph to visualize the data and relationship between the
#' outcome and the variable of interest, after having partialLed out controls.
#'
#' @inheritParams idid_weights
#'
#' @returns
#' A ggplot2 graph of the relationship between the
#'
#' @export
#'
idid_viz_bivar <- function(reg, var_interest) {
  df <- eval(reg$call$data)
  name_var_y <- reg$call[[2]][[2]]

  df[["y_par"]] <- ididvar::idid_partial_out(reg, name_var_y, var_interest)
  df[["x_par"]] <- ididvar::idid_partial_out(reg, var_interest)
  # df[["weight"]] <- ididvar::idid_weights(reg, var_interest)
  # df[["weight_log"]] <- log10(df$weight * nrow(df))

  df |>
    ggplot2::ggplot(ggplot2::aes(x = x_par, y = y_par)) +
    ggplot2::geom_point(color = idid_colors_table[[1, "base"]]) +
    ggplot2::geom_smooth(
      method = "lm",
      formula = 'y ~ x',
      color = idid_colors_table[[1, "complementary"]],
      fill = idid_colors_table[[1, "complementary"]]
    ) +
    ididvar::theme_idid() +
    ggplot2::labs(
      title = "Relationship after partialling out controls",
      subtitle = paste("In the", deparse(substitute(reg)), "model"),
      caption = paste("Full model:", deparse(reg$call[[2]])),
      x = paste(var_interest, "(residualized)"),
      y = paste(name_var_y, "(residualized)")
    )
}
