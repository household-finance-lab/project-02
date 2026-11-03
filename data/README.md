# Data

The respondent-level data used in this project are **not included in this repository**.

This directory explains where to obtain the source data, what the build script expects, what it produces locally, and how to check that you have reproduced it.

## Why the data are not here

The SHED public use file is distributed free by the Federal Reserve. Free to download is not the same as licensed for redistribution, so we point to the source rather than republishing a copy.

More importantly: a reader who downloads the Federal Reserve's file and runs our build script has reproduced the chain. A reader who runs our analysis against a dataset we prepared has only re-run our last step.

## Source data

**2025 Survey of Household Economics and Decisionmaking (SHED)**, public use file.

- Full sample: **12,934 respondents**
- Analytic sample: **6,962** (age 50+), of whom **1,738** live with an adult child

**Where to get it:** the Federal Reserve, https://www.federalreserve.gov/consumerscommunities/shed_data.htm — free, no registration. Download the 2025 public use file in CSV format.

## Expected local file

`code/01_build.do` expects:

```text
data/
└── public2025.csv
```

All paths are repository-relative. Run the Stata scripts from the repository root (`cd` to the folder containing `code/` and `data/`); they stop with an error if you don't. The Python script finds its paths from its own location, so it runs from anywhere. No path needs editing unless your data live outside `data/`, in which case change `RAW` at the top of `code/01_build.do`.

## What the build produces

`code/01_build.do` writes these files locally. All are ignored by `.gitignore` and none belongs in version control.

| File | Contents |
|---|---|
| `analytic.dta` | Analytic sample, adults 50+ (n = 6,962); input to `02_analyze.do` |
| `analytic_allages.dta` | All adults (n = 12,934); input to sensitivity S3 in `02_analyze.do` |
| `analytic_dataset.csv` | Input to the Python prediction layer (`03_predict.py`) |

## Verifying your build

The build stops on its own if the reconstruction drifts. Expected values are asserted in code, so a mismatch halts the run. Watch for these in the log:

- Raw n: **12,934**
- EF7 arm **6,453**, EF7A arm **6,481**, no overlap
- Coresident adult child on the full file: **2,429**
- Analytic n: **6,962** (5,224 without a coresident adult child, 1,738 with)
- Profile-inconsistent cases: **161**
- Weighted capacity to cover $2,000: **64.7%** (no coresident adult child) and **51.6%** (coresident adult child)

A successful build prints `GATE 9 PASS`. If it does, your build matches ours.

To confirm you have the same source file we used, compare checksums:

```bash
shasum -a 256 public2025.csv
```

```text
c728d566008309c9abd87a026069ee70c2b58e7aef2d5c701884d371101d2a97  public2025.csv
```

## Questions

Open an Issue, or email householdfinancelab@gmail.com.
