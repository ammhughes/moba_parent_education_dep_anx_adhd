*ENTRY POINT: POST-IMPUTATION DESCRIPTIVES

clear all
set maxvar 20000
cd "N:\durable\projects\parental_educ_mh"
sysdir set PLUS "N:\durable\people\Mandy\Statafiles\ado\plus"

use "scratch\impx50_mi_analysis_dataset", clear

count
*should be 40,879

*for misum, data needs to be in flong format.
***ssc install misum***
mi convert flong

********************************************************************************
*TABLE 1:

/*
capture log close
log using "output\post_imp_descriptives.log", replace

*Means for contin ones
foreach var in father_eduyears mother_eduyears cov_mother_age cov_father_age mhopkins_Q1 fhopkins_QF mADHD_Q6 fADHD_QF ///
c_yob out_q8yrs_smfq out_q8yrs_scared out_q8yrs_adhd_full out_q8yrs_inadhd out_q8yrs_hyadhd {
*change display format
format `var' %12.2fc
misum `var' 
}

*Categ ones:
*no need to do c_sex: non missingness so will be the same as complete-case
foreach var in c_sex cov_num_previous_preg cov_mother_marstat cov_q1_mumsmokes_v2 cov_q1qf_dadsmokes  {
mi estimate: proportion `var' 
}

log close
*/
***************************************
*PUTEXCEL

*TRY TABLE 1?: https://blog.uvm.edu/tbplante/2019/07/11/make-a-table-1-in-stata-in-no-time-with-table1_mc/
*actually, can't do that with imputed data anyway, so just do this manually

capture erase "output\tables\imputed_Table1.xlsx"
putexcel set "output\tables\imputed_Table1.xlsx", replace
*top gubbins:
local k=3
putexcel A`k'="Table 1: Descriptive Characteristics of Analytic Samplea", bold 
local k=`k'+1
putexcel B`k'="mean" C`k'="SD" D`k'="min" E`k'="max" F`k'="N", bold border(top bottom)
***ssc install misum***
*Means for contin ones
local k=`k'+1
foreach var in father_eduyears mother_eduyears cov_mother_age cov_father_age mhopkins_Q1 fhopkins_QF mADHD_Q6 fADHD_QF out_q8yrs_smfq out_q8yrs_scared out_q8yrs_adhd_full out_q8yrs_inadhd out_q8yrs_hyadhd {
misum `var' 
return list
putexcel A`k'="`var'"
putexcel B`k'=(r(`var'_mean)), nformat(#.0)
putexcel C`k'=(r(`var'_sd)), nformat(#.0)
putexcel D`k'=(r(`var'_min)), nformat(#.0)
putexcel E`k'=(r(`var'_max)), nformat(#.0)
putexcel F`k'=(r(`var'_N)), nformat(number)
local k=`k'+1
}
*convert back to wide format:
*capture mi convert wide
local k=18
putexcel E`k'="%" , bold
local k=`k'+1
foreach var in c_sex cov_num_previous_preg cov_mother_marstat cov_q1_mumsmokes_v2 cov_q1qf_dadsmokes {
putexcel A`k'="`var'"
*Get proportions, tranpose,fill
mi estimate: proportion `var' 
matlist e(b_mi)
matrix `var'=e(b_mi)'
putexcel A`k'="`var'" E`k'=matrix(`var')
*get number of rows needed before the next one
capture drop counter
by `var', sort: gen counter=1 if _n==1
replace counter=sum(counter)
local k=`k'+counter[_N]
display `k'
}
*will need to convert to % in excel but not the end of the world