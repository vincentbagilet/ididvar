test_that("idid_viz_cumul counts the observations holding the top weights", {
  df <- mtcars
  reg <- lm(mpg ~ hp + wt, df)
  w <- sort(idid_weights(reg, "hp"), decreasing = TRUE)

  #smallest number of observations holding 80% of the weights
  n_contrib <- which(cumsum(w) >= 0.8)[1]

  plot_obj <- idid_viz_cumul(reg, "hp", prop_weights = 0.2)
  expect_match(plot_obj$labels$subtitle, paste0("(", n_contrib, " obs.)"), fixed = TRUE)
})
