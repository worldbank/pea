********************************************************************************
* 	PEA code example GNB
* 	(For questions contact Henry Stemmler hstemmler@worldbank.org)
********************************************************************************

clear all
global pea_path "C:/Users/wb567239/OneDrive - WBG/PEA 3.0/Min core analytics/PEA ado"	// Set path if data is to be stored locally							
local today : display %tdNDY date(c(current_date), "DMY")

// Preparations
* Create Excel files to export to
set obs 1 
gen empty = .
cap export excel using "${pea_path}/output/GNB_core`today'.xlsx"
cap export excel using "${pea_path}/output/GNB_tables`today'.xlsx"
cap export excel using "${pea_path}/output/GNB_figures`today'.xlsx"
cap export excel using "${pea_path}/output/GNB_table2_`today'.xlsx"
cap export excel using "${pea_path}/output/GNB_table14_`today'.xlsx"
clear

* Pull data from DLW
datalibweb, country(GNB) year(2018 2021) type(gmd) mod(all) clear

gen welfppp = welfare/cpi2017/icp2017/365
gen pline215 = 2.15
gen pline365 = 3.65
gen pline685 = 6.85
gen 	natline = 298084	if year == 2021
replace natline = 270706.7  if year == 2018
la var pline215 "Poverty line: $2.15 per day (2017 PPP)"
la var pline365 "$3.65 per day (2017 PPP)"
la var pline685 "$6.85 per day (2017 PPP)"
la var natline	"National poverty line (2021 LCU)"
split subnatid, parse("-") gen(tmp)
replace tmp2 = ustrlower( ustrregexra( ustrnormalize( tmp2, "nfd" ) , "\p{Mark}", "" ) )
replace tmp2 = " bolama/bijagos" if tmp2 == " bolama_bijagos"
replace tmp2 = proper(tmp2)
encode tmp2, gen(subnatvar)
drop tmp1 tmp2
replace countrycode = "GNB" if countrycode == ""

save "${pea_path}/data/GNB_GMD_clean.dta", replace


********************************************************************************
* 1) Core Appendix Tables
clear all
use "${pea_path}/data/GNB_GMD_clean", clear
adopath + "${pea_path}/ado/pea/Stata/plus"										// ADJUST THIS PATH to where pea ado folder is stored
pea core [aw=weight_p], c(GNB)  year(year) 					///
		natw(welfare) natp(natline) 						///	
		pppw(welfppp) pppp(pline365 pline215 pline685)		///	
		onew(welfppp) oneline(pline365)						///					// ONELINE is the main poverty line you want to use
		byind(urban subnatvar) 								///					// GROUPS by which poverty rates are calculated
		benchmark(CIV GHA GMB SEN)							/// 				// SPECIFY BENCHMARK COUNTRIES HERE
		setting(GMD) missing								///					// WITH setting(GMD) standardized variables are used.
		spells(2018 2021)									/// 				// ADJUST SPELLS YOU WOULD LIKE (e.g. for GICs) HERE
		excel("${pea_path}/output/GNB_core`today'.xlsx")						// Add this option to store Excel file in a specific path (note that Excel file needs to exist)

		
********************************************************************************
* 2) Main text Tables
clear all
use "${pea_path}/data/GNB_GMD_clean", clear
adopath + "${pea_path}/ado/pea/Stata/plus"										// ADJUST THIS PATH to where pea ado folder is stored
pea tables [aw=weight_p], c(GNB)  year(year) 				///
		natw(welfare) natp(natline) 						///	
		pppw(welfppp) pppp(pline365 pline215 pline685)		///
		onew(welfppp) oneline(pline365)						///					// ONELINE is the main poverty line you want to use
		byind(urban subnatvar) 								///					// GROUPS by which poverty rates are calculated
		benchmark(CIV GHA GMB SEN)							/// 				// SPECIFY BENCHMARK COUNTRIES HERE
		setting(GMD) missing								///					// WITH setting(GMD) standardized variables are used.
		spells(2018 2021)									///	 				// ADJUST SPELLS YOU WOULD LIKE (e.g. for GICs) HERE
		excel("${pea_path}/output/GNB_tables`today'.xlsx")						// Add this option to store Excel file in a specific path (note that Excel file needs to exist)

		
********************************************************************************		
* 3) PEA Figures
clear all
use "${pea_path}/data/GNB_GMD_clean", clear
adopath + "${pea_path}/ado/pea/Stata/plus"										// ADJUST THIS PATH to where pea ado folder is stored

pea figures [aw=weight_p], c(GNB) year(year) 				///
		natw(welfare) natp(natline) 						///	
		pppw(welfppp) pppp(pline365 pline215 pline685)		///
		onew(welfppp) oneline(pline215) welfare(welfppp)	///					// ONELINE is the main poverty line you want to use
		byind(urban) benchmark(CIV GHA GMB SEN)				/// 				// SPECIFY BENCHMARK COUNTRIES HERE
		setting(GMD) urban(urban)							///					// Urban variable
		within(3) comparability(comparability) 				///					// Comparability: Only comparable years are connected. Within(3): year range for surveys of other countries to be included, from the latest year of the PEA country
		combine welfaretype(CONS)							///					// Combine: combines 4 panels to one figure for figure 1. Welfaretype: Specify the welfare type of the PEA country here	
		spells(2018 2021)									///	 				// ADJUST SPELLS YOU WOULD LIKE (e.g. for GICs) HERE
		excel("${pea_path}/output/GNB_figures`today'.xlsx")						// Add this option to store Excel file in a specific path (note that Excel file needs to exist)
		// nonotes equalspacing palette() scheme()								// nonotes: Removes figure notes. equalspacing: Forces equal spacing between years. palette() and scheme() specify color palette and scheme.

		
********************************************************************************		
* 4) Table with urban-rural-capital regions
clear all
use "${pea_path}/data/GNB_GMD_clean", clear
adopath + "${pea_path}/ado/pea/Stata/plus"										// ADJUST THIS PATH to where pea ado folder is stored

// Generate urban area to have capital region separate
clonevar urban_cap = urban
replace	 urban_cap = 2 if subnatvar == 8
label define urban 2  "Capital region", modify		

pea table2 [aw=weight_p], natw(welfare) natp(natline) 						///
						  pppw(welfppp) pppp(pline365 pline215 pline685) 	///
						  year(year) byind(urban_cap) 						///		// or byind(urban_cat subnatvar) 
						  excel("${pea_path}/output/GNB_table2_`today'.xlsx")


********************************************************************************		
* 5) Table 14 with LCU poverty line
clear all
use "${pea_path}/data/GNB_GMD_clean", clear
adopath + "${pea_path}/ado/pea/Stata/plus"										// ADJUST THIS PATH to where pea ado folder is stored
local today : display %tdNDY date(c(current_date), "DMY")

// When running single tables, setting(GMD) is not called, and additional variables need to be created
gen head = relationharm==1 if relationharm~=.
la def head 1 "HH head" 
la val head head 
gen nowork = lstatus==2|lstatus==3 if lstatus~=.
gen married = marital==1 if marital~=.

pea table14 [aw=weight_p], welfare(welfare) povlines(natline) 						///
						  year(year) urban(urban)									///	
						  missing age(age) male(male) hhhead(head) 					///
						  edu(educat4) married(married) 				///	
						  school(school) 											///
						  services(imp_wat_rec imp_san_rec electricity) 			///
						  assets(tv car cellphone computer fridge) 					///
						  hhsize(hsize) hhid(hhid) pid(pid) 						///
						  industrycat4(industrycat4) lstatus(nowork) 				///
						  empstat(empstat)											///
						  excel("${pea_path}/output/GNB_table14_`today'.xlsx")