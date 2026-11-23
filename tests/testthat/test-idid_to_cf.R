test_that("refitting the control form gives back the coefficients of lm and glm", {
  df <- sim_panel()

  regs <- list(
    stats::lm(y ~ x + z, data = df, weights = w, subset = t > 1),
    stats::glm(binary ~ x + z, data = df, family = stats::binomial),
    stats::glm(count ~ x + z, data = df, family = stats::poisson, offset = log(w))
  )

  for (reg in regs) {
    cf <- idid_to_cf(reg)
    expect_s3_class(cf, "idid_cf")
    expect_equal(refit_cf(cf), cf$coefficients, tolerance = 1e-6)
  }
})

test_that("refitting the control form gives back the coefficients of fixest", {
  skip_if_not_installed("fixest")
  df <- sim_panel()
  df$inst[5] <- NA

  regs <- list(
    fixest::feols(y ~ x + z | id, data = df, weights = ~w, subset = ~ t > 1, notes = FALSE),
    #IV with fixed effects, a transformed endogenous variable and missing values
    fixest::feols(y ~ x | id | log(y_pos) + endo ~ inst + z, data = df, notes = FALSE),
    fixest::fepois(count ~ x + z | id, data = df, weights = ~w, offset = ~ log(w), notes = FALSE),
    fixest::feglm(binary ~ x + z, data = df, family = "logit", notes = FALSE)
  )

  for (reg in regs) {
    cf <- idid_to_cf(reg)
    expect_equal(refit_cf(cf), cf$coefficients, tolerance = 1e-6)
  }
})

test_that("refitting the control form gives back the coefficients of ivreg, plm and felm", {
  skip_if_not_installed("AER")
  skip_if_not_installed("plm")
  skip_if_not_installed("lfe")
  df <- sim_panel()
  df_shuffled <- df[sample(nrow(df)), ]

  regs <- list(
    #transformed variables
    AER::ivreg(log(y_pos) ~ x + exp(endo / 4) | x + exp(inst / 4), data = df),
    plm::plm(y ~ x + z, data = df_shuffled, index = c("id", "t"), model = "within"),
    plm::plm(y ~ x + z, data = df_shuffled, index = c("id", "t"), model = "fd"),
    plm::plm(y ~ x + z, data = df_shuffled, index = c("id", "t"), model = "random"),
    lfe::felm(y ~ x + z | id, data = df, weights = df$w)
  )

  for (reg in regs) {
    cf <- idid_to_cf(reg)
    expect_equal(refit_cf(cf), cf$coefficients, tolerance = 1e-6)
  }
})

test_that("idid_to_cf errors for unsupported models", {
  skip_if_not_installed("fixest")
  df <- sim_panel()

  expect_error(idid_to_cf(fixest::feols(y ~ z | id[t], data = df)), "varying slopes")
  expect_error(idid_to_cf(stats::nls(y ~ a * z, data = df, start = list(a = 1))), "does not support")
})
