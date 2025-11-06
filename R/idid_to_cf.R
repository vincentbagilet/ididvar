#only works for feols for now
idid_to_cf <- function(reg, ...) {
  if (!inherits(reg, "fixest")) stop("Model must be from fixest::feols().")
  if (is.null(reg$iv)) stop("This feols model is not an IV regression.")

  if (inherits(reg, "fixest")) {
    df <- eval(reg$call$data, envir = environment(stats::formula(reg)))
    for (endo_var in reg$iv_endo_names) {
      df[[paste(endo_var, "first", sep = "_")]] <-
        reg$iv_first_stage[[endo_var]] |> residuals()
    }

    formula_second_stage <-
      stats::as.formula(paste(
        ". ~ . + ",
        paste(reg$iv_endo_names, "first", sep = "_", collapse = " + "),
        "| . | 0"
      ))
  } else {

  }

  reg_cf <-
    stats::update(
      reg,
      formula_second_stage,
      data = df,
      na.action = stats::na.exclude,
      use_calling_env = FALSE,
      ...
    ) |>
    #handle warning when using feols for instance:
    #feols does not have a 'na.action' argument and there is a weird warning
    #for use_calling_env (likely a update.feols bug)
    withCallingHandlers(
      warning = function(w) {
        if (grepl("use_calling_env and na.action are not valid",
                  conditionMessage(w))) {
          invokeRestart("muffleWarning")
        }
      }
    )

  return(reg_cf)
}
