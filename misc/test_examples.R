reg_ex <- ggplot2::economics |>
  dplyr::mutate(
    year = lubridate::year(date),
    year_fe = year |> as.factor(),
    group_
  ) |>
  lm(formula = unemploy ~ pce + uempmed + psavert + pop + year_fe)

idid_viz_weights(reg_ex, "pce", var_x = year) +
  ggplot2::labs(x = NULL)

idid_viz_contrib(reg_ex, "pce", var_1 = pop) +
  ggplot2::labs(x = NULL)



#regression using lm
reg_ex_lm <- ggplot2::txhousing |>
  lm(formula = volume ~ sales + listings + city + as.factor(date))

#regression using fixest
reg_ex_fixest <- ggplot2::txhousing  |>
  fixest::feols(fml = volume ~ sales + listings |  as.factor(date) + city)

#regression using plm
reg_ex_plm <- ggplot2::txhousing  |>
  plm::plm(
    formula = volume ~ sales + listings,
    index = c("date", "city"),
    model = "within",
    effect = "twoways"
  )

#computing identifying variation weights
idid_weights(reg_ex_fixest, "sales") |>
  head()

idid_weights(reg_ex_lm, "sales") |>
  head()

idid_weights(reg_ex_plm, "sales") |>
  head()


txhousing_clean <- ggplot2::txhousing |>
  dplyr::mutate(dt = as.factor(date)) |>
  tidyr::drop_na()


#regression using lm
reg_ex_lm <- ggplot2::txhousing |>
  lm(formula = volume ~ sales + listings + city + as.factor(date))

idid_viz_weights(reg_ex_lm, "sales", city) +
  ggplot2::coord_flip() +
  ggplot2::labs(x = NULL)

#regression using fixest
reg_ex_fixest <- ggplot2::txhousing |>
  fixest::feols(fml = volume ~ sales + listings |  as.factor(date) + city)

idid_viz_weights(reg_ex_fixest, "sales", city, date)

#regression using plm
reg_ex_plm <- ggplot2::txhousing  |>
  plm::plm(
    formula = volume ~ sales + listings,
    index = c("date", "city"),
    model = "within",
    effect = "twoways"
  )



idid_weights(reg_ex_lm, "sales") |>
  head()

idid_weights(reg_ex_plm, "sales") |>
  head()
