*FROM MERGED GENO, PHENO, ADMIN FILE, THIS DOES FINAL PREP AND RUNS IMPUTATION

************************************************************************
*FOR RUNNING ON TSD

capture set maxvar 20000
cd "N:\durable\projects\parental_educ_mh"
sysdir set PLUS "N:\durable\people\Mandy\Statafiles\ado\plus"

use  "scratch/merged_phenotype_genotype_admin_pre_imp",clear

************************************************************************

*FOR RUNNING ON COLOSSUS:

*JUST THE INSIDE PART OF THE LOOP - BUT DOING 100 AS ONE BATCH

*still needs to be called with the shell script, but the supershell isn't necessary

/*
set processors 8

cd /cluster/p/p471/cluster/projects/parental_educ_mh
sysdir set PLUS "/cluster/p/p471/cluster/people/Mandystatafiles/ado/plus"
set maxvar 20000
sysdir

*load pre-imputation data
use  "scratch/merged_phenotype_genotype_admin_pre_imp",clear
count
*/
**********************************************************************

*EXCLUSIONS:
*as in the bmi analysis, restrict to people with a record in the birth registry file, so that cov_num_previous_preg cov_mother_age can go on right-hand side of the imputation. this really helps it.
keep if present_MBRN==1
count
*113,603

gen nQ_present=0
foreach q in Q1 QF Q5 Q6 Q5y Q8y {
	replace nQ_present=nQ_present+1 if present_`q'==1
}
fre nQ_present
*OK, so there's a chunk of people who never were included in a single questionnaire.
*these are the people that weren't present at the very first one:
tab nQ_present present_Q1, mi


//Restrict to observations with at least some questionnaire data:
*keep if nQ_present>0
count
//Restrict to observations with valid genetic data for the full trio:
keep if nQ_present>0 
count
*104,723
keep if complete_trio==1
count
*40,879 after fixing the issue with the incorrect drop in the parents_educ file (12/06/2023)

*NB: using the variable c_sex for the child's sex (from genetic data) rather than the one derived from KJONN in the birth registry file.
drop cov_male

*all pgs vars already standardized:
describe *_z_*pgs

*drop the non-dummy versions of these:
drop c_genotyping_center c_genotyping_chip m_genotyping_center m_genotyping_chip f_genotyping_center f_genotyping_chip
drop c_genotyping_center_num c_genotyping_chip_num m_genotyping_center_num m_genotyping_chip_num f_genotyping_center_num f_genotyping_chip_num

************************************************************
*mi set - wide takes up the least space!
mi set wide
************************************************************

//Register all the variables
*regular:
mi register regular *_pgs c_sex c_yob ///
/* PCs */ c_PC* m_PC* f_PC* ///
/*genotyping center*/ c_genotyping_center1  c_genotyping_center2 m_genotyping_center1 m_genotyping_center2 f_genotyping_center1  f_genotyping_center2 ///
/*genotyping chip: omitted (largest) group is 2, 1, 1*/ c_genotyping_chip1 c_genotyping_chip3 c_genotyping_chip4 c_genotyping_chip6 m_genotyping_chip2  m_genotyping_chip3 m_genotyping_chip4 m_genotyping_chip5 m_genotyping_chip6 f_genotyping_chip2 f_genotyping_chip3 f_genotyping_chip4 f_genotyping_chip5 f_genotyping_chip6 ///
cov_num_previous_preg cov_mother_age cov_mother_marstat

*imputed:

*for the two extra items of the SCQ, need to rebase as 0/1 for the logistic regression.
*makes sense anyway as the social and repetitive subscales have already been rebased to start at 0.
foreach var in out_q6_scq_rGG272 out_q6_scq_GG289 rout_q8yrs_scq_NN166 out_q8yrs_scq_NN184 {
	fre `var'
	replace `var'=`var'-1
	fre `var'
}

mi register imputed mother_eduyears father_eduyears cov_q1qf_income cov_father_age ///
/*outcomes: child's mental health and neurodevelopment at age 8*/ ///
out_q8yrs_smfq out_q8yrs_scared out_q8yrs_inadhd out_q8yrs_hyadhd out_q8yrs_scq_sci out_q8yrs_scq_rrb ///
out_q6_scq_rGG272 out_q6_scq_GG289 ///
/*earlier measures of outcome variables*/ ///
out_q6_S_SCQ_Q6 out_q6_R_SCQ_Q6 out_q5yrs_conners ///
rout_q8yrs_scq_NN166 out_q8yrs_scq_NN184 ///
/*covariates*/ ///
cov_q1_mumsmokes_v2 cov_q1qf_dadsmokes cov_q1_mother_educ cov_q1qf_father_educ  ///
cov_q1_mothers_bmi cov_q1qf_fathers_bmi ///
mhopkins_Q1 fhopkins_QF mhopkins_Q6 mhopkins_Q5y mhopkins_Q8y fhopkins_QF2 mADHD_Q6 fADHD_QF 


save "scratch/mi_analysis_dataset_pre",replace
use "scratch/mi_analysis_dataset_pre",clear

//Run imputation 

cap:rm impstats.dta

mi impute chained ///
/*exposures*/ (truncreg, ll(7) ul(21))  mother_eduyears father_eduyears ///
/*outcomes*/ /*child's mental health and neurodevelopment at age 8*/ ///
(pmm, knn(10)) out_q8yrs_smfq out_q8yrs_scared out_q8yrs_inadhd out_q8yrs_hyadhd ///
/*earlier measures of outcome variables*/ (pmm, knn(10)) out_q5yrs_conners ///
/*covariates*/ ///
(ologit) cov_q1_mumsmokes_v2 cov_q1qf_dadsmokes  ///
(pmm, knn(10)) cov_q1_mother_educ cov_q1qf_father_educ ///
(pmm, knn(10)) cov_q1qf_income cov_father_age ///
(pmm, knn(10)) cov_q1_mothers_bmi cov_q1qf_fathers_bmi ///
(pmm, knn(10)) mhopkins_Q1 fhopkins_QF mhopkins_Q6 mhopkins_Q5y mhopkins_Q8y fhopkins_QF2 mADHD_Q6 fADHD_QF ///
/*regular variables (i.e. non-missing)*/ ///
= c_sex  c_yob *_PC* *_z_*pgs* ///
c_genotyping_center1  c_genotyping_center2 m_genotyping_center1 m_genotyping_center2 f_genotyping_center1  f_genotyping_center2 ///
c_genotyping_chip1 c_genotyping_chip3 c_genotyping_chip4 c_genotyping_chip6 m_genotyping_chip2  m_genotyping_chip3 m_genotyping_chip4 m_genotyping_chip5 m_genotyping_chip6 f_genotyping_chip2 f_genotyping_chip3 f_genotyping_chip4 f_genotyping_chip5 f_genotyping_chip6 ///
 present_* cov_num_previous_preg cov_mother_age cov_mother_marstat ///
, add(50) rseed(100) dots savetrace(impstats.dta) augment 

compress
save "scratch/impx50_mi_raw_dataset", replace


*prep in mi passive
*adhd full scale
mi passive: gen out_q8yrs_adhd_full = out_q8yrs_inadhd + out_q8yrs_hyadhd
*scq full scale
*mi passive: gen out_q8yrs_scq_full= out_q6_S_SCQ_Q6 + out_q6_R_SCQ_Q6 + rout_q8yrs_scq_NN166 + out_q8yrs_scq_NN184

*standardize all the outcomes:
foreach outcome in out_q8yrs_smfq out_q8yrs_scared out_q8yrs_adhd_full out_q8yrs_inadhd out_q8yrs_hyadhd /*out_q8yrs_scq_full*/ {
mi passive: egen z_`outcome'=std(`outcome')
}

*log-transform them:
foreach outcome in out_q8yrs_smfq out_q8yrs_scared out_q8yrs_adhd_full out_q8yrs_inadhd out_q8yrs_hyadhd /*out_q8yrs_scq_full*/ {
mi passive: gen ln_`outcome'=ln(`outcome'+1)
}

save "scratch/impx50_mi_analysis_dataset", replace
