*==============================================================================
* HFL PROJECT 02 -- 01_build.do
* Adult-child coresidence and emergency savings capacity among adults 50+
*
* Data   : SHED 2025 public file (public2025.csv, n = 12,934)
* Spec   : DESIGN.md
* Inputs : public2025.csv
* Outputs: analytic.dta          (for 02_analyze.do)
*          analytic_dataset.csv  (input to code/03_predict.py)
*          01_build_log.txt
*
* Builds the analytic sample, constructs cap2k, assigns cross-validation
* folds, and enforces the nine validation gates in DESIGN.md
* Sec.8. Any gate failure aborts the build.
*
* Household Finance Lab
*==============================================================================

version 17
clear all
set more off

*------------------------------------------------------------------------------
* 0. Paths
*
*  Run this file from the repository root, e.g.
*      cd "/path/to/project-02"
*      do code/01_build.do
*
*  RAW is where you placed public2025.csv (see data/README.md).
*  OUT is where built datasets are written; LOGS is where the log goes.
*  All default to repository-relative locations; override them only if
*  your data live elsewhere.
*------------------------------------------------------------------------------
global REPO "`c(pwd)'"
global RAW  "$REPO/data"
global OUT  "$REPO/data"
global LOGS "$REPO/logs"

* Fail early and loudly if the working directory is not the repository root.
capture confirm file "$REPO/code/01_build.do"
if _rc {
    display as error "Working directory is not the repository root."
    display as error "cd to the folder containing code/ and data/, then rerun."
    exit 601
}

cap mkdir "$OUT"
cap mkdir "$LOGS"
cap log close _all
log using "$LOGS/01_build_log.txt", replace text name(build)

* Dollar sign as a literal. Never type $ inside a quoted string in Stata:
* it triggers global macro expansion and silently mangles the comparison.
local D = char(36)

*------------------------------------------------------------------------------
* 1. Import
*------------------------------------------------------------------------------
*------------------------------------------------------------------------------
* 1. Import
*------------------------------------------------------------------------------
capture confirm file "$RAW/public2025.csv"
if _rc {
    di as err "Cannot find public2025.csv in: $RAW"
    error 601
}

import delimited "$RAW/public2025.csv", varnames(1) stringcols(_all) clear

* Stable row id, fixed before anything reorders the data.
gen long rid = _n
label var rid "Row id, file order at import"
order rid

*--- GATE 1: raw file n = 12,934
count
assert r(N) == 12934
di as res "GATE 1 PASS: raw n = " r(N)

*------------------------------------------------------------------------------
* 2. Clean copies of the dollar-denominated string variables
*    Strip currency symbols and thousands separators so that exact string
*    matching is unambiguous. char(36) is used rather than a literal dollar
*    sign: inside a quoted string Stata treats $ as macro expansion and would
*    silently mangle every comparison downstream.
*------------------------------------------------------------------------------
foreach v in ef7 ef7a i40 {
    gen str40 `v'_s = subinstr(subinstr(`v', char(36), "", .), ",", "", .)
    replace `v'_s = strtrim(`v'_s)
}

tab ef7_s, missing
*------------------------------------------------------------------------------
* 3. Outcome: cap2k
*    1 = could cover a $2,000 emergency expense from savings, 0 = could not.
*    EF7 and EF7A are the two arms of the randomized dov_ef7 split. Their
*    categories are identical below $2,000 and diverge only above it, so the
*    threshold is common to both forms and no respondent is lost.
*------------------------------------------------------------------------------
gen byte cap2k = .

* EF7 arm: ceiling category is "$2,000 or more"
replace cap2k = 0 if ef7_s != ""
replace cap2k = 1 if ef7_s == "2000 or more"

* EF7A arm: top two categories both clear $2,000
replace cap2k = 0 if ef7a_s != ""
replace cap2k = 1 if ef7a_s == "2000 to 4999"
replace cap2k = 1 if ef7a_s == "5000 or more"

label var cap2k "Could cover a 2000 dollar emergency expense from savings"
label define yesno 0 "No" 1 "Yes"
label values cap2k yesno

*--- GATE 2: cap2k complete for all 12,934
count if missing(cap2k)
assert r(N) == 0
di as res "GATE 2 PASS: cap2k has no missing values"

*--- GATE 3: arm counts and disjointness
count if ef7_s  != ""
local n_ef7 = r(N)
count if ef7a_s != ""
local n_ef7a = r(N)
count if ef7_s != "" & ef7a_s != ""
local n_both = r(N)

assert `n_ef7'  == 6453
assert `n_ef7a' == 6481
assert `n_both' == 0
assert `n_ef7' + `n_ef7a' == 12934
di as res "GATE 3 PASS: EF7 = `n_ef7', EF7A = `n_ef7a', overlap = `n_both'"

*------------------------------------------------------------------------------
* 4. Exposure
*------------------------------------------------------------------------------
gen byte coresident = .
replace coresident = 0 if l0_c == "No"
replace coresident = 1 if l0_c == "Yes"
label var coresident "Adult child age 18+ lives in the household"
label values coresident yesno

assert !missing(coresident)

*--- GATE 5: unweighted L0_c = Yes on the FULL file (checked before restriction)
count if coresident == 1
assert r(N) == 2429
di as res "GATE 5 PASS: coresident = 1 on full file = " r(N)

*------------------------------------------------------------------------------
* 5. Covariates
*    All enter the models as factor variables, so the internal numbering is
*    immaterial; encode's alphabetical ordering is therefore acceptable except
*    for income, which is built in substantive order for legible output.
*------------------------------------------------------------------------------
destring ppage, gen(age) force
label var age "Age in years"
assert !missing(age)

foreach v in ppgender race_5cat ppmarit5 ppeduc5 ppemploy gh1 {
    encode `v', gen(`v'_n)
}

rename ppgender_n   gender
rename race_5cat_n  race5
rename ppmarit5_n   marital
rename ppeduc5_n    educ
rename ppemploy_n   employ
rename gh1_n        tenure

label var gender  "Gender"
label var race5   "Race and ethnicity, 5 categories"
label var marital "Marital status"
label var educ    "Education, 5 categories"
label var employ  "Employment status"
label var tenure  "Housing tenure (GH1, asked in SHED)"

* Income: respondent and spouse/partner combined (I40, asked in SHED).
* Built in ascending bracket order for readable margins output. Treated as
* categorical in all models -- bracket widths are uneven, so an ordinal score
* would impose a linearity assumption the brackets do not support.
gen byte income = .
replace income =  1 if i40_s == "Less than 5000"
replace income =  2 if i40_s == "5000 to 9999"
replace income =  3 if i40_s == "10000 to 14999"
replace income =  4 if i40_s == "15000 to 19999"
replace income =  5 if i40_s == "20000 to 24999"
replace income =  6 if i40_s == "25000 to 29999"
replace income =  7 if i40_s == "30000 to 34999"
replace income =  8 if i40_s == "35000 to 39999"
replace income =  9 if i40_s == "40000 to 49999"
replace income = 10 if i40_s == "50000 to 59999"
replace income = 11 if i40_s == "60000 to 74999"
replace income = 12 if i40_s == "75000 to 99999"
replace income = 13 if i40_s == "100000 to 149999"
replace income = 14 if i40_s == "150000 to 199999"
replace income = 15 if i40_s == "200000 or more"

label define inclbl  1 "<5k"      2 "5-10k"    3 "10-15k"   4 "15-20k"  ///
                     5 "20-25k"   6 "25-30k"   7 "30-35k"   8 "35-40k"  ///
                     9 "40-50k"  10 "50-60k"  11 "60-75k"  12 "75-100k" ///
                    13 "100-150k" 14 "150-200k" 15 "200k+"
label values income inclbl
label var income "Respondent + spouse/partner income (I40), 15 brackets"

* Unmapped income strings would silently become missing. Stop instead.
count if missing(income)
if r(N) > 0 {
    di as err "Unmapped I40 categories:"
    levelsof i40_s if missing(income), clean
    error 459
}

* Sensitivity S1 income measure (Ipsos profile household income).
encode ppinc7, gen(income_pp)
label var income_pp "Household income (ppinc7, Ipsos profile) -- S1 only"

*------------------------------------------------------------------------------
* 6. Weight and profile variables
*------------------------------------------------------------------------------
destring weight,   gen(wt)      force
destring ppt18ov,  gen(adults)  force
destring pphhsize, gen(hhsize)  force

label var wt     "SHED post-stratification weight"
label var adults "Adults 18+ in household (Ipsos profile)"
label var hhsize "Household size (Ipsos profile)"

assert !missing(wt) & wt > 0

*------------------------------------------------------------------------------
* 7. Analytic sample: age 50 and older
*------------------------------------------------------------------------------
* Save an all-ages copy for sensitivity S3 before restricting.
preserve
    keep rid cap2k coresident age gender race5 marital educ employ tenure ///
         income income_pp wt adults hhsize
    compress
    save "$OUT/analytic_allages.dta", replace
restore

keep if age >= 50

*--- GATE 4: analytic sample sizes
count
assert r(N) == 6962
count if coresident == 0
local n0 = r(N)
count if coresident == 1
local n1 = r(N)
assert `n0' == 5224
assert `n1' == 1738
di as res "GATE 4 PASS: analytic n = 6962 (no child `n0', child `n1')"

*------------------------------------------------------------------------------
* 8. Profile-inconsistency flag
*    L0_c is asked during the SHED interview; ppt18ov is an Ipsos profile
*    variable refreshed on a separate schedule. Where they disagree the
*    contemporaneous survey response is authoritative, so these cases are
*    RETAINED in the primary analysis. Exclusion runs as sensitivity S2.
*------------------------------------------------------------------------------
gen byte flag_profile = (coresident == 1 & adults == 1)
label var flag_profile "L0_c=Yes but profile reports 1 adult in household"
label values flag_profile yesno

*--- GATE 7: flag count
count if flag_profile == 1
assert r(N) == 161
di as res "GATE 7 PASS: profile-inconsistency flag = " r(N)

*------------------------------------------------------------------------------
* 9. Design and weighted checks
*------------------------------------------------------------------------------
svyset [pw=wt]

*--- GATE 6: weighted cap2k by coresidence reproduces the disclosed figures
*    Tolerance 0.1pp: the preregistered values are rounded to one decimal and
*    the survey point estimate should land within that.
qui summarize cap2k [aw=wt] if coresident == 0
local p0 = r(mean)*100
qui summarize cap2k [aw=wt] if coresident == 1
local p1 = r(mean)*100

di as txt "  weighted cap2k, no coresident child: " %5.2f `p0' "%"
di as txt "  weighted cap2k, coresident child   : " %5.2f `p1' "%"
di as txt "  unadjusted difference              : " %5.2f `p1'-`p0' " pp"

assert abs(`p0' - 64.7) < 0.1
assert abs(`p1' - 51.6) < 0.1
di as res "GATE 6 PASS: weighted proportions reproduce"

*--- GATE 8: no missing covariates in the analytic sample
foreach v of varlist cap2k coresident age gender race5 marital educ ///
                     employ tenure income wt {
    count if missing(`v')
    if r(N) > 0 {
        di as err "Missing values in `v': " r(N)
        error 459
    }
}
di as res "GATE 8 PASS: all model variables complete in analytic sample"

*------------------------------------------------------------------------------
* 10. Cross-validation folds for the prediction layer
*     Repeated 5-fold CV, 5 repeats, seeds 202502-202506, stratified on the
*     four cells of cap2k x coresident. Assignment is deterministic given the
*     seed: the data are sorted on rid first, and the random draw is unique
*     per row, so no tie-breaking ambiguity remains.
*     Both the base and augmented models must use these columns. Python must
*     never regenerate folds on the Python side.
*------------------------------------------------------------------------------
forvalues r = 1/5 {
    local seed = 202501 + `r'

    sort rid
    set seed `seed'
    gen double _u = runiform()

    bysort cap2k coresident (_u): gen byte fold_r`r' = mod(_n - 1, 5) + 1
    label var fold_r`r' "CV fold, repeat `r' (seed `seed')"

    drop _u
    sort rid
}

*--- GATE 9: each stratum is spread across the five folds within +/- 1
forvalues r = 1/5 {
    forvalues c = 0/1 {
        forvalues k = 0/1 {
            qui count if cap2k == `k' & coresident == `c'
            local cell = r(N)
            local lo = floor(`cell'/5)
            local hi = ceil(`cell'/5)
            forvalues f = 1/5 {
                qui count if cap2k == `k' & coresident == `c' & fold_r`r' == `f'
                assert r(N) >= `lo' & r(N) <= `hi'
            }
        }
    }
    qui levelsof fold_r`r', local(lv)
    assert `: word count `lv'' == 5
}
di as res "GATE 9 PASS: all folds stratified on cap2k x coresident within +/-1"

*------------------------------------------------------------------------------
* 11. Save
*------------------------------------------------------------------------------

di "$OUT"

keep rid cap2k coresident age gender race5 marital educ employ tenure ///
     income income_pp wt flag_profile adults hhsize dov_ef7 ///
     fold_r1 fold_r2 fold_r3 fold_r4 fold_r5

order rid cap2k coresident age gender race5 marital educ employ tenure ///
      income wt fold_r1 fold_r2 fold_r3 fold_r4 fold_r5 ///
      income_pp flag_profile adults hhsize dov_ef7

compress
save "$OUT/analytic.dta", replace

* Input for the Python layer. Value labels are written as strings so Python receives
* readable categories and does the one-hot encoding inside its training folds.
export delimited using "$OUT/analytic_dataset.csv", replace

dir "$OUT"

log close build
*==============================================================================
* END 01_build.do
*==============================================================================
