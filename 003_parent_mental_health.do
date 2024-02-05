//This creates mental health variables for parents 

clear all

cd "N:\durable\projects\parental_educ_mh\"

*Address for raw study data - amend later for publication to GitHub 
global raw_data= "N:\durable\data\MoBaPhenoData\PDB2306_MoBa_v12\"

*to use the user-writen files, change the path to the PLUS part:
sysdir
sysdir set PLUS "N:\durable\people\Mandy\Statafiles\ado\plus"

**********************************************************************************************
*Start with the BIRTH REGISTRY FILE, which you'll always need the birth registry file to do a pheno-geno linkage.

/*
## Step 1: Read in MoBa Birth Registry file

## This file includes all births in MoBa (in version 12 there are 114,143 children from 112,644 pregnancies)
## key variables: PREG_ID_2306 = main ID for linkage, unique to pregnancy, KJONN=childÂ´s sex, BARN_NR=birth order, 
## FAAR=birth year, MORS_ALDER= mothers age
*/
use "${raw_data}\Statafiles\PDB2306_MBRN_541_v12.dta", clear
keep PREG_ID_2306 BARN_NR 
count

*some people in questionnaires but not in birth registry file.
*make a flag so you can drop them later:
gen present_MBRN=1

**********************************************************************************************
*Q1: by mothers at 17 weeks (no BARN_NR in here as pre-birth!)

merge m:1 PREG_ID_2306 using "${raw_data}\Statafiles\PDB2306_Q1_v12.dta"
*433 unmatched - not in the birth registry file
*how bizarre
*will be a problem as they don't have BARN_NR:
count if BARN_NR==.
*33
*cannot use them for anything, so drop will need to drop them
*DO THIS AT THE END THOUGH - otherwise will need to repeat at every merge

*presence flag:
gen present_Q1=1 if _merge!=1
fre present_Q1

*parents' psych measures?
*have you had Anorexia/ bulimia/ other eating disorder // depression // anxiety
*pairs: before pregnancy, during pregancy
fre AA806 AA807 AA869 AA870 AA878 AA879
*looks like this was a tick vs no tick, so no way to distinguish no from missing among people present at Q1.
*identify people for whom it's definitely a genuine missing by using the _merge variable: they are unmatched from master, i.e. _merge==1. DO NOT CODE .=2 FOR THESE PEOPLE!
*Most will be no's, so assume that. Label as 2.
label define AA806 1"yes" 2"not reported"
foreach var of varlist AA806 AA807 AA869 AA870 AA878 AA879 {
recode `var' .=2 if _merge!=1
label values `var' AA806
fre `var'
}
*Eating disorder screening questions
fre AA1475 AA1476 AA1477 AA1478 AA1479 AA1480 AA1481 AA1482 AA1483 AA1484 AA1485 AA1486 AA1487 AA1488 
*fix multiple ticks
foreach var of varlist AA1475 AA1476 AA1477 AA1478 AA1479 AA1480 AA1481 AA1482 AA1483 AA1484 AA1485 AA1486 AA1487 AA1488 {
recode `var' 0=.
fre `var'
}
*Satisfaction with life scale
fre AA1527 AA1528 AA1529 AA1530 AA1531 
*fix multiple ticks
foreach var of varlist AA1527 AA1528 AA1529 AA1530 AA1531 {
recode `var' 0=.
fre `var'
}
*Hopkins checklist
fre AA1548 AA1549 AA1550 AA1551 AA1552
*fix multiple ticks
foreach var of varlist AA1548 AA1549 AA1550 AA1551 AA1552 {
recode `var' 0=.
recode `var' 12/56=.
fre `var'
}


*trim:
keep PREG_ID_2306 BARN_NR present_MBRN VERSJON_SKJEMA1_TBL1 AA85 AA86 AA87 AA88 AA89  ///
AA806 AA807 AA869 AA870 AA878 AA879 ///
AA1475 AA1476 AA1477 AA1478 AA1479 AA1480 AA1481 AA1482 AA1483 AA1484 AA1485 AA1486 AA1487 AA1488 ///
AA1527 AA1528 AA1529 AA1530 AA1531 ///
AA1548 AA1549 AA1550 AA1551 AA1552 /// 
present_Q1 

*save as temp file while you sort out the father's file:
save "scratch/temp.dta", replace

count if BARN_NR==.
*433

**********************************************************************************************
*QF: first fathers questionnaire, 17 week

use  "${raw_data}\Statafiles\PDB2306_QF_v12.dta", clear

keep PREG_ID_2306 FF15 FF16-FF363 FF214-FF474 ///
FF251 FF252 FF253 FF254 FF255 FF256 FF257 FF258 ///
FF259 FF260 FF261 FF262 FF263 FF264 FF478 FF479 ///
FF266 FF267 FF268  ///
FF146 FF147 FF148 FF386 FF387 FF388 FF389 FF390 FF391 FF392 FF393 FF394 FF395 FF386 FF397 FF398 FF399 FF400 ///
FF480- FF529  ///
FF269 FF270 FF271 FF272 FF273 ///
FF535 FF536 FF537 FF538 FF539 FF540 ///
FF277 FF278 FF279 FF280 FF281 FF282

*presence flag:
gen present_QF=1 
*76,987

*******************************************************
*ERASE THIS DATA for any fathers who withdrew consent:
merge 1:1 PREG_ID_2306 using "data\PDB2306_SV_INFO_v12_fathers.dta"
list F_ID_2306 if _merge==1
keep if fathers_consent==1
*99 excluded
*before updates of Nov 22, 318 excluded
drop _merge

*******************************************************

*MH: reported health problems: 
*in each case: yes/no for ever had, age started, and age stopped
*15. Sleep problems 
fre FF146 FF147 FF148
*25. ADHD 
fre FF386 FF387 FF388 
*26. Anorexia/bulimia/eating disorders 
fre FF389 FF390 FF391 
*27. Manic depressive illness 
fre FF392 FF393 FF394 
*28. Schizophrenia
fre FF395 FF386 FF397 
*29. Other long-term mental illnesses or health problems 
fre FF398 FF399 FF400

*ever/never:
fre FF146 FF386 FF389 FF392 FF395 FF398 /*if _merge!=1*/
*for ever had, was a tick vs no tick, so no way to distinguish no from missing among people present at F1.
*identify people for whom it's definitely a genuine missing by using the _merge variable: they are unmatched from master, i.e. _merge==1. DO NOT CODE .=2 FOR THESE PEOPLE!
*Most will be no's, so assume that. Label as 2.
*label define AA806 1"yes" 2"not reported"
foreach var of varlist FF146 FF386 FF389 FF392 FF395 FF398 {
recode `var' .=2 /*if _merge!=1*/
label values `var' AA806
fre `var'
}
*cell counts so small this will be pretty useless for imputation

*Q66: Hopkins checklist
fre FF251 FF252 FF253 FF254 FF255 FF256 FF257 FF258
*fix multiple ticks
foreach var of varlist FF251 FF252 FF253 FF254 FF255 FF256 FF257 FF258 {
recode `var' 0=.
fre `var'
}
*67-68: Lifetime history of depression:
fre FF259 FF260 FF261 FF262 FF263 FF264 
fre FF478 FF479
*fix multiple ticks
foreach var of varlist FF259 FF260 FF261 FF262 FF263 FF264  {
recode `var' 0=.
fre `var'
}
*For the last 2 items - how many times have you had 3 of these symptoms at once, and for how many weeks,
*the 0s are legit. Leave those.

*69 Rosenberg self-esteem:
fre FF266 FF267 FF268
*fix multiple ticks
foreach var of varlist FF266 FF267 FF268  {
recode `var' 0=.
fre `var'
}
*70 Big 5 Personality
fre FF480- FF529
foreach var of varlist FF480- FF529  {
recode `var' 0=.
fre `var'
}
*71 Satisfaction with life scale
fre FF269 FF270 FF271 FF272 FF273
foreach var of varlist FF269 FF270 FF271 FF272 FF273  {
recode `var' 0=.
fre `var'
}
*72 Adult ADHD
fre FF535 FF536 FF537 FF538 FF539 FF540 
foreach var of varlist FF535 FF536 FF537 FF538 FF539 FF540  {
recode `var' 0=.
fre `var'
}
*78: Differential emotional scale, enjoyment and anger subscales
fre FF277 FF278 FF279 FF280 FF281 FF28
foreach var of varlist FF277 FF278 FF279 FF280 FF281 FF28  {
recode `var' 0=.
fre `var'
}

*then merge back into growing file:
merge 1:m PREG_ID_2306 using "scratch/temp.dta"
drop _merge

***********************************************************************************************
*Q3: parental MH vars 

merge m:1 PREG_ID_2306 using "${raw_data}\Statafiles\PDB2306_Q3_v12.dta", ///
keepus (PREG_ID_2306 CC676 CC677 CC678 CC679 CC680 CC688 CC689 CC690 CC691 CC692 ///
CC1202 CC1203 CC1204 CC1205 CC1206 CC1207 CC1208 CC1209 ///
CC1210 CC1211 CC1212 CC1213 CC1214 CC1215 ///
CC1224 CC1225 CC1226 CC1227 CC1228 ///
CC1229 CC1230 CC1231 CC1232)

*presence flag:
gen present_Q3=1 if _merge!=1
fre present_Q3

*Q52, pt 29: depression at diff stages of preganancy
fre CC676 CC677 CC678 CC679 CC680 
*pt 30: other psychological problem, at different stages
fre CC688 CC689 CC690 CC691 CC692 

*looks like this was a tick vs no tick, so no way to distinguish no from missing among people present at Q1.
*identify people for whom it's definitely a genuine missing by using the _merge variable: they are unmatched from master, i.e. _merge==1. DO NOT CODE .=2 FOR THESE PEOPLE!
foreach var of varlist CC676 CC677 CC678 CC679 CC680 CC688 CC689 CC690 CC691 CC692 {
recode `var' .=2 if _merge!=1
label values `var' AA806
fre `var'
}
*123. Hopkins checklist
fre CC1202 CC1203 CC1204 CC1205 CC1206 CC1207 CC1208 CC1209
*fix multiple ticks
foreach var of varlist CC1202 CC1203 CC1204 CC1205 CC1206 CC1207 CC1208 CC1209 {
recode `var' 0=.
fre `var'
}
*124. Emotion: Enjoyment and Anger: Differential Emotional Scale (DES), Enjoyment and Anger Subscales
fre CC1210 CC1211 CC1212 CC1213 CC1214 CC1215
*fix multiple ticks
foreach var of varlist CC1210 CC1211 CC1212 CC1213 CC1214 CC1215 {
recode `var' 0=.
fre `var'
}
*126 Satisfaction with life scale
fre CC1224 CC1225 CC1226 CC1227 CC1228
*fix multiple ticks
foreach var of varlist CC1224 CC1225 CC1226 CC1227 CC1228 {
recode `var' 0=.
fre `var'
}
*127. The Rosenberg Self-Esteem Scale (RSES)
fre CC1229 CC1230 CC1231 CC1232
*fix multiple ticks
foreach var of varlist CC1229 CC1230 CC1231 CC1232 {
recode `var' 0=.
fre `var'
}
drop _merge
**********************************************************************************************

*Q4 parental MH vars 
merge 1:1 PREG_ID_2306 BARN_NR using "${raw_data}\Statafiles\PDB2306_Q4_6months_v12.dta", ///
keepus (PREG_ID_2306 BARN_NR DD537 DD538 DD539 ///
DD794 DD795 DD796 DD797 DD798 DD799 ///
DD800 DD801 DD802 DD803 DD804 ///
DD827 DD828 DD829 DD830 DD831 DD832 ///
DD833 DD834 DD835  DD836 ///
DD837 DD838 DD839 DD840 DD841 DD842 DD843 DD844)

*presence flag:
gen present_Q4=1 if _merge!=1
fre present_Q4

*MH probs in last part of pregnancy and after the births
fre DD537 DD538 DD539
*like in Q1, this was a tick vs no tick, so no way to distinguish no from missing.
*Most will be no's, so assume that. Label as 2.
*label define AA806 1"yes" 2"not reported"
foreach var of varlist DD537 DD538 DD539 {
recode `var' .=2 if _merge!=1
label values `var' AA806 
fre `var'
}
*89. Emotion: Enjoyment and Anger: Differential Emotional Scale (DES), Enjoyment and Anger Subscales
fre DD794 DD795 DD796 DD797 DD798 DD799
*fix multiple ticks
foreach var of varlist DD794 DD795 DD796 DD797 DD798 DD799 {
recode `var' 0=.
fre `var'
}
*90. Life Satisfaction: The Satisfaction With Life Scale (SWLS)
fre DD800 DD801 DD802 DD803 DD804
*fix multiple ticks
foreach var of varlist DD800 DD801 DD802 DD803 DD804 {
recode `var' 0=.
fre `var'
}
*92. Postnatal Depression: Edinburgh Postnatal Depression Scale (EPDS)
fre DD827 DD828 DD829 DD830 DD831 DD832
*fix multiple ticks
foreach var of varlist DD827 DD828 DD829 DD830 DD831 DD832 {
recode `var' 0=.
fre `var'
}
*93. Rosenberg Self Esteem Scale: The Rosenberg Self-Esteem Scale (RSES)
fre DD833 DD834 DD835  DD836
*fix multiple ticks
foreach var of varlist DD833 DD834 DD835  DD836 {
recode `var' 0=.
fre `var'
}
*94. Hopkins Checklist
fre DD837 DD838 DD839 DD840 DD841 DD842 DD843 DD844
*fix multiple ticks
foreach var of varlist DD837 DD838 DD839 DD840 DD841 DD842 DD843 DD844 {
recode `var' 0=.
fre `var'
}

drop _merge
**********************************************************************************************

*Q5: PARENTAL MENTAL HEALTH
 
merge 1:1 PREG_ID_2306 BARN_NR using "${raw_data}\Statafiles\PDB2306_Q5_18months_v12.dta", ///
keepus (PREG_ID_2306 BARN_NR ///
EE898 EE884 EE885 ///
EE925 EE926 EE927 EE928 EE929 EE930 EE931 EE932 EE933 EE934 EE935 EE936 EE937 EE938 EE939 EE940 EE941 EE942 EE943 ///
EE628 EE629 EE630 EE631 EE632 EE633 ///
EE634 EE635 EE636 EE637 ///
EE638 EE639 EE640 EE641 EE642 EE643 EE644 EE645 ///
EE671 EE672 EE673 EE674 EE675 EE676 EE677 EE678 EE679 EE680 EE681 EE682 EE683 EE684 EE685 EE686 EE687 EE688 EE689 EE690 EE691 EE692 EE693 EE694 EE695 EE696 )

*presence flag:
gen present_Q5=1 if _merge!=1
fre present_Q5

*69-71. Mum's Eating Disorders
fre EE925 EE926 EE927 EE928 EE929 EE930 EE931 EE932 EE933 EE934 EE935 EE936 EE937 EE938 EE939 EE940 EE941 EE942 EE943
*fix multiple ticks
foreach var of varlist EE925 EE926 EE927 EE928 EE929 EE930 EE931 EE932 EE933 EE934 EE935 EE936 EE937 EE938 EE939 EE940 EE941 EE942 EE943  {
recode `var' 0=.
fre `var'
}

*97. Emotion: Enjoyment and Anger: Differential Emotional Scale (DES), Enjoyment and Anger Subscales
fre EE628 EE629 EE630 EE631 EE632 EE633
*fix multiple ticks
foreach var of varlist EE628 EE629 EE630 EE631 EE632 EE633  {
recode `var' 0=.
fre `var'
}

*98. The Rosenberg Self-Esteem Scale: Selective questions from the Rosenberg Self-Esteem Scale (RSES)
fre EE634 EE635 EE636 EE637
foreach var of varlist EE634 EE635 EE636 EE637  {
recode `var' 0=.
fre `var'
}
*99. Depression/Anxiety: Selective items from the (Hopkins) Symptoms Checklist-25 (SCL-25)
fre EE638 EE639 EE640 EE641 EE642 EE643 EE644 EE645
foreach var of varlist EE638 EE639 EE640 EE641 EE642 EE643 EE644 EE645  {
recode `var' 0=.
fre `var'
}
*101-107. World Health Organization's Quality of Life Instrument
fre EE671 EE672 EE673 EE674 EE675 EE676 EE677 EE678 EE679 EE680 EE681 EE682 EE683 EE684 EE685 EE686 EE687 EE688 EE689 EE690 EE691 EE692 EE693 EE694 EE695 EE696
foreach var of varlist EE671 EE672 EE673 EE674 EE675 EE676 EE677 EE678 EE679 EE680 EE681 EE682 EE683 EE684 EE685 EE686 EE687 EE688 EE689 EE690 EE691 EE692 EE693 EE694 EE695 EE696  {
recode `var' 0=.
fre `var'
}

drop _merge

*********************************************************************************

*Q6: PARENTAL HOPKINS, PARENTAL ADHD

//Get Maternal ADHD and MH questions from the Q6 data. 
merge 1:1 PREG_ID_2306 BARN_NR using "$raw_data/Statafiles\PDB2306_Q6_3yrs_v12.dta", keepus(PREG_ID_2306 BARN_NR GG503 GG504 GG505 GG506 GG507 GG508 GG514 GG515 GG516 GG517 GG518 GG519 GG520 GG521)

*fix multiple ticks:
foreach var in GG503 GG504 GG505 GG506 GG507 GG508 GG514 GG515 GG516 GG517 GG518 GG519 GG520 GG521 {
fre `var'
recode `var' 0=.
}

*presence flag:
gen present_Q6=1 if _merge!=1
fre present_Q6

drop _merge


*******************************************************************************************************************
*Q5yr: PARENTAL HOPKINS

merge 1:1 PREG_ID_2306 BARN_NR using "$raw_data/Statafiles\PDB2306_Q5yrs_v12.dta", keepus(LL363 LL364 LL365 LL366 LL367 LL368 LL369 LL370 )

*presence flag:
gen present_Q5y=1 if _merge!=1
fre present_Q5y 

*Most of this section looks fiddly as hell - text entries and differences between versions
*50 Have you ever had any problems with your physical or mental health that has prevented you in your work or social activities with family or friends?  LL361- LL363, last one for degree of MH impairment
fre LL363 LL364 LL365 LL366 LL367 LL368 LL369 LL370

**fix multiple ticks
foreach var of varlist LL363 LL364 LL365 LL366 LL367 LL368 LL369 LL370 {
recode `var' 0=.
fre `var'
}

*51 (Hopkins) Symptoms Checklist-25 (SCL-25)
fre LL363 LL364 LL365 LL366 LL367 LL368 LL369 LL370

drop _merge

*********************************************************************************

*Q8yr: PARENTAL HOPKINS

*52. Depression/Anxiety: Selective items from the (Hopkins) Symptoms Checklist-25 (SCL-25)
merge 1:1 PREG_ID_2306 BARN_NR using "$raw_data/Statafiles\PDB2306_Q8yrs_v12.dta", keepus(PREG_ID_2306 BARN_NR NN325 NN326 NN327 NN328 NN329 NN330 NN331 NN332)

*presence flag:
gen present_Q8yr=1 if _merge!=1
fre present_Q8yr

*Hopkins checklist:
fre NN325-NN332
*fix multiple ticks
foreach var of varlist NN325-NN332  {
recode `var' 0=.
fre `var'	
}

drop _merge
save "scratch/temp.dta",replace

****************************************************
*Last thing: fathers second questionnaire:
use "${raw_data}\Statafiles\PDB2306_Far2_V12.dta", clear
keep F_ID_2306  ///
/*health conditions*/ G__230_1 G__230_2 G__231_1 G__231_2 G__232_1 G__232_2 G__233_1 G__233_2 G__234_1 G__234_2 ///
/*satisfaction with life scale*/  G_51_1 G_51_2 G_51_2 G_51_3 G_51_4 G_51_5 ///
/*Hopkins 12-item version*/ G_52_1 G_52_2 G_52_3 G_52_4 G_52_5 G_52_6 G_52_7 G_52_8 G_52_9 G_5210 G_5211 G_5212 ///
/*suicide ideation and attempts*/ G_54 G_55 ///
/*psychosis symptoms*/ G_56_1_1 G_56_1_2 G_56_2_1 G_56_2_2 G_56_3_1 G_56_4_1 G_56_4_2 G_56_5_1 G_56_5_2 G_56_6_1 G_56_6_2 G_56_7_1 G_56_7_2 G_56_8_1 G_56_8_2 G_56_9_1 G_56_9_2

*presence flag:
gen present_QF2=1 

**********************************************
*ERASE THIS DATA for any fathers who withdrew consent.
*need to merge on F_ID_2306, since PDB2306_Far2_V12.dta doesn't actually contain PREG_ID_2306:
merge 1:m F_ID_2306 using "data\PDB2306_SV_INFO_v12_fathers.dta"
keep if fathers_consent==1
*0 excluded
drop _merge
**********************************************

*then merge back into growing file:
merge 1:m PREG_ID_2306 using "scratch/temp.dta"

*sort out:
*MH stuff:
/*specific relevant health conds and age when */
fre G__230_1 G__230_2 G__231_1 G__231_2 G__232_1 G__232_2 G__233_1 G__233_2 G__234_1 G__234_2
*fix multiple ticks in the yes/no items:
foreach var of varlist G__230_1 G__231_1 G__232_1 G__233_1 G__234_1 {
recode `var' 0=.
fre `var'	
}
/*satisfaction with life scale*/  
fre G_51_1 G_51_2 G_51_2 G_51_3 G_51_4 G_51_5 
*fix multiple ticks:
foreach var of varlist G_51_1 G_51_2 G_51_2 G_51_3 G_51_4 G_51_5  {
recode `var' 0=.
fre `var'	
}
/*Hopkins*/ 
*CAREFUL! IN THE SECOND FATEHR'S QUESTIONNAIRE, IT'S A 12-ITEM VERSION RATHER THAN THE USUAL 8
fre G_52_1 G_52_2 G_52_3 G_52_4 G_52_5 G_52_6 G_52_7 G_52_8 G_52_9 G_5210 G_5211 G_5212
*fix multiple ticks:
foreach var of varlist G_52_1 G_52_2 G_52_3 G_52_4 G_52_5 G_52_6 G_52_7 G_52_8 G_52_9 G_5210 G_5211 G_5212  {
recode `var' 0=.
fre `var'	
}
/*suicide ideation and attempts*/ 
fre G_54 G_55 
*multiple ticks:
recode G_54 0=.
recode G_55 0=.
fre G_54 G_55 

/*psychosis symptoms*/ 
fre G_56_1_1 G_56_1_2 G_56_2_1 G_56_2_2 G_56_3_1 G_56_4_1 G_56_4_2 G_56_5_1 G_56_5_2 G_56_6_1 G_56_6_2 G_56_7_1 G_56_7_2 G_56_8_1 G_56_8_2 G_56_9_1 G_56_9_2
*fix multiple ticks:
foreach var of varlist G_56_1_1 G_56_1_2 G_56_2_1 G_56_2_2 G_56_3_1 G_56_4_1 G_56_4_2 G_56_5_1 G_56_5_2 G_56_6_1 G_56_6_2 G_56_7_1 G_56_7_2 G_56_8_1 G_56_8_2 G_56_9_1 G_56_9_2  {
recode `var' 0=.
fre `var'	
}

drop _merge

****************************************************************************************************************************************************************
**PREP FOR PARENTAL HOPKINS AND ADHD SUMMARY SCORES.

*As with kids measures at 8yr, make a complete-case version of the summary var and also an average item response, to use in the imputation.

*ADD UP PARENTAL HOPKINS CHECKLISTS
*to impute summary scores. To use the information from people who answered some items but not all, calculate per-item average and include in the imputation

*mother Q1
*missingness
gen nitems_mhopkins_Q1=0
foreach var of varlist AA1548 AA1549 AA1550 AA1551 AA1552 {
replace nitems_mhopkins_Q1=nitems_mhopkins_Q1+1 if `var'!=.
}
fre nitems_mhopkins_Q1 if present_Q1==1
*complete case:
gen cc_mhopkins_Q1=(AA1548 + AA1549 + AA1550 + AA1551 + AA1552)
*bump down to start at 0:
replace cc_mhopkins_Q1=cc_mhopkins_Q1-5
*allowing 20% missingness
egen miss20pc_mhopkins_Q1=rowtotal(AA1548 AA1549 AA1550 AA1551 AA1552)
replace miss20pc_mhopkins_Q1=miss20pc_mhopkins_Q1*(5/4) if nitems_mhopkins_Q1==4
replace miss20pc_mhopkins_Q1=. if nitems_mhopkins_Q1<4
*bump down
replace miss20pc_mhopkins_Q1=miss20pc_mhopkins_Q1-5
fre miss20pc_mhopkins_Q1
*check
tab miss20pc_mhopkins_Q1 cc_mhopkins_Q1 , mi
*rename to be default:
rename miss20pc_mhopkins_Q1 mhopkins_Q1

*QF
*missingness
gen nitems_fhopkins_QF=0
foreach var of varlist FF251 FF252 FF253 FF254 FF255 FF256 FF257 FF258 {
replace nitems_fhopkins_QF=nitems_fhopkins_QF+1 if `var'!=.
}
fre nitems_fhopkins_QF if present_QF==1 
*complete case:
gen cc_fhopkins_QF=(FF251 + FF252 + FF253 + FF254 + FF255 + FF256 + FF257 + FF258)
*bump down to start at 0:
replace cc_fhopkins_QF=cc_fhopkins_QF-8
*allowing 20% missingenss:
egen miss20pc_fhopkins_QF=rowtotal(FF251 FF252 FF253 FF254 FF255 FF256 FF257 FF258)
replace miss20pc_fhopkins_QF=miss20pc_fhopkins_QF*(8/7) if nitems_fhopkins_QF==7
replace miss20pc_fhopkins_QF=. if nitems_fhopkins_QF<7
*bump down
replace miss20pc_fhopkins_QF=miss20pc_fhopkins_QF-8
fre miss20pc_fhopkins_QF
*check
tab miss20pc_fhopkins_QF cc_fhopkins_QF , mi
*list cc_fhopkins_QF  nitems_fhopkins_QF miss20pc_fhopkins_QF FF251 FF252 FF253 FF254 FF255 FF256 FF257 FF258 if miss20pc_fhopkins_QF<0
*rename to be default:
rename miss20pc_fhopkins_QF fhopkins_QF

*Q6 HOPKINS

*missingess
gen nitems_mhopkins_Q6=0
foreach var of varlist GG514 GG515 GG516 GG517 GG518 GG519 GG520 GG521 {
replace nitems_mhopkins_Q6=nitems_mhopkins_Q6+1 if `var'!=.
}
//fre nitems_mhopkins_Q6 if present_Q6==1
*complete case:
gen cc_mhopkins_Q6=(GG514 + GG515 + GG516 + GG517 + GG518 + GG519 + GG520 + GG521)
*bump down to start at 0:
replace cc_mhopkins_Q6=cc_mhopkins_Q6-8
*allowing 20% missingness
egen miss20pc_mhopkins_Q6=rowtotal(GG514 GG515 GG516 GG517 GG518 GG519 GG520 GG521)
replace miss20pc_mhopkins_Q6=miss20pc_mhopkins_Q6*(8/7) if nitems_mhopkins_Q6==7
replace miss20pc_mhopkins_Q6=. if nitems_mhopkins_Q6<7
*bump down
replace miss20pc_mhopkins_Q6=miss20pc_mhopkins_Q6-8
fre miss20pc_mhopkins_Q6
*check
tab miss20pc_mhopkins_Q6 cc_mhopkins_Q6, mi
*rename to be default:
rename miss20pc_mhopkins_Q6 mhopkins_Q6

*Q5yr HOPKINS
*missingess
gen nitems_mhopkins_Q5y=0
foreach var of varlist LL363 LL364 LL365 LL366 LL367 LL368 LL369 LL370 {
replace nitems_mhopkins_Q5y=nitems_mhopkins_Q5y+1 if `var'!=.
}
fre nitems_mhopkins_Q5y if present_Q5y==1
*complete case:
gen cc_mhopkins_Q5y=(LL363 + LL364 + LL365 + LL366 + LL367 + LL368 + LL369 + LL370)
*bump down to start at 0:
replace cc_mhopkins_Q5y=cc_mhopkins_Q5y-8
*allowing 20% missingness
egen miss20pc_mhopkins_Q5y=rowtotal(LL363 LL364 LL365 LL366 LL367 LL368 LL369 LL370)
replace miss20pc_mhopkins_Q5y=miss20pc_mhopkins_Q5y*(8/7) if nitems_mhopkins_Q5y==7
replace miss20pc_mhopkins_Q5y=. if nitems_mhopkins_Q5y<7
*bump down
replace miss20pc_mhopkins_Q5y=miss20pc_mhopkins_Q5y-8
fre miss20pc_mhopkins_Q5y
*check
tab miss20pc_mhopkins_Q5y cc_mhopkins_Q5y , mi
*rename to be default:
rename miss20pc_mhopkins_Q5y mhopkins_Q5y


*Q8yr HOPKINS
*missingess
gen nitems_mhopkins_Q8y=0
foreach var of varlist NN325 NN326 NN327 NN328 NN329 NN330 NN331 NN332  {
replace nitems_mhopkins_Q8y=nitems_mhopkins_Q8y+1 if `var'!=.
}
fre nitems_mhopkins_Q8y if present_Q8y==1
*complete case:
gen cc_mhopkins_Q8y=(NN325 + NN326 + NN327 + NN328 + NN329 + NN330 + NN331 + NN332)
*bump down to start at 0:
replace cc_mhopkins_Q8y=cc_mhopkins_Q8y-8
*allowing 20% missingness
egen miss20pc_mhopkins_Q8y=rowtotal(NN325 NN326 NN327 NN328 NN329 NN330 NN331 NN332)
replace miss20pc_mhopkins_Q8y=miss20pc_mhopkins_Q8y*(8/7) if nitems_mhopkins_Q8y==7
replace miss20pc_mhopkins_Q8y=. if nitems_mhopkins_Q8y<7
*bump down
replace miss20pc_mhopkins_Q8y=miss20pc_mhopkins_Q8y-8
fre miss20pc_mhopkins_Q8y
*check
tab miss20pc_mhopkins_Q8y cc_mhopkins_Q8y , mi
*rename to be default:
rename miss20pc_mhopkins_Q8y mhopkins_Q8y

*F2 HOPKINS
*missingess
gen nitems_fhopkins_QF2=0
foreach var of varlist G_52_1 G_52_2 G_52_3 G_52_4 G_52_5 G_52_6 G_52_7 G_52_8 G_52_9 G_5210 G_5211 G_5212 {
replace nitems_fhopkins_QF2=nitems_fhopkins_QF2+1 if `var'!=.
}
fre nitems_fhopkins_QF2 if present_QF2==1
*complete case:
gen cc_fhopkins_QF2=(G_52_1 + G_52_2 + G_52_3 + G_52_4 + G_52_5 + G_52_6 + G_52_7 + G_52_8 + G_52_9 + G_5210 + G_5211 + G_5212)
*bump down to start at 0:
replace cc_fhopkins_QF2=cc_fhopkins_QF2-12
*allowing 20% missingness
egen miss20pc_fhopkins_QF2=rowtotal(G_52_1 G_52_2 G_52_3 G_52_4 G_52_5 G_52_6 G_52_7 G_52_8 G_52_9 G_5210 G_5211 G_5212)
replace miss20pc_fhopkins_QF2=miss20pc_fhopkins_QF2*(12/11) if nitems_fhopkins_QF2==11
replace miss20pc_fhopkins_QF2=miss20pc_fhopkins_QF2*(12/10) if nitems_fhopkins_QF2==10
replace miss20pc_fhopkins_QF2=. if nitems_fhopkins_QF2<10
*bump down
replace miss20pc_fhopkins_QF2=miss20pc_fhopkins_QF2-12
fre miss20pc_fhopkins_QF2
*check
tab miss20pc_fhopkins_QF2 cc_fhopkins_QF2 , mi
*rename to be default:
rename miss20pc_fhopkins_QF2 fhopkins_QF2


*Next problem: skewed AF, so not suitable for regression. Log-transform, then exponentiate back after? 
*Or do with POISSON. For which, integers needed? So can't do the upweighting? Apparently it works, just gives you a warning message about interpretation of non-integer values.

*****************
*parental adhd symptoms
*maternal ADHD from Q6
fre GG503 GG504 GG505 GG506 GG507 GG508 

gen nitems_mADHD_Q6=0
foreach var of varlist GG503 GG504 GG505 GG506 GG507 GG508  {
replace nitems_mADHD_Q6=nitems_mADHD_Q6+1 if `var'!=.
}
fre nitems_mADHD_Q6 if present_Q6==1
*complete case
gen cc_mADHD_Q6=(GG503 + GG504 + GG505 + GG506 + GG507 + GG508)
*for descriptives and imputation, bump down to start at 0
replace cc_mADHD_Q6=cc_mADHD_Q6-6
fre cc_mADHD_Q6
*allowing 20% missingness
egen miss20pc_mADHD_Q6=rowtotal(GG503 GG504 GG505 GG506 GG507 GG508)
replace miss20pc_mADHD_Q6=miss20pc_mADHD_Q6*(6/5) if nitems_mADHD_Q6==5
replace miss20pc_mADHD_Q6=. if nitems_mADHD_Q6<5
*bump down
replace miss20pc_mADHD_Q6=miss20pc_mADHD_Q6-6
fre miss20pc_mADHD_Q6
*check
tab miss20pc_mADHD_Q6 cc_mADHD_Q6 , mi
*rename to be default:
rename miss20pc_mADHD_Q6 mADHD_Q6

*paternal ADHD from QF
fre FF535 FF536 FF537 FF538 FF539 FF540  
gen nitems_fADHD_QF=0
foreach var of varlist FF535 FF536 FF537 FF538 FF539 FF540  {
replace nitems_fADHD_QF=nitems_fADHD_QF+1 if `var'!=.
}
fre nitems_fADHD_QF if present_Q6==1
*complete case
gen cc_fADHD_QF=(FF535 + FF536 + FF537 + FF538 + FF539 + FF540)
*for descriptives and imputation, bump down to start at 0
replace cc_fADHD_QF=cc_fADHD_QF-6
fre cc_fADHD_QF
*allowing 20% missingness
egen miss20pc_fADHD_QF=rowtotal(FF535 FF536 FF537 FF538 FF539 FF540)
replace miss20pc_fADHD_QF=miss20pc_fADHD_QF*(6/5) if nitems_fADHD_QF==5
replace miss20pc_fADHD_QF=. if nitems_fADHD_QF<5
*bump down
replace miss20pc_fADHD_QF=miss20pc_fADHD_QF-6
fre miss20pc_fADHD_QF
*check
tab miss20pc_fADHD_QF cc_fADHD_QF , mi
*rename to be default:
rename miss20pc_fADHD_QF fADHD_QF

*******************************************************************************************************
*NOW DROP ANYONE (WHOLE FAMILY) WHERE THE MOTHER WITHDREW CONSENT:
merge m:1 PREG_ID_2306 using "data\PDB2306_SV_INFO_v12_mothers_children.dta"
keep if mothers_consent==1
drop _merge 
*******************************************************************************************************

count
*114215
fre fathers_consent
*87989


compress
save "scratch/parental_mental_health",replace
