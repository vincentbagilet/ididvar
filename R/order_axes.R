#' Ordering axes
#'
#' @description
#' Orders axes depending on the order desired
#' Used in `idid_viz_weights` and `idid_viz_contrib`.
#'
#' @inheritParams idid_viz_weights
#' @param df A dataframe to order
#'
#' @returns
#' `df` but ordered along the `order` axis and according to the value of `by`
#'
#' @keywords internal
order_axes <- function(df, name_var_x, name_var_y, order, by = "weight") {
  if (order %in% c("y", "xy") & name_var_y != "") {
    df[[name_var_y]] <-
      with(df, reorder(df[[name_var_y]], df[[by]], \(x) sum(x, na.rm = TRUE)))
  }
  if (order %in% c("x", "xy") & name_var_x != "") {
    df[[name_var_x]] <-
      with(df, reorder(df[[name_var_x]], df[[by]], \(x) sum(x, na.rm = TRUE), decreasing = TRUE))
  }

  return(df)
}
