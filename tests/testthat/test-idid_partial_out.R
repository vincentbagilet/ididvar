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
