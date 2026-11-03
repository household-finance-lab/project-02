# Literature

What was already known before this study, who established it, on what data, and what it leaves open.

---

## 1. The constraining study

**Maroto, M. (2017). When the kids live at home: Coresidence, parental assets, and economic insecurity. *Journal of Marriage and Family*, 79(4), 1041–1059. https://doi.org/10.1111/jomf.12407**

NLSY79, 1994–2012. 16,108 person-years across 4,671 individuals. Hybrid mixed-effects models partitioning between- and within-person variation. In years when an adult child lived at home, parents held 24% less in financial assets and 23% less in savings than in years when no adult child was present.

This is the study our inference layer is positioned against, not merely cited alongside. Maroto's longitudinal within-person design addresses an important class of confounding that a cross-section cannot, particularly stable differences between parents who do and do not coreside.

Leaves open: the outcome is an asset and savings *level*, not a threshold. Whether a household can absorb a specific $2,000 shock is a different construct from how much it holds. The NLSY79 cohort was roughly 48–55 by 2012, so the sample ends near where ours begins. The data close in 2012, before the housing-cost cycle that reshaped the economics of leaving home.

**Maroto, M. (2019). Sharing or limiting the wealth? Coresidence, parental support, and wealth outcomes in Canada. *Journal of Family and Economic Issues*, 40(1), 102–116. https://doi.org/10.1007/s10834-018-9588-1**

Canadian Survey of Financial Security, 1999–2012. Coresidence and parental support for adult children were negatively associated with non-home assets and positively associated with debt.

Extends the finding beyond the United States and beyond a single dataset. Together with Maroto (2017), this establishes that an association between coresidence and diminished parental financial resources is documented across two countries and two instruments.

## 2. Who coresides, and why

**Kahn, J. R., Goldscheider, F., & García-Manglano, J. (2013). Growing parental economic power in parent–adult child households: Coresidence and financial dependency in the United States, 1960–2010. *Demography*, 50(4), 1449–1475.**

U.S. census and ACS, 1960–2010. Argues against the assumption that older adults are the primary economic beneficiaries of intergenerational households, showing that such households generally benefit younger adults more, against a backdrop of strengthening finances among older adults and increasing strain among younger ones. Their results show an increasing importance of younger adults' financial needs in shaping intergenerational coresidence.

This is why "adult child living in the household" cannot be read as "parent receiving care," and why our framing rule forbids describing coresidence as supporting an adult child.

**Eickmeyer, K. J., & Brown, S. L. (2019). Coresidence among older adults and their adult children. NCFMR Family Profile FP-19-19, Bowling Green State University.** *(A research brief, not a peer-reviewed article.)*

CPS ASEC, 1988–2018. Scope is parents age 60+ and adult children age 40+, not adult-child coresidence generally. In 2018, 7.6% of these older adults lived with a midlife adult child. Coresiding parents had personal income of $25,880 against $43,605 for noncoresiding parents, while household income was higher among coresiding parents.

Descriptive, and consistent with two readings at once: selection, in that parents with lower personal resources are more likely to coreside, and resource pooling, in that the coresident child brings income into the household. Neither is established by the comparison, and both remain live.

## 3. Coresidence and parental wellbeing

**Caputo, J. (2019). Crowded nests: Parent–adult child coresidence transitions and parental mental health following the Great Recession. *Journal of Health and Social Behavior*, 60(2), 204–221. https://doi.org/10.1177/0022146519849113**

HRS 2008–2012, N = 11,277, U.S. adults age 50+. Distinguishes parents stably living with and without adult children from those transitioning into or out of coresidence. Parents with a newly coresidential adult child showed increased depressive symptoms relative to peers without one; transitions involving out-of-work children were especially associated with increased depression.

The state-versus-transition distinction is the methodological point we borrow, and the sample is the same age range as ours. SHED 2025 observes current status only, so a household two months into the arrangement is indistinguishable from one twelve years in. If any association is concentrated among recent transitions, a cross-sectional estimate averages over two different situations.

**Caputo, J., & Cagney, K. A. (2023). Under different roofs? Coresidence with adult children and parents' mental health across race and ethnicity over two decades. *Demography*, 60(2), 461–492. https://doi.org/10.1215/00703370-10571923**

HRS 1998–2018. Predictors of coresidence shifted over the period and varied by parents' age group and race and ethnicity. Black and Hispanic parents were more likely than White parents to live with adult children, and more likely to report helping those children with household finances or functional limitations. Living with adult children was associated with higher depressive symptoms among White parents.

Emphasizes heterogeneity in why families coreside and how that relates to outcomes. Supports treating coresidence as a category containing several distinct arrangements rather than one condition.

## 4. Explanation and prediction

**Shmueli, G. (2010). To explain or to predict? *Statistical Science*, 25(3), 289–310. https://doi.org/10.1214/10-STS330**

Explanatory and predictive modeling answer different questions, and strong explanatory performance does not imply strong predictive performance.

This is the methodological frame for why Project 02 contains both an inference layer and a prediction layer, not a substantive theory of coresidence. It is the reason the two layers were designed to ask different questions rather than the same question twice.

Leaves open: Shmueli argues the distinction in general and supplies no applied case in household finance where a variable is retained in explanation and near-useless in prediction.

**Cook, N. R. (2007). Use and misuse of the receiver operating characteristic curve in risk prediction. *Circulation*, 115(7), 928–935. https://doi.org/10.1161/CIRCULATIONAHA.106.672402**

The c-statistic, imported into risk prediction from diagnostic testing, can move very little when an informative predictor is added, while calibration and risk reclassification may still shift.

Cook shows why a small change in AUC can coexist with a real and potentially important association, particularly when the base model already discriminates well. This citation constrains the reading of our prediction result in both directions: it explains why a negligible AUC increment is unsurprising, and it forbids treating that increment as evidence that coresidence lacks substantive association.

## 5. What we claim, and what we do not

We do not claim:

- **to have discovered that adult-child coresidence is associated with lower parental financial resources** — Maroto (2017, 2019), across two countries, with longitudinal designs better suited to the question than ours
- **to have established the direction of the relationship** — our data are cross-sectional and cannot distinguish coresidence reducing resilience, low resilience prompting a child to move home, or a common cause
- **to have identified a mechanism** — resource constraint, selection, and resource pooling are each consistent with what we observe, and SHED records no transfers within the household in either direction
- **that coresidence measures financial support of an adult child** — the instrument records the living arrangement and nothing about who supports whom
- **that a small AUC increment means coresidence does not matter** — Cook (2007) is explicit that it does not license that reading
- **to have discovered the explanation–prediction distinction** — Shmueli (2010)

What appears to remain open:

- **Incremental predictive value.** We did not locate a study asking whether knowing about a coresident adult child improves out-of-sample identification of which household can absorb a financial shock. The coresidence literature we found is explanatory throughout: associations, mechanisms, transitions, subgroup differences. Whether the variable is *useful* for classifying individual households has not been posed as a question.
- **A threshold outcome.** Existing work measures asset, savings, and wealth levels. Capacity to cover a specific $2,000 expense is a resilience threshold, and a household can hold modest assets and clear it or hold substantial illiquid assets and not.
- **An older sample on current data.** Adults 50 and older in 2025, where the stake is decumulation rather than accumulation.
- **Both layers on the same sample.** The divergence between a robust adjusted association and a negligible predictive increment is visible only when both are estimated on the same data with the same folds. We did not find a household-finance study that does this.
- **Federal Reserve SHED analysis.** The Fed publishes emergency-savings results by age and by presence of minor children. We did not locate a published Fed analysis crossing adult-child coresidence with emergency savings. Absence of a located analysis is not evidence that none exists.
- **Reproducible code.** None of the studies above ship runnable code. This repository does.

The project's distinctive contribution lies primarily in the prediction layer, while the inference layer provides a contemporary extension of prior coresidence research to emergency savings capacity among adults 50 and older.

---

## Contributing

If we have mischaracterized a study, missed one that occupies this ground, or overstated what remains open, open an Issue or email householdfinancelab@gmail.com. That is a correction we want.
