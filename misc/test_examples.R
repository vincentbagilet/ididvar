reg_test <- ggplot2::economics |>
  dplyr::mutate(
    year = lubridate::year(date),
    year_fe = year |> as.factor()
  ) |>
  lm(formula = unemploy ~ pce + uempmed + psavert + pop + year_fe)

idid_weights_viz(reg_test, "pce", var_x = pop) +
  ggplot2::labs(x = NULL)

idid_contrib_viz(reg_test, "pce", var_1 = pop) +
  ggplot2::labs(x = NULL)



