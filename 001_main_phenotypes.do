
*PREP FOR CHILD PHENOTYPES FROM ALL QUESTIONNAIRES

clear all

cd "N:\durable\projects\parental_educ_mh\"

*Address for raw study data - amend later for publication to GitHub 
global raw_data="N:\durable\data\MoBaPhenoData\PDB2306_MoBa_v12\"

*to use the user-writen files, change the path to the PLUS part:
sysdir
sysdir set PLUS "N:\durable\people\Mandy\Statafiles\ado\plus"

**********************************************************************************************

*PRELIMINARIES:
*REMOVE THE NEW CONSENT WITHDRAWALS 
*This is done by restricting to people in the updated SV_INFO file.
*needs to be done separately for mothers/children and fathers.
use "N:\durable\data\MoBaPhenoData\PDB2306_MoBa_v12\Statafiles\PDB2306_SV_INFO_v12.dta", clear
count
*112,111

*Then split this into one for excluding mothers and children (on PREG_ID_2306) and the one for excluding fathers (on F_ID_2306).
*For mothers/children, APPLY the FILTER AT THE END OF THIS FILE, since less error-prone than applgying individually at each merge.
*For fathers, do this twice: filter the first father's questionnaire before merging in, and the second father's questionnaire, before merging in. This allows you to keep data reported by mothers in those families.
*Will ALSO NEED TO DO THAT FOR FATHER'S GENETIC DATA.
preserve
keep PREG_ID_2306 M_ID_2306
count if M_ID_2306==" "
*none missing
count
*112,111
*make a flag variable:
gen mothers_consent=1
save "data\PDB2306_SV_INFO_v12_mothers_children.dta", replace
restore
keep PREG_ID_2306 F_ID_2306
keep if F_ID_2306!=""
count
*86,351
*make a flag variable:
gen fathers_consent=1
count
save "data\PDB2306_SV_INFO_v12_fathers.dta", replace
*apply these as you go.

**********************************************************************************************

*START FROM THE BIRTH REGISTRY FILE, which you'll always need to do a pheno-geno linkage.
/*

## This file includes all births in MoBa (in version 12 there are 114,143 children from 112,644 pregnancies)
## key variables: PREG_ID_2306 = main ID for linkage, unique to pregnancy, KJONN=child´s sex, BARN_NR=birth order, 
## FAAR=birth year, MORS_ALDER= mothers age
*/

use "${raw_data}Statafiles\PDB2306_MBRN_541_v12.dta", clear
keep PREG_ID_2306 BARN_NR KJONN FAAR MORS_ALDER FARS_ALDER PARITET_5 SIVST_2 VEKT LENGDE ZSCORE_BW_GA  DODKAT_G

*to add to imputation:
fre MORS_ALDER PARITET_5

*recode the <17s group to 16 and the >45 group tp 46, then can at a pinch use as continous
recode MORS_ALDER 917=16
recode MORS_ALDER 945=46

*PARITET_5 can be used as-is
gen cov_num_previous_preg=PARITET_5

*paternal age:
fre FARS_ALDER
recode FARS_ALDER 918=17
recode FARS_ALDER 959=60

gen cov_father_age=FARS_ALDER
gen cov_mother_age=MORS_ALDER

*mother's marital status:
gen cov_mother_marstat=SIVST_2 
*keep the labels:
label values cov_mother_marstat SIVST_2

gen cov_male=(KJONN==1)

*birtweight and birth length:
gen cov_birthweight=VEKT
gen cov_birthlength=LENGDE 

*birth weight and length: will need for imputation.
*trim at 4sd from the mean:
foreach var in cov_birthweight cov_birthlength {
summ `var', det
return list
replace `var'=. if `var'<r(mean)-(4*r(sd))
replace `var'=. if `var'>r(mean)+(4*r(sd))
summ `var', det
}

*some people in questionnaires but not in birth registry file.
*make a flag so you can drop them later:
gen present_MBRN=1

keep PREG_ID_2306 BARN_NR cov_mother_marstat cov_father_age cov_mother_age cov_num_previous_preg cov_male cov_birthweight cov_birthlength present_MBRN  DODKAT_G

compress
save "scratch/cov_MBRN",replace

**********************************************************************************************
*Q1: BY MOTHERS AT 17 WEEKS


*Q1: by mothers at 17 weeks 
use "${raw_data}\Statafiles\PDB2306_Q1_v12.dta",clear

*mother's own height and pre-pregnancy weight
*mother's report of partner's height and weight

gen cov_q1_mother_weight=AA85
gen cov_q1_father_weight=AA89
gen cov_q1_mother_height=AA87
gen cov_q1_father_height=AA88

*first drop these implausible outliers:
replace cov_q1_mother_weight=. if cov_q1_mother_weight==573
replace cov_q1_father_weight=. if cov_q1_father_weight==874

foreach var in cov_q1_mother_weight cov_q1_father_weight cov_q1_mother_height cov_q1_father_height{
	qui:summ `var', det
	qui:return list
	di "`var'"
	local max=r(mean)+(4*r(sd))
	local min=r(mean)-(4*r(sd))
	di "Mean=`r(mean)', min=`min' and max=`max''"	
	qui:summ `var', det
	tab `var'
	replace `var'=. if `var'<`min'
	}
	
*now make BMI:
gen cov_q1_mothers_bmi=cov_q1_mother_weight/((cov_q1_mother_height/100)^2)
label variable cov_q1_mothers_bmi "Q1 mother's pre-preg bmi from self-report h & w"
summ cov_q1_mothers_bmi, det
*looks acceptable
gen cov_q1_fathers_bmi=cov_q1_father_weight/((cov_q1_father_height/100)^2)
label variable cov_q1_fathers_bmi "Q1 father's bmi from mother's self-report h & w"
summ cov_q1_fathers_bmi, det
*looks acceptable

*demographic variables:
fre AA1123 AA1124 AA1125 AA1126 AA1127

*marital status:
gen cov_q1_marital_status=AA1123 
*remove the >1 box checked people
recode cov_q1_marital_status 0=.
*some tiny groups which might mess with the impuation but let's see. Can merge if necessary

*mother's educ, finished and ongoing:
gen cov_q1_mother_educ=AA1124
replace cov_q1_mother_educ=AA1125-1 if cov_q1_mother_educ==.
*recode the new 0s to 1:
recode cov_q1_mother_educ 0=1
*label as original
label list AA1124
label values cov_q1_mother_educ AA1124
fre cov_q1_mother_educ

*father's educ, finished and ongoing:
gen cov_q1_father_educ=AA1126
replace cov_q1_father_educ=AA1127-1 if cov_q1_father_educ==.
recode cov_q1_father_educ 0=1
label values cov_q1_father_educ AA1124
fre cov_q1_father_educ

*smoking?
fre AA1328-AA1357
*clean them

*make a grouped smoking variable for mums:
capture drop cov_q1_mumsmokes
gen cov_q1_mumsmokes=.
label var cov_q1_mumsmokes "mother's smoking status at 17 weeks"
label define cov_q1_mumsmokes 0"never" 1"pre-pregnanacy" 2"during, sometimes" 3"during, daily"
*using these two:
fre AA1355 AA1356
label values cov_q1_mumsmokes cov_q1_mumsmokes
replace cov_q1_mumsmokes=0 if AA1355==1
*then for other groups:
replace cov_q1_mumsmokes=1 if AA1355!=1 & AA1356==1 
replace cov_q1_mumsmokes=2 if AA1356==2 
replace cov_q1_mumsmokes=3 if AA1356==3 
*check it
fre cov_q1_mumsmokes
tab cov_q1_mumsmokes AA1355
tab cov_q1_mumsmokes AA1356
*only 73 could be saved by faffing with the dual-tick categs so leave it:
tab AA1355 AA1356 if cov_q1_mumsmokes==.

*mother's smoking: collapse the 3rd and fourth categories?
fre cov_q1_mumsmokes
gen cov_q1_mumsmokes_v2=cov_q1_mumsmokes
recode cov_q1_mumsmokes_v2 3=2
label define cov_q1_mumsmokes_v2 0"never" 1"pre-pregnancy" 2"during"
label values cov_q1_mumsmokes_v2 cov_q1_mumsmokes_v2
fre cov_q1_mumsmokes_v2

*and for dads?
tab AA1353 AA1354
gen cov_q1_dadsmokes=.
label var cov_q1_dadsmokes "mother report of dad's smoking status at 17 weeks"
label define cov_q1_dadsmokes 0"not before pregnancy" 1"stopped during pregnanacy" 2"during preganacy"
label values cov_q1_dadsmokes cov_q1_dadsmokes
replace cov_q1_dadsmokes=0 if AA1353==1
replace cov_q1_dadsmokes=1 if AA1353==2 & AA1354==1
replace cov_q1_dadsmokes=2 if AA1354==2
fre cov_q1_dadsmokes
tab AA1353 AA1354 if cov_q1_dadsmokes==0
tab AA1353 AA1354 if cov_q1_dadsmokes==1
tab AA1353 AA1354 if cov_q1_dadsmokes==2
*looks ok.

*other socioeconomic/ demographic stuff:
*mum's employment:
fre AA1348-AA1473

*income, financial difficulty
fre AA1315 AA1316 AA1317
*last one needs fixing
recode AA1317 0=.
*change the dont know in mother's report of partner's income to missing:
recode AA1316  8=.

*there's also stuff about housing type, but leave for now.
fre AA1318-AA1328 

keep PREG_ID_2306 cov_* AA1126 AA1348-AA1473 AA1315 AA1316 AA1317

*full variables about smoking, alcohol and drugs
fre AA1348-AA1473

*presence flag:
gen present_Q1=1

compress

save "scratch/cov_q1",replace

**********************************************************************************************
*QF: first fathers questionnaire, 17 week

use "${raw_data}\Statafiles\PDB2306_QF_v12.dta",clear

keep PREG_ID_2306 FF333 FF334 FF15 FF16 FF17 FF214 FF215 FF341

*presence flag:
gen present_QF=1

*clean demographoc variables:
*marital status:
recode FF15 0=.
*income, grouped:
recode FF341 0=.
*completed education
recode FF16 0=.
*ongoing education:
recode FF17 0=.

*rename and keep marital status
rename FF15 cov_FF15

*rename and keep income
rename FF341 cov_qf_income

*NOTE Very low response rates to height and weight for dads

*FF333 FF334: current height and weight
gen cov_qf_father_height_sr=FF333
gen cov_qf_father_weight_sr=FF334

*TRIM AT +/- 4SD FROM THE MEAN
*no obvious single observations to remove
foreach var in cov_qf_father_height_sr cov_qf_father_weight_sr{
	qui:summ `var', det
	qui:return list
	di "`var'"
	local max=r(mean)+(4*r(sd))
	local min=r(mean)-(4*r(sd))
	di "Mean=`r(mean)', min=`min' and max=`max''"	
	qui:summ `var', det
	tab `var'
	replace `var'=. if `var'<`min'
	}

*bmi from current height and weight
gen cov_qf_fathers_bmi_sr=cov_qf_father_weight_sr/((cov_qf_father_height_sr/100)^2)
label variable cov_qf_fathers_bmi_sr "QF father's bmi from self-report current h & w"
summ cov_qf_fathers_bmi_sr, det


*smoking status
tab FF214 FF215
gen cov_qf_dadsmokes=.
label var cov_qf_dadsmokes "father report of dad's smoking status at 17 weeks"
label define cov_qf_dadsmokes 0"not before pregnancy" 1"stopped during pregnanacy" 2"during preganacy"
label values cov_qf_dadsmokes cov_qf_dadsmokes
replace cov_qf_dadsmokes=0 if FF214==1
replace cov_qf_dadsmokes=1 if FF214==2 & FF215==1
replace cov_qf_dadsmokes=2 if FF215==2 | FF215==3
fre cov_qf_dadsmokes
tab FF214 FF215 if cov_qf_dadsmokes==0
tab FF214 FF215 if cov_qf_dadsmokes==1
tab FF214 FF215 if cov_qf_dadsmokes==2
*looks ok.

*completed education, including ongoing study:
gen cov_qf_father_educ_sr=FF16
fre FF17 if FF16==.
replace cov_qf_father_educ_sr=FF17-1 if FF16==. 
*recode the new 0s to 1
recode cov_qf_father_educ_sr 0=1
*label as original
label list FF16
label values cov_qf_father_educ_sr FF16
fre cov_qf_father_educ_sr

compress
keep PREG cov_* present_QF 

*remove for people whose fathers withdrew consent:
merge m:1 PREG_ID_2306 using "data\PDB2306_SV_INFO_v12_fathers.dta"
keep if fathers_consent==1
*99 dropped
drop _merge
save "scratch/cov_qf",replace


**********************************************************************************************
*Q5: Lots of stuff on both parents and kids for imputation

use "${raw_data}\Statafiles\PDB2306_Q5_18months_v12.dta",clear 
 
*presence flag:
gen present_Q5=1

**About the child:

*EAS: Temperament
*fix multiple ticks:
fre EE416 EE417 EE418 EE419 EE420 EE421 EE422 EE423 EE424 EE425 EE426 EE877 EE878
foreach var of varlist EE416 EE417 EE418 EE419 EE420 EE421 EE422 EE423 EE424 EE425 EE426 EE877 EE878 {
	recode `var' 0=.
	gen out_q5yrs_eas_`var'=`var'
	}

	
*Q35/36: ESAT
*Selective questions from Early Screening of Autistic Traits Questionnaire (ESAT)
*NB: questions VARY A LOT BETWEEN THE A B AND C VERSIONS...
fre EE886  EE433 EE887 EE888 EE889 EE890 EE891 EE892 EE893 EE894 EE895 EE896 EE960 EE897
*fix multiple ticks
foreach var of varlist EE886 EE433 EE887 EE888 EE889 EE890 EE891 EE892 EE893 EE894 EE895 EE896 EE960 EE897 {
	recode `var' 0=.
	fre `var'
	gen out_q5yrs_esat_`var'=`var'
	}
	
*These three are from other scales – the SCQ-Social communication questionnaire and Communication and Symbolic Behaviour Scales – and seem to have been asked for everyone:
fre EE898 EE884 EE885
*fix multiple ticks
foreach var of varlist EE898 EE884 EE885 {
	recode `var' 0=.
	fre `var'
	gen out_q5yrs_scq_social_`var'=`var'
	}
	
*35/36. Autistic Traits: M-CHAT
*The Modified Checklist for Autism in Toddlers (M-CHAT)
*NB: questions VARY A LOT BETWEEN THE A B AND C VERSIONS...
*These three are pairs: EE427/EE1005 EE432/997 EE986/406
tab EE427 EE1005, mi
tab EE432 EE997, mi
tab EE986 EE406, mi
*not sure what that means...
gen EE432_EE997=EE997
replace EE432_EE997=EE432 if EE997==.
tab EE432_EE997

*fix multiple ticks
foreach var of varlist EE427 EE1005 EE434 EE429 EE430 EE431 EE998 EE432 EE997 EE432_EE997 EE433 EE428 EE1006 EE900 EE1000 EE879 EE901 EE882 EE986 EE406 EE1001 EE880 EE881 EE1002 EE899 EE833 EE902 {
	recode `var' 0=.
	fre `var'
	gen out_q5yrs_m_chat_`var'=`var'
	}
	
*37. Child Behaviour CheckList (CBCL)
fre EE435 EE961 EE903 EE904 EE905 EE438 EE439 EE962 EE442 EE446 EE447 EE448 EE963 EE964 EE906 EE440 EE907 EE908 EE909
		*fix multiple ticks
foreach var of varlist EE435 EE961 EE903 EE904 EE905 EE438 EE439 EE962 EE442 EE446 EE447 EE448 EE963 EE964 EE906 EE440 EE907 EE908 EE909 {
	recode `var' 0=.
	fre `var'
	gen out_q5yrs_cbcl_`var'=`var'
	}
	
*40. Mother’s concerns
*EE915 EE953 for other concerns not included. Perhaps disclosive?
fre EE910 EE911 EE912 EE913 EE1007 EE914  
*fix multiple ticks
foreach var of varlist EE910 EE911 EE912 EE913 EE1007 EE914  {
	recode `var' 0=.
	fre `var'
	gen out_q5yrs_mo_concerns_`var'=`var'
	}

keep PREG BARN present out_*
compress
save "scratch/out_q5_18month",replace

**********************************************************************************************

*Questionnaire 6, Age 3:
*there is info on the child's height and weight, the age the report relates to and who made the measurement, but is this even relevant?
use "${raw_data}\Statafiles\PDB2306_Q6_3yrs_v12.dta",clear 

keep PREG_ID BARN_NR GG435 GG501 GG502 GG479-GG488 GG37 GG38 GG39 GG40 GG93 GG94 GG95 GG96 GG578 GG579 GG580 GG581 GG109   GG105 GG106 GG107 GG108 GG101 GG582 GG102 GG583 GG103 GG584 GG104 GG585 GG109 GG110 GG111 GG112 ///
GG222 GG223 GG224 GG225 GG237 GG238 GG239 GG240 GG241 GG242 ///
GG227 GG228 GG229 GG230 ///
GG231 GG232 GG233 GG234 GG235 GG236 ///
GG243 GG244 GG245 GG246 GG247 GG248 GG249 GG250 GG251 GG592 GG252 GG253 GG254 ///
GG255 GG257 GG258 GG259 GG260 GG261 GG262 GG263 GG264 GG265 GG266 GG267 GG268 GG269 GG270 GG271 GG272 GG273 GG274 GG256 GG275 GG276 GG277 GG278 GG279 GG280 GG281 GG282 GG283 GG284 GG285 GG286 GG287 GG288 GG289 GG290 GG291 GG292 GG293 GG294 ///
GG295 GG296 GG297 GG298 ///
GG299 GG300 GG301 GG302 GG303 GG304 GG305 GG306 GG307 GG308 GG309 GG310 GG311 GG312 ///
GG313 GG314 GG315 GG316 GG317 GG318 GG319 GG320 GG321 GG322 GG323 GG324 GG325 GG326 GG327 GG328 GG329 GG330 GG331 GG332 GG333 GG334 GG335 GG336 GG337 GG338 ///
GG339 GG340 GG341 GG342 GG343 GG344 GG345 GG346 GG347 GG348 ///
GG349 GG350 GG351 GG352 GG353 GG354 GG355 GG356 GG357 GG358 GG359 GG360 GG361 GG362 GG363 GG364 GG365 GG366 GG367 GG236 ///
GG380 GG381 GG382 GG594 GG595  ///
GG388 GG389 ///
GG452 GG634 GG635 GG636 GG637 GG453 GG638 GG639 GG640 GG641 GG454 GG642 GG643 GG644 GG645 GG455 GG646 GG647 GG648 GG649 GG456 GG650 GG651 GG652 GG653 GG457 GG654 GG655 GG656 GG657 ///
GG462 GG658 GG659 GG660 GG661 GG662 GG663  ///
GG491 GG492 GG493 GG494  GG495 GG496 GG497 GG498 GG499  GG500 GG501 GG502 ///
GG503 GG504 GG505 GG506 GG507 GG508 ///
GG514 GG515 GG516 GG517 GG518 GG519 GG520 GG521 ///
GG600 GG601 GG602 GG603 GG604 GG605 ///
GG606 GG607 GG608 GG609 GG610 GG611 ///
GG612 GG613 GG614 GG615

*presence flag:
gen present_Q6=1
fre present_Q6

*About the child

*Q3 long-term illness
label define Q6_longtermprob 0"no" 1"yes, now" 2"yes, previously"
*3. Delayed motor development (e.g. sits/walks late) 	
fre GG37 	GG38 	GG39 	GG40
*No
*yes now
*yes previously
*combine:
gen out_q6_delayed_motor=.
replace out_q6_delayed_motor=0 if GG37==1
replace out_q6_delayed_motor=1 if GG38==1
replace out_q6_delayed_motor=2 if GG39==1
label values out_q6_delayed_motor Q6_longtermprob 
fre out_q6_delayed_motor
tab1 GG37 GG38 GG39 if out_q6_delayed_motor==. 
*nothing on those ones

*19. Late or abnormal speech development 	
fre GG93 GG94 GG95 GG96 
gen out_q6_delayed_speech=.
replace out_q6_delayed_speech=0 if GG93==1
replace out_q6_delayed_speech=1 if GG94==1
replace out_q6_delayed_speech=2 if GG95==1
label values out_q6_delayed_speech Q6_longtermprob 
fre out_q6_delayed_speech
tab1 GG93 GG94 GG95 if out_q6_delayed_speech==. 

forvalues i=243(1)254{
		fre GG`i'
	}

*Q22 & Q23: ESAT and MoBA-specific ASD screen questions:
*fix multiple ticks
foreach var in GG249 GG250 GG592 GG252 GG253 GG254 {
	recode `var' 0=.
	fre `var'
	gen out_q6_asd_`var'=`var'
	}
*cell sizes might be a bit too small to be useful

*Trouble relating to others
fre GG578 GG579 GG580 GG581 
gen out_q6_trouble_relating=.
replace out_q6_trouble_relating=0 if GG578==1
replace out_q6_trouble_relating=1 if GG579==1
replace out_q6_trouble_relating=2 if GG580==1
label values out_q6_trouble_relating Q6_longtermprob 
fre out_q6_trouble_relating
tab1 GG578 GG579 GG580 if out_q6_trouble_relating==. 

*hyperactivity
fre GG105 GG106 GG107 GG108 
gen out_q6_hyperactivity=.
replace out_q6_hyperactivity=0 if GG105==1
replace out_q6_hyperactivity=1 if GG106==1
replace out_q6_hyperactivity=2 if GG107==1
label values out_q6_hyperactivity Q6_longtermprob 
fre out_q6_hyperactivity
tab1 GG105 GG106 GG107 if out_q6_hyperactivity==. 

/*
####################################
*###THIS NEEDS CHECKING - COME BACK TO IT
*autistic traits: VERSION DIFFERENCES
fre GG101 GG582 GG102 GG583 GG103 GG584 GG104 GG585 
tab1 GG101 GG582
tab1 GG102 GG583
tab1 GG103 GG584 
####################################
*/

gen out_q6_autistic_traits=.
replace out_q6_autistic_traits=0 if GG101==1 | GG582==1
replace out_q6_autistic_traits=1 if GG102==1 | GG583==1
replace out_q6_autistic_traits=2 if GG103==1 | GG584==1
label values out_q6_autistic_traits Q6_longtermprob 
fre out_q6_autistic_traits
tab1 GG101 GG582 GG102 GG583 GG103 GG584 GG104 GG585  if out_q6_autistic_traits==.

*other behavioural problems
fre GG109 GG110 GG111 GG112 
gen out_q6_other_behavioural=.
replace out_q6_other_behavioural=0 if GG109==1
replace out_q6_other_behavioural=1 if GG110==1
replace out_q6_other_behavioural=2 if GG111==1
label values out_q6_other_behavioural Q6_longtermprob 
fre out_q6_other_behavioural
tab1 GG109 GG110 GG111 if out_q6_other_behavioural==.

*17 & 21: ages and stages questionnaire:
fre GG222 GG223 GG224 GG225 GG237 GG238 GG239 GG240 GG241 GG242
*fix multiple ticks
foreach var of varlist GG222 GG223 GG224 GG225 GG237 GG238 GG239 GG240 GG241 GG242  {
	recode `var' 0=.
	fre `var'
	gen out_q6_age_stage_`var'=`var'
	}
	
*19 non verbal communication checklist
fre GG227 GG228 GG229 GG230
*fix multiple ticks
foreach var of varlist GG227 GG228 GG229 GG230  {
	recode `var' 0=.
	fre `var'
	gen out_q6_non_verbal_comms_`var'=`var'
	}
	
*20: strengths and difficulties questionnaire
fre GG231 GG232 GG233 GG234 GG235 GG236
*fix multiple ticks
foreach var of varlist GG231 GG232 GG233 GG234 GG235 GG236  {
	recode `var' 0=. 2=1 3=0 1=2
	fre `var'
	gen out_q6_sdq_`var'=`var'
	}
egen out_q6_prosocial=rowtotal(GG231 GG232 GG233 GG234 GG235)
	
	
*22. Autistic Traits Part I: Modified Checklist for Autism in Toddlers (M-CHAT)  
fre GG243 GG244 GG245 GG246 GG247 GG248 GG251
*fix multiple ticks
foreach var of varlist GG243 GG244 GG245 GG246 GG247 GG248  GG251  {

	recode `var' 0=.
	fre `var'
	gen out_q6_m_chat_`var'=`var'
	}


************************************************************

*23-25. Social Communication Questionnaire (SCQ) 36 months
foreach var of varlist GG255 GG257 GG258 GG259 GG260 GG261 GG262 GG263 GG264 GG265 GG266 GG267 GG268 GG269 GG270 GG271 GG272 GG273 GG274 GG256 GG275 GG276 GG277 GG278 GG279 GG280 GG281 GG282 GG283 GG284 GG285 GG286 GG287 GG288 GG289 GG290 GG291 GG292 GG293 GG294  {
recode `var' 0=.
fre `var'
}
*same as at Q8yr -items are identical

*reverse code the SCQ variables NN152,NN153,NN154,NN155,NN156,NN157,NN159,NN160,NN161,NN162,NN163,NN164,NN165,NN166,NN167
foreach var in GG258 GG259 GG260 GG261 GG262 GG263 GG265 GG266 GG267 GG268 GG269 GG270 GG271 GG272 GG273 {
fre `var'
gen r`var'=`var'
recode r`var' 2=0
replace r`var'=r`var'+1
}
*inspect
tab GG258 rGG258, nol
*ok.

*missigness counter and summary scores:
*full scale:
gen nitems_SCQ_Q6=0
foreach var of varlist GG255 GG257 rGG258 rGG259 rGG260 rGG261 rGG262 rGG263 GG264 rGG265 rGG266 rGG267 rGG268 rGG269 rGG270 rGG271 rGG272 rGG273 GG274 GG256 GG275 GG276 GG277 GG278 GG279 GG280 GG281 GG282 GG283 GG284 GG285 GG286 GG287 GG288 GG289 GG290 GG291 GG292 GG293 GG294 {
replace nitems_SCQ_Q6=nitems_SCQ_Q6+1 if `var'!=.
}
fre nitems_SCQ_Q6 if present_Q6==1
*social
gen nitems_S_SCQ_Q6=0
foreach var of varlist GG255 GG257 rGG259 GG264 rGG265 GG274 GG256 GG275 GG276 GG277 GG278 GG279 GG280 GG281 GG282 GG283 GG284 GG285 GG286 GG287 GG288 GG290 GG291 GG292 GG293 GG294 {
replace nitems_S_SCQ_Q6=nitems_S_SCQ_Q6+1 if `var'!=.
}
fre nitems_S_SCQ_Q6 if present_Q6==1
*repetitive
gen nitems_R_SCQ_Q6=0
foreach var of varlist rGG258 rGG260 rGG261 rGG262 rGG263 rGG266 rGG267 rGG268 rGG269 rGG270 rGG271 rGG273 {
replace nitems_R_SCQ_Q6=nitems_R_SCQ_Q6+1 if `var'!=.
}
fre nitems_R_SCQ_Q6 if present_Q6==1

*not included in either:
tab1 rGG272 GG289 

*summary scales:
*full scale:
gen cc_SCQ_Q6 =(GG255 + GG257 + rGG258 + rGG259 + rGG260 + rGG261 + rGG262 + rGG263 + GG264 + rGG265 + rGG266 + rGG267 + rGG268 + rGG269 + rGG270 + rGG271 + rGG272 + rGG273 + GG274 + GG256 + GG275 + GG276 + GG277 + GG278 + GG279 + GG280 + GG281 + GG282 + GG283 + GG284 + GG285 + GG286 + GG287 + GG288 + GG289 + GG290 + GG291 + GG292 + GG293 + GG294)
*bump down to start at 0
replace cc_SCQ_Q6=cc_SCQ_Q6-40 
summ cc_SCQ_Q6
*social:
gen cc_S_SCQ_Q6 =(GG255 + GG257 + rGG259 + GG264 + rGG265 + GG274 + GG256 + GG275 + GG276 + GG277 + GG278 + GG279 + GG280 + GG281 + GG282 + GG283 + GG284 + GG285 + GG286 + GG287 + GG288 + GG290 + GG291 + GG292 + GG293 + GG294)
*bump down to start at 0
replace cc_S_SCQ_Q6=cc_S_SCQ_Q6-26
summ cc_S_SCQ_Q6
*repetitive
gen cc_R_SCQ_Q6 =(rGG258 + rGG260 + rGG261 + rGG262 + rGG263 + rGG266 + rGG267 + rGG268 + rGG269 + rGG270 + rGG271 + rGG273)
*bump down to start at 0
replace cc_R_SCQ_Q6=cc_R_SCQ_Q6-12
summ cc_R_SCQ_Q6


*full scale:
egen miss20pc_SCQ_Q6 =rowtotal (GG255 GG257 rGG258 rGG259 rGG260 rGG261 rGG262 rGG263 GG264 rGG265 rGG266 rGG267 rGG268 rGG269 rGG270 rGG271 rGG272 rGG273 GG274 GG256 GG275 GG276 GG277 GG278 GG279 GG280 GG281 GG282 GG283 GG284 GG285 GG286 GG287 GG288 GG289 GG290 GG291 GG292 GG293 GG294)
replace miss20pc_SCQ_Q6=miss20pc_SCQ_Q6*(40/39) if nitems_SCQ_Q6==39
replace miss20pc_SCQ_Q6=miss20pc_SCQ_Q6*(40/38) if nitems_SCQ_Q6==38
replace miss20pc_SCQ_Q6=miss20pc_SCQ_Q6*(40/37) if nitems_SCQ_Q6==37
replace miss20pc_SCQ_Q6=miss20pc_SCQ_Q6*(40/36) if nitems_SCQ_Q6==36
replace miss20pc_SCQ_Q6=miss20pc_SCQ_Q6*(40/35) if nitems_SCQ_Q6==35
replace miss20pc_SCQ_Q6=miss20pc_SCQ_Q6*(40/34) if nitems_SCQ_Q6==34
replace miss20pc_SCQ_Q6=miss20pc_SCQ_Q6*(40/33) if nitems_SCQ_Q6==33
replace miss20pc_SCQ_Q6=miss20pc_SCQ_Q6*(40/32) if nitems_SCQ_Q6==32
replace miss20pc_SCQ_Q6=. if nitems_SCQ_Q6<32
*bump down to start at 0
replace miss20pc_SCQ_Q6=miss20pc_SCQ_Q6-40 
fre miss20pc_SCQ_Q6
tab miss20pc_SCQ_Q6 cc_SCQ_Q6, mi

*social:
egen miss20pc_S_SCQ_Q6 =rowtotal(GG255 GG257 rGG259 GG264 rGG265 GG274 GG256 GG275 GG276 GG277 GG278 GG279 GG280 GG281 GG282 GG283 GG284 GG285 GG286 GG287 GG288 GG290 GG291 GG292 GG293 GG294)
replace miss20pc_S_SCQ_Q6=miss20pc_S_SCQ_Q6*(26/25) if nitems_S_SCQ_Q6==25
replace miss20pc_S_SCQ_Q6=miss20pc_S_SCQ_Q6*(26/24) if nitems_S_SCQ_Q6==24
replace miss20pc_S_SCQ_Q6=miss20pc_S_SCQ_Q6*(26/23) if nitems_S_SCQ_Q6==23
replace miss20pc_S_SCQ_Q6=miss20pc_S_SCQ_Q6*(26/22) if nitems_S_SCQ_Q6==22
replace miss20pc_S_SCQ_Q6=miss20pc_S_SCQ_Q6*(26/21) if nitems_S_SCQ_Q6==21
replace miss20pc_S_SCQ_Q6=. if nitems_S_SCQ_Q6<21
fre miss20pc_S_SCQ_Q6
*bump down to start at 0
replace miss20pc_S_SCQ_Q6=miss20pc_S_SCQ_Q6-26
fre miss20pc_S_SCQ_Q6
tab miss20pc_S_SCQ_Q6 cc_S_SCQ_Q6, mi

*repetitive
egen miss20pc_R_SCQ_Q6 =rowtotal(rGG258 rGG260 rGG261 rGG262 rGG263 rGG266 rGG267 rGG268 rGG269 rGG270 rGG271 rGG273)
replace miss20pc_R_SCQ_Q6=miss20pc_R_SCQ_Q6*(12/11) if nitems_R_SCQ_Q6==11
replace miss20pc_R_SCQ_Q6=miss20pc_R_SCQ_Q6*(12/10) if nitems_R_SCQ_Q6==10
replace miss20pc_R_SCQ_Q6=. if nitems_R_SCQ_Q6<10
fre miss20pc_R_SCQ_Q6
*bump down to start at 0
replace miss20pc_R_SCQ_Q6=miss20pc_R_SCQ_Q6-12
fre miss20pc_R_SCQ_Q6
tab miss20pc_R_SCQ_Q6 cc_R_SCQ_Q6, mi

*rename these to be the default:
foreach varstem in SCQ_Q6 S_SCQ_Q6 R_SCQ_Q6 {
	rename miss20pc_`varstem' `varstem'
}

************************************************************

*26. loss of skills
fre GG295 GG296 GG297 GG298
*fix multiple ticks
foreach var of varlist GG295 GG296 GG297 GG298  {
	recode `var' 0=.
	fre `var'
	gen out_q6_loss_skill_`var'=`var'
	}
	
*27. Temperament
fre GG299 GG300 GG301 GG302 GG303 GG304 GG305 GG306 GG307 GG308 GG309 GG310 GG311 GG312
*fix multiple ticks
foreach var of varlist GG299 GG300 GG301 GG302 GG303 GG304 GG305 GG306 GG307 GG308 GG309 GG310 GG311 GG312 {
	recode `var' 0=.
	fre `var'
	gen out_q6_tempera_`var'=`var'
	}

*28. Child Behaviour Checklist (CBCL)
fre GG313 GG314 GG315 GG316 GG317 GG318 GG319 GG320 GG321 GG322 GG323 GG324 GG325 GG326 GG327 GG328 GG329 GG330 GG331 GG332 GG333 GG334 GG335 GG336 GG337 GG338
*fix multiple ticks
foreach var of varlist GG313 GG314 GG315 GG316 GG317 GG318 GG319 GG320 GG321 GG322 GG323 GG324 GG325 GG326 GG327 GG328 GG329 GG330 GG331 GG332 GG333 GG334 GG335 GG336 GG337 GG338 GG309 GG310 GG311 GG312 {
	recode `var' 0=.
	fre `var'
	gen out_q6_cbcl_`var'=`var'
	}

	
foreach var of varlist  GG317 GG336 GG328 GG322 {
	recode `var' 0=. 1=0 2=1 3=2
	fre `var'
	gen out_q6_sdq_`var'=`var'
	}
egen out_q6_cbcl_anxiety=rowtotal( GG317 GG336 GG328 GG322)
	

*29. Part I: Child Behavior and Manner
fre GG339 GG340 GG341 GG342 GG343 GG344 GG345 GG346 GG347 GG348
*fix multiple ticks
foreach var of varlist GG339 GG340 GG341 GG342 GG343 GG344 GG345 GG346 GG347 GG348 {
	recode `var' 0=.
	fre `var'
	gen out_q6_cbm_`var'=`var'
	}

*29. Part II: The Infant-Toddler Social and Emotional Assessment (ITSEA)
fre GG349 GG350 GG351 GG352 GG353 GG354 GG355 GG356 GG357 GG358 GG359 GG360 GG361 GG362 GG363 GG364 GG365 GG366 GG367 GG236
*fix multiple ticks
foreach var of varlist GG349 GG350 GG351 GG352 GG353 GG354 GG355 GG356 GG357 GG358 GG359 GG360 GG361 GG362 GG363 GG364 GG365 GG366 GG367 GG236 {
	recode `var' 0=.
	fre `var'
	gen out_q6_itsea_`var'=`var'
	}

*31. Maternal Concerns
*GG596 not there
fre GG380 GG381 GG382 GG594 GG595 
*fix multiple ticks
foreach var of varlist GG380 GG381 GG382 GG594 GG595  {
	recode `var' 0=.
	fre `var'
	gen out_q6_mat_con_`var'=`var'
	}

*34-35. Brushing Teeth
*these variable not there. weird.
*fre GG386 GG387

*36 Is your child ever present in a room where someone smokes?
fre GG388 GG389
recode GG388 0=.
gen out_q6_passive_smoke=GG388
replace out_q6_passive_smoke=(out_q6_passive_smoke==1|out_q6_passive_smoke==2|out_q6_passive_smoke==3) if out_q6_passive_smoke!=.& out_q6_passive_smoke!=4
replace out_q6_passive_smoke=. if out_q6_passive_smoke==4
*an 0 in the other one is legit

*******************************

*update 1/11/22: changed the below to be consistent between reverse and forward-coded items for the SCQ:
foreach var in GG255 GG257 GG258 GG259 GG260 GG261 GG262 GG263 GG264 GG265 GG266 GG267 GG268 GG269 GG270 GG271 GG272 GG273 GG274 GG256 GG275 GG276 GG277 GG278 GG279 GG280 GG281 GG282 GG283 GG284 GG285 GG286 GG287 GG288 GG289 GG290 GG291 GG292 GG293 GG294 {
rename `var' out_q6_scq_`var'
}
*as well as the line which was already there:
renpfix rGG out_q6_scq_rGG


foreach i in cc_SCQ_Q6 cc_S_SCQ_Q6 cc_R_SCQ_Q6 SCQ_Q6 S_SCQ_Q6 R_SCQ_Q6{
	rename `i' out_q6_`i'
}

*better not to trim here
*keep PREG BARN_NR  present_Q6- out_q6_passive_smoke

*********************************************************************

*LAST THING: PHRASE SPEECH AT AGE 3 USED AS ID INDICATOR.

*for ID, can stratify on whether phrase speech at 36 months.

*yes vs sometimes/not yet:
fre GG239
*fix multiple ticks:
gen phrasespeech_36m=GG239
recode phrasespeech_36m 0=.
*condense other categories:
recode phrasespeech_36m 2/3=0
label define phrasespeech_36m 0"no" 1"yes"
label values phrasespeech_36m phrasespeech_36m
fre phrasespeech_36m

fre out_q6_scq_rGG272 out_q6_scq_GG289


compress
save "scratch/out_q6_3yrs",replace


*****************************************************************************************************************

*Age 5:

/*
Clean the age 5 outcomes
Education-> learning
 
Age 5 (documentation here)
Preschool Activities: Experiences with Letter and Sound Knowledge
Preschool Activities: Literacy Skills
Preschool Activities: Home Reading
*/
/*
use "N:\durable\data\MoBaPhenoData\PDB2306_MoBa_v12\Statafiles\PDB2306_Q5yrs_v12.dta"
keep PREG_ID_2306 BARN_NR LL222-LL231
gen present_Q5yrs=1
fre present_Q5yrs

ds LL*
fre LL*
*fix multiple ticks:
foreach var of varlist LL222-LL231 {
	recode `var' 0=.
}
*make summary score for narrative/communication skills:
fre LL222 LL223
gen out_q5yrs_comm_narr=LL222+LL223-2
label variable out_q5yrs_comm_narr "q5y parent-rated communication/narrative skills: LL222+LL223"
fre out_q5yrs_comm_narr

*make summary score for experiences with letters and sounds:
gen out_q5yrs_teach_letters=LL224+LL225-2
label variable out_q5yrs_teach_letters "q5y experiences with teaching letters and sounds: LL224+LL225"
fre out_q5yrs_teach_letters

*make summary score for literacy:
gen out_q5yrs_child_literacy=LL226+LL227+LL228+LL229+LL230-5
label variable out_q5yrs_child_literacy "q5 child's interest in writing, reading: LL226+LL227+LL228+LL229+LL230"
fre out_q5yrs_child_literacy

*does the child enjoy being read to:
gen out_q5yrs_enjoy_read_to=LL231-1
//Set to zero if they're never read to.
replace out_q5yrs_enjoy_read_to=0 if out_q5yrs_enjoy_read_to==5
label variable out_q5yrs_enjoy_read_to "q5 does the child enjoy being read to: LL231"
fre out_q5yrs_enjoy_read_to

keep PREG BARN  present_Q5yrs out_*
compress
tabstat out_* ,stats(N mean sd min max) c(s) var(30)

save "scratch/out_q5yrs",replace
*/

*##CAN REMOVE ALL THE STUFF BELOW? OR KEEP IN MH STUFF WHICH SHOWS UP AT AGE 8 AS OUTCOMES?

use "${raw_data}\Statafiles\PDB2306_Q5yrs_v12.dta",clear 

keep PREG_ID_2306 BARN_NR ///
LL12 LL13 LL338 LL339 LL508 AGE_SENT_MTHS_Q5AAR AGE_MTHS_Q5AAR AGE_RETURN_MTHS_Q5AAR ///
LL508 LL340- LL515 ///
LL174 LL175 LL176 LL177 LL178 LL179 LL180 ///
LL264 LL265 LL266 LL267 LL268 LL269 LL270 LL271 LL272 LL273 LL274 LL275 ///
LL190 LL191 LL192 LL193 LL194 LL195 LL196 LL197 LL198 LL199 LL200 LL201 LL202 LL203 LL204 LL205 LL206 LL207 LL208 LL209 LL210 LL211 LL212 ///
LL213 LL214 LL215 LL216 LL217 LL218 LL219 LL220 LL221 LL480 LL481 LL482 LL483 ///
LL222 LL223 LL224 LL225 LL226 LL227 LL228 LL229 LL230 LL231 ///
LL232 LL233 LL234 LL235 LL236 LL237 LL238 LL239 LL240 LL241 LL242 LL243 LL244 LL245 LL246 LL247 LL248 LL249 LL250 LL251 ///
LL252 LL253 LL254 LL255 LL256 LL257 LL258 LL259 LL260 LL261 LL262 LL263 ///
LL276 LL277 LL278 LL279 LL280 LL281 LL282 LL283 LL284 LL285 LL286 LL287 ///
LL288 LL289 LL290 LL292 LL293 LL294 LL295 LL296 LL297 LL298 LL299 LL300 ///
LL301 LL302 LL303 LL304 LL305 LL306 LL307 LL308 LL309 LL310 LL311 LL312 LL313 LL314 LL315 LL316 LL317 LL318 LL319 LL320 LL321 LL322 LL323 LL324 LL325 LL504 LL505 ///
LL326 LL327 LL328 LL329 LL330 LL331 LL332 LL333 LL334 LL335 LL336 LL337 ///
LL361 LL362 LL363 ///
LL363 LL364 LL365 LL366 LL367 LL368 LL369 LL370 ///
LL382 LL383 LL384 LL385 LL386 LL387

*presence flag:
gen present_Q5y=1
fre present_Q5y 

*Child reading and literacy
ds LL*
fre LL*
*fix multiple ticks:
foreach var of varlist LL222-LL231 {
	recode `var' 0=.
}
*make summary score for narrative/communication skills:
fre LL222 LL223
gen out_q5yrs_comm_narr=LL222+LL223-2
label variable out_q5yrs_comm_narr "q5y parent-rated communication/narrative skills: LL222+LL223"
fre out_q5yrs_comm_narr

*make summary score for experiences with letters and sounds:
gen out_q5yrs_teach_letters=LL224+LL225-2
label variable out_q5yrs_teach_letters "q5y experiences with teaching letters and sounds: LL224+LL225"
fre out_q5yrs_teach_letters

*make summary score for literacy:
gen out_q5yrs_child_literacy=LL226+LL227+LL228+LL229+LL230-5
label variable out_q5yrs_child_literacy "q5 child's interest in writing, reading: LL226+LL227+LL228+LL229+LL230"
fre out_q5yrs_child_literacy

*does the child enjoy being read to:
gen out_q5yrs_enjoy_read_to=LL231-1
//Set to zero if they're never read to.
replace out_q5yrs_enjoy_read_to=0 if out_q5yrs_enjoy_read_to==5
label variable out_q5yrs_enjoy_read_to "q5 does the child enjoy being read to: LL231"
fre out_q5yrs_enjoy_read_to

*28 & 36. Ages and Stages Questionnaires (ASQ)
fre LL174 LL175 LL176 LL177 LL178 LL179 LL180 
fre LL264 LL265 LL266 LL267 LL268 LL269 LL270 LL271 LL272 LL273 LL274 LL275
**fix multiple ticks
foreach var of varlist LL174 LL175 LL176 LL177 LL178 LL179 LL180 ///
	LL264 LL265 LL266 LL267 LL268 LL269 LL270 LL271 LL272 LL273 LL274 LL275 {
	recode `var' 0=.
	fre `var'
	gen out_q5yrs_asq_`var'=`var'
	}
	
**for imputation, MAKE BINARY VERSIONS FOR THE 3-CATEG ONES - the non-no categories too small to use
label define ASQ_binarized 1"yes" 2"sometimes or not yet"
foreach var of varlist LL174 LL175 LL176 LL177 LL178 LL179 LL180  {
	gen out_q5yrs_asq_`var'_binary=out_q5yrs_asq_`var'
	recode out_q5yrs_asq_`var'_binary 3=2
	label variable out_q5yrs_asq_`var'_binary "ever had this condition, no/yes"
	label values out_q5yrs_asq_`var'_binary ASQ_binarized
	fre out_q5yrs_asq_`var'_binary
}
	

*31. Checklist of 20 Statements about Language-Related Difficulties (Språk20)
fre LL190 LL191 LL192 LL193 LL194 LL195 LL196 LL197 LL198 LL199 LL200 LL201 LL202 LL203 LL204 LL205 LL206 LL207 LL208 LL209 LL210 LL211 LL212
**fix multiple ticks
foreach var of varlist LL190 LL191 LL192 LL193 LL194 LL195 LL196 LL197 LL198 LL199 LL200 LL201 LL202 LL203 LL204 LL205 LL206 LL207 LL208 LL209 LL210 LL211 LL212 {
recode `var' 0=.
fre `var'
}

*32. Children's Communication Checklist-2 Coherence Sub-scale (CCC-2 Coherence)
fre LL213 LL214 LL215 LL216 LL217 LL218 LL219 LL220 LL221 LL480 LL481 LL482 LL483
**fix multiple ticks
foreach var of varlist LL213 LL214 LL215 LL216 LL217 LL218 LL219 LL220 LL221 LL480 LL481 LL482 LL483 {
	recode `var' 0=.
	fre `var'
	gen out_q5yrs_ccc2_`var'=`var'
	}

	
*some of these certainly measure the child's environment rather than ability, but relevant for imputation:
*33. Preschool Activities: Narrative and Communicative SkiLLs
fre  LL222 LL223

*33. Preschool Activities: Experiences with Letter and Sound Knowledge
fre  LL224 LL225

*Preschool Activities: Literacy SkiLLs
fre LL226 LL227 LL228 LL229 LL230

*33. Preschool Activities: Home Reading
fre LL231 

**fix multiple ticks
foreach var of varlist LL222 LL223 LL224 LL225 LL226 LL227 LL228 LL229 LL230 LL231 {
recode `var' 0=.
fre `var'
}	
	
*35a. Childhood Asperger Syndrome Test (CAST)
fre LL232 LL233 LL234 LL235 LL236 LL237 LL238 LL239 LL240 LL241 LL242 LL243 LL244 LL245 LL246 LL247 LL248 LL249 LL250 LL251
**fix multiple ticks
foreach var of varlist LL232 LL233 LL234 LL235 LL236 LL237 LL238 LL239 LL240 LL241 LL242 LL243 LL244 LL245 LL246 LL247 LL248 LL249 LL250 LL251 {
recode `var' 0=.
fre `var'
}


*35. Conners Parent Rating Scale-Revised, Short Form (CPRS-R (S))
fre LL252 LL253 LL254 LL255 LL256 LL257 LL258 LL259 LL260 LL261 LL262 LL263
**fix multiple ticks
foreach var of varlist LL252 LL253 LL254 LL255 LL256 LL257 LL258 LL259 LL260 LL261 LL262 LL263 {
recode `var' 0=.
fre `var'
}
*missigness counter and summary scores:
*missingness
gen nitems_conners_Q5y=0
foreach var of varlist LL252 LL253 LL254 LL255 LL256 LL257 LL258 LL259 LL260 LL261 LL262 LL263 {
replace nitems_conners_Q5y=nitems_conners_Q5y+1 if `var'!=.
}
fre nitems_conners_Q5y if present_Q5y==1
*complete case:
gen cc_conners_Q5y=(LL252 + LL253 + LL254 + LL255 + LL256 + LL257 + LL258 + LL259 + LL260 + LL261 + LL262 + LL263)
*bump down cc scale to start at 0 
replace cc_conners_Q5y=cc_conners_Q5y-12
fre cc_conners_Q5y
*miss20pc version:
*12 items, so make a version allowing up to 2 missing:
egen miss20pc_conners_Q5y=rowtotal(LL252 LL253 LL254 LL255 LL256 LL257 LL258 LL259 LL260 LL261 LL262 LL263)
replace miss20pc_conners_Q5y=miss20pc_conners_Q5y*(12/11) if nitems_conners_Q5y==11
replace miss20pc_conners_Q5y=miss20pc_conners_Q5y*(12/10) if nitems_conners_Q5y==10
replace miss20pc_conners_Q5y=. if nitems_conners_Q5y<10
*bump down cc scale to start at 0 
replace miss20pc_conners_Q5y=miss20pc_conners_Q5y-12
*check these:
tab miss20pc_conners_Q5y cc_conners_Q5y, mi

*rename this to be the default:
foreach varstem in conners_Q5y {
	rename miss20pc_`varstem' `varstem'
}

rename cc_conners_Q5y out_q5yrs_cc_conners
rename conners_Q5y out_q5yrs_conners



*37. Selective items from the Emotionality, Activity and Shyness Temperament Questionnaire (EAS)
fre LL276 LL277 LL278 LL279 LL280 LL281 LL282 LL283 LL284 LL285 LL286 LL287
**fix multiple ticks
foreach var of varlist LL276 LL277 LL278 LL279 LL280 LL281 LL282 LL283 LL284 LL285 LL286 LL287 {
	recode `var' 0=.
	fre `var'
	gen out_q5yrs_eas_`var'=`var'
	}
*38. Speech and Language Assessment Scale (SLAS)
fre LL288 LL289 LL290 LL292 LL293 LL294 LL295 LL296 LL297 LL298 LL299 LL300
**fix multiple ticks
foreach var of varlist LL288 LL289 LL290 LL292 LL293 LL294 LL295 LL296 LL297 LL298 LL299 LL300 {
	recode `var' 0=.
	fre `var'
	gen out_q5yrs_slas_`var'=`var'
	}
	
*39. Child Behaviour Checklist (CBCL)
fre LL301 LL302 LL303 LL304 LL305 LL306 LL307 LL308 LL309 LL310 LL311 LL312 LL313 LL314 LL315 LL316 LL317 LL318 LL319 LL320 LL321 LL322 LL323 LL324 LL325 LL504 LL505
**fix multiple ticks
foreach var of varlist LL301 LL302 LL303 LL304 LL305 LL306 LL307 LL308 LL309 LL310 LL311 LL312 LL313 LL314 LL315 LL316 LL317 LL318 /// 
LL319 LL320 LL321 LL322 LL323 LL324 LL325 LL504 LL505 {
	recode `var' 0=.
	fre `var'
	gen out_q5yrs_cbcl_`var'=`var'
	}

*Q5yr Child Behaviour Checklist (CBCL): make binary versions
foreach var of varlist LL301 LL302 LL303 LL304 LL305 LL306 LL307 LL308 LL309 LL310 LL311 LL312 LL313 LL314 LL315 LL316 LL317 LL318 LL319 LL320 LL321 LL322 LL323 LL324 LL325 LL504 LL505 {
	gen `var'_bin=`var'
	recode `var'_bin 3=2
	tab `var'_bin
}
*Don't use the last two as version-specific - only there for a subset
	
	
*42. Maternal Concerns
fre LL326 LL327 LL328 LL329 LL330 LL331 LL332 LL333 LL334 LL335 LL336 LL337
**fix multiple ticks
*the last is weeks when started so 0 is legit
foreach var of varlist LL326 LL327 LL328 LL329 LL330 LL331 LL332 LL333 LL334 LL335 LL336 {
	recode `var' 0=.
	fre `var'
	gen out_q5yrs_mat_con_`var'=`var'
	}
	

**********************************
*About the mother and father - do they smoke age 5?

capture drop mumsmokes_Q5y
gen mumsmokes_Q5y=LL509
recode mumsmokes_Q5y 4/7=.
*bump down
replace mumsmokes_Q5y=mumsmokes_Q5y-1
label var mumsmokes_Q5y "mother's smoking status a Q5y"
label define mumsmokes_Q5y 0"never" 1"sometimes" 2"daily"
label values mumsmokes_Q5y mumsmokes_Q5y
tab mumsmokes_Q5y LL509

*and for dads?
capture drop dadsmokes_Q5y
gen dadsmokes_Q5y=LL511
recode dadsmokes_Q5y 4/7=.
*bump down
replace dadsmokes_Q5y=dadsmokes_Q5y-1
label var dadsmokes_Q5y "father's smoking status a Q5y"
label define dadsmokes_Q5y 0"never" 1"sometimes" 2"daily"
label values dadsmokes_Q5y dadsmokes_Q5y
tab dadsmokes_Q5y LL511
	
	
compress	
keep PREG BARN present out_* dadsmokes_Q5y mumsmokes_Q5y
save "scratch/out_q5yrs",replace

**************************************************************************************************************

*Age 7:

use "${raw_data}\Statafiles\PDB2306_Q7yrs_v12.dta",clear 
keep PREG BARN JJ300 JJ303

gen present_Q7y=1
fre present_Q7y

*smoking
capture drop mumsmokes_Q7y
gen mumsmokes_Q7y=JJ300
recode mumsmokes_Q7y 4/7=.
*bump down
replace mumsmokes_Q7y=mumsmokes_Q7y-1
label var mumsmokes_Q7y "mother's smoking status at Q7y"
label define mumsmokes_Q7y 0"never" 1"sometimes" 2"daily"
label values mumsmokes_Q7y mumsmokes_Q7y
tab mumsmokes_Q7y JJ300

capture drop dadsmokes_Q7y
gen dadsmokes_Q7y=JJ303
recode dadsmokes_Q7y 4/7=.
*bump down
replace dadsmokes_Q7y=dadsmokes_Q7y-1
label var dadsmokes_Q7y "father's smoking status at Q7y"
label define dadsmokes_Q7y 0"never" 1"sometimes" 2"daily"
label values dadsmokes_Q7y dadsmokes_Q7y
tab dadsmokes_Q7y JJ303

**********************************
keep PREG BARN present 
compress
save "scratch/out_q7yrs",replace
*/
**********************************************************************************************
*Age 8 questionnaire for child phenotypes

use "${raw_data}\Statafiles\PDB2306_Q8yrs_v12.dta",clear 

/* 
Age 8
//Delayed motor
//Delayed language
//Hyperactivity
//Concentration
//Behavioural problems
//Emotional difficulties
//Other conditions
are the above binary variables of parent-reported concern about this problems? Likely to have low power for these outcomes?
 
//DBD – ADHD (included in paper with JB, but there we don't use MR, so ok?)
//DBD – inADHD
//DBD – hyADHD
//DBD OD
//DBD CD
//Anxiety
//MFQ
//SCQ
//SCQ-SCI
//SCQ-RRB

Teacher rating
Hours homework
Help after school work
Hours help with school work
How often do you read to your child? NN262
How long does your child like to sit still and be read for? NN263/NN385
Child mastery (is this 28. Reading and Writing Skills?)
Language skills
*/

gen present_Q8y=1
fre present_Q8y

*Q9 Has your child ever had any of the following health problems? 
*no / yes currently / yes in past + seen as specialist (y/n)
*for all of these, first three items are tick vs no tick so missing includes nos.
*code as you did for equivalent questions at Q6, and use the same label
*label define Q6_longtermprob 0"no" 1"yes, now" 2"yes, previously"

*1. Delayed psychomotor development 	
fre NN36 	NN37 	NN38 	NN39 
*No
*yes now
*yes previously
*combine:
gen out_q8yrs_delayed_motor=.
replace out_q8yrs_delayed_motor=0 if NN36==1
replace out_q8yrs_delayed_motor=1 if NN37==1
replace out_q8yrs_delayed_motor=2 if NN38==1
label values out_q8yrs_delayed_motor Q6_longtermprob 
fre out_q8yrs_delayed_motor
tab1 NN36 NN37 NN38 if out_q8yrs_delayed_motor==.
*nothing on those ones

*2. Delayed or abnormal language development 	
fre NN40 	NN41 	NN42 	NN43
gen out_q8yrs_delayed_language=.
replace out_q8yrs_delayed_language=0 if NN40==1
replace out_q8yrs_delayed_language=1 if NN41==1
replace out_q8yrs_delayed_language=2 if NN42==1
label values out_q8yrs_delayed_language Q6_longtermprob 
fre out_q8yrs_delayed_language
tab1 NN40 NN41 NN42 if out_q8yrs_delayed_language==.
 
*3. Hyperactivity 	
fre NN44 	NN45 	NN46 	NN47 
gen out_q8yrs_hyperactivity=.
replace out_q8yrs_hyperactivity=0 if NN44==1
replace out_q8yrs_hyperactivity=1 if NN45==1
replace out_q8yrs_hyperactivity=2 if NN46==1
label values out_q8yrs_hyperactivity Q6_longtermprob 
fre out_q8yrs_hyperactivity
tab1 NN44 NN45 NN46 if out_q8yrs_hyperactivity==.

*4. Concentration or attention difficulties 
fre	NN48 	NN49 	NN50 	NN51 
gen out_q8yrs_concentration=.
replace out_q8yrs_concentration=0 if NN48==1
replace out_q8yrs_concentration=1 if NN49==1
replace out_q8yrs_concentration=2 if NN50==1
label values out_q8yrs_concentration Q6_longtermprob 
fre out_q8yrs_concentration
tab1 NN48 NN49 NN50 if out_q8yrs_concentration==. 

*5. Autistic traits /autism/Asperger’s Syndrome 
fre	NN52 NN53 NN54 NN55 
gen out_q8yrs_autistic_traits=.
replace out_q8yrs_autistic_traits=0 if NN52==1
replace out_q8yrs_autistic_traits=1 if NN53==1
replace out_q8yrs_autistic_traits=2 if NN54==1
label values out_q8yrs_autistic_traits Q6_longtermprob 
fre out_q8yrs_autistic_traits
tab1 NN52 NN53 NN54 if out_q8yrs_autistic_traits==. 

*6. Behavioural problems (difficult and unruly) 
fre NN56 NN57 NN58 NN59 
gen out_q8yrs_behavioural_problems=.
replace out_q8yrs_behavioural_problems=0 if NN56==1
replace out_q8yrs_behavioural_problems=1 if NN57==1
replace out_q8yrs_behavioural_problems=2 if NN58==1
label values out_q8yrs_behavioural_problems Q6_longtermprob 
fre out_q8yrs_behavioural_problems
tab1 NN56 NN57 NN58 if out_q8yrs_behavioural_problems==. 


*7. Emotional difficulties (sad or anxious) 	
fre NN60 NN61 NN62 NN63 
gen out_q8yrs_emotional_diffic=.
replace out_q8yrs_emotional_diffic=0 if NN60==1
replace out_q8yrs_emotional_diffic=1 if NN61==1
replace out_q8yrs_emotional_diffic=2 if NN62==1
label values out_q8yrs_emotional_diffic Q6_longtermprob 
fre out_q8yrs_emotional_diffic
tab1 NN60 NN61 NN62 if out_q8yrs_emotional_diffic==. 

*8. Other 	
fre NN64 NN65 NN66 NN67 
gen out_q8yrs_other_condition=.
replace out_q8yrs_other_condition=0 if NN64==1
replace out_q8yrs_other_condition=1 if NN65==1
replace out_q8yrs_other_condition=2 if NN66==1
label values out_q8yrs_other_condition Q6_longtermprob 
fre out_q8yrs_other_condition
tab1 NN60 NN61 NN62 if out_q8yrs_other_condition==. 

**********************************************************************************************************************************

*10. Short Mood and Feelings Questionnaire (SMFQ)
/*
*Description of original scale: Short Mood and Feelings Questionnaire (SMFQ)
The Mood and Feelings Quesionnaire (MFQ Angold & Costello, 1987) is a 32-item questionnaire based on DSM-III-R criteria for depression. 
The MFQ consists of a series of descriptive phrases regarding how the subject has been feeling or acting recently. 
A 13-item short form was developed, based on the discriminating ability between the depressed and non-depressed (Angold, et al., 1995). 
Both parent and child-report forms are available. The parent version is used in the MoBa 8-year questionnaire.
*/

foreach var of varlist NN68-NN80 {
	tab `var' if `var'==0
	recode `var' 0=.
	gen out_q8yrs_smfq_`var'=`var'
	}
*Nothing needs reverse-coding

*make a complete-case summary score:
gen cc_out_q8yrs_mfq =( out_q8yrs_smfq_NN68 +  out_q8yrs_smfq_NN69 +  out_q8yrs_smfq_NN70 +  out_q8yrs_smfq_NN71 +  out_q8yrs_smfq_NN72 +  out_q8yrs_smfq_NN73 +  out_q8yrs_smfq_NN74 +  out_q8yrs_smfq_NN75 +  out_q8yrs_smfq_NN76 +  out_q8yrs_smfq_NN77 +  out_q8yrs_smfq_NN78 +  out_q8yrs_smfq_NN79 +  out_q8yrs_smfq_NN80)
*make the scales start at 0 so you can use nbreg or poisson
replace cc_out_q8yrs_mfq=cc_out_q8yrs_mfq-13
sum cc_out_q8yrs_mfq

*examine missingness:
gen out_q8yrs_nitems_mfq=0
foreach var of varlist out_q8yrs_smfq_NN68 out_q8yrs_smfq_NN69 out_q8yrs_smfq_NN70 out_q8yrs_smfq_NN71 out_q8yrs_smfq_NN72 out_q8yrs_smfq_NN73 out_q8yrs_smfq_NN74 out_q8yrs_smfq_NN75 out_q8yrs_smfq_NN76 out_q8yrs_smfq_NN77 out_q8yrs_smfq_NN78 out_q8yrs_smfq_NN79 out_q8yrs_smfq_NN80 {
	replace out_q8yrs_nitems_mfq=out_q8yrs_nitems_mfq+1 if `var'!=.
	}
fre out_q8yrs_nitems_mfq if present_Q8y==1

*make versions allowing up to 20% missing:
display 13-(13/5)
*10.4
egen out_q8yrs_smfq=rowtotal (out_q8yrs_smfq_NN68 out_q8yrs_smfq_NN69 out_q8yrs_smfq_NN70 out_q8yrs_smfq_NN71 out_q8yrs_smfq_NN72 out_q8yrs_smfq_NN73 out_q8yrs_smfq_NN74 out_q8yrs_smfq_NN75 out_q8yrs_smfq_NN76 out_q8yrs_smfq_NN77 out_q8yrs_smfq_NN78 out_q8yrs_smfq_NN79 out_q8yrs_smfq_NN80)
replace out_q8yrs_smfq=out_q8yrs_smfq*(13/12) if out_q8yrs_nitems_mfq==12
replace out_q8yrs_smfq=out_q8yrs_smfq*(13/11) if out_q8yrs_nitems_mfq==11
replace out_q8yrs_smfq=. if out_q8yrs_nitems_mfq<11 | out_q8yrs_nitems_mfq==.
summ out_q8yrs_smfq
*actually, bump this all down - since lowest value for any item was 1 not 0, mimimum possible value is not 0 which is weird
replace out_q8yrs_smfq=out_q8yrs_smfq-13
summ out_q8yrs_smfq
fre out_q8yrs_smfq
tab out_q8yrs_smfq cc_out_q8yrs_mfq, mi


*11. Short Norwegian Hierarchical Personality Inventory for Children (NHiPIC-30)
*Note: here also there are changes between versions a/b/c
*versions B & C:
fre NN81 NN82 NN83 NN84 NN85 NN86 NN87 NN88 NN89 NN90 NN91 NN92 NN93 NN94 NN95 NN96 NN97 NN98 NN99 NN100 NN101 NN102 NN103 NN104 NN105 NN106 NN107 NN108 NN109 NN110
*In version A, the five items below differ from those in versions B 
*1.Become easily panic
fre NN368
*2. Will get to the bottom of things
fre NN369
*8. Have energy to spare
fre NN370
*10. Seeking contact with new classmates
fre NN371
*27. Feel at ease with him/herself
fre NN372

*fix multiple ticks:
foreach var of varlist NN81 NN82 NN83 NN84 NN85 NN86 NN87 NN88 NN89 NN90 NN91 NN92 NN93 NN94 NN95 NN96 NN97 NN98 NN99 NN100 NN101 NN102 NN103 NN104 NN105 NN106 NN107 NN108 NN109 NN110 NN368 NN369 NN370 NN371 NN372 {
recode `var' 0=.
fre `var'
}

**********************************************************************************************************************************

*12-13. Parent/Teacher Rating Scale for Disruptive Behaviour Disorders (RS-DBD)
/*
Description of original scale: 
Parent/Teacher Rating Scale for Disruptive Behaviour Disorders (RS-DBD) Parent/Teacher Rating Scale for Disruptive Behavior Disorders (RS-DBD; Silva et al., 2005) 
consists of 41 DSM-IV items; with 18 items related to ADHD, 8 items related to Oppositional Defiant (OD), and 15 items to Conduct Disorder (CD). 
The 18 items (items 1-18 of section 13) related to ADHD, the 8 items related to OD (items 19-26 of section 13), and 8 items to CD were selected into use in this section.
Each item is rated on a four-point scale (1 = never/rarely, 2 = sometimes, 3 = often, 4 = very often).
*/
 *Recode to missing >1 response for all items
foreach var of varlist NN111-NN144 {
	tab `var' if `var'==0
	recode `var' 0=.
	tab `var', nol
	cap:gen out_q8yrs_`var'=`var'
	}
*Nothing needs reverse-coding


*adhd 
*summary scale, complete-case version:
gen cc_out_q8yrs_adhd=(out_q8yrs_NN119 + out_q8yrs_NN120 + out_q8yrs_NN121 + out_q8yrs_NN122 + out_q8yrs_NN123 + out_q8yrs_NN124 + out_q8yrs_NN125 + out_q8yrs_NN126 + out_q8yrs_NN127 + out_q8yrs_NN128 + out_q8yrs_NN129 + out_q8yrs_NN130 + out_q8yrs_NN131 + out_q8yrs_NN132 + out_q8yrs_NN133 + out_q8yrs_NN134 + out_q8yrs_NN135 + out_q8yrs_NN136)
*make the scales start at 0 so you can use nbreg or poisson
replace cc_out_q8yrs_adhd =cc_out_q8yrs_adhd-18
label var cc_out_q8yrs_adhd "q8yr rs-dbd adhd score"
sum cc_out_q8yrs_adhd 

*examine missingness
forvalues i=119(1)136{
	fre out_q8yrs_NN`i'
	}
gen out_q8yrs_nitems_rs_dbd=0
forvalues i=119(1)136{
	replace out_q8yrs_nitems_rs_dbd=out_q8yrs_nitems_rs_dbd+1 if out_q8yrs_NN`i'!=.
	}
fre out_q8yrs_nitems_rs_dbd if present_Q8y==1

*make a version allowing up to 20% missing
display 18-(18/5)
*14.4
egen out_q8yrs_adhd=rowtotal (out_q8yrs_NN119 out_q8yrs_NN120 out_q8yrs_NN121 out_q8yrs_NN122 out_q8yrs_NN123 out_q8yrs_NN124 out_q8yrs_NN125 out_q8yrs_NN126 out_q8yrs_NN127 out_q8yrs_NN128 out_q8yrs_NN129 out_q8yrs_NN130 out_q8yrs_NN131 out_q8yrs_NN132 out_q8yrs_NN133 out_q8yrs_NN134 out_q8yrs_NN135 out_q8yrs_NN136)
replace out_q8yrs_adhd=out_q8yrs_adhd*(18/17) if out_q8yrs_nitems_rs_dbd==17
replace out_q8yrs_adhd=out_q8yrs_adhd*(18/16) if out_q8yrs_nitems_rs_dbd==16
replace out_q8yrs_adhd=out_q8yrs_adhd*(18/15) if out_q8yrs_nitems_rs_dbd==15
replace out_q8yrs_adhd=. if out_q8yrs_nitems_rs_dbd<15 | out_q8yrs_nitems_rs_dbd==.
summ out_q8yrs_adhd
*actually, bump this all down - since lowest value for any item was 1 not 0, mimimum possible value is not 0 which is weird
replace out_q8yrs_adhd=out_q8yrs_adhd-18
summ out_q8yrs_adhd
tab out_q8yrs_adhd cc_out_q8yrs_adhd, mi

***********************************************
*adhd - inattention
*complete case scale
gen cc_out_q8yrs_inadhd =(out_q8yrs_NN119 + out_q8yrs_NN120 + out_q8yrs_NN121 + out_q8yrs_NN122 + out_q8yrs_NN123 + out_q8yrs_NN124 + out_q8yrs_NN125 + out_q8yrs_NN126 + out_q8yrs_NN127)
*make the scales start at 0 so you can use nbreg or poisson
replace cc_out_q8yrs_inadhd=cc_out_q8yrs_inadhd-9
label variable cc_out_q8yrs_inadhd "q8yr rs-dbd adhd-inattention score"
summ cc_out_q8yrs_inadhd

*missingness
gen out_q8yrs_nitems_inadhd=0
foreach i in NN119 NN120 NN121 NN122 NN123 NN124 NN125 NN126 NN127 {
	replace out_q8yrs_nitems_inadhd=out_q8yrs_nitems_inadhd+1 if out_q8yrs_`i'!=.
	}
fre out_q8yrs_nitems_inadhd if present_Q8y==1

*version allowing 20% missingness
display 9-(9/5)
*7.2
egen out_q8yrs_inadhd=rowtotal (out_q8yrs_NN119 out_q8yrs_NN120 out_q8yrs_NN121 out_q8yrs_NN122 out_q8yrs_NN123 out_q8yrs_NN124 out_q8yrs_NN125 out_q8yrs_NN126 out_q8yrs_NN127)
replace out_q8yrs_inadhd=out_q8yrs_inadhd*(9/8) if out_q8yrs_nitems_inadhd==8
replace out_q8yrs_inadhd=. if out_q8yrs_nitems_inadhd<8 | out_q8yrs_nitems_inadhd==.
summ out_q8yrs_inadhd
*actually, bump this all down - since lowest value for any item was 1 not 0, mimimum possible value is not 0 which is weird
replace out_q8yrs_inadhd=out_q8yrs_inadhd-9
summ out_q8yrs_inadhd
tab out_q8yrs_inadhd cc_out_q8yrs_inadhd, mi

**********************************************
*adhd - hyperactivity
*complete-case scale
gen cc_out_q8yrs_hyadhd =(out_q8yrs_NN128 + out_q8yrs_NN129 + out_q8yrs_NN130 + out_q8yrs_NN131 + out_q8yrs_NN132 + out_q8yrs_NN133 + out_q8yrs_NN134 + out_q8yrs_NN135 + out_q8yrs_NN136)
*make the scales start at 0 so you can use nbreg or poisson
replace cc_out_q8yrs_hyadhd=cc_out_q8yrs_hyadhd-9
label variable cc_out_q8yrs_hyadhd "q8yr rs-dbd adhd-hyperactivity score"
summ cc_out_q8yrs_hyadhd

*missingness
gen out_q8yrs_nitems_hyadhd=0
foreach i in NN128 NN129 NN130 NN131 NN132 NN133 NN134 NN135 NN136 {
	replace out_q8yrs_nitems_hyadhd=out_q8yrs_nitems_hyadhd+1 if out_q8yrs_`i'!=.
	}
fre out_q8yrs_nitems_hyadhd if present_Q8y==1

*version allowing 20% missingness
display 9-(9/5)
*7.2
egen out_q8yrs_hyadhd=rowtotal (out_q8yrs_NN128 out_q8yrs_NN129 out_q8yrs_NN130 out_q8yrs_NN131 out_q8yrs_NN132 out_q8yrs_NN133 out_q8yrs_NN134 out_q8yrs_NN135 out_q8yrs_NN136)
replace out_q8yrs_hyadhd=out_q8yrs_hyadhd*(9/8) if out_q8yrs_nitems_hyadhd==8
replace out_q8yrs_hyadhd=. if out_q8yrs_nitems_hyadhd<8 | out_q8yrs_nitems_hyadhd==.
summ out_q8yrs_hyadhd
*actually, bump this all down - since lowest value for any item was 1 not 0, mimimum possible value is not 0 which is weird
replace out_q8yrs_hyadhd=out_q8yrs_hyadhd-9
summ out_q8yrs_hyadhd
tab out_q8yrs_hyadhd cc_out_q8yrs_hyadhd, mi

****************************************************
*oppositional defiant disorder
*complete-case scale
gen cc_out_q8yrs_od =(out_q8yrs_NN137 + out_q8yrs_NN138 + out_q8yrs_NN139 + out_q8yrs_NN140 + out_q8yrs_NN141 + out_q8yrs_NN142 + out_q8yrs_NN143 + out_q8yrs_NN144)
*make the scales start at 0 so you can use nbreg or poisson
replace cc_out_q8yrs_od=cc_out_q8yrs_od-8
label variable cc_out_q8yrs_od "q8yr rs-dbd odd score"
summ cc_out_q8yrs_od

*missingness
gen out_q8yrs_nitems_od=0
foreach i in NN137 NN138 NN139 NN140 NN141 NN142 NN143 NN144 {
	replace out_q8yrs_nitems_od=out_q8yrs_nitems_od+1 if out_q8yrs_`i'!=.
	}
fre out_q8yrs_nitems_od if present_Q8y==1

*version allowing 20% missingness
display 8-(8/5)
*6.4
egen out_q8yrs_od=rowtotal (out_q8yrs_NN137 out_q8yrs_NN138 out_q8yrs_NN139 out_q8yrs_NN140 out_q8yrs_NN141 out_q8yrs_NN142 out_q8yrs_NN143 out_q8yrs_NN144)
replace out_q8yrs_od=out_q8yrs_od*(8/7) if out_q8yrs_nitems_od==7
replace out_q8yrs_od=. if out_q8yrs_nitems_od<7 | out_q8yrs_nitems_od==.
summ out_q8yrs_od
*actually, bump this all down - since lowest value for any item was 1 not 0, mimimum possible value is not 0 which is weird
replace out_q8yrs_od=out_q8yrs_od-8
summ out_q8yrs_od
tab out_q8yrs_od cc_out_q8yrs_od, mi

*************************************************
*conduct disorder
*complete-case scale
gen cc_out_q8yrs_cd =(out_q8yrs_NN111 + out_q8yrs_NN112 + out_q8yrs_NN113 + out_q8yrs_NN114 + out_q8yrs_NN115 + out_q8yrs_NN116 + out_q8yrs_NN117 + out_q8yrs_NN118)
summ cc_out_q8yrs_cd
*make the scales start at 0 so you can use nbreg or poisson
replace cc_out_q8yrs_cd=cc_out_q8yrs_cd-8
label variable cc_out_q8yrs_cd "q8yr rs-dbd conduct disorder score"
summ cc_out_q8yrs_cd

*missingness
gen out_q8yrs_nitems_cd=0
foreach i in NN111 NN112 NN113 NN114 NN115 NN116 NN117 NN118 {
	replace out_q8yrs_nitems_cd=out_q8yrs_nitems_cd+1 if out_q8yrs_`i'!=.
	}
fre out_q8yrs_nitems_cd if present_Q8y==1

*version allowing 20% missingness
display 8-(8/5)
*6.4
egen out_q8yrs_cd=rowtotal (out_q8yrs_NN111 out_q8yrs_NN112 out_q8yrs_NN113 out_q8yrs_NN114 out_q8yrs_NN115 out_q8yrs_NN116 out_q8yrs_NN117 out_q8yrs_NN118)
replace out_q8yrs_cd=out_q8yrs_cd*(8/7) if out_q8yrs_nitems_cd==7
replace out_q8yrs_cd=. if out_q8yrs_nitems_cd<7 | out_q8yrs_nitems_cd==.
summ out_q8yrs_cd
*actually, bump this all down - since lowest value for any item was 1 not 0, mimimum possible value is not 0 which is weird
replace out_q8yrs_cd=out_q8yrs_cd-8
summ out_q8yrs_cd
tab out_q8yrs_cd cc_out_q8yrs_cd, mi

************************************************************

*14.Screen for Child Anxiety Related Disorders (SCARED)
/*
Description of original scale: Screen for Child Anxiety Related Disorders (SCARED)
The SCARED (Birmaher et al., 1997) is a multidimensional questionnaire that purports to measure DSM-defined anxiety symptom. 
It contains 41 items which can be allocated to five separate anxiety subscales. 
Four of these subscales represent anxiety disorders that correspond with DSM categories, namely panic disorder, generalized anxiety disorder, social phobia, 
and separation anxiety. The fifth subscale is school phobia. The SCARED comes in two versions: a parent version and a child version. 
The 5-item short version, as used in the MoBa, was developed in Birmaher et al. (1999). 
Mothers rate how true the statements describe their children using a 3-point scale (i.e. 1= Not true, 2=Sometimes true, 3=True).
*/

 *Recode to missing >1 response for all items
foreach var of varlist NN145-NN149  {
	tab `var' if `var'==0
	recode `var' 0=.
	gen out_q8yrs_scared_`var'=`var'
	}
*Nothing needs reverse coding.

*complete-case scale:
gen cc_out_q8yrs_scared =(out_q8yrs_scared_NN145 + out_q8yrs_scared_NN146 + out_q8yrs_scared_NN147 + out_q8yrs_scared_NN148 + out_q8yrs_scared_NN149)
summ cc_out_q8yrs_scared
*make the scales start at 0 so you can use nbreg or poisson
replace cc_out_q8yrs_scared=cc_out_q8yrs_scared-5
sum cc_out_q8yrs_scared

*missingness
gen out_q8yrs_nitems_scared=0
foreach var of varlist out_q8yrs_scared_NN145 out_q8yrs_scared_NN146 out_q8yrs_scared_NN147 out_q8yrs_scared_NN148 out_q8yrs_scared_NN149 {
	replace out_q8yrs_nitems_scared=out_q8yrs_nitems_scared+1 if `var'!=.
	}
fre out_q8yrs_nitems_scared if present_Q8y==1

*version allowing 20% missingness
egen out_q8yrs_scared=rowtotal (out_q8yrs_scared_NN145 out_q8yrs_scared_NN146 out_q8yrs_scared_NN147 out_q8yrs_scared_NN148 out_q8yrs_scared_NN149)
replace out_q8yrs_scared=out_q8yrs_scared*(5/4) if out_q8yrs_nitems_scared==4
replace out_q8yrs_scared=. if out_q8yrs_nitems_scared<4 | out_q8yrs_nitems_scared==.
summ out_q8yrs_scared
*actually, bump this all down - since lowest value for any item was 1 not 0, mimimum possible value is not 0
replace out_q8yrs_scared=out_q8yrs_scared-5
summ out_q8yrs_scared
tab out_q8yrs_scared cc_out_q8yrs_scared, mi

**********************************************************************************************************************************
*15-17. Social Communication Questionnaire (SCQ)
/*
*Description of original instrument: Social Communication Questionnaire (SCQ)
The SCQ (Ritter, et al., 2003) is a parental-report Autism screening tool developed to serve as a practical piece of early childhood developmental screenings 
which parallels the Autism Diagnostic Interview-Revised (ADI-R; Lord, et al., 1994). 
It is a 40-question screening form designed for children with an age of 4.0 years (and a mental age of 2.0) which takes less than 10 minutes to complete and score. 
The items are administered in a yes/no response format.
*/

 *Recode to missing >1 response for all items
foreach var of varlist NN150-NN189  {
	tab `var' if `var'==0
	recode `var' 0=.
	gen out_q8yrs_scq_`var'=`var'
	}
/*R code:
#reverse code the SCQ variables NN152,NN153,NN154,NN155,NN156,NN157,NN159,NN160,NN161,NN162,NN163,NN164,NN165,NN166,NN167
q8yr[,c("rNN152", "rNN153","rNN154","rNN155","rNN156","rNN157","rNN159","rNN160", "rNN161","rNN162", "rNN163", "rNN164", "rNN165","rNN166", "rNN167")]<- 
  abs(q8yr[,c("NN152","NN153", "NN154","NN155","NN156", "NN157", "NN159", "NN160", "NN161","NN162", "NN163", "NN164", "NN165", "NN166", "NN167")]-4)
 */
 
*do this a different way - easier to avoid upweighting the reverse-coded items
foreach var in NN152 NN153 NN154 NN155 NN156 NN157 NN159 NN160 NN161 NN162 NN163 NN164 NN165 NN166 NN167 {
gen rout_q8yrs_scq_`var'=out_q8yrs_scq_`var'
recode rout_q8yrs_scq_`var' 2=0
replace rout_q8yrs_scq_`var'=rout_q8yrs_scq_`var'+1
	}
*inspect
tab out_q8yrs_scq_NN152 rout_q8yrs_scq_NN152

**NB: NN189 AND NN189 ARE INCLUDED in the full scale and SCI subscale - checked with Laurie 19/06/2022

*full scale:
*complete-case
gen cc_out_q8yrs_scq =(out_q8yrs_scq_NN150 + out_q8yrs_scq_NN151 + rout_q8yrs_scq_NN152 + rout_q8yrs_scq_NN153 + rout_q8yrs_scq_NN154 + rout_q8yrs_scq_NN155 + rout_q8yrs_scq_NN156 + rout_q8yrs_scq_NN157 + out_q8yrs_scq_NN158 + rout_q8yrs_scq_NN159 + rout_q8yrs_scq_NN160 + rout_q8yrs_scq_NN161 + rout_q8yrs_scq_NN162 + rout_q8yrs_scq_NN163 + rout_q8yrs_scq_NN164 + rout_q8yrs_scq_NN165 + rout_q8yrs_scq_NN166 + rout_q8yrs_scq_NN167 + out_q8yrs_scq_NN168 + out_q8yrs_scq_NN169 + out_q8yrs_scq_NN170 + out_q8yrs_scq_NN171 + out_q8yrs_scq_NN172 + out_q8yrs_scq_NN173 + out_q8yrs_scq_NN174 + out_q8yrs_scq_NN175 + out_q8yrs_scq_NN176 + out_q8yrs_scq_NN177 + out_q8yrs_scq_NN178 + out_q8yrs_scq_NN179 + out_q8yrs_scq_NN180 + out_q8yrs_scq_NN181 + out_q8yrs_scq_NN182 + out_q8yrs_scq_NN183 + out_q8yrs_scq_NN184 + out_q8yrs_scq_NN185 + out_q8yrs_scq_NN186 + out_q8yrs_scq_NN187 + out_q8yrs_scq_NN188 +out_q8yrs_scq_NN189)
*make the scales start at 0 so you can use nbreg or poisson
replace cc_out_q8yrs_scq=cc_out_q8yrs_scq-40
sum cc_out_q8yrs_scq

*missingness
gen out_q8yrs_nitems_scq=0
foreach i in NN150 NN151 NN152 NN153 NN154 NN155 NN156 NN157 NN158 NN159 NN160 NN161 NN162 NN163 NN164 NN165 NN166 NN167 NN168 NN169 NN170 NN171 NN172 NN173 NN174 NN175 NN176 NN177 NN178 NN179 NN180 NN181 NN182 NN183 NN184 NN185 NN186 NN187 NN188 NN189 {
	cap:replace out_q8yrs_nitems_scq=out_q8yrs_nitems_scq+1 if out_q8yrs_scq_`i'!=.
	if _rc==111{
		replace out_q8yrs_nitems_scq=out_q8yrs_nitems_scq+1 if rout_q8yrs_scq_`i'!=.
		}
	}
fre out_q8yrs_nitems_scq if present_Q8y==1

*version allowing 20% missingness:
egen out_q8yrs_scq=rowtotal (out_q8yrs_scq_NN150 out_q8yrs_scq_NN151 rout_q8yrs_scq_NN152 rout_q8yrs_scq_NN153 rout_q8yrs_scq_NN154 rout_q8yrs_scq_NN155 rout_q8yrs_scq_NN156 rout_q8yrs_scq_NN157 out_q8yrs_scq_NN158 rout_q8yrs_scq_NN159 rout_q8yrs_scq_NN160 rout_q8yrs_scq_NN161 rout_q8yrs_scq_NN162 rout_q8yrs_scq_NN163 rout_q8yrs_scq_NN164 rout_q8yrs_scq_NN165 rout_q8yrs_scq_NN166 rout_q8yrs_scq_NN167 out_q8yrs_scq_NN168 out_q8yrs_scq_NN169 out_q8yrs_scq_NN170 out_q8yrs_scq_NN171 out_q8yrs_scq_NN172 out_q8yrs_scq_NN173 out_q8yrs_scq_NN174 out_q8yrs_scq_NN175 out_q8yrs_scq_NN176 out_q8yrs_scq_NN177 out_q8yrs_scq_NN178 out_q8yrs_scq_NN179 out_q8yrs_scq_NN180 out_q8yrs_scq_NN181 out_q8yrs_scq_NN182 out_q8yrs_scq_NN183 out_q8yrs_scq_NN184 out_q8yrs_scq_NN185 out_q8yrs_scq_NN186 out_q8yrs_scq_NN187 out_q8yrs_scq_NN188 out_q8yrs_scq_NN189)
replace out_q8yrs_scq=out_q8yrs_scq*(40/39) if out_q8yrs_nitems_scq==39 
replace out_q8yrs_scq=out_q8yrs_scq*(40/38) if out_q8yrs_nitems_scq==38
replace out_q8yrs_scq=out_q8yrs_scq*(40/37) if out_q8yrs_nitems_scq==37 
replace out_q8yrs_scq=out_q8yrs_scq*(40/36) if out_q8yrs_nitems_scq==36 
replace out_q8yrs_scq=out_q8yrs_scq*(40/35) if out_q8yrs_nitems_scq==35 
replace out_q8yrs_scq=out_q8yrs_scq*(40/34) if out_q8yrs_nitems_scq==34 
replace out_q8yrs_scq=out_q8yrs_scq*(40/33) if out_q8yrs_nitems_scq==33 
replace out_q8yrs_scq=out_q8yrs_scq*(40/32) if out_q8yrs_nitems_scq==32 
replace out_q8yrs_scq=. if out_q8yrs_nitems_scq<32 | out_q8yrs_nitems_scq==.
summ out_q8yrs_scq
*actually, bump this all down - since lowest value for any item was 1 not 0, mimimum possible value is not 0
replace out_q8yrs_scq=out_q8yrs_scq-40
summ out_q8yrs_scq
tab out_q8yrs_scq cc_out_q8yrs_scq, mi

****************************************************

*SEPARATE SYMPTOM CLUSTERS:
*split SCQ into social and repetitive:
*according to Ragna's spreadsheet, there are three 'groupings': language, behaviour, social development
*also, there are three 'syndrome scales':  communication / Restricted, repetitive, and stereotyped patterns of behavior /Reciprosal Social Interaction
*and a few items don't map to any of these
*thirdly, DSM-oriented scales: SCI and RRB, with a few items mapping to neither
*SPLIT ON THESE LINES.

*Not included in either:
*rNN166 + NN184 
tab rout_q8yrs_scq_NN166 out_q8yrs_scq_NN184
*need to PRESERVE THESE THROUGH IMPUTATION - will need them to reconstruct the full scale post-imputation

*SCI
*complete-case
gen cc_out_q8yrs_scq_sci =(out_q8yrs_scq_NN150 + out_q8yrs_scq_NN151 + rout_q8yrs_scq_NN153 + out_q8yrs_scq_NN158 + rout_q8yrs_scq_NN159 + out_q8yrs_scq_NN168 + out_q8yrs_scq_NN169 + out_q8yrs_scq_NN170 + out_q8yrs_scq_NN171 + out_q8yrs_scq_NN172 + out_q8yrs_scq_NN173 + out_q8yrs_scq_NN174 + out_q8yrs_scq_NN175 + out_q8yrs_scq_NN176 + out_q8yrs_scq_NN177 + out_q8yrs_scq_NN178 + out_q8yrs_scq_NN179 + out_q8yrs_scq_NN180 + out_q8yrs_scq_NN181 + out_q8yrs_scq_NN182 + out_q8yrs_scq_NN183 + out_q8yrs_scq_NN185 + out_q8yrs_scq_NN186 + out_q8yrs_scq_NN187 + out_q8yrs_scq_NN188 +out_q8yrs_scq_NN189)
*make the scales start at 0 so you can use nbreg or poisson
replace cc_out_q8yrs_scq_sci=cc_out_q8yrs_scq_sci-26
sum cc_out_q8yrs_scq_sci

*missingness
gen out_q8yrs_nitems_scq_sci=0
foreach i in 150 151 153 158 159 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 185 186 187 188 189 {
	replace out_q8yrs_nitems_scq_sci=out_q8yrs_nitems_scq_sci+1 if out_q8yrs_scq_NN`i'!=.
	}
fre out_q8yrs_nitems_scq_sci if present_Q8y==1

*version allowing 20% missingness:
egen out_q8yrs_scq_sci=rowtotal (out_q8yrs_scq_NN150 out_q8yrs_scq_NN151 rout_q8yrs_scq_NN153 out_q8yrs_scq_NN158 rout_q8yrs_scq_NN159 out_q8yrs_scq_NN168 out_q8yrs_scq_NN169 out_q8yrs_scq_NN170 out_q8yrs_scq_NN171 out_q8yrs_scq_NN172 out_q8yrs_scq_NN173 out_q8yrs_scq_NN174 out_q8yrs_scq_NN175 out_q8yrs_scq_NN176 out_q8yrs_scq_NN177 out_q8yrs_scq_NN178 out_q8yrs_scq_NN179 out_q8yrs_scq_NN180 out_q8yrs_scq_NN181 out_q8yrs_scq_NN182 out_q8yrs_scq_NN183 out_q8yrs_scq_NN185 out_q8yrs_scq_NN186 out_q8yrs_scq_NN187 out_q8yrs_scq_NN188 out_q8yrs_scq_NN189)
replace out_q8yrs_scq_sci=out_q8yrs_scq_sci*(26/25) if out_q8yrs_nitems_scq_sci==25
replace out_q8yrs_scq_sci=out_q8yrs_scq_sci*(26/24) if out_q8yrs_nitems_scq_sci==24
replace out_q8yrs_scq_sci=out_q8yrs_scq_sci*(26/23) if out_q8yrs_nitems_scq_sci==23
replace out_q8yrs_scq_sci=out_q8yrs_scq_sci*(26/22) if out_q8yrs_nitems_scq_sci==22
replace out_q8yrs_scq_sci=out_q8yrs_scq_sci*(26/21) if out_q8yrs_nitems_scq_sci==21
replace out_q8yrs_scq_sci=. if out_q8yrs_nitems_scq_sci<21 | out_q8yrs_nitems_scq==.
summ out_q8yrs_scq_sci
*actually, bump this all down - since lowest value for any item was 1 not 0, mimimum possible value is not 0
replace out_q8yrs_scq_sci=out_q8yrs_scq_sci-26
summ out_q8yrs_scq_sci
tab  out_q8yrs_scq_sci  cc_out_q8yrs_scq_sci, mi

****************************************************

*RRB
*complete-case
gen cc_out_q8yrs_scq_rrb = (rout_q8yrs_scq_NN152 + rout_q8yrs_scq_NN154 + rout_q8yrs_scq_NN155 + rout_q8yrs_scq_NN156 + rout_q8yrs_scq_NN157 + rout_q8yrs_scq_NN160 + rout_q8yrs_scq_NN161 + rout_q8yrs_scq_NN162 + rout_q8yrs_scq_NN163 + rout_q8yrs_scq_NN164 + rout_q8yrs_scq_NN165 + rout_q8yrs_scq_NN167)
*make the scales start at 0 so you can use nbreg or poisson
replace cc_out_q8yrs_scq_rrb=cc_out_q8yrs_scq_rrb-12
sum cc_out_q8yrs_scq_rrb

*missingness
gen out_q8yrs_nitems_scq_rrb=0
foreach var of varlist rout_q8yrs_scq_NN152 rout_q8yrs_scq_NN154 rout_q8yrs_scq_NN155 rout_q8yrs_scq_NN156 rout_q8yrs_scq_NN157 rout_q8yrs_scq_NN160 rout_q8yrs_scq_NN161 rout_q8yrs_scq_NN162 rout_q8yrs_scq_NN163 rout_q8yrs_scq_NN164 rout_q8yrs_scq_NN165 rout_q8yrs_scq_NN167{
	replace out_q8yrs_nitems_scq_rrb=out_q8yrs_nitems_scq_rrb+1 if `var'!=.
	}
fre out_q8yrs_nitems_scq_rrb if present_Q8y==1

*version allowing 20% missingness:
egen out_q8yrs_scq_rrb=rowtotal (rout_q8yrs_scq_NN152 rout_q8yrs_scq_NN154 rout_q8yrs_scq_NN155 rout_q8yrs_scq_NN156 rout_q8yrs_scq_NN157 rout_q8yrs_scq_NN160 rout_q8yrs_scq_NN161 rout_q8yrs_scq_NN162 rout_q8yrs_scq_NN163 rout_q8yrs_scq_NN164 rout_q8yrs_scq_NN165 rout_q8yrs_scq_NN167)
replace out_q8yrs_scq_rrb=out_q8yrs_scq_rrb*(12/11) if out_q8yrs_nitems_scq_rrb==11
replace out_q8yrs_scq_rrb=out_q8yrs_scq_rrb*(12/10) if out_q8yrs_nitems_scq_rrb==10
replace out_q8yrs_scq_rrb=. if out_q8yrs_nitems_scq_rrb<10 | out_q8yrs_nitems_scq_rrb==.
summ out_q8yrs_scq_rrb
*actually, bump this all down - since lowest value for any item was 1 not 0, mimimum possible value is not 0
replace out_q8yrs_scq_rrb=out_q8yrs_scq_rrb-12
summ out_q8yrs_scq_rrb
fre out_q8yrs_scq_rrb cc_out_q8yrs_scq_rrb
**************************************************************************************************************************

*20. Children’s Communication Checklist-2 (CCC-2)
fre NN211-NN226
*fix multiple ticks:
foreach var of varlist NN211-NN226 {
	recode `var' 0=.
	fre `var'
	gen out_q8yrs_ccc2_`var'=`var'
	}
*21. Checklist of 20 Statements about Language-Related Difficulties (Språk20)
*Note: VERSION DIFFERENCE: ITEM 8, NN374, ONLY IN VERSION C
fre NN227 NN228 NN229 NN230 NN231 NN232 NN233 NN374
*fix multiple ticks:
foreach var of varlist NN227 NN228 NN229 NN230 NN231 NN232 NN233 NN374 {
	recode `var' 0=.
	fre `var'
	gen out_q8yrs_lrd_`var'=`var'
	}

******************************************************************
*PLACEHOLDER EDUCATION OUTCOME:

*Q25: All children take mandatory tests at school: reading in 1st grade and reading and arithmetic in 2nd grade. Parents are usually informed of the results during parent-teacher discussions. What feedback have you gotten about your child?
/*Response options:
1-Has mastered subject well
2-Must work more but teacher is not concerned
3-Teacher is concerned
4-Don't know/not discussed with teacher
*/
*…Reading skills in 1st grade
*NN239
*…Reading skills in 2nd grade
*NN240
*…Arithmetic skills in 2nd grade
*NN241
fre NN239 NN240 NN241

*fix multiple ticks
*also the 'Don't know / have not talked to the teacher about it' needs to be coded to missing
foreach var of varlist NN239 NN240 NN241 {
	recode `var' 0=.
	*and the don't know category
	recode `var' 4=.
	fre `var'
	gen out_q8yrs_teach_rate_`var'=`var'
	}

*MAKE AN OVERALL SCORE by summing legitimate answers.
fre out_q8yrs_teach_rate_NN239 out_q8yrs_teach_rate_NN240 out_q8yrs_teach_rate_NN241
*next line imported from other script cr_04_phenotypes:
gen out_q8yrs_teach_rate_score=9-out_q8yrs_teach_rate_NN239-out_q8yrs_teach_rate_NN240-out_q8yrs_teach_rate_NN241
label variable out_q8yrs_teach_rate_score "summ of parent-report of teacher-report for reading and arithmetic skills NN239 NN240 NN241"
fre out_q8yrs_teach_rate_score

**************************************************

*Q26. Special Education. Is an administrative decision made about your child being eligible for special education?
*in various subjects:
fre NN242 NN244 NN246 NN248
*fix multiple ticks:
foreach var of varlist NN242 NN244 NN246 NN248 {
	recode `var' 0=.
	fre `var'
	gen out_q8yrs_sen_`var'=`var'
	}
*how many hours: 0s are legit!
fre NN243 NN245 NN247 NN249 
foreach var of varlist NN243 NN245 NN247 NN249  {
	fre `var'
	gen out_q8yrs_sen_`var'=`var'
	}

*does your child get extra help because of a disability or developmental problem? 
gen out_q8yrs_sen_NN250=NN250
replace out_q8yrs_sen_NN250=. if out_q8yrs_sen_NN250==0
*label it with original label:
describe NN250 
label values out_q8yrs_sen_NN250 NN250
fre  out_q8yrs_sen_NN250

*check these:
*In Norwegian language?
fre out_q8yrs_sen_NN242 out_q8yrs_sen_NN243
*In arithmetic?
fre out_q8yrs_sen_NN244 out_q8yrs_sen_NN245
*In other subjects?
fre out_q8yrs_sen_NN246 out_q8yrs_sen_NN247
*Does your child receive any other educational support?
fre out_q8yrs_sen_NN248 out_q8yrs_sen_NN249
*Does your child get extra help (e.g. an assistant) at school because of a disability or a developmental problem?
fre  out_q8yrs_sen_NN250

****************************************
*Homework

*NB: CHANGED THE RECODING OF THESE BELOW SO THAT 'DON'T HAVE HOMEWORK' WAS SET EQUAL TO 0 HOURS

*Three questions on homework: 
*Approximately how many hours per week……does your child spend doing homework at home?
fre NN251
gen out_q8yrs_hrs_homework_NN251=NN251
*clean: including the 'don't have homework' group and the combo of that and zero hours - set to 2, which means zero hours
recode out_q8yrs_hrs_homework_NN251 0=. 1=2 12 =2 23=2.5 34=3.5 45=4.5 56=5.5
*label it with original label:
describe NN251 
label values out_q8yrs_hrs_homework_NN251 NN251
label variable out_q8yrs_hrs_homework_NN251 "hours/week spent on homework"
fre  out_q8yrs_hrs_homework_NN251

*Help with homework
fre NN252
gen out_q8yrs_hlp_hw_home_NN252=NN252
*clean: including the 'don't have homework' group and the combo of that and zero hours - set to 2, which means zero hours
recode out_q8yrs_hlp_hw_home_NN252 0=. 1=2 12=2 23=2.5 34=3.5 45=4.5 56=5.5
*label it with original label:
describe NN252
label values out_q8yrs_hlp_hw_home_NN252 NN252
label variable out_q8yrs_hlp_hw_home_NN252 "hours/week helped at home with homework"
fre out_q8yrs_hlp_hw_home_NN252

*Help afterschool
fre NN253
gen out_q8yrs_hlp_hw_aftersch_NN253=NN253	
*clean: including the 'don't have homework' group and the combo of that and zero hours - set to 2, which means zero hours
recode out_q8yrs_hlp_hw_aftersch_NN253 0=. 1=2 12 =2 23=2.5 34=3.5 45=4.5 56=5.5
*label it with original label:
describe NN253
label values out_q8yrs_hlp_hw_aftersch_NN253 NN253
label variable out_q8yrs_hlp_hw_aftersch_NN253 "hours/week helped at school/afterschool with homework"
fre out_q8yrs_hlp_hw_aftersch_NN253

	
********************************************************
*28. Reading and Writing Skills
*Potentially useful but differs quite a lot between versions

*28 Enter a cross indicating what your child masters:
*In version C, responses were 3-choice categorical:  Yes/ 2- Partially /3-Not yet
fre NN380 NN381 NN382 NN383 NN384 
describe NN380 NN381 NN382 NN383 NN384 
*fix multiple ticks
foreach var of varlist NN380 NN381 NN382 NN383 NN384 {
	recode `var' 0=.
	fre `var'
	gen out_q8yrs_child_master_`var'=`var'
	*apply original labelling and check:
	label values out_q8yrs_child_master_`var' `var'
	fre out_q8yrs_child_master_`var'
	}
*In version A & B, the questions were slightly different, but moreover binary response,
*but with a don't know option:
fre  NN254 NN255 NN256 NN257
*fix multiple ticks	
foreach var of varlist NN254 NN255 NN256 NN257 {
	recode `var' 0=.
	*also the don't knows, here=3:
	recode `var' 3=.
	fre `var'
	gen out_q8yrs_child_master_`var'=`var'
		*apply original labelling and check:
	label values out_q8yrs_child_master_`var' `var'
	fre out_q8yrs_child_master_`var'
	}

*make summary scores, although need to make two versions for people who answered the different versions of the questionnaire, as not comparable:
gen out_q8yrs_master_score1=NN254+NN255+NN256+NN257 -4
label variable out_q8yrs_master_score1 "child's reading & writing mastery summscore (QC): NN380 NN381 NN382 NN383 NN384"
fre out_q8yrs_master_score1
gen out_q8yrs_master_score2=NN380+NN381+NN382+NN383+NN384-5
label variable out_q8yrs_master_score2 "child's reading & writing mastery summscore (QA/B): NN254 NN255 NN256 NN257"
fre out_q8yrs_master_score2


//Will leave these variables in, but use imputation to merge. The issue here is that the older version of the question is very different.
//So it asks much more simple questions which are not really good for the age of kids. 

*check
desc *NN254 *NN255 *NN256 *NN257,f
fre *NN254 *NN255 *NN256 *NN257

********************************************************

*Q29: Pronunciation, ability to tell a story,
*ability to communicate his/her own needs in a way understandable to adults and friends?
*The Child's Pronunciation. 2 questions about understandability of the child's speech; 2 questions about the child's narrative skills
fre NN258 NN259 NN260 NN261 
*fix multiple ticks
foreach var of varlist NN258 NN259 NN260 NN261 {
recode `var' 0=.
*also the 2+3, 3+4 and 4+5 categories: for consistency with other educ measures, recode to the midpoint:
recode `var' 23=2.5
recode `var' 34=3.5
recode `var' 45=4.5
gen out_q8yrs_lang_skills_`var'=`var'
fre out_q8yrs_lang_skills_`var'
}
*make a summary score (bumped down to start at 0):
gen out_q8yrs_lang_skills_score=NN258+NN259+NN260+NN261	-4
label variable out_q8yrs_lang_skills_score "language/communication summ score: NN258+NN259+NN260+NN261"
fre out_q8yrs_lang_skills_score

*check
desc *NN258 *NN259 *NN260 *NN261,f
fre *NN258 *NN259 *NN260 *NN261

********************************************************
*30-31: Home Reading and Self-reading

*How often do you read to your child?
fre NN262
gen out_q8yrs_parentreading_NN262=NN262
*fix multiple ticks
recode out_q8yrs_parentreading_NN262 0=.
*apply original labelling:
label values out_q8yrs_parentreading_NN262 NN262
label variable out_q8yrs_parentreading_NN262 "how often to you read to your child: NN262"
fre out_q8yrs_parentreading_NN262

*VERSION DIFFERENCES: NN263/NN385 NN264/NN386
fre NN263 NN385 NN264 NN386 

//Home reading: 
*merge the two versions of NN263 & NN385
fre NN263 NN385
*nb: merging "does not like it at all" and "is not read to", which are different. need to acknowledge this by changing the labelling
gen out_q8yrs_reading_NN263_NN385=NN263
recode out_q8yrs_reading_NN263_NN385 6=1
replace out_q8yrs_reading_NN263_NN385=NN385 if NN263==.
fre out_q8yrs_reading_NN263_NN385
label variable out_q8yrs_reading_NN263_NN385 "how long the child likes to be read to: NN263 or NN385"
*fix multiple ticks:
recode out_q8yrs_reading_NN263_NN385 0=.
recode out_q8yrs_reading_NN263_NN385 12=1.5 23=2.5 34=3.5 45=4.5
label define out_q8yrs_reading_NN263_NN385 1"doesn't like it at all/not read to" 2"5 minutes or less" 3"6-15 minutes" 4"16-45 minutes" 5">45 minutes"
label values out_q8yrs_reading_NN263_NN385 out_q8yrs_reading_NN263_NN385
fre out_q8yrs_reading_NN263_NN385 

//self-reading:
fre NN264 NN386
*as above, merge the two versions, but change the labelling to acknowledge version differences:
gen out_q8yrs_selfread_NN264_NN386=NN264
recode out_q8yrs_selfread_NN264_NN386 6=1
replace out_q8yrs_selfread_NN264_NN386=NN386 if NN264==.
fre out_q8yrs_selfread_NN264_NN386
label variable out_q8yrs_selfread_NN264_NN386 "for how long does the child read by him/herself: NN264 or NN386"
*fix multiple ticks:
recode out_q8yrs_selfread_NN264_NN386 0=.
recode out_q8yrs_selfread_NN264_NN386 12=1.5 23=2.5 34=3.5 45=4.5
label define out_q8yrs_selfread_NN264_NN386 1"doesn't like it at all/Never read by him/herself" 2"5 minutes or less" 3"6-15 minutes" 4"16-45 minutes" 5">45 minutes"
label values out_q8yrs_selfread_NN264_NN386 out_q8yrs_selfread_NN264_NN386
fre out_q8yrs_selfread_NN264_NN386 

*Kind of things the child reads:
fre NN265
gen out_q8yrs_whatread_NN265=NN265
*don't know to missing
recode out_q8yrs_whatread_NN265 5=.
*fix multiple ticks
recode out_q8yrs_whatread_NN265 0=. 12=1.5 23=2.5 34=3.5 45=4.5
fre out_q8yrs_whatread_NN265
*here, lots of multiple ticks but of non-adjacent categories. code these to missing.
recode out_q8yrs_whatread_NN265 13=. 14=. 15=. 24=. 25=. 35=. 234=.
*apply original labelling:
label values out_q8yrs_whatread_NN265 NN265
label variable out_q8yrs_whatread_NN265 "what does the child read: NN265"
fre out_q8yrs_whatread_NN265


*Generate scale (bumped down to start at 0)
gen out_q8yrs_reading_score=out_q8yrs_parentreading_NN262+out_q8yrs_reading_NN263_NN385+out_q8yrs_selfread_NN264_NN386+out_q8yrs_whatread_NN265-4
label variable out_q8yrs_reading_score "reading behaviour summ score: NN262, NN262/NN385, NN263/NN385, NN265"
fre out_q8yrs_reading_score


*check
desc *NN262 *NN263* *NN264* *NN265*,f
fre *NN262 *NN263* *NN264* *NN265*

***********************************************************************

*34. Difficulties, Impairment and Impact: from Strengths and Difficulties Questionnaire (SDQ)
fre NN388 NN389 NN390 NN391 NN392 NN393 NN394 NN395 NN396
*fix multiple ticks
foreach var of varlist NN388 NN389 NN390 NN391 NN392 NN393 NN394 NN395 NN396 {
	recode `var' 0=.
	fre `var'
	gen out_q8yrs_sdq_`var'=`var'
	}

*check
desc *NN388 *NN389 *NN390 *NN391 *NN392 *NN393 *NN394 *NN395 *NN396,f
fre *NN388 *NN389 *NN390 *NN391 *NN392 *NN393 *NN394 *NN395 *NN396
	
	
keep PREG BARN present out_* rout_*
compress

save "scratch/out_q8yrs",replace


****************************************************

*Last thing: fathers second questionnaire:
use "${raw_data}\Statafiles\PDB2306_Far2_V12.dta", clear
keep F_ID_2306 G__5 G__6 G__7_1 G_21 G_66 ///

*presence flag:
gen present_QF2=1 

*************************************
*ERASE THIS DATA for any fathers who withdrew consent.
*need to merge on F_ID_2306, since PDB2306_Far2_V12.dta doesn't actually contain PREG_ID_2306:
merge 1:m F_ID_2306 using "data\PDB2306_SV_INFO_v12_fathers.dta"
keep if fathers_consent==1
*0 excluded following update to main files
drop _merge
*************************************

*clean auxillary vars: smoking status and income bands
gen dadsmokes_QF2=G_21
recode dadsmokes_QF2 0=. 12/34=.
*bump down
replace dadsmokes_QF2=dadsmokes_QF2-1
label var dadsmokes_QF2 "father's smoking status at F2"
label define dadsmokes_QF2 0"never" 1"ex" 2"current, socially" 3"current, daily"
label values dadsmokes_QF2 dadsmokes_QF2
tab dadsmokes_QF2 G_21
*income
recode G_66 0=.

*finish Dad's BMI:
*clean vars:
foreach var in G__5 G__6 {
summ `var', det
return list
replace `var'=. if `var'<r(mean)-(4*r(sd))
replace `var'=. if `var'>r(mean)+(4*r(sd))
summ `var', det
}
*now make BMI:
gen fathers_bmi_FQ2=G__6/((G__5/100)^2)
label variable fathers_bmi_FQ2 "Father's second Q: bmi from own self-report h & w"
summ fathers_bmi_FQ2, det

save "scratch/cov_qf2",replace

***********************************************************************

*MERGE ALL TOGETHER:

*start with covariates which came from the birth registry file, MBRN:
use "scratch/cov_MBRN", clear
*then stitch on questionnaires in chronological order (remember Q1 has no BARN_NR because pre-birth)
merge m:1 PREG_ID using "scratch/cov_q1"
*10,477 people in birth registry file not in Q1
*433 people in Q1 not in birth registry file
drop _merge
merge m:1 PREG_ID using "scratch/cov_qf"
drop _m
merge 1:1 PREG BARN using "scratch/out_q5_18month"
drop _m
merge 1:1 PREG BARN using "scratch/out_q6_3yrs"
drop _m
merge 1:1 PREG BARN using "scratch/out_q5yrs"
drop _m
merge 1:1 PREG BARN using "scratch/out_q8yrs"
drop _m
merge m:1 PREG using "scratch/cov_qf2"
drop _m

duplicates report PREG BARN
*all good.

*************************
*dad'd composite report variables: for bmi and education, make variables that use self-report or, when not available,  the mum's report.

*income
*check labelling is the same:
fre AA1316 cov_qf_income
gen  cov_q1qf_income=cov_qf_income
replace cov_q1qf_income=AA1316 if cov_qf_income==.
label values cov_q1qf_income FF341
label variable cov_q1qf_income "dad's income during pregnancy, self- and mother-report"
fre cov_q1qf_income

*bmi:
gen cov_q1qf_fathers_bmi=cov_qf_fathers_bmi_sr
replace cov_q1qf_fathers_bmi=cov_q1_fathers_bmi if cov_q1qf_fathers_bmi==.

*smoking:
gen cov_q1qf_dadsmokes=cov_qf_dadsmokes
replace cov_q1qf_dadsmokes=cov_q1_dadsmokes if cov_q1qf_dadsmokes==.
label values cov_q1qf_dadsmokes cov_q1_dadsmokes
label values cov_q1qf_dadsmokes cov_q1_dadsmokes
fre cov_q1qf_dadsmokes

*educ:
gen cov_q1qf_father_educ=cov_qf_father_educ_sr
replace cov_q1qf_father_educ=cov_q1_father_educ if cov_q1qf_father_educ==.
fre cov_q1qf_father_educ
*apply labelling of original var
label list FF16
label values cov_q1qf_father_educ FF16
fre cov_q1qf_father_educ

*************************************************************************
*Now cleaned, make standardized versions of everything:

foreach var in out_q8yrs_smfq out_q8yrs_adhd out_q8yrs_inadhd out_q8yrs_hyadhd out_q8yrs_od out_q8yrs_cd out_q8yrs_scared out_q8yrs_scq out_q8yrs_scq_sci out_q8yrs_scq_rrb {
	egen z`var'=std(`var')
	summ z`var'
	}


********************************************************************
*NOW DROP ANYONE (WHOLE FAMILY) WHERE THE MOTHER WITHDREW CONSENT:
merge m:1 PREG_ID_2306 using "data\PDB2306_SV_INFO_v12_mothers_children.dta"
keep if mothers_consent==1
drop _merge
********************************************************************

*update
compress


save "scratch\main_phenotypes.dta", replace


