test_that("idid_drop_change finds coefficients with special names", {
  skip_if_not_installed("fixest")

  #exogenous variable in an IV
  reg <- fixest::feols(mpg ~ wt | cyl | hp ~ qsec, data = mtcars, notes = FALSE)
  expect_equal(nrow(idid_drop_change(reg, "wt", prop_drop = 0.1)), 1)
  expect_equal(nrow(idid_drop_change(reg, "hp", prop_drop = 0.1)), 1)

  #parentheses in the name
  reg <- stats::lm(mpg ~ log(hp) + wt, data = mtcars)
  expect_equal(nrow(idid_drop_change(reg, "log(hp)", prop_drop = 0.1)), 1)
})
