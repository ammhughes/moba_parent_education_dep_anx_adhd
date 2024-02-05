****************************************************************************************

*ENTRY POINT: R2 AND WEAK INSTRUMENT TESTS ACROSS IMPUTATIONS

clear all
set maxvar 20000
cd "N:\durable\projects\parental_educ_mh"
sysdir set PLUS "N:\durable\people\Mandy\Statafiles\ado\plus"
sysdir set PERSONAL "N:\durable\people\Mandy\Statafiles\ado\personal"

use "scratch\impx50_mi_analysis_dataset", clear

**************************************************************************
*MANUALLY LOAD IVREG2
*after putting the mlib file in the new PERSONAL folder, manually run:
do "N:\durable\people\Mandy\statafiles\ado\plus\livreg2.do.txt"
do "N:\durable\people\Mandy\statafiles\ado\plus\ivreg2.ado.txt"
do "N:\durable\people\Mandy\statafiles\ado\plus\ivreg2_p.ado.txt"

**************************************************************************

/*genetic covariates: PCs, center and chip but not batch*/ 
*PCs:
global covar_pc = " c_PC* m_PC* f_PC*" 
/*genotyping center*/ 
global covar_gc =" c_genotyping_center1  c_genotyping_center2 m_genotyping_center1  m_genotyping_center2 f_genotyping_center1 f_genotyping_center2" 
/*genotyping chip*/ 
global cov_chip=" c_genotyping_chip1 c_genotyping_chip3 c_genotyping_chip4 c_genotyping_chip6 m_genotyping_chip2  m_genotyping_chip3 m_genotyping_chip4 m_genotyping_chip5 m_genotyping_chip6 f_genotyping_chip2 f_genotyping_chip3 f_genotyping_chip4 f_genotyping_chip5 f_genotyping_chip6"

*for the conditional R2, need to get SWr2 from the output using ", first" after ivreg2.

*EA4
*run this across all imputations, then take the average
*can just do one outcome because the first stage is the same!
foreach var in z_out_q8yrs_smfq {
*vars to store the r2 and F stats in:
capture gen `var'_m_ea4_swfs=.
capture gen `var'_f_ea4_swfs=.
capture gen `var'_m_ea4_swr2=.
capture gen `var'_f_ea4_swr2=.
forvalues m = 1/50 {
ivreg2 _`m'_`var' (_`m'_mother_eduyears _`m'_father_eduyears = m_z_ea4_pgs f_z_ea4_pgs) c_z_ea4_pgs $covar_pc $cov_gc $cov_chip, first
*retrieve:
mat list e(first)
mat ivreg2stats=e(first)
*SW R2:
*for mother:
scalar m_swr2 = ivreg2stats[14,1] 
display m_swr2
replace `var'_m_ea4_swr2=m_swr2 in `m'
*for father:
scalar f_swr2 = ivreg2stats[14,2] 
display f_swr2
replace `var'_f_ea4_swr2=f_swr2 in `m'
*SW F stats:
*for mother:
scalar m_swfs = ivreg2stats[8,1] 
display m_swfs
replace `var'_m_ea4_swf=m_swfs in `m'
*for father:
scalar f_swfs = ivreg2stats[8,2] 
display f_swfs
replace `var'_f_ea4_swf=f_swfs in `m'
}
}

*summarize across imputations:
*conditional r2
foreach var in z_out_q8yrs_smfq {
mean `var'_m_ea4_swr2
mean `var'_f_ea4_swr2
}

*conditional F stat
foreach var in z_out_q8yrs_smfq {
mean `var'_m_ea4_swfs
mean `var'_f_ea4_swfs
}

ivreg2 _1_z_out_q8yrs_smfq (_1_mother_eduyears _1_father_eduyears = m_z_ea4_pgs f_z_ea4_pgs) c_z_ea4_pgs $covar_pc $cov_gc $cov_chip, ffirst
mat list e(first)

ivreg2 _1_z_out_q8yrs_smfq (_1_mother_eduyears _1_father_eduyears = m_z_ea4_pgs f_z_ea4_pgs) $covar_pc $cov_gc $cov_chip, ffirst
mat list e(first)

ivreg2 _1_z_out_q8yrs_smfq (_1_mother_eduyears = m_z_ea4_pgs) $covar_pc $cov_gc $cov_chip, ffirst
mat list e(first)
