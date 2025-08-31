## The (super simple) code to prepare the `color_table` data set goes here

idid_colors_table <- read.csv("inst/data-raw/colors_table.csv", sep = ";")

usethis::use_data(idid_colors_table, overwrite = TRUE)
