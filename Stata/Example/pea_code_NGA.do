********************************************************************************
* 	PEA code example Nigeria
* 	(For questions contact Henry Stemmler hstemmler@worldbank.org)
********************************************************************************

clear all
global pea_path "C:/Users/wb567239/OneDrive - WBG/PEA 3.0/Min core analytics/PEA ado"	// Set path if data is to be stored locally							

* Pull data from DLW
datalibweb, country(NGA) year(2018) type(gmd) mod(all) clear

* Welfare and poverty lines
gen 	welfppp		= welfare/cpi2017/icp2017/365
gen 	pline215 	= 2.15
gen 	pline365 	= 3.65
gen 	pline685 	= 6.85
// ADJUST NATIONAL POVERTY LINE HERE
gen 	natline 	= 80000
*replace natline	= X		if year == 2022
la var 	pline215 	"Poverty line: $2.15 per day (2017 PPP)"
la var 	pline365 	"Poverty line: $3.65 per day (2017 PPP)"
la var 	pline685 	"Poverty line: $6.85 per day (2017 PPP)"
la var 	natline		"Poverty line: X per year (2017 LCU)"
* Region cleaning
split 	subnatid,	parse(". ") gen(tmp)
encode 	tmp2, 		gen(subnatvar)
la var	subnatvar	"Region"
drop tmp1 tmp2
// APPEND 2022 DATA
save "${pea_path}/data/NGA_GMD_clean.dta"	


********************************************************************************
* 1) Core Appendix Tables
clear all
use "${pea_path}/data/NGA_GMD_clean", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"	// ADJUST THIS PATH to where pea ado folder is stored
pea core [aw=weight_p], c(NGA)  year(year) 					///
		natw(welfare) natp(natline) 						///	
		pppw(welfppp) pppp(pline365 pline215 pline685)		///	
		onew(welfppp) oneline(pline215)						///					// ONELINE is the main poverty line you want to use
		byind(urban subnatvar) 								///					// GROUPS by which poverty rates are calculated
		benchmark(CIV EGY GHA KEN IND PAK)					/// 				// SPECIFY BENCHMARK COUNTRIES HERE
		setting(GMD) missing													// WITH setting(GMD) standardized variables are used. If you leave this option out, you need to enter demographic variables, assets, labor force status etc.
//		spells(2018 2022)									/// 				// ADJUST SPELLS YOU WOULD LIKE (e.g. for GICs) HERE
//		excel("${pea_path}/output/NGA_core.xlsx")								// Add this option to store Excel file in a specific path


********************************************************************************
* 2) Main text Tables
clear all
use "${pea_path}/data/NGA_GMD_clean", clear
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"	// ADJUST THIS PATH to where pea ado folder is stored
pea tables [aw=weight_p], c(NGA)  year(year) 				///
		natw(welfare) natp(natline) 						///	
		pppw(welfppp) pppp(pline365 pline215 pline685)		///
		onew(welfppp) oneline(pline215)						///					// ONELINE is the main poverty line you want to use
		byind(urban subnatvar) 								///					// GROUPS by which poverty rates are calculated
		benchmark(CIV EGY GHA KEN IND PAK)					/// 				// SPECIFY BENCHMARK COUNTRIES HERE
		setting(GMD) missing													// WITH setting(GMD) standardized variables are used. If you leave this option out, you need to enter demographic variables, assets, labor force status etc.
//		spells(2018 2022)									/// 				// ADJUST SPELLS YOU WOULD LIKE (e.g. for GICs) HERE

		
********************************************************************************		
* 3) PEA Figures
clear all
adopath + "C:/Users/wb567239/OneDrive - WBG/Documents/GitHub/pea/Stata/plus"	// Set path of PEA3.0 ado-files 
use "${pea_path}/data/NGA_GMD_clean", clear

pea figures [aw=weight_p], c(NGA) year(year) 				///
		natw(welfare) natp(natline) 						///	
		pppw(welfppp) pppp(pline365 pline215 pline685)		///
		onew(welfppp) oneline(pline215)						///					// ONELINE is the main poverty line you want to use
		byind(urban) benchmark(CIV EGY GHA KEN IND PAK)		/// 				// SPECIFY BENCHMARK COUNTRIES HERE
		setting(GMD) urban(urban)							///					// Urban variable
		within(3) comparability(comparability) 				///					
		combine welfaretype(CONS)							///					/
		spells(2018 2022) yrange0										 		// ADJUST SPELLS YOU WOULD LIKE (e.g. for GICs) HERE. yrange0 specifies that figures 1, 9a, 10a have a y-axis starting at 0.
		// nonotes equalspacing palette() scheme()								// nonotes: Removes figure notes. equalspacing: Forces equal spacing between years. palette() and scheme() specify color palette and scheme.
	