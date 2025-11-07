library(tidyverse)
library(fixest)

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

## Testing iv to control function

#first check that it works
reg_iv <- data_ex |>
  feols(fml = unemploy ~ psavert + pop | year_fe | pce ~ uempmed, vcov = "hetero")

reg_iv
first_stage <- data_ex |>
  feols(fml = pce ~ uempmed + psavert + pop | year_fe)

cf_iv <- data_ex |>
  mutate(
    pred_first = predict(first_stage),
  ) %>%
  mutate(
    unempl_res = predict(feols(data = ., fml = unemploy ~ pred_first + psavert + pop | year_fe))
  ) |>
  feols(fml = unempl_res ~ pred_first + psavert + pop | year_fe)

reg_iv
cf_iv

ld <- rnorm(574)

update(reg_iv, fml = as.formula(". ~ . + ld"))

cf_iv <- data_ex |>
  mutate(resid_first = residuals(first_stage)) |>
  feols(fml = unemploy ~ pce + psavert + pop + resid_first | year_fe)


reg_iv
cf_iv


form <- reg_iv$call[[2]]


reg_iv$fml_all$linear



deparse(form) |>
  str_ex


|>
  as.formula()






#only works
idid_to_cf <- function(reg) {
  if (!inherits(reg, "fixest")) stop("Model must be from fixest::feols().")
  if (is.null(reg$iv)) stop("This feols model is not an IV regression.")

  df <- eval(reg$call$data, envir = environment(stats::formula(reg)))
  df[["first_predict"]] <- reg$iv_first_stage[["endo_var"]] |> pedict()

  formula_second_stage <-
      stats::as.formula(
        paste(". ~ . -", var_interest)
        # env = environment(stats::formula(reg))
      )

  reg_cf <-
    stats::update(
      reg,
      formula_second_stage,
      na.action = stats::na.exclude,
      ...
    ) |>
    #handle warning when using feols for instance:
    #feols does not have a 'na.action' argument
    withCallingHandlers(
      warning = function(w) {
        if (grepl("na.action is not a valid",
                  conditionMessage(w))) {
          invokeRestart("muffleWarning")
        }
      }
    )

  return(reg_cf)
}
