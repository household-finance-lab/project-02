# Codebook

Every variable used in Project 02, its source in the 2025 SHED public file, how it was derived, and how to rebuild it outside Stata.

Source file: `public2025.csv`, n = 12,934. Analytic sample: age 50+, n = 6,962.
Built by: `code/01_build.do`. Handoff file: `data/analytic_dataset.csv`.

---

## Identifier

| Variable | Type | Definition |
|---|---|---|
| `rid` | long | Row id, assigned as `_n` at import before anything reorders the data. Stable across the build. Not a SHED variable. |

---

## Outcome

### `cap2k` — could cover a $2,000 emergency expense from savings

**Source:** EF7 and EF7A, the two arms of the randomized `dov_ef7` split.
**Coding:** 1 = yes, 0 = no. Complete for all 12,934 (Gate 2).

The arms are disjoint (Gate 3: EF7 n = 6,453, EF7A n = 6,481, overlap 0). Their categories are identical below $2,000 and diverge only above it, so the threshold is common to both.

| Arm | Response | `cap2k` |
|---|---|---|
| EF7 | `$2,000 or more` | 1 |
| EF7 | any other non-missing category | 0 |
| EF7A | `$2,000 to $4,999` | 1 |
| EF7A | `$5,000 or more` | 1 |
| EF7A | any other non-missing category | 0 |

**Rebuilding elsewhere:** strip `$` and thousands separators from the raw strings before matching. In Stata specifically, use `char(36)` rather than a literal `$` inside a quoted string — `$` triggers macro expansion and silently mangles the comparison.

```python
# Python equivalent
def clean(s):
    return s.fillna("").str.replace("$", "", regex=False) \
            .str.replace(",", "", regex=False).str.strip()

ef7, ef7a = clean(df.ef7), clean(df.ef7a)
cap2k = pd.Series(pd.NA, index=df.index, dtype="Int64")
cap2k[ef7 != ""] = 0
cap2k[ef7 == "2000 or more"] = 1
cap2k[ef7a != ""] = 0
cap2k[ef7a.isin(["2000 to 4999", "5000 or more"])] = 1
```

---

## Exposure

### `coresident` — an adult child age 18+ lives in the household

**Source:** L0_c (`l0_c`).
**Coding:** 1 = Yes, 0 = No. No missing values.
**Full-file count:** 2,429 coresident (Gate 5). **Analytic sample:** 1,738 of 6,962 (Gate 4).

This records a living arrangement and nothing about financial transfers in either direction. It is never described as supporting an adult child.

---

## Covariates

All enter the models as factor variables, so internal numbering is immaterial. `encode` assigns categories alphabetically, which is acceptable for factors; income is the exception and is built in substantive order for legible `margins` output.

| Variable | SHED source | Type | Notes |
|---|---|---|---|
| `age` | `ppage` | continuous | `destring`, no missing. Analytic sample restricted to ≥ 50 |
| `gender` | `ppgender` | factor | encoded |
| `race5` | `race_5cat` | factor, 5 levels | encoded |
| `marital` | `ppmarit5` | factor, 5 levels | encoded |
| `educ` | `ppeduc5` | factor, 5 levels | encoded |
| `employ` | `ppemploy` | factor | encoded |
| `tenure` | `gh1` | factor | housing tenure, asked in the SHED interview |
| `income` | `i40` | factor, 15 levels | respondent + spouse/partner income. See below |
| `income_pp` | `ppinc7` | factor, 7 levels | Ipsos profile household income. **Used only in sensitivity S1** |

All model variables are complete in the analytic sample (Gate 8).

### `income` — respondent and spouse/partner income (I40)

Built in ascending bracket order, treated as categorical. Any unmapped category aborts the build rather than becoming missing.

| Code | Label | Raw string (cleaned) |
|---|---|---|
| 1 | <5k | `Less than 5000` |
| 2 | 5–10k | `5000 to 9999` |
| 3 | 10–15k | `10000 to 14999` |
| 4 | 15–20k | `15000 to 19999` |
| 5 | 20–25k | `20000 to 24999` |
| 6 | 25–30k | `25000 to 29999` |
| 7 | 30–35k | `30000 to 34999` |
| 8 | 35–40k | `35000 to 39999` |
| 9 | 40–50k | `40000 to 49999` |
| 10 | 50–60k | `50000 to 59999` |
| 11 | 60–75k | `60000 to 74999` |
| 12 | 75–100k | `75000 to 99999` |
| 13 | 100–150k | `100000 to 149999` |
| 14 | 150–200k | `150000 to 199999` |
| 15 | 200k+ | `200000 or more` |

`income` and `income_pp` are different constructs collected by different means at different times, with different bracket counts. Substituting one for the other moves the estimate from −5.11 to −7.82 pp. See `ANALYTICAL-DECISIONS.md` §4 for what that does and does not establish.

---

## Design and household variables

| Variable | SHED source | Notes |
|---|---|---|
| `wt` | `weight` | SHED post-stratification weight. All positive, no missing. Applied via `svyset [pw=wt]` in Stata and as `sample_weight` in the Python metrics |
| `adults` | `ppt18ov` | Adults 18+ in household, Ipsos profile |
| `hhsize` | `pphhsize` | Household size, Ipsos profile |
| `dov_ef7` | `dov_ef7` | Randomization indicator for the EF7/EF7A split. Retained for audit; not a model variable |

The public use file releases weights but **not** strata or PSU identifiers, so the design specification is weights only.

### `flag_profile` — profile inconsistency

1 where `coresident == 1` and `adults == 1`: the respondent reported an adult child in the household while the profile variable reports a single adult. 161 cases in the analytic sample (Gate 7).

These are **retained** in the primary analysis. L0_c is contemporaneous and authoritative; `ppt18ov` is refreshed on a separate schedule. Excluding them is sensitivity S2.

---

## Cross-validation folds

`fold_r1` … `fold_r5`, values 1–5.

Assigned in Stata and written into the Python input file. **The Python layer must never regenerate them** — the base and augmented models must see identical splits or the AUC increment absorbs fold noise.

- Repeated 5-fold, 5 repeats, seeds 202502, 202503, 202504, 202505, 202506
- Stratified on the four cells of `cap2k` × `coresident`
- Data sorted on `rid` before each draw, so assignment is deterministic given the seed
- Gate 9 asserts every stratum is spread across the five folds within ±1

---

## Handoff file

`data/analytic_dataset.csv` — the analytic sample with value labels written as strings, so categories arrive readable and the Python layer performs one-hot encoding inside each training fold rather than on the full sample.

Columns, in order: `rid`, `cap2k`, `coresident`, `age`, `gender`, `race5`, `marital`, `educ`, `employ`, `tenure`, `income`, `wt`, `fold_r1`–`fold_r5`, `income_pp`, `flag_profile`, `adults`, `hhsize`, `dov_ef7`.

---

## Validation gates

`01_build.do` aborts on any failure.

| Gate | Asserts |
|---|---|
| 1 | Raw file n = 12,934 |
| 2 | `cap2k` complete, no missing |
| 3 | EF7 = 6,453, EF7A = 6,481, overlap = 0, sum = 12,934 |
| 4 | Analytic n = 6,962 (5,224 without, 1,738 with) |
| 5 | `coresident == 1` on the full file = 2,429 |
| 6 | Weighted `cap2k` reproduces 64.7% and 51.6% within 0.1pp |
| 7 | `flag_profile` = 161 |
| 8 | No missing values in any model variable |
| 9 | Every `cap2k` × `coresident` stratum spread across five folds within ±1 |
