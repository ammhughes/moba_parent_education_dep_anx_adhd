*ENTRY POINT: REGRESSIONS

clear all
set maxvar 20000
cd "N:\durable\projects\parental_educ_mh"
sysdir set PLUS "N:\durable\people\Mandy\Statafiles\ado\plus"

use "scratch\impx50_mi_analysis_dataset_females", clear

*should be 20,013
count
*20,013

//Covariates

//The same set of covariates to be used with all regressions, along with child's sex and age:

/*extra covariates for non-genetic models only*/
*for now, leaving the following out of phenotypic as well as genetic regressions:
*cov_mother_age cov_father_age i.cov_num_previous_preg 
*rationale being that education impacts these more than they influence education. if parental age (and hence, number of previous pregnancies) is on the causal pathway from education to child's outcomes, will heavily overadjust, leading to non-genetic estimates which are too small compared to mr estimates.
global covar_pheno = "i.cov_q1_mumsmokes_v2 i.cov_q1qf_dadsmokes mhopkins_Q1 fhopkins_QF mADHD_Q6 fADHD_QF"

/*genetic covariates: PCs, center and chip but not batch*/ 
*PCs:
global covar_pc = " c_PC* m_PC* f_PC*" 
/*genotyping center*/ 
global covar_gc =" c_genotyping_center1  c_genotyping_center2 m_genotyping_center1  m_genotyping_center2 f_genotyping_center1 f_genotyping_center2" 
/*genotyping chip*/ 
global cov_chip=" c_genotyping_chip1 c_genotyping_chip3 c_genotyping_chip4 c_genotyping_chip6 m_genotyping_chip2  m_genotyping_chip3 m_genotyping_chip4 m_genotyping_chip5 m_genotyping_chip6 f_genotyping_chip2 f_genotyping_chip3 f_genotyping_chip4 f_genotyping_chip5 f_genotyping_chip6"


*do this via estout as before:
capture erase "output\tables\females_imputed_dep_anx_adhd_subscales.txt"
capture erase "output\tables\females_imputed_dep_anx_adhd_subscales.xls"

*non-genetic and WFMR models
eststo clear
foreach i in smfq scared adhd_full inadhd hyadhd  {
*non-genetic, unadjusted:
eststo `i'_ph_un: mi estimate, post cmdok: reg z_out_q8yrs_`i' /*parents education*/ mother_eduyears father_eduyears c_sex c_yob $covar_pc $cov_gc $cov_chip, vce(cluster fid) 
*non-genetic
eststo `i'_pheno: mi estimate, post cmdok: reg z_out_q8yrs_`i' /*parents education*/ mother_eduyears father_eduyears c_sex c_yob $covar_pheno $covar_pc $cov_gc $cov_chip, vce(cluster fid) 
*mr
eststo `i'_mr: mi estimate, post cmdok: ivregress 2sls  z_out_q8yrs_`i' /*parents education*/ (mother_eduyears father_eduyears=f_z_ea4_pgs m_z_ea4_pgs) c_sex c_yob $covar_pc $cov_gc $cov_chip, vce(cluster fid) 
*wfmr
eststo `i'_wf: mi estimate, post cmdok: ivregress 2sls  z_out_q8yrs_`i' /*parents education*/ (mother_eduyears father_eduyears=f_z_ea4_pgs m_z_ea4_pgs) c_z_ea4_pgs c_sex c_yob $covar_pc $cov_gc $cov_chip, vce(cluster fid) 
*check:
esttab, b(%9.2f) ci(%9.2f) keep(*eduyears* c_z_ea4_pgs) compress noparen nostar
}
estout using "output\tables\females_imputed_dep_anx_adhd_subscales.xls", cells ("b(fmt(2)) ci_l(fmt(2)) ci_u(fmt(2)) se(fmt(3)) p(fmt(3))") keep(*eduyears* c_z_ea4_pgs) replace title(maternal and paternal education to age 8 outcomes) note("comparing non-genetic and within-family MR models.")


*FIGURES:
*now do the figures, since estimates already stored:

label variable z_out_q8yrs_smfq "depressive traits"
label variable z_out_q8yrs_scared "anxiety traits"
label variable z_out_q8yrs_adhd_full "ADHD traits"
label variable z_out_q8yrs_inadhd "ADHD traits (inattention)"
label variable z_out_q8yrs_hyadhd "ADHD traits (hyperactivity)"
label variable c_z_ea4_pgs "child's PGI (standardized)"
label variable mother_eduyears "mother's years of education"
label variable father_eduyears "father's years of education"

*pull graph titles from macros defined here:
global smfq_title = "Child's depressive traits"
global scared_title = "Child's anxiety traits"
global adhd_full_title = "Child's ADHD traits"

foreach i in smfq scared adhd_full /*inadhd hyadhd*/  {
coefplot ///
(`i'_ph_un, label (non-genetic)) ///
(`i'_pheno, label (non-genetic, adjusted)) ///
(`i'_mr, label (genetic, adjusted for co-parent pgs)) ///
(`i'_wf, label (genetic trio model)), ///
keep (mother_eduyears father_eduyears c_z_ea4_pgs) drop(_cons) xline(0) grid(none) msize(small) title("{bf:$`i'_title}", size(medsmall) pos(4) ring(0) color(black)) scheme(s1mono) graphregion(margin(l=10 r=10)  color(white)) legend(rows(1) size(small)) xsc(r(-0.1 0.1)) xtick(-0.1 -0.08 -0.06 -0.04 -0.02 0.0 0.02 0.04 0.06 0.08 0.1) xlabel(-0.1 -0.08 -0.06 -0.04 -0.02 0.0 0.02 0.04 0.06 0.08 0.1) xlabel(,labsize(small)) ylabel(,labsize(small)) legend(region(lwidth(none)))
graph save output/graphs/females_imputed_`i'_coefeplot.gph, replace
}
*combine:
grc1leg2 output/graphs/females_imputed_smfq_coefeplot.gph output/graphs/females_imputed_scared_coefeplot.gph output/graphs/females_imputed_adhd_full_coefeplot.gph, cols(1) scheme(s1mono) imargin(10 10 0 0) position(6) 
graph save output/graphs/females_imputed_alloutcomes_coefeplot.gph, replace
graph export output/graphs/females_imputed_alloutcomes_coefeplot.tif, replace width(1200)


*SENSITIVITY ANALYSES:

*complete-case already done before imputation
*sex-stratified analyses done in seperate files
*snp-level checks done on colossus
*still need to do:log-transformed

*do this via estout as before:
capture erase "output\tables\females_ln_dep_anx_adhd_subscales.txt"
capture erase "output\tables\females_ln_dep_anx_adhd_subscales.xls"

*non-genetic and WFMR models
eststo clear
foreach i in smfq scared adhd_full inadhd hyadhd  {
*non-genetic
eststo ln_`i'_ph_un: mi estimate, post cmdok: reg ln_out_q8yrs_`i' /*parents education*/ mother_eduyears father_eduyears c_sex c_yob $covar_pc $cov_gc $cov_chip, vce(cluster fid) 
*non-genetic, adjusted
eststo ln_`i'_pheno: mi estimate, post cmdok: reg ln_out_q8yrs_`i' /*parents education*/ mother_eduyears father_eduyears c_sex c_yob $covar_pheno $covar_pc $cov_gc $cov_chip, vce(cluster fid) 
*mr
eststo ln_`i'_mr: mi estimate, post cmdok: ivregress 2sls  ln_out_q8yrs_`i' /*parents education*/ (mother_eduyears father_eduyears=f_z_ea4_pgs m_z_ea4_pgs) c_sex c_yob $covar_pc $cov_gc $cov_chip, vce(cluster fid) 
*wfmr
eststo ln_`i'_wf: mi estimate, post cmdok: ivregress 2sls  ln_out_q8yrs_`i' /*parents education*/ (mother_eduyears father_eduyears=f_z_ea4_pgs m_z_ea4_pgs) c_z_ea4_pgs c_sex c_yob $covar_pc $cov_gc $cov_chip, vce(cluster fid) 
*check:
esttab, b(%9.2f) ci(%9.2f) keep(*eduyears* c_z_ea4_pgs) compress noparen nostar
}
estout using "output\tables\females_ln_dep_anx_adhd_subscales.xls", cells ("b(fmt(2)) ci_l(fmt(2)) ci_u(fmt(2)) se(fmt(3)) p(fmt(3))") keep(*eduyears* c_z_ea4_pgs) replace title(maternal and paternal education to age 8 outcomes) note("comparing non-genetic and within-family MR models.")

*now do the figures, since estimates already stored:
label variable ln_out_q8yrs_smfq "depressive traits"
label variable ln_out_q8yrs_scared "anxiety traits"
label variable ln_out_q8yrs_adhd_full "ADHD traits"
label variable ln_out_q8yrs_inadhd "ADHD traits (inattention)"
label variable ln_out_q8yrs_hyadhd "ADHD traits (hyperactivity)"
label variable c_z_ea4_pgs "child's PGI (standardized)"
label variable mother_eduyears "mother's years of education"
label variable father_eduyears "father's years of education"

*pull graph titles from macros defined here:
global smfq_title = "Child's depressive traits"
global scared_title = "Child's anxiety traits"
global adhd_full_title = "Child's ADHD traits"

foreach i in smfq scared adhd_full /*inadhd hyadhd*/  {
coefplot ///
(ln_`i'_ph_un, label (non-genetic)) ///
(ln_`i'_pheno, label (non-genetic, adjusted)) ///
(ln_`i'_mr, label (genetic, adjusted for co-parent pgs)) ///
(ln_`i'_wf, label (genetic trio model)), ///
keep (mother_eduyears father_eduyears c_z_ea4_pgs) drop(_cons) xline(0) grid(none) msize(small) title("{bf:$`i'_title}", size(medsmall) pos(4) ring(0) color(black)) scheme(s1mono) graphregion(margin(l=10 r=10)  color(white)) legend(rows(1) size(small)) xsc(r(-0.1 0.1)) xtick(-0.1 -0.08 -0.06 -0.04 -0.02 0.0 0.02 0.04 0.06 0.08 0.1) xlabel(-0.1 -0.08 -0.06 -0.04 -0.02 0.0 0.02 0.04 0.06 0.08 0.1) xlabel(,labsize(small)) ylabel(,labsize(small)) legend(region(lwidth(none)))
graph save output/graphs/females_imputed_ln_`i'_coefeplot.gph, replace
}
*combine:
grc1leg2 output/graphs/females_imputed_ln_smfq_coefeplot.gph output/graphs/females_imputed_ln_scared_coefeplot.gph output/graphs/females_imputed_ln_adhd_full_coefeplot.gph, cols(1) scheme(s1mono) imargin(10 10 0 0) position(6) 
graph save output/graphs/females_imputed_ln_alloutcomes_coefeplot.gph, replace
graph export output/graphs/females_imputed_ln_alloutcomes_coefeplot.tif, replace width(1200)