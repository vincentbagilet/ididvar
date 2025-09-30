reg_test <- ggplot2::mpg |>
  dplyr::mutate(
    md = paste(model, trans, sep = "_")
    # year = as.factor(year)
  ) |>
  lm(formula = cty ~ displ + drv)

reg_test |>
  idid_weights("displ")

reg_test |>
  idid_viz_weights("displ", year, model) +
  ggplot2::facet_wrap(~ manufacturer)


dat <- eval(reg_test$call$data) |>
  dplyr::mutate(
    weight = idid_weights(reg_test, "displ"),
    weight_cat = idid_weights_cat(weight),
    contrib = (weight > idid_contrib_threshold(reg_test, "displ")),
    md = paste(model, trans, sep = "_")
  )

# ggplot2::mpg |>
#   ggplot2::ggplot(ggplot2::aes(x = displ, y = cty)) +
#   ggplot2::geom_point()+
#   ggplot2::geom_smooth(method = "lm")

idid_drop_change(reg_test, "displ", 0.1) |> dplyr::tibble()

lapply(seq(0.1, 0.9, 0.05), idid_drop_change, reg = reg_test, var_interest = "displ") |> do.call(what = rbind)

purrr::map(seq(0.2, 0.9, 0.1), idid_drop_change, reg = reg_test, var_interest = "displ") |>
  purrr::list_rbind() |>
  ggplot2::ggplot(ggplot2::aes(x = prop_drop, y = abs(prop_change_se))) +
  ggplot2::geom_line()

contrib_threshold <- idid_contrib_threshold(reg_test, "displ", threshold_change = 0.05)

idid_viz_contrib(reg_test, "displ", var_x = year, var_y = md) +
  ggplot2::facet_wrap(~ manufacturer, scales = "free_y")

# idid_viz(reg_test, "displ", manufacturer, md, keep_labels = FALSE)

+
  ggplot2::facet_wrap(~ manufacturer, scales = "free_y")


### Test-feols
reg_test <- ggplot2::mpg |>
  dplyr::mutate(
    md = paste(model, trans, sep = "_")
  ) |>
  fixest::feols(fml = cty ~ displ + drv | year)

dat <- ggplot2::mpg |>
  dplyr::mutate(
    weights = idid_weights(fixest::feols(cty ~ displ + drv | year, ggplot2::mpg), "displ"),
    md = paste(model, trans, sep = "_")
  )


### Additional tests

idid_viz_drop_change(reg_test, "displ")

idid_grouping_var(reg_test, "displ", names(ggplot2::mpg))

idid_viz_weights(reg_test, "displ", year, manufacturer)

dat$weights |> idid_viz_cumul()


dat |>
  dplyr::arrange(weight) |>
  dplyr::mutate(
    obs_nb = dplyr::row_number(),
    cum_sum = cumsum(weight)
  ) |>
  ggplot2::ggplot(ggplot2::aes(x = obs_nb, y = cum_sum)) +
  ggplot2::geom_line()




