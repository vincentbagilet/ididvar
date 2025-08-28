idid_viz_weights_sf <- function(df_sf) {
  df_sf |>
    group_by(geometry) |>
    summarise(
      weight = sum(weight, na.rm = TRUE),
      contrib = mean(contrib, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(logweight = log10(weight * nrow(.)))

}
