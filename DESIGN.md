# DESIGN

**Adult-child coresidence and emergency savings capacity among adults 50+**
Household Finance Lab · Data: Federal Reserve Survey of Household Economics and Decisionmaking (SHED), 2025 public file (`public2025.csv`, n = 12,934)

**Status:** documented analysis plan. Everything below was fixed before the adjusted and prediction-layer results were examined. The unadjusted comparison and age-benchmark figures were computed while the plan was being written; see the disclosure in §2 and the figures in §7.

---

## 1. Research question

Emergency savings capacity is substantially higher among adults 50 and older than among younger adults in SHED 2025. This project focuses on whether, within the 50+ population, living with an adult child is associated with lower $2,000 emergency savings capacity.

**RQ.** Among adults age 50 and older, are those living with an adult child less able to cover a $2,000 emergency expense from savings than otherwise similar adults without a coresident adult child?

The age contrast is context and motivation. It is not part of the estimand, and the under-50 population is not a comparison group in any model.

## 2. Hypothesis

**H1.** Adults age 50 and older who live with an adult child are less likely to be able to cover a $2,000 emergency expense from savings than those who do not.

H1 is the only hypothesis. Model 2 answers a question — whether the difference persists after accounting for major differences between these households — but that question is not stated as a directional hypothesis, because predicting attenuation after adjusting for covariates correlated with both exposure and outcome would be predicting the mechanics of regression rather than a claim about the world.

The prediction layer (§9) is stated as a question, not a hypothesis. No direction is assumed.

**Disclosure:** the unadjusted comparison and the age-benchmark figures were computed while the design was being written and are reported in §7. H1 therefore frames the project rather than tests it. What remains unobserved is the adjusted difference and all prediction-layer results.

## 3. Sample

| | |
|---|---|
| Universe | SHED 2025 respondents, `ppage` ≥ 50 |
| n | 6,962 (5,224 without coresident adult child, 1,738 with) |
| Primary restriction | 50+, pre-specified |
| Sensitivity restrictions | 45+; unrestricted adult sample |

Restriction cutoffs are fixed in advance and will not be selected on the basis of results.

## 4. Variables

All variables verified present in `public2025.csv`. Missing counts are for the full file.

### Outcome

| Variable | Description | Missing |
|---|---|---|
| `EF7` | Largest emergency expense coverable from savings — 5 categories, ceiling "$2,000 or more" | 6,481 |
| `EF7A` | Same item, 6 categories, ceiling continues to "$5,000 or more" | 6,453 |

`EF7` and `EF7A` are the two arms of the randomized `dov_ef7` split. Assignment is disjoint and covers the full sample.

**Constructed outcome — `cap2k`:** 1 if the respondent could cover $2,000 or more, 0 otherwise.

- From `EF7`: 1 if "$2,000 or more"
- From `EF7A`: 1 if "$2,000 to $4,999" or "$5,000 or more"

The two arms use identical response categories below the $2,000 threshold and diverge only above it. Binarizing at $2,000 therefore loses no information needed to identify whether a respondent can cover $2,000, and loses no respondents. `cap2k` is complete for all 12,934 cases.

Because the arms are equivalent by construction at this threshold, `dov_ef7` does not enter the models. An empirical arm check is recorded in the validation log (§8), not used as justification.

### Exposure

| Variable | Description | Missing |
|---|---|---|
| `L0_c` | An adult child age 18 or older currently lives in the household | 0 |

### Covariates

| Variable | Description | Type | Missing |
|---|---|---|---|
| `ppage` | Exact age, 18–98 | Continuous | 0 |
| `ppgender` | Gender | Categorical | 0 |
| `race_5cat` | White / Black / Hispanic / Asian / Other | Categorical | 0 |
| `ppmarit5` | Married / Never married / Divorced / Widowed / Separated | Categorical | 0 |
| `ppeduc5` | Five-level education | Categorical | 0 |
| `ppemploy` | Full-time / part-time / not working | Categorical | 0 |
| `GH1` | Housing tenure — own with mortgage / own free and clear / rent / neither | Categorical | 0 |
| `I40` | Respondent and spouse/partner combined income, 15 brackets | Categorical | 0 |

`I40` is treated as categorical, not as an ordinal score. Bracket widths are uneven, particularly at the top, so a one-category step has no common substantive meaning. This applies in both layers.

`GH1` is used rather than `pprent` because it is asked during the SHED interview; `pprent` is an Ipsos panel profile variable.

`I40` is used rather than `ppinc7` because it is asked during the SHED interview and its universe is explicitly stated. `ppinc7` is an Ipsos profile variable labeled "Household Income," collected outside the SHED interview and refreshed on Ipsos's own schedule.

### Design

| Variable | Description | Missing |
|---|---|---|
| `weight` | Post-stratification weight; the weight used for published Fed statistics | 0 |
| `dov_ef7` | Randomization arm indicator (validation only) | 0 |
| `ppt18ov` | Adults 18+ in household (data-quality flag only) | 0 |

The public file supplies no strata, PSU, or replicate weights. Variance estimation uses `svyset [pw=weight]`, which treats the sample as weighted simple random sampling. Standard errors are approximate on that basis, and this is stated in the README.

## 5. Inference layer (Stata)

**Model 1 — headline descriptive.** Weighted proportion able to cover $2,000, by `L0_c`, among 50+. Reported as two percentages and their difference in percentage points. The confidence interval on the difference is the survey-linearized interval produced under `svyset [pw=weight]`, not a naive two-proportion interval.

**Model 2 — adjusted.** Survey-weighted logistic regression of `cap2k` on `L0_c` plus the covariates in §4.

Results are reported as **average marginal effects on the percentage-point scale** (`margins, dydx(L0_c)` after `svy: logit`), averaged over the observed covariate distribution — not as odds ratios, and not evaluated at covariate means.

Logistic coefficients and odds ratios are non-collapsible: the conditional odds ratio differs from the marginal odds ratio even absent confounding, purely from rescaling when covariates enter. Comparing odds ratios across Models 1 and 2 would therefore conflate adjustment with an artifact of the link function. The percentage-point scale is collapsible and comparable across the two models, and is also the scale a general reader can interpret.

**Reporting commitment.** The adjusted difference and its confidence interval will be reported whatever their magnitude. No threshold is pre-specified for calling the result "meaningful," because no substantive basis exists for placing one. The research question will not be reframed after the adjusted estimate is seen.

### Sensitivity analyses

| # | Change | Purpose |
|---|---|---|
| S1 | Substitute `ppinc7` for `I40` | Whether the conclusion depends on the income construct |
| S2 | Exclude the 161 cases flagged in §6 | Whether the profile-inconsistent records matter |
| S3 | Age cutoff at 45+; then unrestricted | Whether the estimand boundary matters |

Each reported in one sentence stating whether the conclusion changes. Sensitivity samples apply to the inference layer only; §9 runs on the primary analytic sample.

## 6. Data-quality decision, fixed in advance

161 respondents aged 50+ report `L0_c` = Yes but `ppt18ov` = 1, with a mean `pphhsize` of 1.19. `L0_c` is asked during the SHED interview; `pphhsize` and `ppt18ov` are Ipsos panel profile variables refreshed separately. Where the two disagree, the contemporaneous survey response is treated as authoritative.

**These cases are retained in the primary analysis.** Exclusion runs as sensitivity S2.

## 7. Figures already observed

Computed during design, disclosed here so that nothing below is presented as a fresh result.

**Within the analytic sample:**

| Quantity | Value |
|---|---|
| Can cover $2,000, no coresident adult child (50+) | 64.7% |
| Can cover $2,000, coresident adult child (50+) | 51.6% |
| Unadjusted difference | −13.1 pp (SE 1.5, p < 0.0001) |
| Same, excluding the 161 flagged cases | −12.9 pp |
| Arm check at 50+: `EF7` vs `EF7A` on `cap2k` | 61.0% vs 61.2% |

**Age benchmarks (context, §1):**

| Group | Can cover $2,000 |
|---|---|
| All adults 18+ | 49.7% |
| Adults 18–49 | 39.4% |
| Adults 50+ | 61.1% |
| By decade: 18–29 / 30–39 / 40–49 | 30.3% / 44.0% / 45.9% |
| By decade: 50–59 / 60–69 / 70+ | 54.4% / 60.7% / 68.5% |

Nothing about the adjusted estimate or any prediction-layer result has been observed.

## 8. Validation gates for `01_build.do`

The build fails loudly if any of these do not reproduce:

1. Raw file n = 12,934
2. `cap2k` complete for all 12,934; no missing after construction
3. `EF7` answered by 6,453; `EF7A` by 6,481; disjoint, summing to 12,934
4. Analytic sample at 50+: n = 6,962 (5,224 / 1,738)
5. Unweighted `L0_c` = Yes overall: 2,429
6. Weighted `cap2k` by `L0_c` at 50+ reproduces 64.7% / 51.6%
7. Profile-inconsistency flag counts 161 cases
8. All §4 covariates have zero missing in the analytic sample
9. Each of `fold_r1`–`fold_r5` has five levels, and each `cap2k` × `L0_c` cell is distributed across folds within ±1 observation

## 9. Prediction layer (Python)

**Question.** Does adding adult-child coresidence improve out-of-sample prediction of the ability to cover a $2,000 emergency expense?

Stated as a question, not a hypothesis. This is a different question from the inference layer, not a translation of it. The inference layer estimates how much the probability shifts on average between groups; the prediction layer asks whether the variable carries information a model does not already hold. Those can diverge.

**Comparison.** Base model uses the §4 covariates excluding `L0_c`. Augmented model uses the same predictors plus `L0_c`. Nothing else differs.

**Primary model.** L2-regularized logistic regression, solver `lbfgs`, `max_iter=5000`.

**Secondary model.** Gradient boosting, fixed and untuned: `n_estimators=200`, `learning_rate=0.05`, `max_depth=2`, `min_samples_leaf=20`, `subsample=1.0`, `random_state` set to the corresponding repeat seed. No hyperparameter search.

**Outer validation.** Repeated 5-fold cross-validation, 5 repeats, fixed seeds 202502, 202503, 202504, 202505, 202506. Folds stratified on the four cells of `cap2k` × `L0_c`. Base and augmented models use identical folds within every repeat. Fold assignments are generated once in `01_build.do` and shipped as `fold_r1`–`fold_r5` in `analytic_dataset.csv`.

**Penalty tuning.** Within each outer training partition, 5-fold inner CV over a fixed grid of 21 values of `C` log-spaced from 1e-4 to 1e4, selecting the `C` with lowest mean unweighted log loss across inner validation folds. Tuned separately for base and augmented models within every outer training fold.

**Preprocessing.** All preprocessing parameters are estimated on training observations only and applied unchanged to held-out observations, at both outer and inner CV levels. `ppage` is standardized using training-fold mean and SD. All categorical predictors are one-hot encoded within the training pipeline, `I40` included. No transformation parameter may be computed from the full analytic dataset before cross-validation. Fold assignment itself is created in Stata from `cap2k` × `L0_c` and is design, not preprocessing.

**Weighting.** Models are fit unweighted. Out-of-sample performance is evaluated using SHED `weight`.

**Primary metric.** Weighted AUC.

**Secondary metrics.** Weighted Brier score; weighted calibration slope and intercept. Slope is the coefficient from a weighted logistic regression of the outcome on the logit of the out-of-fold predicted probability. Intercept is from a second weighted logistic regression with that logit entered as an offset. All secondary metrics are reported regardless of result.

**Aggregation.** Each repeat produces exactly one complete set of out-of-fold predictions covering all 6,962 observations. Metrics are computed once per repeat and averaged across the five repeats. That average is the headline. Metrics are not computed on predictions pooled across repeats, which would compare observations' predictions from different partitions.

The increment is the augmented-minus-base difference, presented as five paired repeat-level differences. The 25 fold-level differences are retained as a stability diagnostic. Neither set is treated as independent observations for significance testing: training sets overlap across folds and observations recur across repeats, so conventional variance estimators are biased downward. Magnitude and stability are reported; no p-value is attached to the increment.

**Direction of predictive increment.** No improvement is assumed. Adding `L0_c` may improve, leave unchanged, or worsen out-of-sample performance. A negative change in AUC or deterioration in any pre-specified metric is a substantive result, not grounds for modifying the model, folds, preprocessing, or hyperparameters.

**Noted limitation.** Penalty tuning selects on unweighted log loss while the headline metric is weighted AUC. The tuned model is therefore optimized for a criterion other than the one reported. This is standard practice and is stated rather than concealed.

## 10. Limitations, fixed in advance

**Reference group.** `L0_c` identifies whether an adult child currently lives in the household. It does not identify whether respondents coded 0 have adult children living elsewhere. The comparison group therefore pools people who never had children, people whose children have launched, and parents of minors only. Results describe an association with household coresidence, not the financial effect of an adult child moving home. The project will not be titled or framed as being about what adult children do to their parents' finances.

**Framing rule.** Coresidence is described as an adult child living in the household, never as supporting an adult child, in the paper, the repository, and any media copy. SHED observes the arrangement, not the direction of transfers within it.

**Direction.** SHED 2025 is cross-sectional. It cannot distinguish coresidence reducing resilience, low resilience prompting an adult child to move home, or both arising from a common cause. All language stays associational.

**Household size.** Household size and adult count are deliberately not adjusted. Conditioning on them would change the question from whether coresidence is associated with lower resilience to whether composition matters among households of similar size. That is a legitimate question and a different one.

**Resource flows.** SHED observes the living arrangement but not transfers within the household. Whether a coresident adult child contributes to or draws on household resources is unobserved.

**Variance.** No design variables in the public file; see §4.

## 11. A question for future work

`panel_weight` covers 4,419 respondents who completed both the 2024 and 2025 surveys. If both waves carry `L0_c` and the emergency-expense item, that subsample can observe coresidence transitions, which is the only design available in SHED that addresses the direction problem in §10.
