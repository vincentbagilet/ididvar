test_that("the share of variance removed is the R2 on the controls: lm", {
  df <- sim_panel()
  reg <- stats::lm(y ~ x + z, data = df, weights = w)

  r2_y <- summary(stats::lm(y ~ z, data = df, weights = w, subset = !is.na(x)))$r.squared
  r2_x <- summary(stats::lm(x ~ z, data = df, weights = w))$r.squared

  expect_equal(idid_share_var(reg, "x")$share_var_removed, c(r2_y, r2_x))
  expect_equal(idid_share_var(reg, "x")$variable, c("y", "x"))
})

test_that("the share of variance removed is the R2 on the controls: fixest", {
  skip_if_not_installed("fixest")
  df <- sim_panel()
  reg <- fixest::feols(y ~ x + z | id, data = df, weights = ~w, notes = FALSE)

  r2_x <- fixest::r2(
    fixest::feols(x ~ z | id, data = df, weights = ~w, notes = FALSE), "r2"
  )

  expect_equal(idid_share_var(reg, "x")$share_var_removed[2], unname(r2_x))
})
