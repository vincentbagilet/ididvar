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

test_that("idid_drop_reg only drops observations of the estimation sample", {
  skip_if_not_installed("fixest")
  df <- sim_panel()

  reg <- fixest::feols(y ~ x + z | id, data = df, subset = ~ t > 1, notes = FALSE)
  expect_equal(stats::nobs(idid_drop_reg(reg, "x", prop_drop = 0.5)),
               stats::nobs(reg) - floor(0.5 * stats::nobs(reg)))
})

test_that("idid_drop_reg never splits observations with the same weight", {
  skip_if_not_installed("fixest")
  set.seed(2)
  df <- data.frame(block = rep(1:100, each = 4), treat = rep(c(1, 0, 0, 0), 100))
  df$y <- df$treat + stats::rnorm(400)

  #only two distinct weights: the 300 controls are all kept or all dropped
  reg <- fixest::feols(y ~ treat | block, data = df)
  expect_equal(stats::nobs(idid_drop_reg(reg, "treat", prop_drop = 0.3)), 400)
})

test_that("idid_drop_change returns one row per variable of interest", {
  reg <- stats::lm(mpg ~ hp + wt + qsec, data = mtcars)
  out <- idid_drop_change(reg, c("hp", "wt"), prop_drop = 0.1)
  expect_equal(out$var_interest, c("hp", "wt"))
})

test_that("idid_drop_change uses the same variance for both standard errors", {
  skip_if_not_installed("fixest")

  #clustering set in summary or in the call
  reg <- fixest::feols(mpg ~ hp + wt, data = mtcars)
  reg_cluster <- fixest::feols(mpg ~ hp + wt, data = mtcars, cluster = ~cyl)
  expect_equal(idid_drop_change(summary(reg, cluster = ~cyl), "hp", prop_drop = 0.2),
               idid_drop_change(reg_cluster, "hp", prop_drop = 0.2))
})

test_that("idid_drop_change works with felm and glm", {
  skip_if_not_installed("lfe")

  reg <- lfe::felm(mpg ~ hp + wt | cyl | 0 | gear, data = mtcars)
  expect_false(anyNA(idid_drop_change(reg, "hp", prop_drop = 0.1)))

  reg <- stats::glm(am ~ hp + wt, data = mtcars, family = stats::binomial)
  expect_false(anyNA(idid_drop_change(reg, "hp", prop_drop = 0.1)))
})

test_that("idid_drop_change returns NA when the coefficient cannot be estimated", {
  skip_if_not_installed("fixest")
  set.seed(1)
  df <- data.frame(g = rep(1:10, each = 10), t = rep(1:10, 10))
  df$treat <- as.numeric(df$g == 1 & df$t > 5)
  df$y <- df$treat + stats::rnorm(100)

  #the treated observations are dropped
  reg <- fixest::feols(y ~ treat | g + t, data = df)
  expect_true(is.na(idid_drop_change(reg, "treat", prop_drop = 0.6)$prop_change_est))
})

test_that("idid_drop_change uses the vcov function for both standard errors", {
  skip_if_not_installed("sandwich")
  reg <- stats::lm(mpg ~ hp + wt, data = mtcars)
  reg_sliced <- idid_drop_reg(reg, "hp", prop_drop = 0.2)
  se <- function(reg_x) sqrt(sandwich::vcovCL(reg_x, cluster = ~cyl)["hp", "hp"])

  vcov_cl <- function(reg_x) sandwich::vcovCL(reg_x, cluster = ~cyl)
  expect_equal(idid_drop_change(reg, "hp", prop_drop = 0.2, vcov = vcov_cl)$prop_change_se,
               (se(reg) - se(reg_sliced)) / se(reg))

  #passed on by the search
  expect_no_error(idid_contrib_threshold(reg, "hp", vcov = vcov_cl))
})
