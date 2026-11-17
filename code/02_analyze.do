*==============================================================================
* HFL PROJECT 02 -- 02_analyze.do
* Adult-child coresidence and emergency savings capacity among adults 50+
*
* Spec   : DESIGN.md Sec.5
* Inputs : analytic.dta          (primary, 50+)
*          analytic_allages.dta  (sensitivity S3)
* Outputs: stata_primary_results.csv
*          02_analyze_log.txt
*
* Runs ONLY what Sec.5 pre-specifies:
*   Model 1  unadjusted weighted difference in cap2k by coresidence
*   Model 2  survey-weighted logit, reported as average marginal effects
*   S1       substitute ppinc7 for I40
*   S2       exclude the 161 profile-inconsistent cases
*   S3       age cutoff at 45+, then unrestricted
*
* Nothing here is exploratory. Any additional model run against these data
* is not covered by the analysis plan (DESIGN.md) and must be labelled as such.
*
* Household Finance Lab
*==============================================================================

version 17
clear all
set more off

*------------------------------------------------------------------------------
* 0. Paths -- must match 01_build.do. Run from the repository root:
*      do code/02_analyze.do
*------------------------------------------------------------------------------
global REPO    "`c(pwd)'"
global OUT     "$REPO/data"
global LOGS    "$REPO/logs"
global RESULTS "$REPO/results"

capture confirm file "$REPO/code/02_analyze.do"
if _rc {
    display as error "Working directory is not the repository root."
    display as error "cd to the folder containing code/ and data/, then rerun."
    exit 601
}

cap mkdir "$LOGS"
cap mkdir "$RESULTS"
cap log close _all
log using "$LOGS/02_analyze_log.txt", replace text name(analyze)

* Covariate set, fixed by DESIGN.md Sec.4. Defined once so that
* Model 2 and every sensitivity use an identical adjustment set.
global XVARS "age i.gender i.race5 i.marital i.educ i.employ i.tenure"

*------------------------------------------------------------------------------
* Helper: capture the AME on coresidence from the last margins call and
* write one row to the results file.
*------------------------------------------------------------------------------
capture program drop postAME
program define postAME
    args handle label n
    tempname M
    matrix `M' = r(table)
    local k = colsof(`M')
    post `handle' ("`label'") (`M'[1,`k']*100) (`M'[2,`k']*100) ///
                  (`M'[5,`k']*100) (`M'[6,`k']*100) (`M'[4,`k']) (`n')
    di as res "  `label': " %6.2f `M'[1,`k']*100 " pp " ///
       "[" %6.2f `M'[5,`k']*100 ", " %6.2f `M'[6,`k']*100 "]"
end

tempname RES
postfile `RES' str32 model double(estimate_pp se_pp ci_low ci_high pvalue) ///
         long n using "$OUT/_results_tmp.dta", replace
*==============================================================================
* PART A -- PRIMARY ANALYSIS (analytic sample, 50+)
*==============================================================================
use "$OUT/analytic.dta", clear
svyset [pw=wt]

count
local N_primary = r(N)

di as txt _n "{hline 78}"
di as txt "SAMPLE DESCRIPTION (weighted), analytic sample n = `N_primary'"
di as txt "{hline 78}"

svy: mean age, over(coresident)
foreach v in gender race5 marital educ employ tenure income {
    svy: proportion `v', over(coresident)
}

*------------------------------------------------------------------------------
* MODEL 1 -- unadjusted
* The two weighted proportions, then the difference. The difference is taken
* from a survey-weighted linear probability model so that the confidence
* interval is the design-linearized interval on the percentage-point scale,
* not a naive two-proportion interval.
*------------------------------------------------------------------------------
di as txt _n "{hline 78}"
di as txt "MODEL 1 -- unadjusted weighted difference"
di as txt "{hline 78}"

svy: mean cap2k, over(coresident)

svy: regress cap2k i.coresident
margins, dydx(coresident)
postAME `RES' "M1_unadjusted" `N_primary'

*------------------------------------------------------------------------------
* MODEL 2 -- adjusted
* Survey-weighted logistic regression. Reported as average marginal effects on
* the percentage-point scale, averaged over the observed covariate
* distribution. Odds ratios are NOT reported and NOT compared across models:
* they are non-collapsible, so a change between Model 1 and Model 2 would
* confound adjustment with rescaling of the link function.
*------------------------------------------------------------------------------
di as txt _n "{hline 78}"
di as txt "MODEL 2 -- adjusted (primary result)"
di as txt "{hline 78}"

svy: logit cap2k i.coresident $XVARS i.income
estimates store M2

margins, dydx(coresident)
postAME `RES' "M2_adjusted" `N_primary'

* Adjusted predicted probabilities at each level of coresidence, for reporting.
margins coresident

*==============================================================================
* PART B -- PRE-SPECIFIED SENSITIVITY ANALYSES
*==============================================================================

*------------------------------------------------------------------------------
* S1 -- substitute ppinc7 (Ipsos profile household income) for I40
*       Tests whether the conclusion depends on the income construct. I40 is
*       respondent-and-partner income asked in the SHED interview; ppinc7 is a
*       profile variable on a separate refresh schedule.
*------------------------------------------------------------------------------
di as txt _n "{hline 78}"
di as txt "S1 -- ppinc7 substituted for I40"
di as txt "{hline 78}"

svy: logit cap2k i.coresident $XVARS i.income_pp
margins, dydx(coresident)
postAME `RES' "S1_ppinc7" `N_primary'

*------------------------------------------------------------------------------
* S2 -- exclude the 161 profile-inconsistent cases
*       Retained in the primary analysis per Sec.6; excluded here only.
*------------------------------------------------------------------------------
di as txt _n "{hline 78}"
di as txt "S2 -- excluding 161 profile-inconsistent cases"
di as txt "{hline 78}"

count if flag_profile == 0
local N_s2 = r(N)

svy: logit cap2k i.coresident $XVARS i.income if flag_profile == 0
margins, dydx(coresident)
postAME `RES' "S2_drop_flagged" `N_s2'

*------------------------------------------------------------------------------
* S3 -- age cutoff at 45+, then unrestricted
*       Uses the all-ages build. The estimand changes with the boundary; this
*       reports how much.
*------------------------------------------------------------------------------
use "$OUT/analytic_allages.dta", clear
svyset [pw=wt]

di as txt _n "{hline 78}"
di as txt "S3a -- age 45 and older"
di as txt "{hline 78}"

count if age >= 45
local N_s3a = r(N)

svy: logit cap2k i.coresident $XVARS i.income if age >= 45
margins, dydx(coresident)
postAME `RES' "S3a_age45plus" `N_s3a'

di as txt _n "{hline 78}"
di as txt "S3b -- unrestricted adult sample"
di as txt "{hline 78}"

count
local N_s3b = r(N)

svy: logit cap2k i.coresident $XVARS i.income
margins, dydx(coresident)
postAME `RES' "S3b_all_adults" `N_s3b'

*==============================================================================
* PART C -- RESULTS FILE
*==============================================================================
postclose `RES'

di as txt _n "{hline 78}"
di as txt "PRE-SPECIFIED RESULTS  (average marginal effect of coresidence,"
di as txt "                        percentage points, negative = lower capacity)"
di as txt "{hline 78}"

use "$OUT/_results_tmp.dta", clear
list model estimate_pp ci_low ci_high n, noobs sep(0) abbr(16)
export delimited using "$RESULTS/stata_primary_results.csv", replace
erase "$OUT/_results_tmp.dta"

*------------------------------------------------------------------------------
* Reporting reminders, DESIGN.md Sec.5 and Sec.10
*
*  - M2_adjusted is the inference layer's result. Report it with its CI
*    whatever its magnitude. No threshold defines "meaningful"; none was
*    pre-specified because none had a substantive basis.
*  - The research question is not reframed after seeing this estimate.
*  - Language stays associational throughout. SHED 2025 is cross-sectional
*    and cannot distinguish coresidence lowering resilience from low
*    resilience prompting an adult child to move home.
*  - Coresidence is described as an adult child living in the household,
*    never as supporting an adult child. Transfer direction is unobserved.
*  - Project 02's finding is the pair: this estimate together with the
*    prediction-layer result. Neither alone is the result.
*------------------------------------------------------------------------------

log close analyze
*==============================================================================
* END 02_analyze.do
*==============================================================================
