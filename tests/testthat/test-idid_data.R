test_that("idid_data finds the data of a regression estimated inside a function", {
  skip_if_not_installed("fixest")

  #object with the same name as the data, which should not be picked up
  df <- data.frame(y = rnorm(3), x = rnorm(3), f = 1:3)

  estimate <- function() {
    df <- data.frame(
      y = rnorm(10),
      x = rnorm(10),
      f = rep(1:2, each = 5)
    )
    list(
      df = df,
      reg_lm = stats::lm(y ~ x, data = df),
      reg_fixest = fixest::feols(y ~ x | f, data = df)
    )
  }
  out <- estimate()

  expect_identical(idid_data(out$reg_lm), out$df)
  expect_identical(idid_data(out$reg_fixest), out$df)
})

test_that("idid_data errors when the data has been modified after estimation", {
  skip_if_not_installed("fixest")

  df <- data.frame(
    y = rnorm(10),
    x = rnorm(10),
    f = rep(1:2, each = 5)
  )
  reg_lm <- stats::lm(y ~ x, data = df)
  reg_fixest <- fixest::feols(y ~ x | f, data = df)

  df <- df[-1, ]

  expect_error(idid_data(reg_lm), "does not match")
  expect_error(idid_data(reg_fixest), "does not match")
})

test_that("idid_data returns the data saved in a fixest regression", {
  skip_if_not_installed("fixest")

  df <- data.frame(
    y = rnorm(10),
    x = rnorm(10),
    f = rep(1:2, each = 5)
  )
  reg <- fixest::feols(y ~ x | f, data = df, data.save = TRUE)
  df_initial <- df

  df <- df[order(df$x), ][-1, ]

  expect_identical(idid_data(reg), df_initial)
})

test_that("idid_data errors when the data cannot be found", {
  #the formula is created here, so its environment does not contain the data
  fml <- y ~ x

  estimate_dat <- function() {
    dat <- data.frame(y = rnorm(10), x = rnorm(10))
    stats::lm(fml, data = dat)
  }
  estimate_df <- function() {
    df <- data.frame(y = rnorm(10), x = rnorm(10))
    stats::lm(fml, data = df)
  }

  #no object called dat outside of estimate_dat
  expect_error(idid_data(estimate_dat()), "Cannot find")
  #outside of estimate_df, df is the function stats::df
  expect_error(idid_data(estimate_df()), "Cannot find")
})

test_that("functions work with a regression estimated inside a function", {
  skip_if_not_installed("fixest")

  df <- data.frame(y = rnorm(3), x = rnorm(3), z = rnorm(3), g = 1:3, f = 1:3)

  estimate <- function() {
    df <- data.frame(
      y = rnorm(20),
      x = rnorm(20),
      z = rnorm(20),
      g = rep(1:4, 5),
      f = rep(1:2, each = 10)
    )
    list(
      stats::lm(y ~ x + z, data = df),
      fixest::feols(y ~ x + z | f, data = df)
    )
  }

  for (reg in estimate()) {
    expect_s3_class(idid_drop_reg(reg, "x", prop_drop = 0.1), class(reg))
    expect_s3_class(idid_grouping_var(reg, "x", grouping_vars = "g"), "data.frame")
    expect_s3_class(idid_viz_weights(reg, "x", var_x = g), "ggplot")
    expect_s3_class(idid_viz_bivar(reg, "x"), "ggplot")
  }
})
