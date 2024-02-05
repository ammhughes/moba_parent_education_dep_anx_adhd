
*COMLETE CASE ANALYSIS.

clear all
set maxvar 20000

cd "N:\durable\projects\parental_educ_mh"
sysdir set PLUS "N:\durable\people\Mandy\Statafiles\ado\plus"

use "scratch/merged_phenotype_genotype_admin_pre_imp", clear

*EXCLUSIONS:
*as in the bmi analysis, restrict to people with a record in the birth registry file, so that cov_num_previous_preg cov_mother_age can go on right-hand side of the imputation. this really helps it.
keep if present_MBRN==1

*identify people present in at least one questionnaire:
gen nQ_present=0
foreach q in Q1 QF Q5 Q6 Q5y Q8y {
	replace nQ_present=nQ_present+1 if present_`q'==1
}
fre nQ_present
*OK, so there's a chunk of people who never were included in a single questionnaire.

*****************************************************************************
*before going further, do the comparison of people retained v excluded:
gen retained=1
replace retained=0 if nQ_present==0 
replace retained=0 if complete_trio!=1
fre retained

*compare in terms of things in table 1.

*Means for contin ones
foreach var in father_eduyears mother_eduyears cov_mother_age cov_father_age mhopkins_Q1 fhopkins_QF mADHD_Q6 fADHD_QF ///
c_yob out_q8yrs_smfq out_q8yrs_scared out_q8yrs_adhd/*_full*/ out_q8yrs_inadhd out_q8yrs_hyadhd {
sdtest `var', by(retained)
}
*everything has unequal variance
foreach var in father_eduyears mother_eduyears cov_mother_age cov_father_age mhopkins_Q1 fhopkins_QF mADHD_Q6 fADHD_QF ///
c_yob out_q8yrs_smfq out_q8yrs_scared out_q8yrs_adhd/*_full*/ out_q8yrs_inadhd out_q8yrs_hyadhd {
display "`var'"
ttest `var', unequal by(retained)
}
*Categ ones:
foreach var in c_sex cov_num_previous_preg cov_q1_mumsmokes_v2 cov_q1qf_dadsmokes cov_mother_marstat {
tab `var' retained, chi col
}

*****************************************************************************
*restrict to people presnet in at least one questionnaire:
keep if nQ_present>0

*now restrict to full trios:
keep if complete_trio==1
count
*should be 40,879
*40,879

*NB: using the variable c_sex for the child's sex (from genetic data) rather than the one derived from KJONN in the birth registry file.
drop cov_male

*standardize all the outcomes:
foreach outcome in out_q8yrs_smfq out_q8yrs_scared out_q8yrs_adhd out_q8yrs_inadhd out_q8yrs_hyadhd {
egen z_`outcome'=std(`outcome')
}

***********************************************************************************************
*COMPLETE-CASE DESCRIPTIVES:

*TABLE S1:

capture log close
log using "output\tables\cc_descriptives.log", replace

foreach var in father_eduyears mother_eduyears cov_mother_age cov_father_age mhopkins_Q1 fhopkins_QF mADHD_Q6 fADHD_QF ///
c_yob out_q8yrs_smfq out_q8yrs_scared out_q8yrs_adhd/*_full*/ out_q8yrs_inadhd out_q8yrs_hyadhd {
*change display format
format `var' %12.2fc
sum `var' 
}

foreach var in c_sex cov_num_previous_preg cov_q1_mumsmokes_v2 cov_q1qf_dadsmokes {
fre `var'
}

log close

***************************************
*PUTEXCEL

*TRY TABLE 1?: https://blog.uvm.edu/tbplante/2019/07/11/make-a-table-1-in-stata-in-no-time-with-table1_mc/
*actually, can't do that with imputed data anyway, so just do this manually

capture erase "output\tables\cc_Table1.xlsx"
putexcel set "output\tables\cc_Table1.xlsx", replace
*top gubbins:
local k=3
putexcel A`k'="Table 1: Descriptive Characteristics of Analytic Samplea", bold 
local k=`k'+1
putexcel B`k'="mean" C`k'="SD" D`k'="min" E`k'="max" F`k'="N", bold border(top bottom)
***ssc install misum***
*Means for contin ones
*foreach var in maternal_age adhd10 depress10 asd10 bmi10 adhd13 depress13 asd13 bmi13 ks4_ptscnewe percent_absenceyear11 percent_absenceyear10 {
local k=`k'+1
foreach var in father_eduyears mother_eduyears cov_mother_age cov_father_age mhopkins_Q1 fhopkins_QF mADHD_Q6 fADHD_QF out_q8yrs_smfq out_q8yrs_scared out_q8yrs_adhd out_q8yrs_inadhd out_q8yrs_hyadhd {
sum `var' 
return list
putexcel A`k'="`var'"
putexcel B`k'=(r(mean)), nformat(#.0)
putexcel C`k'=(r(sd)), nformat(#.0)
putexcel D`k'=(r(min)), nformat(#.0)
putexcel E`k'=(r(max)), nformat(#.0)
putexcel F`k'=(r(N)), nformat(number)
local k=`k'+1
}
local k=18
putexcel E`k'="%" , bold
local k=`k'+1
foreach var in c_sex cov_num_previous_preg cov_mother_marstat cov_q1_mumsmokes_v2 cov_q1qf_dadsmokes {
putexcel A`k'="`var'"
tabulate `var', matcell(freq) matrow(names)
putexcel B`k'=matrix(names) E`k'=matrix(freq/r(N)) 
putexcel F`k'=matrix(r(N)) 
*fix formatting
local rows = rowsof(names)
local row = `k'
forvalues i = 1/`rows' {
        local freq_val = freq[`i',1]
        local percent_val = `freq_val'/`r(N)'*100
        local percent_val : display %9.1fc `percent_val' 
        putexcel E`row'=(`percent_val') 
        local row = `row' + 1
}
*get number of rows needed before the next one
capture drop counter
by `var', sort: gen counter=1 if _n==1
replace counter=sum(counter)
local k=`k'+counter[_N]
display `k'
}

************************************************************************************************
*COMPLETE-CASE ANALYSIS

//Covariates

//The same set of covariates to be used with all regressions:

*extra covariates for non-genetic models only:
*for now, leaving the following out of phenotypic as well as genetic regressions:
*cov_mother_age cov_father_age i.cov_num_previous_preg 
*rationale being that education impacts these more than they influence education. if parental age (and hence, number of previous pregnancies) is on the causal pathway from education to child's outcomes, will heavily overadjust, leading to non-genetic estimates which are too small compared to mr estimates.
global covar_pheno = "i.cov_q1_mumsmokes_v2 i.cov_q1qf_dadsmokes mhopkins_Q1 fhopkins_QF mADHD_Q6 fADHD_QF"

/*genetic covariates: PCs, center and chip but not batch*/ 
global covar_pc = " c_PC* m_PC* f_PC*" 
/*genotyping center*/ 

global covar_gc =" c_genotyping_center1  c_genotyping_center2 m_genotyping_center1  m_genotyping_center2 f_genotyping_center1 f_genotyping_center2" 

/*genotyping chip*/ 
global cov_chip=" c_genotyping_chip1 c_genotyping_chip3 c_genotyping_chip4 c_genotyping_chip6 m_genotyping_chip2  m_genotyping_chip3 m_genotyping_chip4 m_genotyping_chip5 m_genotyping_chip6 f_genotyping_chip2 f_genotyping_chip3 f_genotyping_chip4 f_genotyping_chip5 f_genotyping_chip6"


*for complete-case models, need to make a complete-case flag which is specific to each outcome.
foreach i in smfq scared adhd inadhd hyadhd  {
gen cc_`i'=1
replace cc_`i'=0 if z_out_q8yrs_`i'==.
foreach var in mother_eduyears father_eduyears c_sex c_yob ///
cov_q1_mumsmokes_v2 cov_q1qf_dadsmokes mhopkins_Q1 fhopkins_QF mADHD_Q6 fADHD_QF ///
c_PC1 m_PC1 f_PC1 {
replace cc_`i'=0 if `var'==.
}
}
fre cc_*

*TABLE S2:

*do this via estout as before:
capture erase "output\tables\cc_dep_anx_adhd_subscales.txt"
capture erase "output\tables\cc_dep_anx_adhd_subscales.xls"

*non-genetic and WFMR models
eststo clear
foreach i in smfq scared adhd inadhd hyadhd  {
*non-genetic, unadjusted:
eststo `i'_ph_un: reg z_out_q8yrs_`i' /*parents education*/ mother_eduyears father_eduyears c_sex c_yob $covar_pc $cov_gc $cov_chip if cc_`i'==1, vce(cluster fid) 
*non-genetic
eststo `i'_pheno: reg z_out_q8yrs_`i' /*parents education*/ mother_eduyears father_eduyears c_sex c_yob $covar_pheno $covar_pc $cov_gc $cov_chip if cc_`i'==1, vce(cluster fid) 
*mr
eststo `i'_mr: ivregress 2sls  z_out_q8yrs_`i' /*parents education*/ (mother_eduyears father_eduyears=f_z_ea4_pgs m_z_ea4_pgs) c_sex c_yob $covar_pc $cov_gc $cov_chip if cc_`i'==1, vce(cluster fid) 
*wfmr
eststo `i'_wf: ivregress 2sls  z_out_q8yrs_`i' /*parents education*/ (mother_eduyears father_eduyears=f_z_ea4_pgs m_z_ea4_pgs) c_z_ea4_pgs c_sex c_yob $covar_pc $cov_gc $cov_chip if cc_`i'==1, vce(cluster fid) 
*check:
esttab, b(%9.2f) ci(%9.2f) keep(*eduyears* c_z_ea4_pgs) compress noparen nostar
}
estout using "output\tables\cc_dep_anx_adhd_subscales.xls", cells ("b(fmt(2)) ci_l(fmt(2)) ci_u(fmt(2)) se(fmt(3)) p(fmt(3))") keep(*eduyears* c_z_ea4_pgs) replace title(maternal and paternal education to age 8 outcomes) note("comparing non-genetic and within-family MR models.")


*************************************************

*FIGURES: test in complete-case

*Coefplot guide: http://repec.sowi.unibe.ch/stata/coefplot/getting-started.html

label variable z_out_q8yrs_smfq "depressive traits"
label variable z_out_q8yrs_scared "anxiety traits"
label variable z_out_q8yrs_adhd "ADHD traits"
label variable z_out_q8yrs_inadhd "ADHD traits (inattention)"
label variable z_out_q8yrs_hyadhd "ADHD traits (hyperactivity)"
label variable c_z_ea4_pgs "child's PGI (standardized)"
label variable mother_eduyears "mother's years of education"
label variable father_eduyears "father's years of education"

*pull graph titles from macros defined here:
global smfq_title = "Child's depressive traits"
global scared_title = "Child's anxiety traits"
global adhd_title = "Child's ADHD traits"

foreach i in smfq scared adhd inadhd hyadhd  {
*non-genetic, unadjusted:
eststo `i'_ph_un: reg z_out_q8yrs_`i' /*parents education*/ mother_eduyears father_eduyears c_sex c_yob $covar_pc $cov_gc $cov_chip if cc_`i'==1, vce(cluster fid) 
*non-genetic
eststo `i'_pheno: reg z_out_q8yrs_`i' /*parents education*/ mother_eduyears father_eduyears c_sex c_yob $covar_pheno $covar_pc $cov_gc $cov_chip if cc_`i'==1, vce(cluster fid) 
*mr
eststo `i'_mr: ivregress 2sls  z_out_q8yrs_`i' /*parents education*/ (mother_eduyears father_eduyears=f_z_ea4_pgs m_z_ea4_pgs) c_sex c_yob $covar_pc $cov_gc $cov_chip if cc_`i'==1, vce(cluster fid) 
*wfmr
eststo `i'_wf: ivregress 2sls  z_out_q8yrs_`i' /*parents education*/ (mother_eduyears father_eduyears=f_z_ea4_pgs m_z_ea4_pgs) c_z_ea4_pgs c_sex c_yob $covar_pc $cov_gc $cov_chip if cc_`i'==1, vce(cluster fid) 
*check:
esttab, b(%9.2f) ci(%9.2f) keep(*eduyears* c_z_ea4_pgs) compress noparen nostar
}

*plot the estimates:

*COMBINED: parental effects and child's pgs effects:
foreach i in smfq scared adhd /*inadhd hyadhd*/  {
coefplot ///
(`i'_ph_un, label (non-genetic)) ///
(`i'_pheno, label (non-genetic, adjusted)) ///
(`i'_mr, label (genetic, adjusted for co-parent pgs)) ///
(`i'_wf, label (genetic trio model)), ///
keep (mother_eduyears father_eduyears c_z_ea4_pgs) drop(_cons) xline(0) grid(none) msize(small) title("{bf:$`i'_title}", size(medsmall) pos(4) ring(0) color(black)) scheme(s1mono) graphregion(margin(l=10 r=10)  color(white)) legend(rows(1) size(small)) xsc(r(-0.1 0.1)) xtick(-0.1 0.0 0.1) xlabel(-0.1 0.0 0.1) xlabel(,labsize(small)) ylabel(,labsize(small)) legend(region(lwidth(none)))
graph save output/graphs/cc_`i'_coefeplot.gph, replace
}
*combine:
grc1leg2 output/graphs/cc_smfq_coefeplot.gph output/graphs/cc_scared_coefeplot.gph output/graphs/cc_adhd_coefeplot.gph, cols(1) scheme(s1mono) imargin(10 10 0 0) position(6) 
graph save output/graphs/cc_alloutcomes_coefeplot.gph, replace
graph export output/graphs/cc_alloutcomes_coefeplot.tif, replace width(1200)
