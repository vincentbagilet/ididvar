# ididvar: issues to fix

## Context (read first)

- **Package.** `ididvar` 0.0.2, source in `/Users/vincentbagilet/Documents/Research/R_packages/ididvar` (last commit `44cc9b0`). It computes "identifying variation weights": by Frisch-Waugh-Lovell (FWL), in a regression weighted by $\omega_i$, $\hat{\beta} = \sum_i w_i \, y_i / \tilde{x}_i$ with $w_i = \omega_i \tilde{x}_i^2 / \sum_j \omega_j \tilde{x}_j^2$, where $\tilde{x}$ is the variable of interest residualized on the other regressors. The regression is first rewritten as an equivalent linear regression, its control form (`idid_to_cf`: IRLS weights and working response for GLMs, first-stage residuals as controls for IVs, transformed data for `plm`). The "effective sample" functions then drop low weight observations until the estimate or its standard error changes by more than 5%.
- **Origin.** First written in November 2026 while applying the package to published papers in `/Users/vincentbagilet/Documents/Research/hidden_locality/code/replications/` (commit `f144cde`). Most issues were then fixed (commits `82d2784` to `44cc9b0`). **Re-checked on 2026-11-24 on commit `44cc9b0`** (see Verification): each issue below has a status, and new issues found then are marked *new*.
- **Setup used.** R 4.5.2, fixest 0.14.2, AER 1.2.17, plm 2.6.7, lfe 3.1.1, ggplot2 4.0.4, sf 1.1.3 (the `ivreg` package is not installed). Load the development version with `pkgload::load_all("/Users/vincentbagilet/Documents/Research/R_packages/ididvar")`.
- **Tests.** `tests/testthat` has 9 files (82 expectations), all passing on `44cc9b0`. They include the invariant $\sum_i w_i y_i / \tilde{x}_i = \hat{\beta}$ for `lm`, `glm`, `feols` (fixed effects, weights, `subset`, missing values, IV), `fepois`, interactions, `i()`. Turn each snippet below into a `testthat` test when fixing the issue.
- **How to use this file.** Fix the issues one at a time. Line numbers refer to commit `44cc9b0`. Fixed issues are listed at the end, with what verified them.

## Status (2026-11-24, commit `44cc9b0`)

| Status | Issues |
|---|---|
| Open, wrong results without an error | A13, *new* A14, *new* A15 |
| Partly fixed | A9 (near ties), A12 (the fix introduces a bias), C10, C11, D3 |
| Open | A11, B8, C8, D1, D2, D4, E |
| *New*, minor | B9, C12, C13, C14 |
| Fixed (verified) | A1 to A8, A10, B1 to B7, C1 to C7, C9 |

## Verification (2026-11-24)

About 230 checks, each comparing a function with an independent computation (not through the package's code path), on simulated unbalanced panels with missing values, `mtcars`, `txhousing`, `economics`, `Grunfeld` and `CigarettesSW`. Everything passed except the issues listed in this file.

- **Weights** (`idid_weights`, `idid_partial_out`, `idid_share_var`, `idid_to_cf`). Single variable: $\omega_i \tilde{x}_i^2 / \sum_j \omega_j \tilde{x}_j^2$, with $\tilde{x}$ from an auxiliary regression; several variables: leverage of the full model minus leverage of the controls-only model. Checked on `lm` (weights, `subset`, missing values, shuffled rows, offset, zero weights, collinear control, interactions, factor levels, logical, `poly()`), `feols` (two and three fixed effects, interacted fixed effects, weights, `subset`), `felm` (fixed effects, weights, clusters), `plm` (within, two-ways unbalanced, first differences, random, pooling, shuffled data, `pdata.frame`, individual index only), IVs (`feols` and `AER::ivreg`, one and two endogenous variables, exogenous variable of interest, weights, `log()` variables, `partial_iv = FALSE`), GLMs (`glm` Poisson, logit, probit, Gamma, quasipoisson, `cbind()` binomial; `fepois` with fixed effects, weights and offset; `feglm` logit and probit). The same model gives the same weights through `lm` with dummies, `feols`, `felm` and `plm`, and IVs give the weights of the first-stage fitted values. Every model refits from its control form to its coefficients.
- **Effective sample.** `idid_weight_threshold` drops `floor(p n)` observations without ties and never splits exact ties. `idid_drop_reg` gives the same coefficients and number of observations as a manual regression on the selected rows (9 model types, two proportions). `idid_drop_change` matches manual changes in estimate and standard error (`lm`, `feols` with default, clustered and heteroskedasticity-robust variances, two variables of interest). `idid_contrib_threshold` matches a manual re-implementation of the search on 5 models, and dropping below the threshold passes the 5% criterion. `idid_contrib_stats` counts match.
- **Graphs** (`ggplot2::layer_data()` compared with manual aggregation). Bar heights in `idid_viz_weights` are the summed weights, heatmap tiles are $\log_{10}$(cell weight $\times n_x n_y$), colours follow the bins of `scale_fill_idid`, `order` sorts by total weight. `idid_viz_contrib` bars and tiles count contributing observations. Maps (synthetic `sf`): region weights, $\log_{10}$(weight $\times$ number of regions), facets, counts of contributing observations. `idid_viz_cumul`: curve and subtitle. `idid_viz_drop_change`: points are $|$`idid_drop_change`$| \times 100$. `idid_grouping_var`: between-group variances. `idid_viz_bivar`: see A13.
- **Examples.** All documentation examples run (the map examples were not run, as they download shapes with `tigris`).

## Suggested order

1. **Wrong results without an error:** A15 (silent "everything contributes"), A14 (`plm` weights), A12 (standard errors of `fixest` models), A9 (near ties), A13 (`idid_viz_bivar`).
2. **Feature:** A11 (linear combinations).
3. **Errors and small fixes:** B8, B9, C8, C12, C13, C14.
4. **Design questions:** D1 to D4.

---

## A. Wrong results without an error

### A9. Ties at the effective sample threshold: floating point noise splits ties (partly fixed)

**Status:** exact ties are fixed (all tied observations are dropped or kept, `R/idid_weight_threshold.R:20-27`). But weights that are equal mathematically often differ in the last digits (QR in `lm`, iterative demeaning in `fixest`), so tie groups are still split, and which observations are dropped depends on the row order of the data.

```r
set.seed(1)
d <- expand.grid(t = 1:10, id = 1:60)
d$cohort <- c(4, 6, 8, Inf)[(d$id - 1) %% 4 + 1]
d$treat <- as.numeric(d$t >= d$cohort)
d$y <- d$treat + rnorm(nrow(d)) + d$id / 10
w <- idid_weights(lm(y ~ treat + factor(id) + factor(t), d), "treat")
length(unique(w))      # 227 distinct weights...
table(signif(w, 10))   # ...for 6 values (groups of 90, 150, 60, 90, 150, 60)
d2 <- d[sample(nrow(d)), ]
nobs(idid_drop_reg(lm(y ~ treat + factor(id) + factor(t), d2), "treat", 0.1))
# 540 to 542 depending on the shuffle (600 expected: the lowest tie group has 90 obs)
```

- Over 6 shuffles with `lm`, the change in the estimate at `prop_drop = 0.1` ranges from -3.1% to +4.0%: whether a step passes the 5% criterion depends on the row order. With `feols(y ~ treat | id + t)`, 555 observations are kept at 0.1 (600 expected), and 510 or 495 at 0.3 depending on the shuffle.
- Fix: compare weights up to a relative tolerance, e.g. `signif(weights, 10)`, in `idid_weight_threshold` and in the `>=` comparisons (`R/idid_drop_reg.R:35`, `R/idid_contrib_stats.R:45`, `R/idid_viz_contrib.R:63`, `R/idid_viz_contrib_map.R:48`), or round once at the end of `idid_weights`. Checked: with `signif(w, 10)`, 600 observations are kept in every shuffle, for `lm` and `feols`.

### A11. No weights for a linear combination of coefficients (open)

With several variables of interest, `idid_weights` returns the leverage of the block (`stats::hat()` of the partialled out block): the weights for estimating all the coefficients jointly. When the estimate of interest is a combination $c'\beta$ (a predicted impact, the sum of post-treatment event-study coefficients), the relevant weights are $\omega_i z_i^2 / \sum_j \omega_j z_j^2$ with $z = \tilde{X} (\tilde{X}' \Omega \tilde{X})^{-1} c$, and then $c'\hat{\beta} = \sum_i \omega_i z_i \tilde{y}_i$ exactly.

- Evidence from the replications: Deschênes and Greenstone's predicted impact (Table 5, column 4). Texas holds 10% of the block weights but 36% of the weights of the predicted impact (with regression weights; 19% without). Florida holds 14% of the block weights but 5% of the weights of the predicted impact (without regression weights).
- Fix: add a `combination` argument to `idid_weights` and to the functions calling it. Sketch with the current functions (checked: gives back $c'\hat{\beta}$ on the sum of three `i()` event-study coefficients, and `idid_weights` for a single coefficient):

```r
cf <- idid_to_cf(reg)
x_t <- sapply(var_interest, function(v) idid_partial_out(cf, v, var_interest))[cf$obs, , drop = FALSE]
y_t <- idid_partial_out(cf, cf$y_name, var_interest)[cf$obs]
z <- drop(x_t %*% solve(crossprod(x_t * sqrt(cf$weights)), combination))
w <- cf$weights * z^2 / sum(cf$weights * z^2)
sum(cf$weights * z * y_t)  # = sum(combination * coef(reg)[var_interest])
```

### A12. Effective samples of `fixest` models: no small sample correction biases the standard error change (partly fixed, the fix introduces a bias)

**Status:** the change in the standard error no longer depends on the `ssc` of the regression: `fixest` standard errors are computed with `ssc(K.adj = FALSE, G.adj = FALSE)` (`R/idid_drop_change.R:55-60`). But without the $K$ correction, $\hat{\sigma}^2 = RSS / n$ is biased down by $(n - K)/n$, with $K$ including the fixed effects. When observations are dropped and the fixed effects remain, this bias grows, so the standard error mechanically decreases. Other classes (`lm`, `felm`, ...) keep $RSS / (n - K)$, so the same model gets a different effective sample with `lm` and with `feols`.

```r
set.seed(1)
d <- data.frame(id = rep(1:30, each = 8), x = rnorm(240), z = rnorm(240))
d$y <- 0.5 * d$x + d$z + rep(rnorm(30), each = 8) + rnorm(240)
r_lm <- lm(y ~ x + z + factor(id), d)
r_fe <- feols(y ~ x + z | id, d, vcov = "iid")     # same weights (to 1e-16)
idid_drop_change(r_lm, "x", 0.5)$prop_change_se    # -0.119
idid_drop_change(r_fe, "x", 0.5)$prop_change_se    # -0.036
idid_contrib_stats(r_lm, "x")$prop_effective       # 0.70
idid_contrib_stats(r_fe, "x")$prop_effective       # 0.50
```

- Monte Carlo (500 draws of the outcome, 30 fixed effects, 217 observations, same dropped half): the true change in the standard deviation of $\hat{\beta}$ is -7.9%. The mean estimated change is -0.1% with the current setting (the 5% criterion passes in 56% of the draws) and -9.7% with `ssc(K.fixef = "full")`, which equals `lm` (passes in 21%). The current setting therefore declares too many observations non-contributing when there are many fixed effects relative to $n$.
- The original concern (Burke and Emerick, Table 1, column 4: -3.0% with the default `ssc`, -6.4% with `ssc(fixef.K = "full")`) was that the correction changes when dropping observations removes fixed effects. But this change is legitimate: fewer parameters are estimated.
- Fix: count the parameters actually estimated, `ssc(K.adj = TRUE, K.fixef = "full")`, which equals `lm` with dummies for iid errors. Probably also keep `G.adj = TRUE`: the uncorrected cluster-robust variance is biased down by $(G-1)/G$, which also changes when clusters are dropped (not checked).

### A13. `idid_viz_bivar`: the slope shown is not the coefficient for weighted regressions, GLMs and several variables of interest (open)

`R/idid_viz_bivar.R:35-52`. Correct for unweighted models with one variable of interest (checked: `lm`, `feols` with two fixed effects, `feols` IV).

```r
idid_viz_bivar(lm(mpg ~ hp + wt, mtcars, weights = disp), "hp")  # slope -0.034, coef -0.029
idid_viz_bivar(lm(mpg ~ hp + wt + qsec, mtcars), c("hp", "wt"))  # slope -0.085, coef -0.018
idid_viz_bivar(glm(am ~ hp + wt, binomial, mtcars), "wt")        # slope -8.73, coef -8.08
```

- Several variables of interest: $x_1$ and $y$ are residualized on the controls but not on the other variables of interest. `geom_smooth(method = "lm")` ignores the regression weights (and the IRLS weights of GLMs).
- Fix (checked: the slope equals the coefficient for weighted `feols`, `glm` Poisson and two variables of interest): `x_par = idid_partial_out(reg, var_interest[[1]])` (everything else partialled out), `y_par = idid_partial_out(reg, name_var_y, var_interest[[1]])`, and weight the smoother with the control form weights (`aes(weight = ...)`, `idid_to_cf(reg)$weights` padded to the data rows). Possibly size points by their weight.
- Minor: the data is `idid_data(reg)`, so rows outside the estimation sample trigger "Removed n rows" warnings. Restrict to the estimation sample.

### A14. `plm`: regression weights are ignored (*new*)

`R/idid_to_cf.R:186-192`. `plm` accepts `weights` and stores them in `reg$weights`, but `idid_to_cf.plm` does not pass them, so the control form is unweighted. The weights are wrong and the control form does not refit to the coefficients. No error.

```r
data("Grunfeld", package = "plm")
set.seed(1); G <- Grunfeld; G$w <- runif(nrow(G), 0.2, 3)
r <- plm::plm(inv ~ value + capital, G, index = c("firm", "year"), model = "within", weights = w)
cf <- idid_to_cf(r)
stats::lm.wfit(cf$x, cf$y, cf$weights)$coefficients[["value"]]  # 0.1101, coef(r) is 0.1095
```

- 18% of the weight moves compared with the corrected weights (24% on a simulated panel).
- Fix: `weights = reg$weights` in `idid_to_cf.plm`. Checked: `reg$weights` is in the order of `model.matrix(reg)` and the refit gives back the coefficients for within, pooling and random models, on shuffled data. Note: the weighted within estimator of `plm` differs from `feols` with weights (`plm` demeans without the weights), so compare with `plm`'s own coefficients, not with `feols`.

### A15. Effective sample silently "everything contributes" when the model cannot be re-run (*new*)

`R/idid_drop_change.R:72-77`, `R/idid_contrib_threshold.R:55-59`. The fix of B7 catches *every* error of the regression on the sliced data as `NA`, and the search treats `NA` as a failing step. When `update()` cannot re-run the model for a reason unrelated to the dropped observations, the first step fails and all observations are declared contributing, without a message.

```r
reg <- lm(mpg ~ hp + wt, mtcars, weights = mtcars$disp)  # weights given as a vector
idid_drop_change(reg, "hp", 0.1)    # NA: update() fails ("variable lengths differ")
idid_contrib_stats(reg, "hp")       # prop_effective 1
idid_contrib_stats(lm(mpg ~ hp + wt, mtcars, weights = disp), "hp")  # prop_effective 0.91
```

- `felm` only accepts weights as a vector (`weights = w` gives "object 'w' not found"), so **every weighted `felm` model** gets `prop_effective = 1` (0.50 for the same model with `feols` on a simulated panel), and flat graphs in `idid_viz_contrib`, `idid_viz_contrib_map` and `idid_viz_drop_change`. Same for other arguments given as vectors of the full data (checked with `lm`: `offset = d$qsec` gives 1 instead of 0.97, `subset = d$cyl > 4` gives 1 instead of 0.95).
- Fix: only treat as `NA` the failures caused by the dropped observations. For instance, check once that `idid_drop_reg(reg, var_interest, 0)` gives back `coef(reg)` and stop with a clear message otherwise; and/or turn the caught error into a warning.

---

## B. Errors

### B8. `idid_grouping_var(grouping_vars = "everything")` is documented but not implemented (open)

`R/idid_grouping_var.R:13-15` (documentation) vs `39-50` (loops over the literal strings): `idid_grouping_var(reg, "median", "everything")` errors.

- Fix: implement it (`names(df)` minus `idid_weight`) or remove it from the documentation.

### B9. `felm` with `subset` errors (*new*)

`R/idid_to_cf.R:210`. The rows used are computed from `reg$na.action` only, which does not include the rows excluded by `subset`. `felm` does not keep row names, so they cannot be matched.

```r
r <- lfe::felm(mpg ~ hp + wt | cyl, mtcars, subset = mtcars$am == 0)
idid_weights(r, "hp")  # Error in fixest::demean: `weights` ... of length 32 instead of 19
```

- Always an error (not a silent misalignment): the weights vector has the length of the data, not of the estimation sample.
- Fix: evaluate `reg$call$subset` in `idid_data(reg)` and combine it with `reg$na.action`, or stop with a clear message when `reg$call$subset` is not `NULL`.

---

## C. Ignored arguments, documentation, display, performance

### C8. Heatmaps: zero weights shown as missing; scale labels (open)

`R/scale_fill_idid.R:43-50` and `57-64`. Values beyond `limits` are squished into the extreme bins (checked: 1/150x and 1e-5x get the lowest colour, 150x and 1e5x the top one), but a cell with exactly zero weight ($\log_{10} 0 = -\infty$) gets `na.value`, the same grey as cells with no observations (checked). The extreme breaks (1/100x and 100x) are still labelled "0" and "Inf".

- Exact zeros occur with zero regression weights or IRLS weights (fitted probabilities of exactly 0 or 1). Fix: `oob = scales::oob_squish_any`, and label the extreme breaks "1/100x" and "100x" (or "≤ 1/100x", "≥ 100x").

### C10. Performance: the weights are recomputed at every step (partly fixed)

**Status:** the weights no longer re-estimate the model (they come from the control form), so each computation is much cheaper. But they are still recomputed at every step (`R/idid_drop_reg.R:31`), then again in `idid_contrib_stats` (line 44), `idid_viz_contrib` and the maps. `idid_weights` calls `idid_partial_out` once per variable of interest, and each call demeans all the columns (`R/idid_weights.R:39-41`, `R/idid_partial_out.R:78-86`).

- Fix: compute the weights once and pass them down (internal argument), and demean all columns once in `idid_weights`.

### C11. Missing input checks and fragile data retrieval (partly fixed)

**Status:** `idid_data` (`R/idid_data.R`) now finds the data of models estimated inside functions, uses the data saved with `data.save = TRUE`, and errors if the data cannot be found or no longer matches (number of rows for `fixest`, row names for other classes). Weights are matched to rows by row names for `lm`, `glm` and `ivreg` (checked on shuffled data), by `fixest::obs()` for `fixest`, by the panel index for `plm`, and by `reg$na.action` for `felm` (see B9).

- Still: the data cannot be passed explicitly, and for `fixest` (without `data.save = TRUE`), reordering the rows of the data after estimation is not detected (same number of rows).

### C12. `idid_partial_out` on a regressor that is not a variable of interest returns 0 (*new*, minor)

`R/idid_partial_out.R:89`. The controls are all the regressors except `var_interest`, so they include `var_to_partial` itself when it is not in `var_interest`: it is partialled out of itself.

```r
r <- lm(mpg ~ hp + wt + qsec, mtcars)
idid_partial_out(r, "wt", "hp")  # zeros (2e-16), expected the residuals of wt on qsec
idid_share_var(r, "wt", "hp")    # 1
```

- No internal function calls it this way (always the outcome or a variable of interest), so the weights and graphs are not affected. Fix: `setdiff(colnames(x), c(var_interest, var_to_partial_name))`, or document that `var_to_partial` must be the outcome or one of `var_interest`.

### C13. `idid_contrib_threshold`: accumulated `prop_drop` drops one observation less at some steps (*new*, minor)

`R/idid_contrib_threshold.R:47`. `prop_drop <- prop_drop + search_step` accumulates rounding errors: after 9 steps of 0.05, `prop_drop` is 0.44999999999999996, so `floor(prop_drop * n)` is one less than intended. With `n = 100`, the steps 0.45, 0.50 and 0.55 drop 44, 49 and 54 observations. `idid_viz_drop_change` uses `seq()` and drops 45, 50 and 55, so both can disagree by one observation at the same nominal step.

- Fix: `prop_drop <- k * search_step` with an integer counter `k`.

### C14. `background` vignette: formula of the weights (*new*, minor)

`vignettes/background.Rmd`. The formula $w_i = (x_i - \mathbb{E}[x_i | C_i])^2 / \sum_j w_j$ is normalized by the weights themselves instead of $\sum_j (x_j - \mathbb{E}[x_j | C_j])^2$, and does not mention the regression weights $\omega_i$ (IRLS weights for GLMs) or IVs (the first-stage fitted values are used). "the regression of the independent variable on the treatment" should be "dependent". The numerical example of the vignette is correct (checked: same residuals as the auxiliary `feols`).

---

## D. Design questions (to decide, not bugs)

### D1. The criterion "relative change in the estimate" is meaningless for estimates close to zero (open)

`R/idid_drop_change.R:82`. `(est_full - est_sliced) / est_full` explodes when the estimate is close to zero, so the effective sample of a null or placebo result is driven by noise.

```r
set.seed(1)
dfz <- data.frame(x = rnorm(500), z = rnorm(500)); dfz$y <- 0.001 * dfz$x + dfz$z + rnorm(500)
idid_contrib_stats(lm(y ~ x + z, dfz), "x")  # prop_effective 0.80
```

- Options: express the change in the estimate in units of the standard error ($|\Delta \hat{\beta}| / \widehat{se}$), or only use the standard error criterion. The sign convention is still (full - sliced) / full, the reverse of the usual one.

### D2. `idid_grouping_var` compares variances that are not comparable (open)

`R/idid_grouping_var.R:49`. The variance of the summed weights across groups depends mechanically on the number of groups (the average group weight is $1/G$) and on group sizes. A grouping variable with few groups mechanically ranks higher. Options: compare each group's weight to its share of the observations, or use a scale-free measure (e.g. $G \times$ standard deviation, or the effective number of groups $1 / \sum_g W_g^2$ relative to $G$).

### D3. Scale of `idid_viz_weights` and of the maps (partly fixed)

**Status:** the number of categories is now counted on the estimation sample (`idid_estim_data`). Still:

- The heatmap compares each cell to $1/(n_x n_y)$, the number of *possible* cells (`R/idid_viz_weights.R:84-86`), while the map compares each region to the number of regions *with data* (`R/idid_viz_weights_map.R:62`). On `txhousing` (city by year), 668 of the 736 possible cells have data, so every tile is shifted by $\log_{10}(736/668) = 0.04$; on sparse grids (e.g. judge by month), much more. The legend says "compared to 1/n, the average weight".
- Cell weights are sums over observations, so cells with many observations are mechanically heavy (the Miami issue in Heyes and Saberian). An option to compare each cell to its share of the observations (the nominal sample) would help. `idid_viz_contrib_map` shows counts of contributing observations, not shares.

### D4. Other suggestions (open)

- **Threshold-free concentration measure.** The effective number of observations $1 / \sum_i w_i^2$ (and of groups, $1 / \sum_g W_g^2$) is comparable across specifications and papers, unlike the 5% threshold effective sample.
- **Contributions to the estimate.** Exporting the decomposition $\hat{\beta} = \sum_i c_i$, with $c_i = \omega_i \tilde{x}_i \tilde{y}_i / \sum_j \omega_j \tilde{x}_j^2$, shows which observations drive the estimate, not only where the variation is. Summed by group, it writes the estimate as a weighted average of group-level estimates. With A11, $c_i = \omega_i z_i \tilde{y}_i$.
- **Comparing specifications.** A function computing the share of the weight moving between two specifications ($\frac{1}{2} \sum_i |w_i^A - w_i^B|$), by observation or group, and handling different estimation samples.

## E. Related, not ididvar

- With variables on very different scales (e.g. squared degree-days of the order of $10^7$ in Deschênes and Greenstone), the variance-covariance matrices of `fixest` are numerically unstable. Rescaling the variables fixes it.

---

## Fixed (verified 2026-11-24, commit `44cc9b0`)

The original descriptions and reproductions are in the version of this file in commit `82d2784`. Each original example was re-run on `44cc9b0`.

- **A1. Regression weights ignored.** Weighted `lm`, `feols`, `felm`, `ivreg`: $w_i = \omega_i \tilde{x}_i^2 / \sum_j \omega_j \tilde{x}_j^2$. The original example now gives -0.02945, the coefficient. (`plm` weights: see A14.)
- **A2. Residualization on the formula.** Controls dropped for collinearity are not partialled out (original example: 0.4995, the coefficient). A variable that is not a coefficient and the outcome given through a formula object error. Weights are computed from the control form, without re-estimation.
- **A3. Collinearity with the controls.** A variable of interest dropped by the estimator errors ("not a coefficient").
- **A4. GLMs.** `glm` (Poisson, logit, probit, Gamma, quasipoisson, `cbind()` binomial), `fepois` (fixed effects, weights, offset), `feglm` (logit, probit): IRLS weights; same weights as `glm` with dummies.
- **A5. `ivreg` with transformed variables.** Same weights as the equivalent `feols` IV (CigarettesSW with `log()`), also with weights and two endogenous variables.
- **A6. `plm` on unsorted data.** Within, two-ways, first differences (weight on the later period's row), random and pooling models on shuffled data with missing values: same weights per row as `feols` or `lm`.
- **A7. Effective sample one step too large.** The threshold is the last passing step (manual re-implementation on 5 models). Original example: 65% effective, 0.35 passes, 0.40 fails.
- **A8. Estimation sample differs from the data.** Original example: 176 and 146 observations kept, as expected. `lm` with `subset` works in the graphs.
- **A10. Several variables of interest in `idid_drop_change`.** One row per variable; the search requires all of them to pass.
- **B1.** Exogenous variable of interest in a `feols` IV. **B2.** `feols` IV with missing values. **B3.** Transformed endogenous variable (`log(hp)`). **B4.** Names with parentheses. **B5.** Interactions, factor levels, logicals, `i()`, `poly()` as variables of interest (given as coefficient names). **B6.** `felm` in the effective sample functions (unweighted; weighted: see A15). **B7.** Coefficient not estimable after dropping: `NA` (but see A15).
- **C1.** `idid_viz_drop_change` uses `search_step`. **C2.** `idid_viz_weights_map` passes `...`. **C3.** No warning for IVs. **C4.** `idid_contrib_stats` documents `n_initial`. **C5.** `idid_to_cf` examples run. **C6.** `idid_viz_cumul` subtitle: the smallest number of observations holding `1 - prop_weights` of the weight. **C7.** `idid_viz_bivar` labels (single strings, transformed outcome shown). **C9.** `R/stat_sum_sf.R` removed.
