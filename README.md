# The Five-Point Difference

**Household Finance Lab · Project 2 · 2025 Survey of Household Economics and Decisionmaking**

Among adults 50 and older, does living with an adult child go with less ability to cover a $2,000 emergency from savings?

Yes, by about **5 percentage points**, after accounting for income, education, housing, and other differences (95% CI: 2.7 to 7.5). But knowing whether an adult child lives at home barely helps predict which household can cover the expense. The pair is the finding. Standard errors and confidence intervals are approximate: the public SHED file lacks the strata, PSU, and replicate weights needed to represent the original sampling design fully.

**What it does not show:** that an adult child moving home *causes* lower savings capacity (lower resources may draw a child home), or that the child is being supported (the survey doesn't observe money moving within the household).

📖 [**Read the story**](docs/empirically-yours-02-the-five-point-difference.md) (Empirically Yours №2) · 🔁 [**Reproduce it**](#reproduce-it) · 📎 [**Cite it**](CITATION.cff)

> **Research status:** observational analysis with a documented analysis plan. The unadjusted association and selected descriptive checks were examined during design; the adjusted and predictive analyses were specified before those results were examined. **Not peer reviewed.**

---

## Methodological lesson

**Association and incremental prediction answer different questions.** The adjusted difference asks how much the average probability shifts between groups. The prediction test asks whether the variable adds information a model does not already hold. When the base model already discriminates well (AUC .84 here), a variable with a clear association can barely move AUC (Cook, 2007). A small AUC increment is not evidence that the association is unimportant, and a robust association is not evidence that the variable is useful for classifying individual households.

## What this study supports

- **A clear group difference.** Adults 50+ living with an adult child were 13.1 points less likely to be able to cover $2,000 unadjusted, and **5.1 points** less likely after adjustment (6,962 adults). The gap held at age 45+, across all adults, and after removing 161 records with inconsistent household information.
- **Almost no help predicting individuals.** Adding adult-child coresidence changed weighted out-of-sample AUC from .8414 to .8425, an increment of about .001 (.0009 to .0012 across the five repeats), indicating very little additional discrimination. A second model (gradient boosting) showed an even smaller gain.
- **Both are true.** A difference can be real across a group and barely useful for predicting the person.

## What changed along the way

- **The size of the gap depends on how income is measured.** Swapping in a different income measure moved the gap from 5.1 to 7.8 points. The two measures differ in concept, timing, and detail at once, so we can say the result held under both, and not why its size moved.
- **The question we couldn't ask.** We wanted to know whether adult children living at home cost their parents something. The comparison group ("no adult child at home") mixes parents whose children live elsewhere, people who never had children, and parents of minors, so the survey can't answer that. We narrowed the question rather than stretch the data.
- **A validation check caught a silent coding error.** An early version of the build would have coded every respondent as unable to cover $2,000. A built-in check stopped the run before any model used it.

## What's here

| File | What it is |
|---|---|
| [`DESIGN.md`](DESIGN.md) | The analysis plan: question, hypothesis, variables, methods, limitations |
| [`ANALYTICAL-DECISIONS.md`](ANALYTICAL-DECISIONS.md) | Every judgment call, the alternative, and whether the number moved |
| [`CODEBOOK.md`](CODEBOOK.md) | Every variable: source, coding, how to rebuild it |
| [`LITERATURE.md`](LITERATURE.md) | Who established what before us, and what remains open |
| [`data/README.md`](data/README.md) | Where to get the data, and how to confirm you have the same file |
| `code/` | Stata build and analysis; Python prediction |
| `output/` | Result tables |
| `tools/` | An automatic check, run on every update, for personal file paths, data files, and broken links |

## Reproduce it

**Data** (free, no registration): the 2025 SHED public use file from the [Federal Reserve](https://www.federalreserve.gov/consumerscommunities/shed_data.htm). Save it as `data/public2025.csv`. No survey data are redistributed here. [`data/README.md`](data/README.md) gives the file's checksum.

**Software:** Stata 17 or later. Python 3.10+: `pip install -r requirements.txt`.

**Run order,** from the repository folder:

```
do code/01_build.do         # import, construct, validate, assign folds   (~1 min)
do code/02_analyze.do       # all models and sensitivity checks            (~1 min)
python code/03_predict.py   # repeated cross-validation                    (~10 min)
```

**How you know it worked:** `01_build.do` checks nine expected values and stops if any fail. It ends with `GATE 9 PASS` after reproducing the weighted shares able to cover $2,000: 64.7% without an adult child at home, 51.6% with one. A second run of the Python layer matched our results to eight decimal places.

## Authors

- **Lena Gan, PhD, CFP®, CIMA®**: research design, Stata inference, interpretation
- **Sara Kay** ([sarakay.me](https://sarakay.me)): prediction layer (Python), reproducibility

Analysis was assisted by Claude (Anthropic). All code was run, and all results verified, by the authors.

## Tell us we're wrong

Open an Issue or email householdfinancelab@gmail.com. Corrections, failed reproductions, and "you've mischaracterized my paper" messages are all welcome.

## Using this work

Code: MIT. Writing and documentation: CC BY 4.0. See [`LICENSE`](LICENSE). The SHED belongs to the Board of Governors of the Federal Reserve System.
