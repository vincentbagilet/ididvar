test_that("invalid arguments give clear errors", {
  reg <- stats::lm(mpg ~ hp + wt, data = mtcars)

  expect_error(idid_drop_reg(reg, "hp", prop_drop = 1), "prop_drop")
  expect_error(idid_drop_change(reg, "hp", prop_drop = c(0.1, 0.2)), "prop_drop")
  expect_error(idid_drop_change(reg, "hp", 0.1, vcov = "hetero"), "vcov")
  #search_step = 0 would loop forever
  expect_error(idid_contrib_threshold(reg, "hp", search_step = 0), "search_step")
  expect_error(idid_viz_drop_change(reg, "hp", search_start = 0.5, search_end = 0.2), "search_start")
  expect_error(idid_viz_cumul(reg, "hp", prop_weights = 20), "prop_weights")
  expect_error(idid_weights(reg, character(0)), "var_interest")
  expect_error(idid_weights(reg, "hp", tol = "a"), "tol")
  expect_error(idid_weights(reg, "hp", partial_iv = NA), "partial_iv")
  expect_error(idid_grouping_var(reg, "hp", "nope"), "nope")
  expect_error(idid_viz_weights(reg, "hp"), "var_x")
  expect_error(idid_viz_contrib(reg, "hp", var_x = cyl, colors = "red"), "colors")
})

test_that("map arguments are checked", {
  skip_if_not_installed("sf")
  shape <- sf::st_sf(cyl = c(4, 6, 8), geometry = sf::st_sfc(lapply(1:3, \(i) sf::st_point(c(i, 0)))))
  reg <- stats::lm(mpg ~ hp + wt, data = mtcars)

  expect_error(idid_viz_weights_map(reg, "hp", as.data.frame(shape), "cyl"), "sf object")
  expect_error(idid_viz_weights_map(reg, "hp", shape, "cyl", facet = "nope"), "nope")
  expect_s3_class(idid_viz_weights_map(reg, "hp", shape, "cyl"), "ggplot")
})

test_that("felm with subset gives a clear error", {
  skip_if_not_installed("lfe")
  reg <- lfe::felm(mpg ~ hp + wt | cyl, data = mtcars, subset = mtcars$am == 0)

  expect_error(idid_weights(reg, "hp"), "subset")
})
