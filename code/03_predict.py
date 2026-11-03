#!/usr/bin/env python3
"""
HFL PROJECT 02 -- 03_predict.py
Adult-child coresidence and emergency savings capacity among adults 50+

Spec    : DESIGN.md Sec.9
Input   : analytic_dataset.csv   (written by code/01_build.do, n = 6,962)
Outputs : python_prediction_results.csv    per-repeat metrics, both models
          python_fold_deltas.csv           25 fold-level deltas (stability)
          03_predict_log.txt

Question
--------
Does adding adult-child coresidence improve out-of-sample prediction of the
ability to cover a $2,000 emergency expense?

This is NOT the inference layer's question. Stata estimates how much the
probability shifts on average between groups. This asks whether the variable
carries information a model does not already hold. The two can diverge, and
the divergence is the point.

Frozen design (DESIGN.md Sec.9) -- do not vary any of it:
  Base model       covariates excluding coresidence
  Augmented model  same predictors + coresidence
  Primary model    L2-regularised logistic regression, lbfgs, max_iter=5000
  Secondary model  GradientBoostingClassifier, fixed and untuned
  Outer CV         repeated 5-fold, 5 repeats, folds supplied by Stata
  Penalty tuning   nested 5-fold inner CV, 21 log-spaced C in [1e-4, 1e4],
                   minimising unweighted log loss, tuned SEPARATELY for base
                   and augmented within every outer training fold
  Preprocessing    fitted on training observations only, at both CV levels
  Weighting        fit unweighted; evaluate with SHED weight
  Primary metric   weighted AUC
  Secondary        weighted Brier, weighted calibration slope and intercept
  Aggregation      metrics computed ONCE PER REPEAT over that repeat's complete
                   out-of-fold predictions, then averaged across the 5 repeats.
                   NOT pooled across repeats.

Direction of increment
----------------------
No improvement is assumed. Adding coresidence may improve, leave unchanged, or
worsen out-of-sample performance. A negative delta is a substantive result, not
a bug and not grounds for changing anything above.

Household Finance Lab
"""

import sys
import logging
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import GridSearchCV, StratifiedKFold
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

# ---------------------------------------------------------------------------
# Paths -- repository-relative; resolve from this file's own location, so
# `python code/03_predict.py` and `cd code && python 03_predict.py` both work.
# ---------------------------------------------------------------------------
REPO = Path(__file__).resolve().parent.parent
INDIR = REPO / "data"
OUTDIR = REPO / "output"
LOGDIR = REPO / "logs"
for _d in (OUTDIR, LOGDIR):
    _d.mkdir(parents=True, exist_ok=True)

DATA = INDIR / "analytic_dataset.csv"
if not DATA.exists():
    raise SystemExit(
        f"Analytic dataset not found at {DATA}.\n"
        "Run the Stata build first, from the repository root:\n"
        "    do code/01_build.do\n"
        "See data/README.md for how to obtain the SHED public file."
    )

# ---------------------------------------------------------------------------
# Frozen constants
# ---------------------------------------------------------------------------
REPEATS = [1, 2, 3, 4, 5]
SEEDS = {1: 202502, 2: 202503, 3: 202504, 4: 202505, 5: 202506}

OUTCOME = "cap2k"
EXPOSURE = "coresident"
WEIGHT = "wt"

NUMERIC = ["age"]
CATEGORICAL = ["gender", "race5", "marital", "educ", "employ", "tenure", "income"]

C_GRID = np.logspace(-4, 4, 21)
INNER_FOLDS = 5

GB_PARAMS = dict(
    n_estimators=200,
    learning_rate=0.05,
    max_depth=2,
    min_samples_leaf=20,
    subsample=1.0,
)

# Clip bound for logits in the calibration regressions. Numerical housekeeping,
# not an analytical choice: predicted probabilities of exactly 0 or 1 would
# produce infinite logits.
EPS = 1e-6

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[
        logging.FileHandler(LOGDIR / "03_predict_log.txt", mode="w"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------
def weighted_brier(y, p, w):
    """Weighted Brier score. Lower is better."""
    return float(np.average((p - y) ** 2, weights=w))


def calibration_slope_intercept(y, p, w):
    """
    Weighted calibration slope and intercept (Cox calibration).

    Slope     : coefficient from a weighted logistic regression of the outcome
                on the logit of the predicted probability. 1.0 is ideal;
                below 1 indicates predictions that are too extreme.
    Intercept : from a second weighted logistic regression with that logit
                entered as an offset, so the slope is held at 1. 0.0 is ideal;
                positive means predictions are systematically too low.

    Fitted with statsmodels because scikit-learn's LogisticRegression has no
    offset and always regularises.
    """
    import statsmodels.api as sm

    p = np.clip(p, EPS, 1.0 - EPS)
    lp = np.log(p / (1.0 - p))

    X = sm.add_constant(lp)
    slope_fit = sm.GLM(y, X, family=sm.families.Binomial(), freq_weights=w).fit()
    slope = float(slope_fit.params[1])

    ones = np.ones((len(y), 1))
    int_fit = sm.GLM(
        y, ones, family=sm.families.Binomial(), freq_weights=w, offset=lp
    ).fit()
    intercept = float(int_fit.params[0])

    return slope, intercept


def all_metrics(y, p, w):
    slope, intercept = calibration_slope_intercept(y, p, w)
    return {
        "auc": float(roc_auc_score(y, p, sample_weight=w)),
        "brier": weighted_brier(y, p, w),
        "cal_slope": slope,
        "cal_intercept": intercept,
    }


# ---------------------------------------------------------------------------
# Model construction
# ---------------------------------------------------------------------------
def make_preprocessor(numeric, categorical):
    """
    Standardise continuous predictors, one-hot encode categoricals.

    Wrapped in a Pipeline so every parameter is fitted on the training split
    only and applied unchanged to held-out data, at both outer and inner CV
    levels. Nothing is fitted on the full analytic dataset.
    """
    return ColumnTransformer(
        [
            ("num", StandardScaler(), numeric),
            (
                "cat",
                OneHotEncoder(drop="first", handle_unknown="ignore",
                              sparse_output=False),
                categorical,
            ),
        ],
        remainder="drop",
    )


def fit_logit(X_tr, y_tr, numeric, categorical, seed):
    """
    L2 logistic regression with C selected by nested 5-fold CV on the training
    partition, minimising unweighted log loss over the frozen grid.

    Tuning is unweighted and selects on log loss while the headline metric is
    weighted AUC. That mismatch is deliberate and recorded in Sec.9: tuning
    seeks good probability estimates, the reported comparison concerns
    discrimination.
    """
    pipe = Pipeline(
        [
            ("prep", make_preprocessor(numeric, categorical)),
            ("clf", LogisticRegression(penalty="l2", solver="lbfgs",
                                       max_iter=5000)),
        ]
    )
    inner = StratifiedKFold(n_splits=INNER_FOLDS, shuffle=True,
                            random_state=seed)
    search = GridSearchCV(
        pipe,
        {"clf__C": C_GRID},
        scoring="neg_log_loss",
        cv=inner,
        n_jobs=-1,
        refit=True,
    )
    search.fit(X_tr, y_tr)
    return search.best_estimator_, float(search.best_params_["clf__C"])


def fit_gb(X_tr, y_tr, numeric, categorical, seed):
    """Fixed, untuned gradient boosting. No hyperparameter search."""
    pipe = Pipeline(
        [
            ("prep", make_preprocessor(numeric, categorical)),
            ("clf", GradientBoostingClassifier(random_state=seed, **GB_PARAMS)),
        ]
    )
    pipe.fit(X_tr, y_tr)
    return pipe


# ---------------------------------------------------------------------------
# Cross-validation
# ---------------------------------------------------------------------------
def run_repeat(df, repeat, model_kind, include_exposure):
    """
    One repeat: fit on four folds, predict the fifth, until every observation
    has exactly one out-of-fold prediction. Returns those predictions plus the
    per-fold metrics used only as a stability diagnostic.

    Folds come from the Stata build. They are NOT regenerated here -- base and
    augmented models must see identical partitions, and the stratification on
    cap2k x coresident was verified by Gate 9 of 01_build.do.
    """
    fold_col = f"fold_r{repeat}"
    seed = SEEDS[repeat]

    categorical = list(CATEGORICAL) + ([EXPOSURE] if include_exposure else [])
    features = list(NUMERIC) + categorical

    oof = np.full(len(df), np.nan)
    per_fold = []

    for f in sorted(df[fold_col].unique()):
        te = df[fold_col] == f
        tr = ~te

        X_tr, y_tr = df.loc[tr, features], df.loc[tr, OUTCOME].values
        X_te, y_te = df.loc[te, features], df.loc[te, OUTCOME].values
        w_te = df.loc[te, WEIGHT].values

        if model_kind == "logit":
            model, chosen_C = fit_logit(X_tr, y_tr, NUMERIC, categorical, seed)
        else:
            model = fit_gb(X_tr, y_tr, NUMERIC, categorical, seed)
            chosen_C = np.nan

        p_te = model.predict_proba(X_te)[:, 1]
        oof[te.values] = p_te

        m = all_metrics(y_te, p_te, w_te)
        m.update(repeat=repeat, fold=int(f), C=chosen_C, n_test=int(te.sum()))
        per_fold.append(m)

    assert not np.isnan(oof).any(), "Some observations received no prediction"
    return oof, per_fold


def run_model(df, model_kind, include_exposure, label):
    """All five repeats. Metrics are computed once per repeat, never pooled."""
    log.info("  %s ...", label)

    repeat_rows, fold_rows = [], []
    y = df[OUTCOME].values
    w = df[WEIGHT].values

    for r in REPEATS:
        oof, per_fold = run_repeat(df, r, model_kind, include_exposure)

        # One complete out-of-fold prediction vector per repeat -> one metric.
        # Pooling across repeats would compare an observation's prediction from
        # one partition against another's from a different partition.
        m = all_metrics(y, oof, w)
        m.update(repeat=r, model=model_kind, arm=label)
        repeat_rows.append(m)
        fold_rows.extend([dict(f, model=model_kind, arm=label) for f in per_fold])

        log.info("    repeat %d  AUC %.4f  Brier %.4f  slope %.3f  int %+.3f",
                 r, m["auc"], m["brier"], m["cal_slope"], m["cal_intercept"])

    return pd.DataFrame(repeat_rows), pd.DataFrame(fold_rows)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    log.info("=" * 74)
    log.info("HFL PROJECT 02 -- PREDICTION LAYER")
    log.info("=" * 74)

    df = pd.read_csv(DATA)

    # Sanity checks against the input file. These mirror 01_build.do's gates: if
    # the file is not the one the Stata layer produced, stop rather than model.
    assert len(df) == 6962, f"Expected 6,962 rows, got {len(df):,}"
    for c in [OUTCOME, EXPOSURE, WEIGHT] + NUMERIC + CATEGORICAL:
        assert c in df.columns, f"Missing column: {c}"
    for r in REPEATS:
        assert f"fold_r{r}" in df.columns, f"Missing fold_r{r}"

    # Stata exported value labels, so binary variables arrive as Yes/No.
    for c in (OUTCOME, EXPOSURE):
        if df[c].dtype == object:
            df[c] = (df[c].astype(str).str.strip().str.lower() == "yes").astype(int)
    for c in CATEGORICAL:
        df[c] = df[c].astype(str)

    assert df[[OUTCOME, EXPOSURE, WEIGHT] + NUMERIC].notna().all().all()

    log.info("n = %d   outcome mean (unweighted) = %.4f   exposure = %d",
             len(df), df[OUTCOME].mean(), int(df[EXPOSURE].sum()))
    log.info("")

    all_repeats, all_folds = [], []

    for kind, kind_label in [("logit", "L2 logistic (primary)"),
                             ("gb", "gradient boosting (secondary)")]:
        log.info("%s", kind_label)
        for include, arm in [(False, "base"), (True, "augmented")]:
            rep, fold = run_model(df, kind, include, arm)
            all_repeats.append(rep)
            all_folds.append(fold)
        log.info("")

    repeats = pd.concat(all_repeats, ignore_index=True)
    folds = pd.concat(all_folds, ignore_index=True)

    # -----------------------------------------------------------------------
    # Increment: augmented minus base, paired within repeat.
    # -----------------------------------------------------------------------
    log.info("=" * 74)
    log.info("INCREMENT FROM ADDING CORESIDENCE  (augmented - base)")
    log.info("=" * 74)

    metrics = ["auc", "brier", "cal_slope", "cal_intercept"]
    wide = repeats.pivot_table(index=["model", "repeat"], columns="arm",
                               values=metrics)

    increments = []
    for kind in ["logit", "gb"]:
        sub = wide.loc[kind]
        row = {"model": kind}
        for m in metrics:
            d = sub[(m, "augmented")] - sub[(m, "base")]
            row[f"{m}_base"] = sub[(m, "base")].mean()
            row[f"{m}_augmented"] = sub[(m, "augmented")].mean()
            row[f"{m}_delta"] = d.mean()
            row[f"{m}_delta_min"] = d.min()
            row[f"{m}_delta_max"] = d.max()
        increments.append(row)

        log.info("")
        log.info("%s", "L2 logistic (primary)" if kind == "logit"
                 else "gradient boosting (secondary)")
        log.info("  weighted AUC   base %.4f   augmented %.4f   delta %+.5f",
                 row["auc_base"], row["auc_augmented"], row["auc_delta"])
        log.info("                 delta across repeats: %+.5f to %+.5f",
                 row["auc_delta_min"], row["auc_delta_max"])
        log.info("  weighted Brier base %.4f   augmented %.4f   delta %+.5f",
                 row["brier_base"], row["brier_augmented"], row["brier_delta"])
        log.info("  cal. slope     base %.3f    augmented %.3f    delta %+.4f",
                 row["cal_slope_base"], row["cal_slope_augmented"],
                 row["cal_slope_delta"])
        log.info("  cal. intercept base %+.3f   augmented %+.3f   delta %+.4f",
                 row["cal_intercept_base"], row["cal_intercept_augmented"],
                 row["cal_intercept_delta"])

    increments = pd.DataFrame(increments)

    # -----------------------------------------------------------------------
    # Outputs
    # -----------------------------------------------------------------------
    repeats.to_csv(OUTDIR / "python_prediction_results.csv", index=False)
    increments.to_csv(OUTDIR / "python_increment_summary.csv", index=False)
    folds.to_csv(OUTDIR / "python_fold_deltas.csv", index=False)

    log.info("")
    log.info("=" * 74)
    log.info("Written to %s", OUTDIR)
    log.info("  python_prediction_results.csv   per-repeat metrics, both arms")
    log.info("  python_increment_summary.csv    increments and their range")
    log.info("  python_fold_deltas.csv          fold-level, stability only")
    log.info("=" * 74)
    log.info("")
    log.info("Reading these numbers (DESIGN.md Sec.9):")
    log.info("  - The five repeat-level values are the headline. The 25")
    log.info("    fold-level values show stability across partitions.")
    log.info("  - Neither set is independent: training sets overlap across")
    log.info("    folds and observations recur across repeats. Report")
    log.info("    magnitude and spread. Attach no p-value to the increment.")
    log.info("  - A negative AUC delta is a substantive result. Do not")
    log.info("    retune, reseed, or refit in response to one.")
    log.info("  - Project 02's finding is this together with the Stata")
    log.info("    adjusted AME. Neither alone is the result.")


if __name__ == "__main__":
    main()
