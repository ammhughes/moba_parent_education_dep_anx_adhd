//This merges in the phenotype and genotype data

clear all
set maxvar 20000

cd "N:\durable\projects\parental_educ_mh"
sysdir set PLUS "N:\durable\people\Mandy\Statafiles\ado\plus"

//Update the definition of the categorical variables:
//The non-binary variables cause problems for the imputation


*start with the phenotypic data:
use "scratch\main_phenotypes.dta", clear
merge 1:1 PREG_ID_2306 BARN_NR using "scratch\parental_mental_health.dta"
drop _merge
count 
*114,205

fre fathers_consent

/*fathers_consent
-------------------------------------------------------
          |      Freq.    Percent      Valid       Cum.
----------+--------------------------------------------
Valid   1 |      87885      76.95     100.00     100.00
Missing . |      26330      23.05                      
Total     |     114215     100.00                      
-------------------------------------------------------
*/

*then stitch on all of the the linkable polygenic scores, containing genetic covariates.
*first drop trios without a BARN_NR:
drop if BARN_NR==.
capture drop _merge

foreach pgs in ea4 depression adhd asd childbmi adultbmi {
merge 1:1 PREG_ID_2306 BARN_NR using "data\reshaped_linkable_`pgs'_genetic_pgs.dta"
drop _merge
}
fre BARN_NR

*the unmatched from using are observations with a missing BARN_NR - trios where the only person genotyped was a mother and/or father, so can't use them anyway:
count if BARN_NR==. & c_iid!=""
*drop them
drop if BARN_NR==.
*also drop the people without a record in the MBRN birth registry file:
drop if present_MBRN!=1

fre complete_trio
*42175

count
*113,603

*check all the variables:

#delimit ;
sum 
out_q6_delayed_motor 
out_q6_delayed_speech 
out_q6_trouble_relating 
out_q6_hyperactivity 
out_q6_autistic_traits 
out_q6_other_behavioural 
out_q6_prosocial 
out_q6_SCQ_Q6
out_q6_S_SCQ_Q6 
out_q6_R_SCQ_Q6 
out_q6_scq_rGG272
out_q6_scq_GG289
out_q6_cbcl_anxiety 
out_q6_passive_smoke
out_q5yrs_conners
out_q8yrs_delayed_language
out_q8yrs_teach_rate_score
out_q8yrs_master_score*
out_q8yrs_lang_skills_score
out_q8yrs_delayed_motor
out_q8yrs_delayed_language
out_q8yrs_hyperactivity 
out_q8yrs_concentration 
out_q8yrs_autistic_traits 
out_q8yrs_behavioural_problems 
out_q8yrs_emotional_diffic 
out_q8yrs_other_condition 
out_q8yrs_smfq 
out_q8yrs_adhd 
out_q8yrs_scq_sci 
out_q8yrs_scq_rrb 
out_q8yrs_inadhd 
out_q8yrs_hyadhd 
out_q8yrs_od 
out_q8yrs_cd 
out_q8yrs_scared 
out_q8yrs_scq 
out_q8yrs_scq_sci
out_q8yrs_scq_rrb
rout_q8yrs_scq_NN166 
out_q8yrs_scq_NN184
zout_q8yrs_smfq 
zout_q8yrs_adhd 
zout_q8yrs_inadhd 
zout_q8yrs_hyadhd 
zout_q8yrs_od 
zout_q8yrs_cd 
zout_q8yrs_scared 
zout_q8yrs_scq 
zout_q8yrs_scq_sci 
zout_q8yrs_scq_rrb

;
#delimit cr


//Recode diagnoses as yes any vs no.
#delimit ;
foreach i in
out_q6_delayed_speech
out_q8yrs_delayed_language{;
	fre `i';
	recode `i' 2=1;
	};


//Update present indicators
#delimit ;
ds present_*;
foreach i in `r(varlist)'{;
		replace `i'=0 if `i'==.;
};
#delimit cr

*Standardizing things - wait until after imputation.

#delimit ;
keep *fid* *iid* mid pid M_ID_2306 F_ID_2306 *PC* cov_* PREG_ID_2306 BARN_NR c_sex *_yob *pgs* *center* *chip* complete_trio
out_q6_delayed_speech
out_q6_delayed_motor
out_q6_SCQ_Q6 
out_q6_S_SCQ_Q6 
out_q6_R_SCQ_Q
out_q6_scq_rGG272
out_q6_scq_GG289 
out_q5yrs_conners
out_q8yrs_delayed_language
out_q8yrs_teach_rate_score
out_q8yrs_master_score*
out_q8yrs_lang_skills_score*
out_q8yrs_reading_score
out_q8yrs_smfq 
out_q8yrs_adhd 
out_q8yrs_inadhd 
out_q8yrs_hyadhd 
out_q8yrs_od 
out_q8yrs_cd 
out_q8yrs_scared 
out_q8yrs_scq 
out_q8yrs_scq_sci 
out_q8yrs_scq_rrb 
rout_q8yrs_scq_NN166 
out_q8yrs_scq_NN184
dadsmokes_QF2 
fathers_bmi_FQ2 
mhopkins_Q1 
fhopkins_QF 
mhopkins_Q6 
mhopkins_Q5y 
mhopkins_Q8y 
fhopkins_QF2
mADHD_Q6
fADHD_QF 
mothers_consent
out_q5*
DODKAT_G
present_*;
#delimit cr;


*then merge the linked educational data from the admin datasets - parents only

joinby PREG BARN using  "scratch/parents_eduyears",unmatched(master)
tab _merge
drop _merge

//Check whether there is any data from the questionaires we can use to update the admin data:
count if cov_q1_mother_educ!=. & mother_eduyears==.
count if cov_q1_father_educ!=. & father_eduyears==.
*NB: this is a lot because a lot of the questionnaire data comes from mothers' reports of their partners' qualifications, so wouldn't have been removed because father withdrew consent (but fathers' linked admin quals were)
fre cov_q1_mother_educ
fre cov_q1_father_educ
*update: don't recode to try to match the admin data - can impute using these as-is.

********************************************************************************************
********************************************************************************************

*NEED TO REDO THE REMOVAL OF RECENT CONSENT WITHDRAWALS, SINCE YOU'RE USING AN IMPORTED SCORE MADE A LITTLE WHILE AGO:

*drop whole family where the mum withdrew consent:
capture drop _merge
merge m:1 PREG_ID_2306 using "data\PDB2306_SV_INFO_v12_mothers_children.dta"
keep if _m==3

*then for any families where the father withdrew consent, remove all information he reported, and father's genetic infomrmation.

capture drop _merge
merge m:1 PREG_ID_2306 using "data\PDB2306_SV_INFO_v12_fathers.dta"

/*    Result                      Number of obs
    -----------------------------------------
    Not matched                        26,404
        from master                    26,065  (_merge==1)
        from using                        339  (_merge==2)

    Matched                            87,538  (_merge==3)
    -----------------------------------------
*/

drop if BARN_NR==.

fre fathers_consent

*code to missing:

*string vars
replace F_ID_2306="" if fathers_consent!=1
replace f_iid="" if fathers_consent!=1
replace f_fid="" if fathers_consent!=1

foreach var of varlist f_genotyping_center f_genotyping_chip  {
replace `var'="" if fathers_consent!=1
}

*everything else reported by, or measured from, fathers:
foreach var of varlist father_eduyears f_*pgs* f_genotyping_center_num f_genotyping_chip_num  f_genotyping_center1 f_genotyping_center2 f_genotyping_center3 f_genotyping_chip1 f_genotyping_chip2 f_genotyping_chip3 f_genotyping_chip4 f_genotyping_chip5 f_genotyping_chip6       {
replace `var'=. if fathers_consent!=1
}

*and update complete_trio flag:
replace complete_trio=. if fathers_consent!=1

fre complete_trio
*42159

********************************************************************************************
********************************************************************************************

drop _merge

count
*113,603

fre complete_trio
*42159

save "scratch/merged_phenotype_genotype_admin_pre_imp",replace
