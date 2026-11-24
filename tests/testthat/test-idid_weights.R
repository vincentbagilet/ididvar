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

test_that("the weights give back the coefficient: coefficient names", {
  skip_if_not_installed("fixest")
  df <- sim_panel()
  df$treat <- as.numeric(df$id > 5)
  df$post <- as.numeric(df$t > 3)
  df$group <- factor(letters[df$id %% 3 + 1])

  #interaction, factor level, logical, transformed variable
  reg <- stats::lm(y ~ treat * post + group + I(x > 0) + log(y_pos), data = df)
  expect_equal(fwl_estimate(reg, "treat:post"), stats::coef(reg)[["treat:post"]])
  expect_equal(fwl_estimate(reg, "groupb"), stats::coef(reg)[["groupb"]])
  expect_equal(fwl_estimate(reg, "I(x > 0)"), stats::coef(reg)[["I(x > 0)TRUE"]])
  expect_equal(fwl_estimate(reg, "log(y_pos)"), stats::coef(reg)[["log(y_pos)"]])

  #event study
  reg <- fixest::feols(y ~ i(t, treat, ref = 3) | id + t, data = df, notes = FALSE)
  expect_equal(fwl_estimate(reg, "t::5:treat"), stats::coef(reg)[["t::5:treat"]])
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

#x~ computed manually: residuals of an auxiliary regression of x on the controls
test_that("the weights are equal to manually computed weights: lm and glm", {
  df <- sim_panel()
  rows <- which(!is.na(df$x))

  reg <- stats::lm(y ~ x + z + factor(t), data = df, weights = w)
  aux <- stats::lm(x ~ z + factor(t), data = df[rows, ], weights = w)
  expect_equal(idid_weights(reg, "x")[rows], manual_weights(aux))

  #logit: weighted by the IRLS weights, mu(1 - mu)
  reg <- stats::glm(binary ~ x + z, data = df, family = stats::binomial)
  irls <- stats::fitted(reg) * (1 - stats::fitted(reg))
  aux <- stats::lm(x ~ z, data = df[rows, ], weights = irls)
  expect_equal(idid_weights(reg, "x")[rows], manual_weights(aux), tolerance = 1e-6)
})

test_that("the weights are equal to manually computed weights: fixest", {
  skip_if_not_installed("fixest")
  df <- sim_panel()
  rows <- which(!is.na(df$x))

  #IV: weights of the first stage fitted values
  reg <- fixest::feols(y ~ x | id | endo ~ inst, data = df, weights = ~w, notes = FALSE)
  df_rows <- df[rows, ]
  df_rows$endo_fit <- stats::fitted(stats::lm(endo ~ x + inst + factor(id), df_rows, weights = w))
  aux <- stats::lm(endo_fit ~ x + factor(id), data = df_rows, weights = w)
  expect_equal(idid_weights(reg, "endo")[rows], manual_weights(aux))

  #Poisson: weighted by the IRLS weights, prior weights times mu
  reg <- fixest::fepois(count ~ x + z | id, data = df, weights = ~w, notes = FALSE)
  irls <- df$w[rows] * stats::fitted(reg)
  aux <- stats::lm(x ~ z + factor(id), data = df[rows, ], weights = irls)
  expect_equal(idid_weights(reg, "x")[rows], manual_weights(aux), tolerance = 1e-6)

  #two-way fixed effects and subset
  reg <- fixest::feols(y ~ x + z | id + t, data = df, weights = ~w, subset = ~ t > 1, notes = FALSE)
  rows <- fixest::obs(reg)
  aux <- stats::lm(x ~ z + factor(id) + factor(t), data = df[rows, ], weights = w)
  expect_equal(idid_weights(reg, "x")[rows], manual_weights(aux))
})

test_that("the weights of several variables are the leverage of their block", {
  df <- sim_panel()

  #leverage of the full model minus leverage of the model without x and endo
  reg <- stats::lm(y ~ x + endo + z, data = df, weights = w)
  leverage <- stats::hatvalues(reg) -
    stats::hatvalues(stats::lm(y ~ z, data = df[!is.na(df$x), ], weights = w))
  expect_equal(na.omit(idid_weights(reg, c("x", "endo"))), unname(leverage / sum(leverage)),
               ignore_attr = TRUE)
})

test_that("the same model gives the same weights across packages", {
  skip_if_not_installed("fixest")
  skip_if_not_installed("lfe")
  skip_if_not_installed("AER")
  df <- sim_panel()

  expect_equal(idid_weights(lfe::felm(y ~ x + z | id, data = df, weights = df$w), "x"),
               idid_weights(fixest::feols(y ~ x + z | id, data = df, weights = ~w, notes = FALSE), "x"))
  expect_equal(idid_weights(AER::ivreg(y ~ x + endo | x + inst, data = df), "endo"),
               idid_weights(fixest::feols(y ~ x | endo ~ inst, data = df, notes = FALSE), "endo"))
})
