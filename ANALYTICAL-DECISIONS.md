# Analytical decisions

Every consequential choice in this project, the alternative that was available, and whether the number moved. Decisions marked **pre-specified** were set in `DESIGN.md` before the adjusted and prediction-layer results were examined. Decisions marked **build-time** were made while writing `01_build.do` and are recorded here because they were judgment calls, not mechanics.

---

## 1. Outcome: a threshold, not a level — **pre-specified**

**Chose:** a binary `cap2k`, can the respondent cover a $2,000 emergency expense from savings.

**Alternative:** an asset or savings level, as in Maroto (2017, 2019).

**Why:** a level and a threshold are different constructs. A household can hold modest assets and clear $2,000, or hold substantial illiquid assets and not. The threshold is the one that decides whether a shock becomes an event, and it is the gap the literature left open.

**Cost:** our estimate is not comparable in magnitude to Maroto's, only in direction.

---

## 2. Pooling both arms of the randomized EF7/EF7A split — **build-time**

**Chose:** build `cap2k` from both arms and keep all 12,934 respondents.

**Alternative:** use the EF7 arm only (n = 6,453), avoiding any assumption about comparability.

**Why:** the two forms have identical categories below $2,000 and diverge only above it. The $2,000 threshold is therefore common to both and no respondent is lost. Gate 3 asserts the arms are disjoint and sum to the full file.

**Number moved:** not tested as a sensitivity. Using one arm would halve the sample for no measurement gain.

---

## 3. Income entered as 15 categories, not an ordinal score — **pre-specified**

**Chose:** `i.income`, treated as categorical throughout.

**Alternative:** an ordinal bracket score, or bracket midpoints in dollars.

**Why:** the bracket widths are uneven — $5,000 at the bottom, $50,000 at the top. An ordinal score imposes a linearity the brackets do not support, and midpoints invent a value for the open-ended top category.

**Cost:** 14 parameters spent on income.

---

## 4. Which income measure — **pre-specified as S1, and the one that moved**

**Chose:** I40, income received by the respondent and spouse or partner, asked inside the SHED interview, 15 brackets.

**Alternative:** ppinc7, a household income measure from the Ipsos profile, collected separately and on its own refresh schedule, 7 brackets.

**Number moved:** −5.11 → −7.82 percentage points. This is the largest movement anywhere in the sensitivity set.

**What we can and cannot say about it:** the two measures differ in at least three ways at once — the income concept, how and when it was collected, and the coarseness of the brackets. Our design cannot attribute the movement to any one of them. The result held under both; its magnitude is sensitive to how income is measured. That is the honest statement, and it is weaker than the one it is tempting to make.

---

## 5. The 161 profile-inconsistent cases: retained — **pre-specified, Sec. 6**

**Chose:** keep respondents who answered L0_c = Yes while the Ipsos profile reports one adult in the household.

**Alternative:** drop them as data errors.

**Why:** L0_c is asked contemporaneously in the SHED interview; `ppt18ov` is a profile variable refreshed on a separate schedule. Where they disagree, the contemporaneous answer is authoritative. Fixing this in advance, in Sec. 6, meant the choice could not be made after seeing which way it moved the estimate.

**Number moved:** −5.11 → −5.39 when excluded (S2). Negligible.

---

## 6. Age cutoff at 50 — **pre-specified, with 45+ and unrestricted as S3**

**Chose:** 50+ as the primary sample.

**Alternative:** 45+, or all adults.

**Why:** the stake after 50 is decumulation, and 50+ is the range used by the coresidence-and-wellbeing literature we are extending (Caputo 2019; Caputo & Cagney 2023).

**Number moved:** −5.01 at 45+, −7.18 unrestricted. The boundary changes the estimand — the unrestricted sample includes adults in their twenties and thirties living with parents, a different arrangement entirely — so S3b is reported as a boundary check, not as a better estimate.

---

## 7. Average marginal effects, not odds ratios — **pre-specified**

**Chose:** report AMEs on the percentage-point scale, averaged over the observed covariate distribution.

**Alternative:** report odds ratios from the logit.

**Why:** odds ratios are non-collapsible. An OR that changes between Model 1 and Model 2 confounds adjustment with rescaling of the link function, and a reader cannot tell which they are looking at. No odds ratio appears anywhere in the results.

---

## 8. Unadjusted difference from a survey-weighted LPM — **build-time**

**Chose:** take the M1 difference from `svy: regress cap2k i.coresident`.

**Alternative:** a naive two-proportion confidence interval.

**Why:** the naive interval ignores the design. The linear probability model yields a design-linearized interval on the same percentage-point scale as M2, so M1 and M2 are directly comparable.

---

## 9. Weights without strata or PSU — **forced by the data**

**Chose:** `svyset [pw=wt]`.

**Alternative:** a full design specification with strata and clusters.

**Why:** the SHED public use file releases post-stratification weights but not strata or PSU identifiers. This is a limitation of the public file, not a choice, and it is recorded in the README's limitations section.

---

## 10. Folds assigned in Stata, never regenerated in Python — **pre-specified, Sec. 9**

**Chose:** five fold columns written into the Python input file, stratified on the four cells of `cap2k` × `coresident`, seeds 202502–202506, with the data sorted on `rid` before each draw.

**Alternative:** let the Python layer generate its own folds.

**Why:** the base and augmented models must see identical splits, or the AUC increment measures fold noise as well as the variable. Freezing the folds upstream makes that impossible to get wrong, and makes the split reproducible from Stata alone. Gate 9 asserts every stratum is spread across the five folds within ±1.

---

## 11. Value labels exported as strings in the Python input file — **build-time**

**Chose:** export readable category strings to `analytic_dataset.csv` and let the Python layer do its own one-hot encoding inside each training fold.

**Alternative:** export numeric codes, or pre-encode in Stata.

**Why:** encoding inside the training fold prevents categories present only in a test fold from leaking into the fitted transformer. Strings also make the handoff file readable without the Stata value labels.

---

## Things that did not work

**A string-matching bug nearly produced a silently wrong answer.** Stata expands `$` inside quoted strings as a macro reference, so an early version of the outcome construction compared against a mangled string and would have coded every respondent as unable to cover $2,000. The build now uses `char(36)` for the literal dollar sign and strips currency symbols before matching. Gate 2 catches the failure mode if it ever returns.

**The question we started with could not be asked.** We wanted to know whether an adult child at home costs parents money. That requires comparing parents whose children stayed with parents whose children left, and SHED does not identify the second group. The question was narrowed to coresidence before any model was run. This is described in the write-up rather than filed as a limitation, because it was a retreat rather than a caveat.
