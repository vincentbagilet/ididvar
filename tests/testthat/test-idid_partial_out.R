test_that("idid_partial_out works with lm and handles NAs", {
  df <- data.frame(
    y = c(1, 2, NA, 4, 5),
    x = c(1, 2, 3, 4, 5),
    w = c(5, 4, 3, 2, 1)
  )
  reg <- lm(y ~ x + w, data = df)

  out <- idid_partial_out(reg, "x")

  expect_length(out, nrow(df))
  expect_true(is.numeric(out))
})

test_that("idid_partial_out works with fixest if available", {
  skip_if_not_installed("fixest")

  df <- data.frame(
    y = rnorm(10),
    x = rnorm(10),
    w = rnorm(10),
    f = rep(1:2, each = 5)
  )
  reg_fixest <- fixest::feols(y ~ x + w | f, data = df)

  out <- idid_partial_out(reg_fixest, "x")

  expect_length(out, nrow(df))
  expect_true(is.numeric(out))
})

test_that("idid_partial_out works with plm if available", {
  skip_if_not_installed("plm")

  df <- data.frame(
    y = rnorm(10),
    x = rnorm(10),
    w = rnorm(10),
    f = rep(1:2, each = 5)
  )
  reg_plm <- plm::plm(y ~ x + w, data = df, index = "f", model = "within")

  out <- idid_partial_out(reg_plm, "x")

  expect_length(out, nrow(df))
  expect_true(is.numeric(out))
})

# Tests that check actual results
test_that("idid_partial_out produces correct residuals for x", {
  df <- data.frame(
    y = 1:5,
    x = c(1, 2, 3, 4, 5),
    w = c(5, 4, 3, 2, 1)
  )

  reg <- lm(y ~ x + w, data = df)
  x_perp <- idid_partial_out(reg, "x")

  # Manually computation of hp partialled out
  x_perp_manual <- residuals(lm(x ~ w, data = df))

  expect_equal(x_perp, x_perp_manual, tolerance = 1e-8)
})

test_that("idid_partial_out produces correct residuals for y", {
  df <- data.frame(
    y = 1:5,
    x = c(1, 2, 3, 4, 5),
    w = c(5, 4, 3, 2, 1)
  )

  reg <- lm(y ~ x + w, data = df)
  y_perp <- idid_partial_out(reg, "y", "x")

  # Manually computation of hp partialled out
  y_perp_manual <- residuals(lm(y ~ w, data = df))

  expect_equal(y_perp, y_perp_manual, tolerance = 1e-8)
})
