test_that("dropping observations below the threshold passes the criterion", {
  df <- sim_panel()
  reg <- stats::lm(y ~ x + z, data = df)
  weights <- idid_weights(reg, "x")

  threshold <- idid_contrib_threshold(reg, "x", threshold_change = 0.05)
  reg_effective <- stats::lm(y ~ x + z, data = df[which(weights >= threshold), ])

  expect_lt(stats::nobs(reg_effective), stats::nobs(reg))
  expect_lt(abs(1 - stats::coef(reg_effective)[["x"]] / stats::coef(reg)[["x"]]), 0.05)
})

test_that("all observations contribute when the first step fails", {
  skip_if_not_installed("fixest")
  set.seed(1)
  df <- data.frame(g = rep(1:10, each = 10), t = rep(1:10, 10))
  df$treat <- as.numeric(df$g == 1 & df$t > 5)
  df$y <- df$treat + stats::rnorm(100)

  reg <- fixest::feols(y ~ treat | g + t, data = df)
  expect_equal(idid_contrib_stats(reg, "treat")$prop_effective, 1)
})

test_that("idid_viz_drop_change uses search_step", {
  reg <- stats::lm(mpg ~ hp + wt, data = mtcars)
  graph <- idid_viz_drop_change(reg, "hp", search_step = 0.1)
  expect_equal(unique(graph$data$prop_drop), seq(0.1, 0.9, 0.1))
})
