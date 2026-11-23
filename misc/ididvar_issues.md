# ididvar: issues to fix

## Context (read first)

- **Package.** `ididvar` 0.0.1, source in `/Users/vincentbagilet/Documents/Research/R_packages/ididvar` (last commit `f144cde`). It computes "identifying variation weights": by Frisch-Waugh-Lovell (FWL), in a regression weighted by $\omega_i$, $\hat{\beta} = \sum_i w_i \, y_i / \tilde{x}_i$ with $w_i = \omega_i \tilde{x}_i^2 / \sum_j \omega_j \tilde{x}_j^2$, where $\tilde{x}$ is the variable of interest residualized on the other regressors. The "effective sample" functions then drop low weight observations until the estimate or its standard error changes by more than 5%.
- **Origin.** Found while applying the package to published papers in `/Users/vincentbagilet/Documents/Research/hidden_locality/code/replications/` (November 2026), then by reviewing the full source and running checks on built-in data sets. Every issue below was reproduced on the current source, unless marked otherwise. The snippets and the outputs quoted come from these runs.
- **Setup used.** R 4.5, fixest 0.14.1, AER 1.2.17, plm 2.6.6, lfe 3.1.1, ggplot2 4.0.1 (the `ivreg` package is not installed). Load the development version with `pkgload::load_all("/Users/vincentbagilet/Documents/Research/R_packages/ididvar")`.
- **Tests.** There is a single test (`tests/testthat/test-idid_partial_out.R`, which only checks the length of the output). Turn each snippet below into a `testthat` test when fixing the issue. The most useful test is the invariant $\sum_i w_i y_i / \tilde{x}_i = \hat{\beta}$ (or $= c'\hat{\beta}$ for a combination), on: `lm`, weighted `lm`, `feols` with fixed effects, weights, `subset` and missing values, IV (instrumented and exogenous variable of interest), `fepois`/`glm`. The current package fails it whenever there are regression weights.
- **How to use this file.** Fix the issues one at a time. Line numbers refer to commit `f144cde`. The **Appendix** contains a tested reference implementation that fixes A1 to A5, A11, B1, B3 and B5 at once.

## Suggested order

1. **Core refactor of the weights** (A1, A2, A3, A4, A5, A11, B1, B3, B5, and part of A6, A8, C11). Most of the bugs come from one design choice: `idid_partial_out` residualizes by rewriting the formula and re-running the regression with `update()`. Computing the weights from the design matrix the estimation actually used (`model.matrix`, regression weights, fixed effects demeaned with `fixest::demean`, one pivoted QR for all columns) fixes all of these at once. See the Appendix. `idid_partial_out` can keep its API (return $\tilde{x}$ padded with `NA`) but be computed from the same projection.
2. **Effective samples** (A7, A8, A9, A10, A12, B8, C10, and D1 to decide).
3. **Errors on specific model classes** (A6, B2, B4, B7, B9).
4. **Arguments ignored, documentation, display** (C1 to C11).

---

## A. Wrong results without an error

### A1. Regression weights are ignored (`idid_weights`) (was #1)

`R/idid_weights.R:80-82`. The residualization runs with the regression weights (`update()` keeps them), but the final weights are $\tilde{x}_i^2 / \sum_j \tilde{x}_j^2$ instead of $\omega_i \tilde{x}_i^2 / \sum_j \omega_j \tilde{x}_j^2$.

```r
reg <- lm(mpg ~ hp + wt, mtcars, weights = disp)
x_t <- idid_partial_out(reg, "hp")
sum(idid_weights(reg, "hp") * mtcars$mpg / x_t)  # -0.129, coef(reg)["hp"] is -0.029
```

- Affects every weighted regression in the replications (Deschênes and Greenstone, Burke and Emerick, Hornbeck and Naidu, Moscona and Sastry). In Deschênes and Greenstone, accounting for the farmland weights alone moves Texas from 10% to 17% of the weight. In Burke and Emerick (Table 1, `/Users/vincentbagilet/Documents/Research/hidden_locality/code/replications/ididvar_weights_burke.qmd`), 46% to 59% of the weight moves between the two versions, and only the weighted version gives back the coefficient (column 8: -0.0032 instead of -0.0054).
- Fix: multiply by the regression weights (for several variables, run the QR on $\sqrt{\omega} \tilde{X}$). Minimal patch: `idid_weights_reg()` in `ididvar_weights_burke.qmd` (one changed line). Warning: `stats::weights()` on a `fixest` object returns the weights padded with `NA` to the size of the original data, while `reg$weights` holds the weights of the estimation sample. Better fix: the Appendix, which also handles GLMs (A4), where the relevant weights are the IRLS weights.

### A2. Residualization uses the formula, not the design matrix actually estimated (`idid_partial_out`) (new, includes former #6)

`R/idid_partial_out.R:65-99`. Each variable is residualized by a separate `update()` of the formula (`x ~ . - x - var_interest`). This differs from FWL on the estimated model in several ways:

1. **Controls dropped for collinearity are still partialled out.** When `lm` drops a collinear control (`NA` coefficient), `update()` puts it back in the auxiliary regression.

   ```r
   set.seed(1)
   df <- data.frame(z = rnorm(100)); df$y <- df$z + rnorm(100); df$x <- 2 * df$z + 1
   reg <- lm(y ~ x + z, df)  # coef x = 0.499, z = NA (dropped)
   x_t <- idid_partial_out(reg, "x")  # x residualized on z: numerical noise
   sum(idid_weights(reg, "x") * df$y / x_t)  # 9.4e13 instead of 0.499
   ```

   On a similar example, 79% of the weight moves compared with weights computed on the design `lm` actually used.
2. **Numerical instability with many nearly collinear controls (former #6).** Each auxiliary regression may drop a different set of near-collinear variables, so $\tilde{x}$ and $\tilde{y}$ are not residualized on the same space. Evidence: Hornbeck and Naidu, Table 2 (227 controls, 153 collinear). The residuals of the same regression computed through `update()`, directly with `fixest`, or with `lm` only correlate at 0.96 to 0.98. The FWL estimate built from `idid_partial_out` gives -0.023 for a coefficient of -0.144.
3. **No check that `var_interest` is a regressor.** `idid_weights(lm(mpg ~ hp, mtcars), "wt")` returns weights.
4. **Outcome check is fragile.** `R/idid_weights.R:45` and `R/idid_partial_out.R:66` read the outcome from `all.vars(reg$call[[2]])[[1]]`. With `f <- mpg ~ hp + wt; reg <- lm(f, mtcars)`, `reg$call[[2]]` is the symbol `f`, so `idid_weights(reg, "mpg")` returns weights for the outcome instead of an error. Use `all.vars(stats::formula(reg))[1]`, or check the variable against the coefficient names.

- Fix: compute $\tilde{X}$ and $\tilde{y}$ from the design matrix of the estimation (columns with an `NA` coefficient removed, the columns `fixest` kept), with a single projection (`fixest::demean` for the fixed effects, then one pivoted QR of the weighted controls applied to every column). See `idid_fwl()` in the Appendix. Add a check that the FWL estimate gives back the coefficient (and warn if it does not).

### A3. Collinearity of the variable of interest with the controls is not detected (`idid_weights`) (new)

`R/idid_weights.R:68-73`. The rank check runs `qr()` on the already residualized $\tilde{X}$. `qr()` detects dependence relative to each column's own norm, so a column of pure numerical noise ($\tilde{x} \approx 10^{-15}$) is full rank. The warning only fires for collinearity *among* the variables of interest, never with the controls, and the comment ("`tol` sets how much variation a variable must retain") is wrong.

```r
set.seed(1)
df <- data.frame(id = rep(1:20, each = 5), z = rnorm(100), y = rnorm(100)); df$x <- rnorm(20)[df$id]
reg <- feols(y ~ x + z | id, df)  # fixest removes x (collinear with id)
idid_weights(reg, "x")            # returns weights (noise), no warning
```

- Fix: error if a variable of interest has no coefficient in the model. Warn when the share of the variance of $x$ left after partialling out ($\sum \omega \tilde{x}^2 / \sum \omega x^2$, with $x$ after the fixed effects) is below a tolerance (`share_variance_kept` in the Appendix).

### A4. Nonlinear models (`glm`, `feglm`, `fepois`) get wrong weights or fail (new)

`idid_partial_out` re-runs the GLM with the variable of interest as the outcome. With `fepois`, a variable of interest with negative values fails ("Negative values of the dependent variable are not allowed"). With a positive one, $x$ is residualized by a Poisson regression: on a simulated example (`fepois(y ~ exp(x) + z | f)`), 18% of the weight moves compared with the correct weights. The documentation (`R/idid_weights.R:16-21`) suggests passing `family = "gaussian"`, which still ignores the IRLS weights.

- Correct weights: at convergence, a GLM estimate is the weighted least squares of the working response $z_i = \eta_i + (y_i - \mu_i) / \mu'(\eta_i)$ on $X$, with the IRLS weights $W_i$ (which include the prior weights). The weights are $W_i \tilde{x}_i^2 / \sum_j W_j \tilde{x}_j^2$, with $\tilde{x}$ residualized by least squares weighted by $W$. Checked: this gives back the coefficient for `fepois` with fixed effects and weights, `feglm` logit, and `glm` Poisson and logit.
- `fixest`: `reg$irls_weights`, `reg$linear.predictors`, `reg$fitted.values`, `reg$family$mu.eta`. `glm`: `reg$weights` (working weights) and `reg$linear.predictors + residuals(reg, "working")`.
- Fix: implemented in the Appendix. If not supported, error explicitly for GLMs.

### A5. `idid_to_cf.ivreg` fits the wrong model when variables are transformed (new)

`R/idid_to_cf.R:109-133`. Variables are extracted with `all.vars()`, which strips transformations: `log(packs) ~ log(rprice) + log(rincome) | log(rtax) + log(rincome)` becomes the control function `packs ~ rprice + rincome + rprice_first`. The same happens to `I(x^2)`, `poly()`, interactions, factors. There is no error.

```r
data("CigarettesSW", package = "AER")
CigarettesSW <- transform(CigarettesSW, rprice = price / cpi, rincome = income / population / cpi, rtax = tax / cpi)
reg <- AER::ivreg(log(packs) ~ log(rprice) + log(rincome) | log(rtax) + log(rincome), data = CigarettesSW)
formula(idid_to_cf(reg))  # packs ~ rprice + rincome + rprice_first
```

- Also: the first stage (`R/idid_to_cf.R:122-124`) does not use `na.action = na.exclude`, so its residuals are too short when there are missing values.
- Fix: build the design from the model matrices rather than from variable names. For `ivreg`, `model.matrix(reg, component = "projected")` returns the 2SLS projected regressors directly: FWL on it gives the weights, as in the `fixest` branch of the Appendix (no control function needed).

### A6. `plm`: weights misaligned with the data when the data is not sorted by individual and time (new)

`R/idid_partial_out.R:103-107`. `plm` sorts the data internally. The residuals are put back with `as.numeric(rownames(reg$model))`, which are positions in the *sorted* data.

```r
data("Grunfeld", package = "plm")
G <- Grunfeld[order(-Grunfeld$year), ]; rownames(G) <- NULL
w_plm <- idid_weights(plm::plm(inv ~ value + capital, G, index = c("firm", "year"), model = "within"), "value")
w_fe <- idid_weights(feols(inv ~ value + capital | firm, G), "value")
all.equal(sort(w_plm), sort(w_fe))  # TRUE: same weights...
max(abs(w_plm - w_fe))              # 0.088: ...assigned to the wrong rows
```

- Fix: map back with the index of the `pdata.frame` (individual and time) rather than row names, or document that the data must be sorted.

### A7. The effective sample is one search step too large: dropping the "non-contributing" observations changes the estimate by more than the threshold (`idid_contrib_threshold`) (new)

`R/idid_contrib_threshold.R:42-56`. The loop stops at the first `prop_drop` whose change exceeds `threshold_change`, then returns the weight at that proportion. Observations with a weight below the threshold are therefore those whose removal *fails* the criterion. It should use the last proportion that passed.

```r
reg <- lm(unemploy ~ pce + uempmed + psavert + pop, data = ggplot2::economics)
idid_contrib_stats(reg, "pce")  # prop_effective 0.55: 45% declared non-contributing
idid_drop_change(reg, "pce", 0.40)  # est 3.2%, se -4.1%: passes
idid_drop_change(reg, "pce", 0.45)  # est 4.2%, se -7.1%: fails, but this is the set excluded
```

- Consequence: when the very first step fails (e.g. an estimate close to zero, see D1), 5% of the observations are still declared non-contributing, whereas everything should contribute.
- Related: the loop has no upper bound (`prop_drop` can reach 1 and beyond, and `head()` with a negative `n` then returns unexpected rows). `weights_sorted[[floor(prop_drop * n)]]` fails with "attempt to select less than one element" when `floor(prop_drop * n) == 0`. `idid_drop_reg` (`head(n * (1 - prop_drop))`) and `idid_contrib_threshold` (`floor(prop_drop * n)`) count the dropped observations differently.
- Fix: keep the last passing proportion (threshold below the minimum weight if none passes), stop at `prop_drop < 1`. Compute the number of dropped observations and the threshold from the same sorted vector, ideally in one place (e.g. `idid_drop_reg` returns the threshold it used).

### A8. Effective samples are wrong when the estimation sample differs from the data (`idid_drop_reg`, `idid_contrib_threshold`) (was #3)

`R/idid_drop_reg.R:31-32`, `R/idid_contrib_threshold.R:55-56`. `idid_drop_reg` slices the full data, `head(n = nrow(df) * (1 - prop_drop))`, where observations outside the estimation sample have `NA` weights (sorted last). `idid_contrib_threshold` then picks `weights_sorted[[floor(prop_drop * length(weights_sorted))]]`, where `sort()` has dropped the `NA`s. The two proportions do not refer to the same set of observations.

```r
df <- ggplot2::economics; df$year <- as.numeric(substr(df$date, 1, 4))
reg <- feols(unemploy ~ pce + uempmed + psavert, data = df, subset = ~ year > 1990)  # 292 of 574 rows
nobs(idid_drop_reg(reg, "pce", 0.4))  # 292: nothing dropped (expected 175)
nobs(idid_drop_reg(reg, "pce", 0.5))  # 287 (expected 146)
```

- Triggered by `subset`, by rows with missing values, and by observations dropped by `fixest` (singletons, perfect fit in GLMs). Evidence from the replications: Di Tella and Schargrodsky, Table 3, columns D and E (estimated with `subset`).
- With `lm` and `subset`, `na.exclude` does not pad the rows excluded by `subset`: `idid_weights` returns 292 values for 574 rows, and every function that adds the weights to the data (`idid_viz_weights`, `idid_viz_contrib`, the maps, `idid_drop_reg`) errors ("Can't recycle input of size 292 to size 574").
- Workaround used in the replications: pass a data set containing only the estimation sample.
- Fix: restrict to the estimation sample before slicing (`fixest::obs(reg)`, or the rows with non-missing weights), and compute the proportions on it. Pad the weights to the data rows for every model class (`obs()` for `fixest`; for `lm`, `match(rownames(model.frame(reg)), rownames(data))`; see `pad()` in the Appendix).

### A9. Ties at the effective sample threshold (`idid_viz_contrib`, `idid_contrib_stats`, `idid_drop_reg`) (was #7)

Contributing observations are those with `weight > threshold` (strict inequality). When many observations have the same weight and the threshold falls on that value, they are all excluded. And when `idid_drop_reg` cuts through a group of tied weights, which ones are dropped depends on the row order of the data.

```r
set.seed(2)
df <- data.frame(block = rep(1:100, each = 4), treat = rep(c(1, 0, 0, 0), 100)); df$y <- df$treat + rnorm(400)
reg <- feols(y ~ treat | block, df)  # only 2 distinct weights
idid_contrib_stats(reg, "treat")  # prop_effective 0.25: all controls excluded
df2 <- df[sample(nrow(df)), ]
idid_drop_change(reg, "treat", 0.3)$prop_change_est                                # 0.018
idid_drop_change(feols(y ~ treat | block, df2), "treat", 0.3)$prop_change_est      # 0.045, same regression
```

- Evidence from the replications: Di Tella and Schargrodsky, Table 3, column D (cross-section, binary treatment): only the 185 treated observations are counted as contributing.
- Fix: never cut through a group of ties (drop all tied observations or none), or base the threshold on the cumulative weight, and report the tied observations explicitly.

### A10. Several variables of interest: only the first one is used (`idid_drop_change`) (was #4)

`R/idid_drop_change.R:49-50`. `grep(paste0("^", var_interest_robust, "(TRUE)?$"), ...)` gets one pattern per variable and uses only the first ("argument 'pattern' has length > 1 and only the first element will be used"). The change in the estimate and the standard error only concerns the first variable, while the weights are those of the block.

- Affects `idid_drop_change`, `idid_contrib_threshold`, `idid_viz_contrib`, `idid_viz_contrib_map`, `idid_contrib_stats` and `idid_viz_drop_change` whenever `var_interest` has several variables. Reproduced with `idid_drop_change(lm(mpg ~ hp + wt + qsec, mtcars), c("hp", "wt"), 0.1)`. Evidence from the replications: Deschênes and Greenstone (8 weather variables), Hornbeck and Naidu (5 flood by decade variables).
- Fix: define the change for the block (e.g. the largest change across coefficients), or for the linear combination of A11, consistently with the weights used.

### A11. No weights for a linear combination of coefficients (was #2)

With several variables of interest, `idid_weights` returns the leverage of the block (`rowSums(qr.Q(...)^2)`): the weights for estimating all the coefficients jointly. When the estimate of interest is a combination $c'\beta$ (a predicted impact, the sum of post-treatment event-study coefficients), the relevant weights are $\omega_i z_i^2 / \sum_j \omega_j z_j^2$ with $z = \tilde{X} (\tilde{X}' \Omega \tilde{X})^{-1} c$, and then $c'\hat{\beta} = \sum_i \omega_i z_i y_i$ exactly.

- Evidence from the replications: Deschênes and Greenstone's predicted impact (Table 5, column 4). Texas holds 10% of the block weights but 36% of the weights of the predicted impact (with regression weights; 19% without). Florida holds 14% of the block weights but 5% of the weights of the predicted impact (without regression weights).
- Fix: add a `combination` argument to `idid_weights` and to the functions calling it. Implemented and checked in the Appendix (`idid_weights_comb()`).

### A12. Effective samples depend on the small sample correction (`idid_drop_change`) (was #8)

The change in the standard error after dropping observations includes the change in the degrees of freedom correction. With `ssc(fixef.K = "full")`, dropping observations removes fixed effects and mechanically changes the correction. The same applies with clustered standard errors when entire clusters are dropped ($G / (G - 1)$).

- Evidence from the replications: Burke and Emerick, Table 1, column 4. Dropping the 50% of observations with the lowest weights changes the standard error by -3.0% with the default `ssc` and by -6.4% with `ssc(fixef.K = "full")` (which matches the published standard errors). The effective sample goes from 45% to 55% of the observations.
- Fix: compare standard errors computed with the same correction (e.g. hold the correction factor of the full sample fixed), or document the dependence.

### A13. `idid_viz_bivar`: the slope shown is not the coefficient (new)

`R/idid_viz_bivar.R:35-52`.

- With several variables of interest, $x_1$ and $y$ are residualized on the controls but *not* on the other variables of interest (they are excluded from the formula), so the slope is not $\hat{\beta}_1$: `idid_viz_bivar(lm(mpg ~ hp + wt + qsec, mtcars), c("hp", "wt"))` shows a slope of -0.085 for a coefficient of -0.018.
- `geom_smooth(method = "lm")` ignores the regression weights: slope -0.034 vs coefficient -0.029 for `lm(mpg ~ hp + wt, mtcars, weights = disp)`.
- Fix: residualize $x_1$ on everything else (FWL), weight the smoother (`aes(weight = ...)`), and possibly size points by their weight.

---

## B. Errors

### B1. IV with an exogenous variable of interest (`idid_drop_change`) (was #5)

`R/idid_drop_change.R:39-42`. For any `fixest` IV, `fit_` is prepended to the variable of interest, even when it is not instrumented, so the coefficient is not found.

```r
idid_drop_change(feols(mpg ~ wt | cyl | hp ~ qsec, mtcars), "wt", prop_drop = 0.1)
# Error: attempt to select less than one element in get1index
```

- All the effective sample functions fail in that case.
- Fix: only prepend `fit_` if the variable is instrumented (`reg$iv_endo_names`). Better: let users pass coefficient names (B5).

### B2. `fixest` IV fails when the data has missing values or with `subset` (`idid_to_cf.fixest`) (new)

`R/idid_to_cf.R:64-67`. `stats::residuals()` on the first stage returns the estimation sample only, and assigning it to the data fails.

```r
mt <- mtcars; mt$qsec[1:3] <- NA
idid_weights(feols(mpg ~ wt | hp ~ qsec, data = mt), "hp")
# Error: replacement has 29 rows, data has 32
```

- Fix: `stats::residuals(reg$iv_first_stage[[endo_var]], na.rm = FALSE)`, which pads to the data rows. Or skip the control function and use the first-stage fitted values (Appendix).

### B3. `fixest` IV fails with a transformed endogenous variable (`idid_to_cf.fixest`) (new)

`R/idid_to_cf.R:65, 69-76`. The column `paste0(endo_var, "_first")` gives non-syntactic names in the formula.

```r
idid_weights(feols(mpg ~ wt | log(hp) ~ qsec, mtcars), "log(hp)")
# Error: unexpected input: . ~ . +  log(hp)  +  log(hp)_first
```

- Fix: use syntactic names (`make.names()` or backticks). Note that `model.matrix(reg, type = "iv.rhs2")` also fails in that case ("could not find function fit_log"), and it leaves out the first-stage fixed effects, so it should not be used either. The Appendix computes the fitted values as `iv.endo` minus the first-stage residuals.

### B4. Variable names with parentheses or dots fail in `idid_drop_change` (new)

`R/idid_drop_change.R:50`. The variable name is used as a regular expression: `^log(hp)(TRUE)?$` does not match `log(hp)`.

```r
idid_drop_change(lm(mpg ~ log(hp) + wt, mtcars), "log(hp)", 0.1)
# Error: attempt to select less than one element in get1index
```

- Fix: compare names exactly (`%in%` on `c(var, paste0(var, "TRUE"))`), or escape the pattern. Better: B5.

### B5. Interactions, `i()`, factors and other terms of the design cannot be variables of interest (new)

`var_interest` must be a variable that can be the outcome of the auxiliary regression. Common cases fail:

- Difference-in-differences: `idid_weights(lm(y ~ treat * post, df), "treat:post")` gives the warning "numerical expression has 100 elements: only the first used" (the `:` operator is evaluated) and then the error "variable lengths differ".
- Event studies with `fixest::i()` (coefficients such as `t::5:treat`), factor variables (coefficient `treattreated`), `poly()`, splines.
- Fix: identify the variables of interest by their coefficient names and work on the columns of the design matrix (Appendix: checked on `treat:post` and on `i(t, treat, ref = 3)` coefficients, alone and summed). The current `"(TRUE)?$"` hack becomes unnecessary.

### B6. `felm`: the effective sample functions fail (new)

`R/idid_drop_reg.R:35`, `R/idid_drop_change.R:55-56`. `update(reg, data = ..., use_calling_env = FALSE)` errors for `felm` ("unknown arguments use_calling_env"; for `lm` it only warns and is muffled). Then, with clustered standard errors, the column of `summary(felm)$coefficients` is `"Cluster s.e."`, not `"Std. Error"`.

```r
reg <- lfe::felm(mpg ~ hp + wt | cyl | 0 | gear, data = mtcars)
idid_drop_change(reg, "hp", 0.1)  # Error: unknown arguments use_calling_env
```

- Fix: only pass `use_calling_env` to `fixest` objects. Get the estimate and standard error with `coef()` and `sqrt(diag(vcov()))` rather than column names of the coefficient table.

### B7. Dropping observations can make the coefficient inestimable (`idid_drop_change`) (new)

When the dropped observations remove all the variation in the variable of interest (e.g. a rare treatment), the sliced regression errors and stops the search or the graph.

```r
dfw <- data.frame(g = rep(1:10, each = 10), t = rep(1:10, 10)); dfw$treat <- as.numeric(dfw$g == 1 & dfw$t > 5); dfw$y <- dfw$treat + rnorm(100)
idid_drop_change(feols(y ~ treat | g + t, dfw), "treat", 0.6)
# Error: not a single explanatory variable is different from 0
```

- Fix: catch the error and return `NA` (or `Inf`) changes; treat it as a failing step in `idid_contrib_threshold`. Relevant for `idid_viz_drop_change`, which goes up to `search_end = 0.95` by default.

### B8. `idid_grouping_var(grouping_vars = "everything")` is documented but not implemented (new)

`R/idid_grouping_var.R:13-15` (documentation) vs `40-51` (loops over the literal strings): `idid_grouping_var(reg, "median", "everything")` errors ("arguments must have same length").

- Fix: implement it (`names(df)` minus the weight column) or remove it from the documentation.

---

## C. Ignored arguments, documentation, display, performance

### C1. `idid_viz_drop_change` ignores `search_step`

`R/idid_viz_drop_change.R:42`: `seq(search_start, search_end, 0.05)` hard-codes the step. With `search_step = 0.1`, the points are still 0.10, 0.15, 0.20, ... Fix: `seq(search_start, search_end, search_step)`. The documentation of `search_start` and `search_end` (lines 11-14) refers to "the loop in `idid_contrib_threshold`", which this function does not call.

### C2. `idid_viz_weights_map` ignores `...`

`R/idid_viz_weights_map.R:41`: `idid_weights(reg, var_interest)` does not pass `...`, so `partial_iv`, `tol` or regression arguments are silently ignored (unlike every other function). Fix: add `...`.

### C3. Warning not muffled for IV models (was #9)

Every IV `feols` triggers "na.action is not a valid argument for function feols()". The handler in `idid_to_cf.fixest` (`R/idid_to_cf.R:92`) only matches "use_calling_env and na.action are not valid". Fix: use the same pattern as `R/idid_partial_out.R:93`, `"(na.action is not a|use_calling_env and na.action are not) valid"`, or stop passing `na.action` to `feols`.

### C4. `idid_contrib_stats`: documentation and output disagree

The documentation (`R/idid_contrib_stats.R:12-13`) describes `n_total`; the output column is `n_initial` (line 47).

### C5. `idid_to_cf` examples are broken

`R/idid_to_cf.R:36-45` (in `\dontrun`, so never checked): `CigarettesSW` has no `rprice`, `rincome` or `rtax` (they need to be created, see A5), and the `feols` example uses `log(dist)` both as an exogenous and as an endogenous variable.

### C6. `idid_viz_cumul`: subtitle off by one observation

`R/idid_viz_cumul.R:32-34`. With `k` the first index where the cumulative share exceeds `prop_weights`, observations `k` to `n` account for at least `1 - prop_weights` of the weight, that is `n - k + 1` observations, but `n_contrib = n - k`. Minor. A grouped version (concentration by state, by unit) would often be more informative than by observation.

### C7. `idid_viz_bivar` labels

`R/idid_viz_bivar.R:56`: `paste("In the", substitute(reg), "model")` gives a vector when `reg` is a call (`regs[[1]]` gives `"In the [[ model" "In the regs model" "In the 1 model"`). Use `deparse(substitute(reg))`. Line 58: with several variables of interest, the x label is a vector. The y label uses `all.vars()` and shows `sales` for an outcome `log(sales)`.

### C8. Heatmaps: zero weights shown as missing; scale labels

`scale_fill_idid` (`R/scale_fill_idid.R:43-50`) squishes values beyond `limits` into the extreme bins (correct), but a cell with exactly zero weight ($\log_{10} 0 = -\infty$) gets `na.value`, the same grey as cells with no observations. The extreme breaks (1/100x and 100x) are labelled "0" and "Inf", which is misleading. Fix: squish infinite values too (`oob = scales::oob_squish_any`) and label the breaks "1/100x" and "100x" (or "≤ 1/100x", "≥ 100x").

### C9. Dead code

`R/stat_sum_sf.R`: `StatSumSf` prints its data and returns an undefined object (`merged`). Not exported and not used. Remove it.

### C10. Performance: the weights are recomputed at every step

`idid_contrib_threshold` computes the weights, then each `idid_drop_change` step calls `idid_drop_reg`, which recomputes them from scratch; `idid_contrib_stats`, `idid_viz_contrib` and the maps then recompute them again. For one variable of interest on `txhousing` with two fixed effects, `idid_contrib_stats` runs 20 regressions; for a small IV, 34. With several variables of interest, IVs and large fixed-effects models (Hornbeck and Naidu), this is slow.

- Fix: compute the weights once and pass them down (internal argument `weights =`), and have the threshold search return the weights and the threshold together.

### C11. Missing input checks and fragile data retrieval

All functions get the data with `eval(reg$call$data, envir = environment(stats::formula(reg)))` and align the weights by row position.

- If the data object was modified after the estimation, or if the call contains an expression, the alignment can break silently. There is no check that `length(weights) == nrow(df)`.
- The `run_specs()` helper in the replications exists only so that the formula and the data name appear in the call.
- Fix: check lengths (for `fixest`, `reg$nobs_origin == nrow(df)`), allow passing `data` explicitly, and error with a clear message otherwise.

---

## D. Design questions (to decide, not bugs)

### D1. The criterion "relative change in the estimate" is meaningless for estimates close to zero

`R/idid_drop_change.R:60`. `(est_full - est_sliced) / est_full` explodes when the estimate is close to zero, so the effective sample of a null or placebo result is driven by noise (and by A7: the first step fails, but 5% are still excluded).

```r
set.seed(1)
dfz <- data.frame(x = rnorm(500), z = rnorm(500)); dfz$y <- 0.001 * dfz$x + dfz$z + rnorm(500)
idid_contrib_stats(lm(y ~ x + z, dfz), "x")  # prop_effective 0.75
```

- Options: express the change in the estimate in units of the standard error ($|\Delta \hat{\beta}| / \widehat{se}$), or only use the standard error criterion. Also note that the sign convention is (full - sliced) / full, the reverse of the usual one.

### D2. `idid_grouping_var` compares variances that are not comparable

`R/idid_grouping_var.R:50`. The variance of the summed weights across groups depends mechanically on the number of groups (the average group weight is $1/G$) and on group sizes. A grouping variable with few groups mechanically ranks higher. Options: compare each group's weight to its share of the observations, or use a scale-free measure (e.g. $G \times$ standard deviation, or the effective number of groups $1 / \sum_g W_g^2$ relative to $G$).

### D3. Scale of `idid_viz_weights` and of the maps

`R/idid_viz_weights.R:85-87`. The cell weight is multiplied by `n_cat_x * n_cat_y`, the number of possible cells (counted over all rows, including those outside the estimation sample). On sparse grids (e.g. judge by month), "compared to the average weight" is relative to cells that do not exist. Cell weights are also sums over observations, so cells with many observations are mechanically heavy (the Miami issue in Heyes and Saberian). The legend says "compared to 1/n, the average weight", which is not what is computed. An option to compare each cell to its share of the observations (the nominal sample) would help. Same for `idid_viz_weights_map` (relative to the number of groups with data) and `idid_viz_contrib_map` (counts of contributing observations, not shares).

### D4. Other suggestions

- **Threshold-free concentration measure.** The effective number of observations $1 / \sum_i w_i^2$ (and of groups, $1 / \sum_g W_g^2$) is comparable across specifications and papers, unlike the 5% threshold effective sample.
- **Contributions to the estimate.** Exporting the decomposition $\hat{\beta} = \sum_i c_i$, with $c_i = \omega_i \tilde{x}_i \tilde{y}_i / \sum_j \omega_j \tilde{x}_j^2$, shows which observations drive the estimate, not only where the variation is. Summed by group, it writes the estimate as a weighted average of group-level estimates. With the Appendix, $c_i = \omega_i z_i \tilde{y}_i$.
- **Comparing specifications.** A function computing the share of the weight moving between two specifications ($\frac{1}{2} \sum_i |w_i^A - w_i^B|$), by observation or group, and handling different estimation samples.

## E. Related, not ididvar

- With variables on very different scales (e.g. squared degree-days of the order of $10^7$ in Deschênes and Greenstone), the variance-covariance matrices of `fixest` are numerically unstable. Rescaling the variables fixes it.

---

## Appendix: reference implementation (tested)

FWL on the design matrix of the estimation, with a single projection for all columns, regression weights, IRLS weights for GLMs, IV through the first-stage fitted values, linear combinations of coefficients, and weights padded to the rows of the data. Variables of interest are given as **coefficient names** (`names(coef(reg))`, e.g. `"fit_hp"`, `"treat:post"`, `"t::5:treat"`).

Checked: `check["estimate"] == check["from_weights"]` (to $10^{-6}$ for GLMs, the IRLS tolerance) for weighted `lm`; `lm` with `log(hp)`; `lm` with `subset` and `NA`; `feols` with fixed effects, weights, `subset` and `NA`; `feols` IV (instrumented, exogenous, `log()` endogenous, with fixed effects and weights); `treat:post` with two-way fixed effects; an `i()` event-study coefficient and the sum of three of them; a combination of two `lm` coefficients; `fepois` with fixed effects and weights; `feglm` logit; `glm` Poisson with prior weights; `glm` logit. Without regression weights, it matches the current `idid_weights` to $10^{-16}$.

Not handled: `fixest` varying slopes (`id[t]`), `ivreg`, `plm`, `felm`. To keep a `partial_iv = FALSE` option, use `iv.endo` instead of the fitted values in the IV branch. The `lm` branch needs `data` with the same row names as when estimating.

```r
#FWL on the design matrix: one projection for all columns, regression
#weights, padded to the data rows
idid_fwl <- function(reg, coef_names, data = NULL) {
  if (inherits(reg, "fixest")) {
    if (isTRUE(reg$is_iv)) {
      #2nd stage design: exogenous regressors and first-stage fitted values
      #(model.matrix(type = "iv.rhs2") fails for transformed endogenous
      #variables and leaves out the fixed effects of the first stage)
      endo <- stats::model.matrix(reg, type = "iv.endo")
      fit <- endo - sapply(reg$iv_first_stage, stats::residuals)
      colnames(fit) <- paste0("fit_", colnames(endo))
      X <- cbind(stats::model.matrix(reg, type = "iv.exo"), fit)
    } else {
      X <- stats::model.matrix(reg, type = "rhs")
    }
    X <- X[, names(stats::coef(reg)), drop = FALSE]
    y <- stats::model.matrix(reg, type = "lhs")
    w <- if (is.null(reg$weights)) rep(1, nrow(X)) else reg$weights
    if (reg$method_type == "feglm") {
      #GLM (feglm, fepois): at convergence, the estimate is the weighted LS of
      #the working response on X with the IRLS weights (they include `weights`)
      eta <- reg$linear.predictors
      y <- eta + (y - reg$fitted.values) / reg$family$mu.eta(eta)
      w <- reg$irls_weights
    }
    if (!is.null(reg$fixef_vars)) {
      if (!is.null(reg$slope_flag) && any(reg$slope_flag != 0)) stop("varying slopes not handled here")
      dm <- fixest::demean(cbind(y, X), f = stats::model.matrix(reg, type = "fixef"), weights = w)
      y <- dm[, 1]; X <- dm[, -1, drop = FALSE]
    }
    rows <- fixest::obs(reg)
    n_data <- if (is.null(data)) reg$nobs_origin else nrow(data)
  } else if (inherits(reg, "lm")) {
    X <- stats::model.matrix(reg)[, !is.na(stats::coef(reg)), drop = FALSE]
    if (inherits(reg, "glm")) {
      #working response and working (IRLS) weights, prior weights included
      y <- reg$linear.predictors + stats::residuals(reg, type = "working")
      w <- reg$weights
    } else {
      y <- stats::model.response(stats::model.frame(reg))
      w <- if (is.null(stats::weights(reg))) rep(1, nrow(X)) else stats::weights(reg)
    }
    stopifnot(!is.null(data))
    rows <- match(rownames(stats::model.frame(reg)), rownames(data))
    n_data <- nrow(data)
  } else stop("class not handled in this sketch")

  stopifnot(all(coef_names %in% colnames(X)))
  sw <- sqrt(w)
  ctrl <- X[, setdiff(colnames(X), coef_names), drop = FALSE]
  #one pivoted QR of the weighted controls, applied to y and to every x
  resid_on_ctrl <- function(M) {
    if (ncol(ctrl) == 0) return(M)
    qr.resid(qr(ctrl * sw), M * sw) / sw
  }
  x_t <- resid_on_ctrl(X[, coef_names, drop = FALSE])
  y_t <- resid_on_ctrl(as.matrix(y))[, 1]

  #share of the variance of x (after the fixed effects) left after partialling
  #out the other regressors: close to 0 means nearly collinear (A3)
  kept <- colSums(w * x_t^2) / colSums(w * X[, coef_names, drop = FALSE]^2)

  pad <- function(v) {out <- rep(NA_real_, n_data); out[rows] <- v; out}
  list(x_tilde = x_t, y_tilde = y_t, w = w, rows = rows, pad = pad, share_variance_kept = kept,
       check_coef = drop(solve(crossprod(x_t * sw), crossprod(x_t * sw, y_t * sw))))
}

#weights for c'beta (default: one coefficient). With a single coefficient,
#w_i = omega_i x_i~^2 / sum omega_j x_j~^2 and beta = sum_i w_i y_i / x_i~
idid_weights_comb <- function(reg, coef_names, combination = NULL, data = NULL) {
  f <- idid_fwl(reg, coef_names, data)
  if (is.null(combination)) {
    stopifnot(length(coef_names) == 1)
    combination <- 1
  }
  #z = X~ (X~' Omega X~)^-1 c, so that c'beta_hat = sum_i omega_i z_i y_i
  z <- drop(f$x_tilde %*% solve(crossprod(f$x_tilde * sqrt(f$w)), combination))
  wt <- f$w * z^2
  list(weights = f$pad(wt / sum(wt)),
       check = c(estimate = sum(combination * stats::coef(reg)[coef_names]),
                 from_weights = sum(f$w * z * f$y_tilde)),
       share_variance_kept = f$share_variance_kept)
}
```

Example checks:

```r
mt <- mtcars; mt$qsec[1:3] <- NA
idid_weights_comb(feols(mpg ~ hp + qsec | cyl, mt, weights = ~disp, subset = ~am == 0), "hp")$check
idid_weights_comb(feols(mpg ~ wt | cyl | hp ~ qsec, mt, weights = ~disp), "fit_hp")$check
idid_weights_comb(lm(mpg ~ hp + wt, mt, weights = disp), "hp", data = mt)$check
r_es <- feols(y ~ i(t, treat, ref = 3) | id + t, dfd)  # dfd: panel with id, t, treat
idid_weights_comb(r_es, c("t::4:treat", "t::5:treat", "t::6:treat"), combination = c(1, 1, 1))$check
```
