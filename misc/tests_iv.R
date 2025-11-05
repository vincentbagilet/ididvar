library(tidyverse)
library(fixest)

#test whether my package works with IVs
data_ex <- ggplot2::economics |>
  dplyr::mutate(
    year = lubridate::year(date),
    year_fe = year |> as.factor()
  )

reg_iv <- data_ex |>
  feols(fml = unemploy ~ psavert + pop + year_fe | 0 | pce ~ uempmed)

reg_iv <-
  AER::ivreg(data = data_ex, formula = unemploy ~ pce + psavert + pop + year_fe | uempmed + psavert + pop + year_fe)

reg_ex <- data_ex |>
  feols(fml = unemploy ~ pce + uempmed + psavert + pop + year_fe)


idid_viz_weights(reg_iv, "pce", var_x = year) +
  ggplot2::labs(x = NULL)

idid_drop_change(reg_iv, "pce", 0.1)
idid_contrib_threshold(reg_iv, "pce", 0.1)
idid_contrib_stats(reg_iv, "pce")

idid_viz_contrib(reg_iv, "pce", year)
