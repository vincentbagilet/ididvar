#refit a regression from its control form, as described in ?idid_to_cf
refit_cf <- function(cf) {
  if (is.null(cf$fixef_id)) {
    coefs <- stats::lm.wfit(cf$x, cf$y, cf$weights)$coefficients
  } else {
    coefs <- stats::coef(fixest::feols.fit(
      cf$y,
      cf$x,
      fixef_df = as.data.frame(cf$fixef_id),
      weights = cf$weights,
      notes = FALSE
    ))
  }

  return(coefs[names(cf$coefficients)])
}

#estimate of a coefficient from the identifying variation weights:
#sum(w * y~ / x~)
fwl_estimate <- function(reg, var) {
  w <- idid_weights(reg, var)
  x_partialled <- idid_partial_out(reg, var)
  y_partialled <- idid_partial_out(reg, idid_to_cf(reg)$y_name, var)

  return(sum(w * y_partialled / x_partialled, na.rm = TRUE))
}

#simulated panel used in the tests
sim_panel <- function(n_id = 10, n_t = 6) {
  set.seed(1)
  df <- data.frame(
    id = rep(seq_len(n_id), each = n_t),
    t = rep(seq_len(n_t), n_id),
    x = stats::rnorm(n_id * n_t),
    z = stats::rnorm(n_id * n_t),
    inst = stats::rnorm(n_id * n_t),
    w = stats::runif(n_id * n_t, 0.5, 2)
  )
  df$endo <- df$inst + df$z + stats::rnorm(n_id * n_t)
  df$y <- 0.5 * df$x + 0.3 * df$endo + df$z + rep(stats::rnorm(n_id), each = n_t) +
    stats::rnorm(n_id * n_t)
  df$y_pos <- exp(df$y / 4)
  df$count <- stats::rpois(n_id * n_t, exp(0.3 * df$x + 0.2 * df$z))
  df$binary <- as.numeric(df$y > 0)
  df$x[3] <- NA

  return(df)
}
