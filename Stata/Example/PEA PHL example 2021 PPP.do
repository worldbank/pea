********************************************************************************
* 	PEA code example PHL
* 	(For questions contact Henry Stemmler hstemmler@worldbank.org), Minh
********************************************************************************
clear all

/* --- Enter your path here --- */
global pea_path "C:/Temp/"

* Pull data from DLW
datalibweb, country(PHL) year(2015 2018 2021 2023) type(gmd) mod(all) clear

// Data preparations
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
gen 	natline = 33000	if year == 2023										// Please enter correct national poverty line her3
replace natline = 30000	if year == 2021											// Please enter correct national poverty line here
replace natline = 27500  if year == 2018										// Please enter correct national poverty line here
replace natline = 25000  if year == 2015										// Please enter correct national poverty line here
la var pline300 "$3.00/day"
la var pline420 "$4.20/day"
la var pline830 "$8.30/day"
la var natline	"National poverty line (2021 LCU)"

// Clean subnational ID - make sure we have the same subnational labels across years
replace subnatid1 = proper(subnatid1)
split subnatid1, parse("-") gen(tmp)
encode tmp2, gen(subnatvar)
la var subnatvar "Regions"
drop tmp*
replace countrycode = "PHL" if countrycode == ""

// Clean Labels
local lbl: value label educat4
label define `lbl' 1 "No education" 2 "Primary" 3 "Secondary" 4 "Tertiary", modify
// Survey set
svyset psu [w= weight_p], singleunit(certainty)

// Comparability national poverty for Figure 1 (PEB)
gen comparability_peb = "Yes"

save "${pea_path}/data/PHL_GMD_clean.dta", replace

* Let's check whether the aggregates and lines are correct.
// international poverty
gen ipoor = welfppp < pline300
bys year: sum ipoor [aw = weight_p]				// This is correct
// national poverty
gen poor = natwelfare < natline
bys year: sum poor [aw = weight_p]	
			
// Generate artificial data for forecast example
clear
set obs 3
gen year_fcast = 2023 + 2*_n  
gen gdp_fcast = .
replace gdp_fcast = 183185.4 * 1.038^2 if year == 2025 
replace gdp_fcast = 183185.4 * 1.038^4 if year == 2027 
replace gdp_fcast = 183185.4 * 1.038^6 if year == 2029

gen natpov_fcast = .
replace natpov_fcast = 13.2 if year == 2025
replace natpov_fcast = 12.8 if year == 2027 
replace natpov_fcast = 8.1 if year == 2029  
append using "$pea_path/data/PHL_GMD_clean.dta"
save "$pea_path/data/PHL_GMD_clean.dta", replace
				
********************************************************************************
* Main
********************************************************************************

******************** Core Tables
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "c:\Users\wb327173\OneDrive - WBG\Downloads\ECA\repo\pea\Stata\plus\"

pea core [aw=weight_p], c(PHL) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) pppyear(2021) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline830) benchmark(VNM IDN THA LAO) missing setting(GMD) spells(2015 2018; 2018 2021; 2021 2023) svy std(inside) comparability_peb(comparability_peb) year_fcast(year_fcast) natpov_fcast(natpov_fcast) gdp_fcast(gdp_fcast) yrange(0(5)30) yrange2(80000(40000)280000) aggregate(groups)

******************** Appendix Figures
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "c:\Users\wb327173\OneDrive - WBG\Downloads\ECA\repo\pea\Stata\plus\"
pea figures [aw=weight_p], c(PHL) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) pppyear(2021) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline830) benchmark(VNM IDN THA) missing setting(GMD) spells(2015 2018; 2018 2021; 2021 2023) comparability(comparability) welfaretype(CONS) 

******************** Appendix Tables
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "c:\Users\wb327173\OneDrive - WBG\Downloads\ECA\repo\pea\Stata\plus\"
pea tables [aw=weight_p], c(PHL) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) pppyear(2021) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline830) benchmark(VNM IDN THA) missing setting(GMD) spells(2015 2018; 2018 2021) svy std(inside)

********************************************************************************
* Core Figure 1
********************************************************************************
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figureC1 [aw=weight_p], c(PHL) natw(natwelfare) natp(natline) year(year) year_fcast(year_fcast) natpov_fcast(natpov_fcast) gdp_fcast(gdp_fcast) comparability_peb(comparability_peb) yrange(20(20)80) yrange2(300000(50000)500000)

********************************************************************************
* Core Table 1
********************************************************************************
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
pea tableC1 [aw=weight_p], c(PHL) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) year(year) onew(welfppp) onel(pline300) ppp(2021) benchmark(VNM IDN THA) aggregate(groups) lstatus(nowork) empstat(empstat) industrycat4(industrycat4) age(age) male(male)

********************************************************************************
* Individual Figures
********************************************************************************

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure1 [aw=weight_p], natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) year(year) urban(urban) comparability(comparability) yrange(0(10)100) bar combine

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure2 [aw=weight_p], c(PHL) year(year) ppp(2021) pppw(welfppp) onel(pline300) benchmark(VNM IDN THA)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure3a [aw=weight_p], welfare(welfppp) year(year) spells(2015 2018; 2018 2021)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure3b [aw=weight_p], welfare(welfppp) year(year) spells(2015 2018; 2018 2021) by(urban)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure4 [aw=weight_p], onewelfare(welfppp) oneline(pline300) ppp(2021) year(year) spells(2015 2018; 2018 2021) idpl(urban)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure5a [aw=weight_p], onewelfare(welfppp) oneline(pline300) ppp(2021) year(year) spells(2015 2018; 2018 2021) urban(urban)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head  
pea figure5b [aw=weight_p], onewelfare(welfppp) oneline(pline300) ppp(2021) year(year) spells(2015 2018; 2018 2021) industrycat4(industrycat4) hhid(hhid) hhhead(head)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure6 [aw=weight_p], c(PHL) year(year) onew(welfppp) onel(pline300) ppp(2021) spells(2015 2018; 2018 2021)   

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure7a [aw=weight_p], onewelfare(natwelfare) oneline(natline) year(year) age(age) male(male) edu(educat4) urban(urban) missing

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure7b [aw=weight_p], onewelfare(natwelfare) oneline(natline) year(year) age(age) male(male) edu(educat4) urban(urban)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure8 [aw=weight_p], onewelfare(natwelfare) oneline(natline) year(year) age(age) male(male)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure9a [aw=weight_p], onewelfare(welfppp) year(year) comparability(comparability)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure9b [aw=weight_p], c(PHL) year(year) onew(welfppp) benchmark(VNM IDN THA) within(3) welfaretype(CONS)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure9c [aw=weight_p], c(PHL) year(year) onew(welfppp) benchmark(VNM IDN THA) within(3) welfaretype(CONS)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure9d [aw=weight_p],  year(year) onew(natwelfare) comparability(comparability)  

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure10a [aw=weight_p], onewelfare(welfppp) year(year) urban(urban) comparability(comparability) bar

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure10b [aw=weight_p], c(PHL) year(year) onew(welfppp) benchmark(VNM IDN THA)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure10c [aw=weight_p], c(PHL) year(year) onew(welfppp) benchmark(VNM IDN THA)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure10d [aw=weight_p], c(PHL) year(year) onew(welfppp) benchmark(VNM IDN THA)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure12 [aw=weight_p], onewelfare(welfppp) year(year) spells(2015 2018; 2018 2021) comparability(comparability)  

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure13 [aw=weight_p], onewelfare(welfppp) year(year)    

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure14 [aw=weight_p], country(PHL) welfare(welfppp)  year(year) benchmark(VNM IDN THA) 

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea figure15, c(PHL)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
gen married = marital==1 if marital~=.
pea figure16 [aw=weight_p], onewelfare(natwelfare) oneline(natline) year(year) 			 	///
							age(age) male(male) hhhead(head) 								///
							married(married) empstat(empstat) 								///	
							hhsize(hsize) hhid(hhid) pid(pid) 								///
							industrycat4(industrycat4) lstatus(nowork) 					///
							 earnage(15) missing
*relationharm(relationharm)
							
********************************************************************************
* Individual Tables
********************************************************************************

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea table1 [aw=weight_p], c(PHL) natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) year(year) onew(welfppp) onel(pline300) std(right) svy 

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea table2 [aw=weight_p], natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) year(year) byind(urban subnatvar) 

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
gen married = marital==1 if marital~=.
pea table3 [aw=weight_p], natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) year(year) age(age) male(male) hhhead(head) edu(educat4) missing 

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
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
						  assets(cellphone computer) 								///
						  hhsize(hsize) hhid(hhid) pid(pid) 						///
						  industrycat4(industrycat4) lstatus(nowork) 				///
						  empstat(empstat)	
	
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
pea table5 [aw=weight_p], 	welfare(welfppp) year(year) age(age) male(male) 		///
							urban(urban) edu(educat4) lstatus(nowork) 				///
							empstat(empstat) industrycat4(industrycat4) 			///
							povlines(pline420) missing 
							
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea table6 [aw=weight_p], c(PHL) welfare(welfppp) year(year)  benchmark(VNM IDN THA) last3

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea table7 [aw=weight_p],  year(year) welfare(welfppp) povlines(pline300) vulnerability(1.5) edu(educat4) male(male) age(age)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea table8 [aw=weight_p], welfare(welfppp) year(year) missing

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea table9, c(PHL) year(year) 					
		
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea table10 [aw=weight_p], c(PHL) welfare(welfppp) povlines(pline300 pline420 pline830) ppp(2021) year(year) benchmark(VNM IDN THA) latest

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea table12 [aw=weight_p], natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) spells(2015 2018; 2018 2021) year(year) 

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea table13a [aw=weight_p], natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) spells(2015 2018; 2018 2021) year(year) urban(urban)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
pea table13b [aw=weight_p], natw(natwelfare) natp(natline) pppw(welfppp) pppp(pline300 pline420 pline830) ppp(2021) spells(2015 2018; 2018 2021) year(year) industrycat4(industrycat4) hhhead(head) hhid(hhid)
											
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
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
use "$pea_path/data/PHL_GMD_clean.dta", clear
pea table15 [aw=weight_p], welfare(welfppp)  year(year)
				
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"							
pea table16, country(PHL) year(year) benchmark(VNM IDN THA) 