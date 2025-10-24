library(tidyverse)
library(causaldata)
library(AER)
library(fixest)

## ------- CARD ---------- ##

close_college_clean <- close_college |>
  mutate(id = row_number()) |>
  remove_missing()

reg_ols <- feols(data = close_college_clean, fml = lwage ~ educ + exper + black + south + married + smsa)
reg_ols

reg_iv <- feols(data = close_college_clean, fml = lwage ~ exper + black + south + married + smsa | 0 | educ ~ nearc4)
reg_iv

reg_regiv <- AER::ivreg(data = close_college_clean, formula = lwage ~ educ + exper + black + south + married + smsa | nearc4 + exper + black + south + married + smsa)
summary(reg_regiv)

#control function approach
ctrl <- feols(data = close_college_clean, fml = educ ~ nearc4 + exper + black + south + married + smsa) |> predict()

reg_ctrl <- close_college_clean |>
  mutate(ctrl = ctrl) |>
  feols(data = _, fml = lwage ~ ctrl + exper + black + south + married + smsa)
reg_ctrl

#graphs
idid_drop_change(reg_ols, "educ", 0.3)
idid_viz_contrib(reg_ols, "educ", exper)
idid_viz_bivar(reg_ols, "educ")

# the control function approach cannot work because do not compare to the right thing I think
idid_viz_weights(reg_ctrl, "ctrl", exper)

idid_viz_bivar(reg_ctrl, "ctrl")
idid_viz_contrib(reg_ctrl, "ctrl", educ)

idid_weights(reg_ctrl, "ctrl") |> idid_viz_cumul()




idid_viz_weights(reg_regiv, "educ", exper)


#######------------- OTHER EX ------------ ###


od <- causaldata::organ_donations

# Treatment variable
od <- od %>%
  mutate(
    Treated = State == 'California' &
           Quarter %in% c('Q32011','Q42011','Q12012'),
    Treated = as.integer(Treated)
  )

# feols clusters by the first
# fixed effect by default, no adjustment necessary
clfe <- lm(Rate ~ Treated + State + Quarter,
              data = od)
# msummary(clfe, stars = c('*' = .1, '**' = .05, '***' = .01))

clfe |>
  idid_viz_contrib("Treated", Quarter, State)


