reg_ex <- ggplot2::economics |>
  dplyr::mutate(
    year = lubridate::year(date),
    year_fe = year |> as.factor()
  ) |>
  lm(formula = unemploy ~ pce + uempmed + psavert + pop + year_fe)

idid_viz_weights(reg_ex, "pce", var_x = year) +
  ggplot2::labs(x = NULL)



ex_data <- ggplot2::economics
ex_data[["year"]] <- substr(ex_data[["date"]], 1, 4) |> as.numeric()

reg_ex_lm <- lm(data = ex_data,
                formula = unemploy ~ pce + uempmed + psavert + pop + year)

idid_viz_weights(reg_ex_lm, "pce", var_x = year) +
  ggplot2::labs(x = NULL)



ex_data <- ggplot2::economics
ex_data[["year"]] <- substr(ex_data[["date"]], 1, 4) |> as.numeric()

reg_ex_lm <- lm(data = ex_data,
                formula = unemploy ~ pce + uempmed + psavert + pop + year)

eval(reg_ex_lm$call$data)




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

idid_viz_weights(reg_ex_lm, "sales", date, city) +
  ggplot2::labs(x = NULL, y = NULL)

#regression using fixest
reg_ex_fixest <- ggplot2::txhousing |>
  fixest::feols(fml = volume ~ sales + listings |  as.factor(date) + city)

idid_viz_weights(reg_ex_fixest, "sales", date, city) +
  ggplot2::labs(x = NULL, y = NULL)

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



ggplot2::mpg |>
  ggplot2::ggplot(ggplot2::aes(x = displ, hwy, color = cyl)) +
  ggplot2::geom_point() +
  ggplot2::labs(
    title = "A wonderful title",
    subtitle = "Something to add"
  ) +
  theme_idid()









