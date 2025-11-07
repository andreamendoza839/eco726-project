*========================================================================================
* File name: bracero_aer_replication.do
* Author: Andrea Mendoza
* Date created: 10/29/2025
* Purpose: Replicate the main graphs and tables from bracero paper with replication code
*========================================================================================

* running this code requires the following .ado file by entering in the command prompt:
* ssc install outtable, from(http://fmwww.bc.edu/RePEc/bocode/o)

cap log close _all
clear
global data_folder "/Users/andreamendoza/Desktop/ECO 726/data" //change to individual data directory
global results_folder "/Users/andreamendoza/Desktop/ECO 726/results" //change to individual results directory
global code_folder "/Users/andreamendoza/Desktop/ECO 726/results" //change to individual code directory, for log file


cd "$data_folder"
log using "$code_folder/bracero_aer_replication.log", name (AM) replace 

* read in bracero aer dataset 
use "bracero_aer_dataset_prep.dta", clear

* recreate table 1: bracero on wages
preserve
keep if quarterly_flag
xtset State_FIPS time_q
gen time_q_plus = time_q + 100   
fvset base 0 time_q_plus
eststo clear
eststo: qui xtreg realwage_hourly treatment_frac i.time_q_plus, fe vce(cluster State_FIPS)
eststo: qui xtreg realwage_daily treatment_frac i.time_q_plus, fe vce(cluster State_FIPS)
eststo: qui xtreg realwage_hourly treatment_frac i.time_q_plus if Year>=1960 & Year<=1970, fe vce(cluster State_FIPS)
eststo: qui xtreg realwage_daily treatment_frac i.time_q_plus if Year>=1960 & Year<=1970, fe vce(cluster State_FIPS)

* write table 1 to tex
esttab using "$results_folder/tables_bracero_1.tex", se ar2 nostar compress replace keep(treatment_frac) ///
	booktabs alignment(D{.}{.}{-1}) title(TABLE 1: Differences-in-differences with continuous treatment, quarterly)  ///
	scalars(N_clust) 

* table 1 semielasticity
mat pvals = (.)
eststo clear
eststo: qui xtreg ln_realwage_hourly treatment_frac i.time_q_plus, fe vce(cluster State_FIPS)
test _b[treatment_frac]=.1
mat new_p = (r(p))
mat pvals = pvals\new_p
eststo: qui xtreg ln_realwage_daily treatment_frac i.time_q_plus, fe vce(cluster State_FIPS)
test _b[treatment_frac]=.1
mat new_p = (r(p))
mat pvals = pvals\new_p
eststo: qui xtreg ln_realwage_hourly treatment_frac i.time_q_plus if Year>=1960 & Year<=1970, fe vce(cluster State_FIPS)
test _b[treatment_frac]=.1
mat new_p = (r(p))
mat pvals = pvals\new_p
eststo: qui xtreg ln_realwage_daily treatment_frac i.time_q_plus if Year>=1960 & Year<=1970, fe vce(cluster State_FIPS)
test _b[treatment_frac]=.1
mat new_p = (r(p))
mat pvals = pvals\new_p

esttab using "$results_folder/tables_bracero_1.tex", se ar2 nostar compress append keep(treatment_frac) ///
	booktabs alignment(D{.}{.}{-1}) title(TABLE 1: Semielasticities, DD with continuous treatment, quarterly)  ///
	scalars(N_clust) 

mat pvals = pvals[2...,1...]	// Drop leading blank
mat pvals = pvals'			// transpose for LaTeX conversion
outtable using tables_bracero_b, mat(pvals) append norowlab nobox caption("TABLE 1: p vals of semielasticities") format(%5.4f %5.4f %5.4f %5.4f)
restore

* recreate table 2: bracero on employment
sort State_FIPS time_m
by State_FIPS: egen time_num = seq()
fvset base 0 Year
fvset base 0 Month
fvset base 0 time_num 	
				
eststo clear
eststo: xtreg domestic_seasonal treatment_frac i.time_num, fe vce(cluster State_FIPS)
eststo: xtreg ln_domestic_seasonal treatment_frac i.time_num, fe vce(cluster State_FIPS)
eststo: xtreg domestic_seasonal treatment_frac i.time_num if Year>=1960 & Year<=1970, fe vce(cluster State_FIPS)
eststo: xtreg ln_domestic_seasonal treatment_frac i.time_num if Year>=1960 & Year<=1970, fe vce(cluster State_FIPS)
eststo: xtreg domestic_seasonal treatment_frac i.time_num if !none, fe vce(cluster State_FIPS)
eststo: xtreg ln_domestic_seasonal treatment_frac i.time_num if !none, fe vce(cluster State_FIPS)

* write table 2 to tex 
esttab using "$results_folder/tables_bracero_2.tex", se ar2 nostar compress replace keep(treatment_frac) ///
	booktabs alignment(D{.}{.}{-1}) title(TABLE 2: Differences-in-differences with continuous treatment, monthly, Jan 1954--Jul 1973 only)  ///
	scalars(N_clust ) 

* recreate table 3: bracero and interstate employment
eststo clear
eststo: xtreg Local_final treatment_frac i.time_num, fe vce(cluster State_FIPS)
eststo: xtreg Intrastate_final treatment_frac i.time_num, fe vce(cluster State_FIPS)
eststo: xtreg Interstate_final treatment_frac i.time_num, fe vce(cluster State_FIPS)
eststo: xtreg ln_local treatment_frac i.time_num, fe vce(cluster State_FIPS)
eststo: xtreg ln_intrastate treatment_frac i.time_num, fe vce(cluster State_FIPS)
eststo: xtreg ln_interstate treatment_frac i.time_num, fe vce(cluster State_FIPS)

* write table 3 to tex 
esttab using "$results_folder/tables_bracero_3.tex", se ar2 nostar compress replace keep(treatment_frac) ///
	booktabs alignment(D{.}{.}{-1}) title(TABLE 3: Differences-in-differences with continuous treatment, monthly)  ///
	scalars(N_clust ) 
