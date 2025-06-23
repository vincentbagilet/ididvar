ggplot2::mpg |>
  dplyr::mutate(
    weights = idid_weights(lm(cty ~ displ, ggplot2::mpg), "displ"),
    md = paste(model, trans, sep = "_")
  ) |>
  idid_heatmap(weights, year, md, keep_labels = FALSE) +
  ggplot2::facet_wrap(~ manufacturer, scales = "free_y")


dat <- ggplot2::mpg |>
  dplyr::mutate(
    weights = idid_weights(lm(cty ~ displ, ggplot2::mpg), "displ"),
    md = paste(model, trans, sep = "_")
  )

regt <- ggplot2::mpg |>
  dplyr::mutate(
    md = paste(model, trans, sep = "_")
  ) |>
  lm(formula = cty ~ displ)

# ggplot2::mpg |>
#   ggplot2::ggplot(ggplot2::aes(x = displ, y = cty)) +
#   ggplot2::geom_point()+
#   ggplot2::geom_smooth(method = "lm")


idid_diff_drop(regt, "displ", 0.2) |> dplyr::tibble()


lapply(seq(0.2, 0.9, 0.1), idid_diff_drop, reg = regt, var_interest = "displ") |> do.call(what = rbind)

purrr::map(seq(0.2, 0.9, 0.1), idid_diff_drop, reg = regt, var_interest = "displ") |>
  dplyr::bind_rows() |>
  dplyr::tibble() |>
  ggplot2::ggplot(ggplot2::aes(x = prop_keep, y = var_se)) +
  ggplot2::geom_line()


idid_heatmap_contrib(regt, "displ", var_1 = year, var_2 = md, keep_labels = FALSE)
