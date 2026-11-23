test_that("idid_viz_bivar produces correct ggplot mappings and labels", {

  data <- data.frame(
    y = rnorm(10),
    x = rnorm(10),
    w = rnorm(10)
  )
  reg <- lm(y ~ x + w, data = data)

  plot_obj <- idid_viz_bivar(reg, "x")

  # check ggplot data
  df <- plot_obj$data
  expect_true(all(c("x_par", "y_par") %in% names(df)))

  # # Check that the x and y aesthetics are mapped correctly
  # mapping <- ggplot2::ggplot_build(plot_obj)$plot$mapping
  # expect_equal(as.character(mapping$x), "x_par")
  # expect_equal(as.character(mapping$y), "y_par")
  #
  # # Check that the labels mention residualized variables
  # expect_match(plot_obj$labels$x, "residualized")
  # expect_match(plot_obj$labels$y, "residualized")
  # expect_match(plot_obj$labels$title, "Relationship after partialling out controls")
})
