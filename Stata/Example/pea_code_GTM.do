********************************************************************************
* 	PEA code example GTM
* 	(For questions contact Henry Stemmler hstemmler@worldbank.org)
********************************************************************************

clear all
global pea_path "C:/Users/wb567239/OneDrive - WBG/PEA 3.0/Min core analytics/PEA ado"	// Set path if data is to be stored locally							
local today : display %tdNDY date(c(current_date), "DMY")

// Preparations
* Create Excel files to export to
set obs 1 
gen empty = .
cap export excel using "${pea_path}/output/GTM_core`today'.xlsx"
cap export excel using "${pea_path}/output/GTM_tables`today'.xlsx"
cap export excel using "${pea_path}/output/GTM_figures`today'.xlsx"
clear

* Pull data from DLW
//datalibweb, country(GTM) year(2006 2014) type(gmd) mod(all) clear
use "${pea_path}/data/GTM_GMD_2006_2014.dta", clear
// append (harmonized) new survey data here
gen welfppp = welfare/cpi2017/icp2017/365
gen pline215 = 2.15
gen pline365 = 3.65
gen pline685 = 6.85
gen 	natline = 4500	if year == 2014											// Please enter correct national poverty line here
replace natline = 4000  if year == 2006											// Please enter correct national poverty line here
la var pline215 "$2.15 per day (2017 PPP)"
la var pline365 "$3.65 per day (2017 PPP)"
la var pline685 "$6.85 per day (2017 PPP)"
la var natline	"National poverty line (2021 LCU)"
// Clean subnational ID
replace subnatid = proper(subnatid)
split subnatid, parse(" - ") gen(tmp)
encode tmp2, gen(subnatvar)
la var subnatvar "Regions"
drop tmp*
replace countrycode = "GTM" if countrycode == ""

save "${pea_path}/data/GTM_GMD_clean.dta", replace


********************************************************************************
* 1) Core Appendix Tables
clear all
use "${pea_path}/data/GTM_GMD_clean", clear
adopath + "${pea_path}/ado/pea/Stata/plus"										// ADJUST THIS PATH to where pea ado folder is stored
pea core [aw=weight_p], c(GTM)  year(year) 					///
		natw(welfare) natp(natline) 						///	
		pppw(welfppp) pppp(pline365 pline215 pline685)		///	
		onew(welfppp) oneline(pline685)						///					// ONELINE is the main poverty line you want to use
		byind(urban subnatvar) 								///					// GROUPS by which poverty rates are calculated
		benchmark(CRI HND SLV PAN NIC)						/// 				// SPECIFY BENCHMARK COUNTRIES HERE
		setting(GMD) missing								///					// WITH setting(GMD) standardized variables are used.
		spells(2006 2014)									/// 				// ADJUST SPELLS YOU WOULD LIKE (e.g. for GICs) HERE
		excel("${pea_path}/output/GTM_core`today'.xlsx")						// Add this option to store Excel file in a specific path (note that Excel file needs to exist)

		
********************************************************************************
* 2) Main text Tables
clear all
use "${pea_path}/data/GTM_GMD_clean", clear
adopath + "${pea_path}/ado/pea/Stata/plus"										// ADJUST THIS PATH to where pea ado folder is stored
pea tables [aw=weight_p], c(GTM)  year(year) 				///
		natw(welfare) natp(natline) 						///	
		pppw(welfppp) pppp(pline365 pline215 pline685)		///
		onew(welfppp) oneline(pline685)						///					// ONELINE is the main poverty line you want to use
		byind(urban subnatvar) 								///					// GROUPS by which poverty rates are calculated
		benchmark(CRI HND SLV PAN NIC)						/// 				// SPECIFY BENCHMARK COUNTRIES HERE
		setting(GMD) missing								///					// WITH setting(GMD) standardized variables are used.
		spells(2006 2014)									
		
		
		///	 				// ADJUST SPELLS YOU WOULD LIKE (e.g. for GICs) HERE
		excel("${pea_path}/output/GTM_tables`today'.xlsx")						// Add this option to store Excel file in a specific path (note that Excel file needs to exist)

		
********************************************************************************		
* 3) PEA Figures
clear all
use "${pea_path}/data/GTM_GMD_clean", clear
adopath + "${pea_path}/ado/pea/Stata/plus"										// ADJUST THIS PATH to where pea ado folder is stored

pea figures [aw=weight_p], c(GTM) year(year) 				///
		natw(welfare) natp(natline) 						///	
		pppw(welfppp) pppp(pline365 pline215 pline685)		///
		onew(welfppp) oneline(pline685)						///					// ONELINE is the main poverty line you want to use
		byind(urban) benchmark(CRI HND SLV PAN NIC)			/// 				// SPECIFY BENCHMARK COUNTRIES HERE
		setting(GMD) urban(urban)							///					// Urban variable
		within(3) comparability(comparability) 				///					// Comparability: Only comparable years are connected. Within(3): year range for surveys of other countries to be included, from the latest year of the PEA country
		combine welfaretype(CONS)							///					// Combine: combines 4 panels to one figure for figure 1. Welfaretype: Specify the welfare type of the PEA country here	
		spells(2006 2014)									///	 				// ADJUST SPELLS YOU WOULD LIKE (e.g. for GICs) HERE
		excel("${pea_path}/output/GTM_figures`today'.xlsx")						// Add this option to store Excel file in a specific path (note that Excel file needs to exist)
		// nonotes equalspacing palette() scheme()								// nonotes: Removes figure notes. equalspacing: Forces equal spacing between years. palette() and scheme() specify color palette and scheme.
