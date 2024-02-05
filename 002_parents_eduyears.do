//This creates a cleaned data file for parents education from the linked data

clear all

cd "N:\durable\projects\parental_educ_mh\"

*Address for raw study data - amend later for publication to GitHub 
global raw_data="N:\durable\data\MoBaPhenoData\PDB2306_MoBa_v12\"

*to use the user-writen files, change the path to the PLUS part:
sysdir
sysdir set PLUS "N:\durable\people\Mandy\Statafiles\ado\plus"

***********************************************************************

//The first digit indicates the level of education
//This corresponds to the ISCED definitions
/*
Level name
0 No education and pre-school education 1
1 Primary education 7
2 Lower secondary education 10
3 Upper secondary, basic 13
4 Upper secondary, final year 13
5 Post-secondary not higher education 15
6 First stage of higher education, undergraduate level 19
7 First stage of higher education, graduate level 19
8 Second stage of higher education (postgraduate education) 22
9 Unspecified
*/

/*UPDATE 23/01/23: Fartein says:
1: 7 (primary)
2: 9 (lower secondary)
3: 11 (this is tricky, one could also argue for 12 or 11.5)
4: 13 (upper secondary)
5: This is tricky, it could vary from 13 to 15, so maybe set 14?
6: 16 (bachelor)
7: 18 (master)
8: 21 (phd)

*go with that. 
*/

import delimited "N:\durable\data\SSB\Utdanning\W21_5323_TAB_PERSON.csv", clear 

gen father_eduyears=1 if substr(string(nus2000_far),1,1)=="0"
replace father_eduyears=7 if substr(string(nus2000_far),1,1)=="1"
replace father_eduyears=9 if substr(string(nus2000_far),1,1)=="2"
replace father_eduyears=11 if substr(string(nus2000_far),1,1)=="3"
replace father_eduyears=13 if substr(string(nus2000_far),1,1)=="4"
replace father_eduyears=14 if substr(string(nus2000_far),1,1)=="5"
replace father_eduyears=16 if substr(string(nus2000_far),1,1)=="6"
replace father_eduyears=18 if substr(string(nus2000_far),1,1)=="7"
replace father_eduyears=21 if substr(string(nus2000_far),1,1)=="8"

fre father_eduyears

gen mother_eduyears=1 if substr(string(nus2000_mor),1,1)=="0"
replace mother_eduyears=7 if substr(string(nus2000_mor),1,1)=="1"
replace mother_eduyears=9 if substr(string(nus2000_mor),1,1)=="2"
replace mother_eduyears=11 if substr(string(nus2000_mor),1,1)=="3"
replace mother_eduyears=13 if substr(string(nus2000_mor),1,1)=="4"
replace mother_eduyears=14 if substr(string(nus2000_mor),1,1)=="5"
replace mother_eduyears=16 if substr(string(nus2000_mor),1,1)=="6"
replace mother_eduyears=18 if substr(string(nus2000_mor),1,1)=="7"
replace mother_eduyears=21 if substr(string(nus2000_mor),1,1)=="8"

fre  mother_eduyears

keep pid mother_eduyears father_eduyears
compress
save "scratch/parents_eduyears",replace

//Match onto the child IDs
 import spss using "N:\durable\data\Linkage_files\SSB_link\PDB2306_kobling_SSB&KUHR_Combined_20220112.sav", clear
 rename PID pid
 joinby pid using  "scratch/parents_eduyears",unmatched(both)
 keep if _m==3
 keep PREG BARN father mother_eduyears
 

save  "scratch/parents_eduyears",replace