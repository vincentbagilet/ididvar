test_that("the weights give back the coefficient: lm and glm", {
  df <- sim_panel()

  reg <- stats::lm(y ~ x + z, data = df, weights = w, subset = t > 1)
  expect_equal(fwl_estimate(reg, "x"), stats::coef(reg)[["x"]])

  reg <- stats::glm(count ~ x + z, data = df, family = stats::poisson, offset = log(w))
  expect_equal(fwl_estimate(reg, "x"), stats::coef(reg)[["x"]], tolerance = 1e-6)
})

test_that("the weights give back the coefficient: fixest", {
  skip_if_not_installed("fixest")
  df <- sim_panel()

  reg <- fixest::feols(y ~ x + z | id, data = df, weights = ~w, subset = ~ t > 1, notes = FALSE)
  expect_equal(fwl_estimate(reg, "x"), stats::coef(reg)[["x"]])

  #IV: instrumented (named as the variable or as the coefficient) and exogenous
  reg <- fixest::feols(y ~ x | id | log(y_pos) + endo ~ inst + z, data = df, notes = FALSE)
  expect_equal(fwl_estimate(reg, "endo"), stats::coef(reg)[["fit_endo"]])
  expect_equal(fwl_estimate(reg, "fit_endo"), stats::coef(reg)[["fit_endo"]])
  expect_equal(fwl_estimate(reg, "x"), stats::coef(reg)[["x"]])

  reg <- fixest::fepois(count ~ x + z | id, data = df, weights = ~w, notes = FALSE)
  expect_equal(fwl_estimate(reg, "x"), stats::coef(reg)[["x"]], tolerance = 1e-6)
})

test_that("plm weights are on the right rows when the data is not sorted", {
  skip_if_not_installed("plm")
  skip_if_not_installed("fixest")
  data("Grunfeld", package = "plm")
  df <- Grunfeld[order(-Grunfeld$year), ]
  rownames(df) <- NULL

  reg_plm <- plm::plm(inv ~ value + capital, data = df, index = c("firm", "year"), model = "within")
  reg_fixest <- fixest::feols(inv ~ value + capital | firm, data = df)

  expect_equal(idid_weights(reg_plm, "value"), idid_weights(reg_fixest, "value"))
})

test_that("partial_iv = FALSE uses the endogenous variable itself", {
  skip_if_not_installed("fixest")
  df <- sim_panel()
  reg <- fixest::feols(y ~ x | id | endo ~ inst, data = df, notes = FALSE)

  w_iv <- idid_weights(reg, "endo")
  w_no_iv <- idid_weights(reg, "endo", partial_iv = FALSE)

  expect_length(w_no_iv, nrow(df))
  expect_false(isTRUE(all.equal(w_iv, w_no_iv)))
})

test_that("idid_weights errors for variables that are not coefficients", {
  skip_if_not_installed("fixest")
  df <- sim_panel()

  #the outcome, a variable not in the model, a variable dropped by fixest
  expect_error(idid_weights(stats::lm(y ~ x + z, data = df), "y"), "not a coefficient")
  expect_error(idid_weights(stats::lm(y ~ x, data = df), "z"), "not a coefficient")
  df$x_id <- stats::rnorm(10)[df$id]
  expect_error(
    idid_weights(fixest::feols(y ~ x_id + z | id, data = df, notes = FALSE), "x_id"),
    "not a coefficient"
  )
})
