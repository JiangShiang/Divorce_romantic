clear all
global path /Users/jiangshianghu/Desktop/labor_econ


***Read Data (2001) Control Variables***

use "$path/raw data/cp2001/w1_j_s_lv7.0.dta"
rename w1admarea city
rename w1sx06    sex_charact
recode w1s502    (2 = 1) (1 = 0), gen(female)
global score     w1nright w1cfree w1math
global sibilings w1s203 w1s204 w1s205 w1s206

* merge the dataset with 2001 parent survey
merge m:m stud_id using  "$path/raw data/cp2001_parent/w1_j_p_lv7.0.dta"
keep if _merge == 3
drop _merge


* generate variables of parent's education level
gen father_edu = w1p104 if w1p101==1 & w1p102==1 // parent and male
gen mother_edu = w1p104 if w1p101==1 & w1p102==2 // parent and female
replace father_edu = w1p121 if w1p102==2 // spouse education repoted by mother
replace mother_edu = w1p121 if w1p102==1 // spouse education repoted by fatehr
replace father_edu = . if father_edu > 6 // not valid 
replace mother_edu = . if mother_edu > 6 // not valid

label define edu 1 "國中" 2 "高中" 3 "專科" 4 "大學" 5 "研究所" 6 "其他"
label values father_edu edu
label values mother_edu edu

* generate variable for family income
gen family_income = w1p515 if w1p515 < 7

* generate variables of having confict with child
global child_conflict w1p3062 w1p3063 w1p3064 w1p3065 w1p3066 

foreach v in $child_conflict $sibilings{
replace `v' = . if `v' >96 // no response
tab `v'
}


***Read Data (2007) Treatment Variables***
merge m:m stud_id using "$path/raw data/cp2007/STATA/w4_sf_s_cp_lv7.0.dta"
keep if _merge == 3
drop _merge

* variables of interest
global intact_family w4s2061 w4s2071 // 高中前父母無分居或離婚；高中前父母沒有去世

foreach v in $intact_family {
replace `v' = . if `v' == 99 // no response
tab `v'
}

* generate variables of single family
gen parent_div_sep = (w4s2061==0) if w4s2061 != .
gen parent_death   = (w4s2071==0) if w4s2071 != .

* label the variables of interest
label define sep_div 0 "無父母離婚分居" 1 "有父母離婚分居" 
label values parent_div_sep sep_div
label define death 0 "無父母去世" 1 "有父母去世" 
label values parent_death death

* examine the variables of interest
global single_family parent_div_sep parent_death 
foreach v in $single_family {
tab `v'
}

* consider only single family with parental divorce (exclude death)
drop if parent_death == 1
drop if parent_div_sep == .



***Read Data (2014) Treatment Variables***
merge m:m stud_id using "$path/raw data/cp2014/cpn2014.dta"
keep if _merge==3
drop _merge


global marriage_status_2014   cpn14c1a cpn14c1b cpn14c2a cpn14c2b cpn14c4
global marriage_attitude_2014 cpn14c3_1 cpn14c3_2 cpn14c3_3 cpn14c3_4 cpn14c3_5 cpn14c3_6 
global negativ_symptom_1      cpn14f4_1 cpn14f4_2 cpn14f4_3 cpn14f4_4 cpn14f4_5 cpn14f4_6 
global negativ_symptom_2      cpn14f4_7 cpn14f4_8 cpn14f4_9 cpn14f4_10 cpn14f4_11 cpn14f4_12

* change (1 agree - 5 disagree) to (5 agree - 1 disagree)
label define agreement 5 "非常同意" 4 "同意" 3 "無意見" 2 "不同意" 1 "非常不同意"
foreach v in $marriage_attitude_2014 {
replace `v' = . if `v' > 89 // no response
recode `v' (1 = 5) (2 = 4) (3 = 3) (4 = 2) (5 = 1)
label values `v' agreement
tab `v'
}

* change (1 always - 4 never) to (3 always - 0 never)
label define oftenness 3 "經常" 2 "有時候" 1 "偶爾" 0 "從未" 
foreach v in $marriage_attitude_2014 {
replace `v' = . if `v' > 89 // no response
recode `v' (1 = 5) (2 = 4) (3 = 3) (4 = 2) (5 = 1)
label values `v' agreement
tab `v'
}

foreach v in $marriage_attitude_2014 {
reg `v' parent_div_sep female i.family_income i.father_edu i.mother_edu i.city i.sex_charact $score $sibilings $child_conflict, r
est store reg_`v'
}

outreg2 [reg_cpn14c3_1 reg_cpn14c3_2 reg_cpn14c3_3 reg_cpn14c3_4 reg_cpn14c3_5 reg_cpn14c3_6] using "$path/output/reg_attitude.tex" , replace ///
 dec(3) alpha(0.001, 0.01, 0.05, 0.1) symbol(***, **, *, †) ///
 title("Parental Divore on Marriage Attitude") ctitle("Agreement")


* generate variables of marriage related questions
gen married = (cpn14c1a > 1) // 非未婚：含初婚或已離婚
gen couple  = (cpn14c1b < 3) // 非單身：含同居或非同居伴侶
rename cpn14c2a want_marriage // 現在是否想結婚
rename cpn14c4  num_of_lovers // 高一以來有交過多少男女朋友

* label the outcome variables
label define married 0 "未婚" 1 "初婚或已離婚" 
label values married married
label define couple  0 "單身" 1 "有同居或非同居伴侶" 
label values couple couple

* extract the dataset
keep stud_id female parent* married couple want_marriage num_of_lovers
save "$path/input/preliminary.dta", replace





