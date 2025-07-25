********************************************************************************
* 	PEA code example PHL
* 	(For questions contact Henry Stemmler hstemmler@worldbank.org) /Minh
********************************************************************************
clear all

/* --- Enter your path here --- */
global pea_path "C:/Temp/"

* Pull data from DLW
clear all
datalibweb, country(GNB) year(2010 2018 2021) type(gmd) mod(all) clear

// Data preaprations
gen welfppp = welfare/cpi2021/icp2021/365
label var welfppp "Welfare (constant 2021 PPP)"

* -------------------------------------------------------
* Please add here the correct national welfare aggregate.
* The construction of the national welfare aggregate will 
* depend on the country. For illustrative purposes, we 
* treat variable "welfare" as the national welfare aggregate
gen natwelfare = welfare 
label var natwelfare "Welfare (local currency)"
*--------------------------------------------------------

gen pline300 = 3.00
gen pline420 = 4.20
gen pline830 = 8.30
gen 	natline = 298083.5 if year == 2021
replace natline = 271071.8 if year == 2018
replace natline = 200000 if year == 2010										// Please note that this is not the correct poverty line, it is added for illustrative purposes
la var pline300 "$3.00 per day (2021 PPP)"
la var pline420 "$4.20 per day (2021 PPP)"
la var pline830 "$8.30 per day (2021 PPP)"
la var natline	"National poverty line (2017 LCU)"

// Clean subnational ID - make sure we have the same subnational labels across years
split subnatid, parse("-") gen(tmp)
replace tmp2 = ustrlower( ustrregexra( ustrnormalize( tmp2, "nfd" ) , "\p{Mark}", "" ) )
replace tmp2 = " bolama/bijagos" if tmp2 == " bolama_bijagos"
replace tmp2 = proper(tmp2)
encode tmp2, gen(subnatvar)
label var subnatvar "Regions"
label var urban "Urban or Rural"
replace countrycode = "GNB" if countrycode == ""
// Comparability national poverty for Figure 1 (PEB)
gen comparability_peb = "Yes"
// Clean Labels
local lbl: value label educat4
label define `lbl' 1 "No education" 2 "Primary" 3 "Secondary" 4 "Tertiary", modify
// Survey set
svyset psu [w= weight_p], singleunit(certainty)
save "$pea_path/data/GNB_GMD_ALL_clean.dta", replace

* Let's check whether the aggregates and lines are correct.
// international poverty
gen ipoor = welfppp < pline300
bys year: sum ipoor [aw = weight_p]				// This is correct
// national poverty
gen poor = natwelfare < natline
bys year: sum poor [aw = weight_p]				

// Generate artificial data for forecast example
clear
set obs 4
gen year_fcast = 2021 + 2*_n  
gen gdp_fcast = .
replace gdp_fcast = 429895.7 * 1.03^2 if year == 2023 
replace gdp_fcast = 429895.7 * 1.03^4 if year == 2025  
replace gdp_fcast = 429895.7 * 1.03^6 if year == 2027
replace gdp_fcast = 429895.7 * 1.03^8 if year == 2029
gen natpov_fcast = .
replace natpov_fcast = 51.2 if year == 2023
replace natpov_fcast = 48.8 if year == 2025 
replace natpov_fcast = 47.1 if year == 2027  
replace natpov_fcast = 45.5 if year == 2029  
append using "$pea_path/data/GNB_GMD_ALL_clean.dta"
save "$pea_path/data/GNB_GMD_ALL_clean.dta", replace

********************************************************************************
* Main
********************************************************************************

******************** Core Tables
clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
adopath + "c:\Users\wb327173\OneDrive - WBG\Downloads\ECA\repo\pea\Stata\plus\"
pea core [aw=weight_p], c(GNB) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline420) benchmark(SEN CIV GHA SLE) aggregate(groups) missing setting(GMD) spells(2018 2021) svy std(right) comparability_peb(comparability_peb) year_fcast(year_fcast) natpov_fcast(natpov_fcast) gdp_fcast(gdp_fcast) yrange(20(20)80) yrange2(300000(50000)500000) aggregate(groups)

******************** Appendix Figures
clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
adopath + "c:\Users\wb327173\OneDrive - WBG\Downloads\ECA\repo\pea\Stata\plus\"

pea figures [aw=weight_p], c(GNB) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline300) benchmark(SEN CIV GHA SLE) missing setting(GMD) spells(2018 2021) comparability(comparability) welfaretype(CONS) 

******************** Appendix Tables
clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
adopath + "c:\Users\wb327173\OneDrive - WBG\Downloads\ECA\repo\pea\Stata\plus\"

pea tables [aw=weight_p], c(GNB) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline830) benchmark(SEN CIV GHA SLE) missing setting(GMD) spells(2018 2021) svy std(inside)

********************************************************************************
* Core Table 1
********************************************************************************
clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear

gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
pea_tableC1 [aw=weight_p], c(GNB) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) year(year) onew(welfppp) onel(pline300) benchmark(SEN CIV GHA SLE GNB) lstatus(nowork) empstat(empstat) industrycat4(industrycat4) age(age) male(male) aggregate(groups)


********************************************************************************
* Core Figure 1
********************************************************************************
clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear

pea figureC1 [aw=weight_p], c(GNB) natw(natwelfare) natp(natline) year(year) year_fcast(year_fcast) natpov_fcast(natpov_fcast) gdp_fcast(gdp_fcast) comparability_peb(comparability_peb) yrange(20(20)80) yrange2(300000(50000)500000)

********************************************************************************
* Individual Figures
********************************************************************************
clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear

pea figure1 [aw=weight_p], natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) year(year) urban(urban) comparability(comparability) yrange(0(10)100)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear

pea figure2 [aw=weight_p], c(GNB) year(year) pppw(welfppp) onel(pline300) benchmark(CIV GHA GMB SEN)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear

pea figure3a [aw=weight_p], welfare(welfppp) year(year) spells(2018 2021)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear

pea figure3b [aw=weight_p], welfare(welfppp) year(year) spells(2010 2018; 2018 2021) by(urban)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear

pea figure4 [aw=weight_p], onewelfare(natwelfare) oneline(natline) year(year) spells(2010 2018; 2018 2021) idpl(urban)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear

pea figure5a [aw=weight_p], onewelfare(welfppp) oneline(pline300) year(year) spells(2010 2018; 2018 2021) urban(urban)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear

gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
pea figure5b [aw=weight_p], onewelfare(welfppp) oneline(pline300) year(year) spells(2018 2021) industrycat4(industrycat4) hhhead(head) hhid(hhid)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear

pea figure6 [aw=weight_p], c(GNB) year(year) onew(welfppp) onel(pline300) spells(2010 2018; 2018 2021)   

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure7a [aw=weight_p], onewelfare(natwelfare) oneline(natline) year(year) age(age) male(male) edu(educat4) urban(urban) missing

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure7b [aw=weight_p], onewelfare(natwelfare) oneline(natline) year(year) age(age) male(male) edu(educat4) urban(urban)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure8 [aw=weight_p], onewelfare(natwelfare) oneline(natline) year(year) age(age) male(male)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure9a [aw=weight_p], onewelfare(welfppp) year(year) comparability(comparability)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure9b [aw=weight_p], c(GNB) year(year) onew(welfppp) benchmark(SEN CIV GHA SLE ) within(3) welfaretype(CONS)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure9c [aw=weight_p], c(GNB) year(year) onew(welfppp) benchmark(SEN CIV GHA SLE ) within(3) welfaretype(CONS)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure9d [aw=weight_p],  year(year) onew(natwelfare) comparability(comparability)  

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure10a [aw=weight_p], onewelfare(welfppp) year(year) urban(urban) comparability(comparability) bar

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure10b [aw=weight_p], c(GNB) year(year) onew(welfppp) benchmark(CIV GHA GMB SEN AGA)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure10c [aw=weight_p], c(GNB) year(year) onew(welfppp) benchmark(CIV GHA GMB SEN AGA)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure10d [aw=weight_p], c(GNB) year(year) onew(welfppp) benchmark(CIV GHA GMB SEN AGA)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure12 [aw=weight_p], onewelfare(welfppp) year(year) spells(2010 2018; 2018 2021; 2010 2021) comparability(comparability)  

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure13 [aw=weight_p], onewelfare(welfppp) year(year)    

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure14 [aw=weight_p], country(GNB) welfare(welfppp)  year(year) benchmark(CIV GHA GMB SEN AGA) 

clear all //**issue
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea figure15, c(GNB)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear

gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
gen married = marital==1 if marital~=.
pea figure16 [aw=weight_p], onewelfare(welfppp) oneline(pline300) year(year) 			 	///
							age(age) male(male) hhhead(head) 								///
							married(married) empstat(empstat) 								///	
							hhsize(hsize) hhid(hhid) pid(pid) 								///
							industrycat4(industrycat4) lstatus(nowork) 						///
							 earnage(15) missing

*relationharm(relationharm)
							
											
********************************************************************************
* Individual Tables
********************************************************************************

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea table1 [aw=weight_p], c(GNB) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) year(year) onew(welfppp) onel(pline300) std(inside) svy

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
// Generate urban area to have capital region separate
clonevar urban_cap = urban
replace	 urban_cap = 2 if subnatvar == 8
label define urban 2  "Capital region", modify		
pea table2 [aw=weight_p], natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) year(year) byind(urban_cap) 

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
gen married = marital==1 if marital~=.
pea table3 [aw=weight_p], natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) year(year) age(age) male(male) hhhead(head) edu(educat4) missing

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
gen married = marital==1 if marital~=.
pea table4 [aw=weight_p], welfare(natwelfare) povlines(natline) 						///
						  year(year) urban(urban)									///	
						  missing age(age) male(male) hhhead(head) 					///
						  edu(educat4) married(married) 							///	
						  school(school) 											///
						  services(imp_wat_rec imp_san_rec electricity) 			///
						  assets(tv car cellphone computer fridge) 					///
						  hhsize(hsize) hhid(hhid) pid(pid) 						///
						  industrycat4(industrycat4) lstatus(nowork) 				///
						  empstat(empstat)	

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
pea table5 [aw=weight_p], 	welfare(natwelfare) povlines(natline) year(year) age(age)	///
							male(male) urban(urban) edu(educat4) lstatus(nowork) 	///
							empstat(empstat) industrycat4(industrycat4) missing	
				  
clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea_table6 [aw=weight_p], c(GNB) welfare(welfppp) year(year)  benchmark(CIV)				  
						  
clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea table7 [aw=weight_p],  year(year) welfare(welfppp) povlines(pline300) vulnerability(1.5) edu(educat4) male(male) age(age)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea table8 [aw=weight_p], welfare(welfppp) year(year) missing

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea table9, c(GNB) year(year) 					
		
clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea table10 [aw=weight_p], c(GNB) welfare(welfppp) povlines(pline420 pline300 pline830) ppp(2021) year(year) benchmark(CIV GHA GMB SEN AGA) latest

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
pea table12 [aw=weight_p], natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) spells(2018 2021) year(year) 

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear	
pea table13a [aw=weight_p], natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) spells(2018 2021) year(year) urban(urban)

clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
pea table13b [aw=weight_p], natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) spells(2018 2021) year(year) industrycat4(industrycat4) hhhead(head) hhid(hhid)
						  
clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
gen married = marital==1 if marital~=.
pea table14 [aw=weight_p], welfare(natwelfare) povlines(natline) 						///
						  year(year) 												///	
						  missing age(age) male(male) 			 					///
						  hhsize(hsize) hhid(hhid) pid(pid) 						///
						  lstatus(nowork) 											///
						  empstat(empstat)	
						  
						  
clear all
use "$pea_path/data/GNB_GMD_ALL_clean.dta", clear					
pea table15 [aw=weight_p], welfare(welfppp)  year(year)
