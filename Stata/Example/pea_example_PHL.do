********************************************************************************
* 	PEA code example PHL
* 	(For questions contact Henry Stemmler hstemmler@worldbank.org)
********************************************************************************
clear all

/* --- Enter your path here --- */
global pea_path "C:/Users/wb567239/OneDrive - WBG/PEA 3.0/Min core analytics/PEA ado"

* Pull data from DLW
datalibweb, country(PHL) year(2015 2018 2021) type(gmd) mod(all) clear

// Data preparations
gen welfppp = welfare/cpi2017/icp2017/365
label var welfppp "Welfare (constant 2017 PPP)"
label var welfare "Welfare (local currency)"
gen pline215 = 2.15
gen pline365 = 3.65
gen pline685 = 6.85
gen 	natline = 30000	if year == 2021											// Please enter correct national poverty line here
replace natline = 27500  if year == 2018										// Please enter correct national poverty line here
replace natline = 25000  if year == 2015										// Please enter correct national poverty line here
la var pline215 "$2.15 per day (2017 PPP)"
la var pline365 "$3.65 per day (2017 PPP)"
la var pline685 "$6.85 per day (2017 PPP)"
la var natline	"National poverty line (2021 LCU)"
// Clean subnational ID
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
save "${pea_path}/data/PHL_GMD_clean.dta", replace

********************************************************************************
* Main
********************************************************************************

******************** Core Tables
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea core [aw=weight_p], c(PHL) natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(VNM BGD PAK NPL IDN) missing setting(GMD) spells(2015 2018; 2018 2021) svy std(inside)

******************** Appendix Figures
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figures [aw=weight_p], c(PHL) natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline215) benchmark(VNM BGD PAK NPL IDN) missing setting(GMD) spells(2015 2018; 2018 2021) comparability(comparability) welfaretype(CONS) 

******************** Appendix Tables
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea tables [aw=weight_p], c(PHL) natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline685) benchmark(VNM BGD PAK NPL IDN) missing setting(GMD) spells(2015 2018; 2018 2021) svy std(inside)

******************** Appendix Figures (bars)
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figures [aw=weight_p], c(PHL) natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) byind(urban subnatvar) onew(welfppp) oneline(pline215) benchmark(VNM BGD PAK NPL IDN) missing setting(GMD) spells(2015 2018; 2018 2021) comparability(comparability) welfaretype(CONS) bar 

********************************************************************************
* Individual Figures
********************************************************************************

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure1 [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) urban(urban) comparability(comparability) yrange(0(10)100) bar combine

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure2 [aw=weight_p], c(PHL) year(year) onew(welfppp) onel(pline215) benchmark(CIV GHA GMB SEN)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure3a [aw=weight_p], welfare(welfppp) year(year) spells(2015 2018; 2018 2021)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure3b [aw=weight_p], welfare(welfppp) year(year) spells(2015 2018; 2018 2021) by(urban)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure4 [aw=weight_p], onewelfare(welfppp) oneline(pline215) year(year) spells(2015 2018; 2018 2021) idpl(urban)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure5a [aw=weight_p], onewelfare(welfppp) oneline(pline215) year(year) spells(2015 2018; 2018 2021) urban(urban)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head  
pea figure5b [aw=weight_p], onewelfare(welfppp) oneline(pline215) year(year) spells(2015 2018; 2018 2021) industrycat4(industrycat4) hhid(hhid) hhhead(head)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure6 [aw=weight_p], c(PHL) year(year) onew(welfppp) onel(pline215) spells(2015 2018; 2018 2021)   

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure7a [aw=weight_p], onewelfare(welfare) oneline(natline) year(year) age(age) male(male) edu(educat4) urban(urban) missing

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure7b [aw=weight_p], onewelfare(welfare) oneline(natline) year(year) age(age) male(male) edu(educat4) urban(urban)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure8 [aw=weight_p], onewelfare(welfare) oneline(natline) year(year) age(age) male(male)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure9a [aw=weight_p], onewelfare(welfppp) year(year) comparability(comparability)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure9b [aw=weight_p], c(PHL) year(year) onew(welfppp) benchmark(VNM BGD PAK NPL IDN) within(3) welfaretype(CONS)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure9c [aw=weight_p], c(PHL) year(year) onew(welfppp) benchmark(VNM BGD PAK NPL IDN) within(3) welfaretype(CONS)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure9d [aw=weight_p],  year(year) onew(welfare) comparability(comparability)  

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure10a [aw=weight_p], onewelfare(welfppp) year(year) urban(urban) comparability(comparability) bar

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure10b [aw=weight_p], c(PHL) year(year) onew(welfppp) benchmark(VNM BGD PAK NPL IDN)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure10c [aw=weight_p], c(PHL) year(year) onew(welfppp) benchmark(VNM BGD PAK NPL IDN)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure10d [aw=weight_p], c(PHL) year(year) onew(welfppp) benchmark(VNM BGD PAK NPL IDN)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure12 [aw=weight_p], onewelfare(welfppp) year(year) spells(2015 2018; 2018 2021) comparability(comparability)  

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure13 [aw=weight_p], onewelfare(welfppp) year(year)    

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure14 [aw=weight_p], country(PHL) welfare(welfppp)  year(year) benchmark(VNM BGD PAK NPL IDN) 

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea figure15, c(PHL)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
gen married = marital==1 if marital~=.
pea figure16 [aw=weight_p], onewelfare(welfare) oneline(natline) year(year) 			 	///
							age(age) male(male) hhhead(head) 								///
							married(married) empstat(empstat) 								///	
							hhsize(hsize) hhid(hhid) pid(pid) 								///
							industrycat4(industrycat4) lstatus(nowork) 					///
							relationharm(relationharm) earnage(15) missing

							
********************************************************************************
* Individual Tables
********************************************************************************

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea table1 [aw=weight_p], c(PHL) natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215 pline685) year(year) onew(welfppp) onel(pline215) std(right) svy ppp(2017)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea table2 [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) byind(urban subnatvar) 

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
gen married = marital==1 if marital~=.
pea table3 [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) year(year) age(age) male(male) hhhead(head) edu(educat4) missing ppp(2017)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
gen married = marital==1 if marital~=.
pea table4 [aw=weight_p], welfare(welfare) povlines(natline) 						///
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
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea table5 [aw=weight_p], 	welfare(welfppp) year(year) age(age) male(male) 		///
							urban(urban) edu(educat4) lstatus(nowork) 				///
							empstat(empstat) industrycat4(industrycat4) missing	
							
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea table6 [aw=weight_p], c(PHL) welfare(welfppp) year(year)  benchmark(VNM BGD PAK NPL IDN) last3

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea table7 [aw=weight_p],  year(year) welfare(welfppp) povlines(pline215) vulnerability(1.5) edu(educat4) male(male) age(age)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea table8 [aw=weight_p], welfare(welfppp) year(year) missing

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
pea table9, c(PHL) year(year) 					
		
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"		
pea table10 [aw=weight_p], c(PHL) welfare(welfppp) povlines(pline365 pline215 pline685) year(year) benchmark(VNM BGD PAK NPL IDN) latest

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"	
pea table12 [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) spells(2015 2018; 2018 2021) year(year) 

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"	
pea table13a [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) spells(2015 2018; 2018 2021) year(year) urban(urban)

clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"	
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
pea table13b [aw=weight_p], natw(welfare) natp(natline) pppw(welfppp) pppp(pline365 pline215  pline685) spells(2015 2018; 2018 2021) year(year) industrycat4(industrycat4) hhhead(head) hhid(hhid)
											
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
label define nowork 0 "Working" 1 "Not working (unemployed or out of labor force)"
label values nowork nowork
gen married = marital==1 if marital~=.
pea table14 [aw=weight_p], welfare(welfare) povlines(natline) 						///
						  year(year) 												///	
						  missing age(age) male(male) 			 					///
						  hhsize(hsize) hhid(hhid) pid(pid) 						///
						  lstatus(nowork) 											///
						  empstat(empstat)	
						  
clear all
use "$pea_path/data/PHL_GMD_clean.dta", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"							
pea table15 [aw=weight_p], welfare(welfppp)  year(year)
						