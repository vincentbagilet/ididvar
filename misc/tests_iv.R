library(tidyverse)
library(fixest)
library(ididvar)

#test whether my package works with IVs
data_ex <- ggplot2::economics |>
  dplyr::mutate(
    year = lubridate::year(date),
    year_fe = year |> as.factor()
  )

reg_iv <- data_ex |>
  feols(fml = unemploy ~  1 | year_fe | pce + psavert ~ uempmed + pop)

reg_iv <- data_ex |>
  feols(fml = unemploy ~ psavert + pop | year_fe | pce ~ uempmed)

reg_ivreg <-
  AER::ivreg(
    data = data_ex,
    formula = unemploy ~ pce + psavert + pop + year_fe | uempmed + psavert + pop + year_fe
  )

AER::ivreg(data = data_ex, formula = unemploy ~ pce + psavert + pop + year_fe)

reg_ex <- data_ex |>
  lm(formula = unemploy ~ pce + uempmed + psavert + pop + year_fe)




# testing idid functions
idid_viz_weights(reg_iv, "pce", var_x = year) +
  ggplot2::labs(x = NULL)

idid_drop_change(reg_iv, "pce", 0.1)
idid_contrib_threshold(reg_iv, "pce", 0.1)
idid_contrib_stats(reg_iv, "pce")

idid_viz_contrib(reg_iv, "pce", year)

idid_viz_drop_change(reg_iv, "pce", search_end = 0.8)

## Testing iv to control function

#first check that it works
reg_iv <- data_ex |>
  feols(fml = unemploy ~ psavert + pop | year_fe | pce ~ uempmed, vcov = "hetero")


first_stage <- data_ex |>
  feols(fml = pce ~ uempmed + psavert + pop | year_fe)

cf_iv <- data_ex |>
  mutate(
    resid_first = residuals(first_stage)
  ) |>
  feols(fml = unemploy ~ pce + psavert + pop + resid_first | year_fe)



hand_2sls <- data_ex |>
  mutate(
    pred_first = predict(first_stage)
  ) |>
  feols(fml = unemploy ~ pred_first + psavert + pop | year_fe)

# cf_iv <- data_ex |>
#   mutate(
#     pred_first = predict(first_stage),
#   ) %>%
#   mutate(
#     unempl_res = predict(feols(data = ., fml = unemploy ~ pred_first + psavert + pop | year_fe))
#   ) |>
#   feols(fml = unempl_res ~ pred_first + psavert + pop | year_fe)

reg_iv
cf_iv
hand_2sls

x_per_cf <- update(cf_iv, as.formula("pce ~ . | .")) |> residuals()
y_per_cf <- update(cf_iv, as.formula(". ~ . - pce | .")) |> residuals()

x_per_cf |> qplot()
qplot(data_ex$pce - mean(data_ex$pce))

lm(y_per_cf ~ x_per_cf) |>
  summary()

reg_iv

# check the equivalence of weights depending on the specification
weight_cf <- data_ex |>
  mutate(
    resid_first = residuals(first_stage)
  ) |>
  feols(fml = pce ~ psavert + pop + resid_first | year_fe) |>
  residuals() %>%
  .^2

weight_cf |> head()

weight_pred <- data_ex |>
  mutate(
    pred_first = predict(first_stage)
  ) |>
  feols(fml = pred_first ~ psavert + pop | year_fe) |>
  residuals() %>%
  .^2

weight_pred |> head()

