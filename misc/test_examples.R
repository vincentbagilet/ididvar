reg_test <- ggplot2::economics |>
  dplyr::mutate(
    year = lubridate::year(date) |> as.factor()
  ) |>
  lm(formula = unemploy ~ pce + uempmed + psavert + pop + year)

idid_contrib_viz(reg_test, "pce", var_1 = year) +
  ggplot2::labs(x = NULL)



