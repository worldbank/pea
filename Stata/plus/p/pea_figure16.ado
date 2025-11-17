*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 

* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.

//Figure 16: Composition of the poor
cap program drop pea_figure16
program pea_figure16, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [ONEWelfare(varname numeric) ONELine(varname numeric) Year(varname numeric) setting(string) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) married(varname numeric) hhsize(varname numeric) hhid(string) pid(string) industrycat4(varname numeric) lstatus(varname numeric) empstat(varname numeric) earnage(integer 15) MISSING scheme(string) palette(string) excel(string) PPPyear(integer 2021)]
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	//house cleaning
	_pea_export_path, excel("`excel'")

		//Working variable 
	gen _work 	 = `lstatus'== 0 | `empstat'==1 | `empstat'==3 | `empstat' == 4
	replace _work = . if `lstatus' == . & `empstat' == .
	
	if "`missing'"~="" { //show missing
		foreach var of varlist `male' `age' _work {
			qui su `var'
			local max_`var' = r(max) + 10
			replace `var' = `max_`var'' if `var'==.
			local varlbl : value label `var'
			if "`varlbl'" == "" local varlbl `var'
			la def `varlbl' `max_`var'' "Missing", add
			la values `var' `varlbl'
		}
	}	
	
	if "`earnage'"=="" {
		local earnage = 15
		di "Age cut-off for earners of 15 assumed."
	}
	// Figure Setup
	pea_figure_setup, scheme("`scheme'") palette("`palette'")		//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)	
	
	//Weights
	local wvar : word 2 of `exp'
	qui if "`wvar'"=="" {
		tempvar w
		gen `w' = 1
		local wvar `w'
	}
	//missing observation check
	marksample touse
	local flist `"`wvar' `onewelfare' `oneline' `year'"'
	markout `touse' `flist' 
	
	if "`onewelfare'"~="" { //reset to the floor
		replace `onewelfare' = ${floor_} if `onewelfare'< ${floor_}
		noi di in yellow "Welfare in `pppyear' PPP is adjusted to a floor of ${floor_}"
	}
	
	//Only one year
	qui sum `year', d   // Get last year of survey data (year of scatter plot)
	local lasty `r(max)'
	keep if `year' == `lasty'
	
	tempfile dataori datalbl
	save `dataori', replace
	des, replace clear
	save `datalbl', replace
	use `dataori', clear
	
	//Keep only poor population
	keep if `onewelfare' < `oneline' & `onewelfare'~=. & `touse'
	local lblline: var label `oneline'		

	
		************************************************************************
		// Preparation for Demographic composition
		* Number adults
		gen _pea_adult = `age' > 14 
		bys `year' `hhid' (`pid'): egen number_adults = sum(_pea_adult)
		* Any children
		gen _pea_child = `age' < 15
		bys `year' `hhid' (`pid'): egen any_children = max(_pea_child)
		* Female adult or senior
		gen femaleolder14 = `age' > 14 &  `male' == 0
		bys `year' `hhid' (`pid'): egen female_older14 = sum(femaleolder14)
		* Male adult or senior
		gen maleolder14 = `age' > 14 & `male' == 1
		bys `year' `hhid' (`pid'): egen male_older14 = sum(maleolder14)
		* Senior
		gen _pea_senior = `age' > 64
		bys `year' `hhid' (`pid'): egen number_seniors = sum(_pea_senior)
		
		* Only seniors as adults
		gen only_seniors = number_seniors == number_adults & number_seniors ~= 0 & number_seniors ~= .
		
		* Missing demographics
		gen dem_miss = 0
		if "`missing'" ~= "" {
			foreach var in `male' `age' {			
				su `var' if `var' ==`max_`var''			
				local `var'_mis = r(mean)
				replace dem_miss = 1 if `var' == ``var'_mis'
			}
		}
		else replace dem_miss = 2 if `male' == . | `age' == . 					// These households won't be used in sample
		bys `year' `hhid' (`pid'): egen any_dem_miss = max(dem_miss)
		
		// Preparation for Economic composition
		* Earners
		gen earner = _work == 1 if `age' >= `earnage' 							// Employed, self-employed, or employer (`lstatus' is nowork)
		bys `year' `hhid' (`pid'): egen number_earners = sum(earner) 
				
		* Nonearners
		gen nonearner = _work == 0 if `age' >= `earnage'	
		bys `year' `hhid' (`pid'): egen number_nonearners = sum(nonearner) 

		* Missing earner information
		gen earner_miss = 0
		replace _work = 0 if `age' < `earnage'									// don't count missing under working age
		if "`missing'" ~= "" {
			foreach var in `age' _work {			
				su `var' if `var' ==`max_`var''			
				local `var'_mis = r(mean)
				replace earner_miss = 1 if `var' == ``var'_mis'
			}
		}
		else replace earner_miss = 2 if `age' == . | _work == . 				// These households won't be used in sample
		bys `year' `hhid' (`pid'): egen any_earner_miss = max(earner_miss)
		
		************************************************************************
		// Demographic classification								
		* 1) Two adults with children
		gen demographic_class1 = number_adults == 2 & any_children == 1 ///	
								& only_seniors == 0 & any_dem_miss ~= 1 ///
								if any_dem_miss ~= 2
		* 2) One female adult with children
		gen demographic_class2 = female_older14 == 1 & male_older14 == 0 ///
								& any_children == 1 & only_seniors == 0  ///
								& any_dem_miss ~= 1	if any_dem_miss ~= 2
		* 3) Multiple adults with children		
		gen demographic_class3 = number_adults >= 3 & any_children == 1 ///	
								& only_seniors == 0 & any_dem_miss ~= 1	///
								if any_dem_miss ~= 2		
		* 4) Only seniors with children
		gen demographic_class4 = only_seniors == 1 & any_children == 1 ///	
								& any_dem_miss ~= 1	if any_dem_miss ~= 2		
		* 5) Adult(s) without children
		gen demographic_class5 = number_adults >= 1 & any_children == 0 ///	
								& only_seniors == 0 & any_dem_miss ~= 1	///
								if any_dem_miss ~= 2						
		* 6) Senior adult(s) without children
		gen demographic_class6 = only_seniors == 1 & any_children == 0 ///	
								& any_dem_miss ~= 1 if any_dem_miss ~= 2
								
		* 7) Other
		cap drop anyd
		egen anyd = rowmax(demographic_class*)
		gen demographic_class7 = anyd == 0								///	
								& any_dem_miss ~= 1 if any_dem_miss ~= 2	
		drop anyd
		
		* 8) Missing
		if "`missing'"~="" { //show missing
			gen demographic_class8 = any_dem_miss == 1
			label var demographic_class8 "Missing"
			local m_note "Households are classified as 'missing' in the demographic typology if any member has no information on sex or age."
			for var demographic_class*: replace X = 0 if X == .		
		}
		for var demographic_class*: replace X = X*100
			
		// Economic classification
		* 1) One earner only 
		gen economic_class1 = number_earners == 1 & number_nonearners == 0 	///
							& any_earner_miss ~= 1 if any_earner_miss ~= 2
		* 2) One earner, other nonearners
		gen economic_class2 = number_earners == 1 & number_nonearners >= 1 	///
							& any_earner_miss ~= 1 if any_earner_miss ~= 2
		* 3) Multiple earners
		gen economic_class3 = number_earners >= 2  							///
							& any_earner_miss ~= 1 if any_earner_miss ~= 2
		* 4) No earners
		gen economic_class4 = number_earners == 0 & number_nonearners >= 1 	///
							& any_earner_miss ~= 1 if any_earner_miss ~= 2
		
		* 5) Other 
		cap drop ecc_any
		egen ecc_any = rowtotal(economic_class*)
		gen economic_class5 = ecc_any == 0 & any_earner_miss ~= 1 if any_earner_miss ~= 2
		cap drop ecc_any
	
		* 6) Missing
		if "`missing'"~="" { //show missing
			gen economic_class6 = any_earner_miss == 1
			label var economic_class6 "Missing"
			local m_note "`m_note' Households are classified as 'missing' in the economic typology if any adult has no information on labor market, employment status or age."
			for var economic_class*: replace X = 0 if X == .			
		}
		

		for var economic_class* : replace X = X*100
		
	collapse (mean) economic_class* demographic_class* [aw=`wvar'], by(`year')

	reshape long economic_class demographic_class, i(year) j(group)	
	rename (economic_class*) 	(vareconomic_class*)	
	rename (demographic_class*) (vardemographic_class*)	
	reshape long var, i(year group) j(type, string)	
	gen Demographic = group if type == "demographic_class"
	gen Economic = group if type == "economic_class"
	
	label define group_d 						///
		1 "Two adults with children"			///
		2 "One adult female with children"		///
		3 "Multiple adults with children"		///
		4 "Only seniors with children"			///
		5 "Adult(s) without children"			///
		6 "Senior adult(s) without children"	///
		7 "Other"								///
		8 "Missing"								///
		9 "All Others"
		
	label values Demographic group_d
	label var	 Demographic "Demographic typology"
	
	label define group_e 				///
	1 "One earner only"	 				///
	2 "One earner, other nonearners" 	///
	3 "Multiple earners" 				///
	4 "No earners" 						///
	5 "Other"							///
	6 "Missing"							///
	7 "All Others"					 	
	
	label values Economic group_e
	label var	 Economic "Economic typology"
	drop group
	// Figure
		local figname Figure16
		if "`excel'"=="" {
			local excelout2 "`dirpath'\\`figname'.xlsx"
			local act replace
			cap rm "`dirpath'\\`figname'.xlsx"
		}
		else {
			local excelout2 "`excelout'"
			local act modify
		}
		local u  = 5	
		tempfile graph1

		// a) Demographic
		insobs 1
		replace var = 0 if  type == ""
		replace Demographic = 9 if type == ""
		replace type = "demographic_class" if type == ""
		replace var = 0 if  Demographic == 9
		gen less5 = var <= 5
		bys type less5: egen sum = sum(var) 
		replace var = sum if Demographic == 9
		drop less5 sum		
		tempfile graph1

		splitvallabels Demographic if (var > 5 | Demographic == 9) & var != ., length(25) recode
		graph hbar var if (var > 5 | Demographic == 9) & var != .,	///
				over(Demographic, relabel(`r(relabel)'))		///
				ytitle("Share of poor population")				///
				bar(1, color("`: word 1 of ${colorpalette}'"))	///	
				name(bar_dem, replace)
				
		putexcel set "`excelout2'", modify sheet("Figure16a", replace)
		graph export "`graph1'", replace as(png) name(bar_dem) wid(1500)
		putexcel A`u' = image("`graph1'")
		putexcel A1 = ""
		putexcel A2 = "Figure 16a: Profiles of the poor by demographic composition"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The figure shows the composition of poor households. The poor are defined against the `lblline'. Demographic compositions follow Table 14. Data is from `year'. Household typologies are an extended version of Munoz Boudet et al. (2018)."
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"graph hbar var if (var > 5 | Demographic == 9) & var != ., over(Demographic, relabel(`r(relabel)')) ytitle("Share of poor population") bar(1, color("`: word 1 of ${colorpalette}'"))"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
		// Export data
		export excel year Demographic var using "`excelout2'" if Demographic ~= ., sheet("Figure16a", modify) cell(O11) keepcellfmt firstrow(variables)
		
		// b) Economic	
		insobs 1
		replace var = 0 if  type == ""
		replace Economic = 9 if type == ""
		replace type = "economic_class" if type == ""
		replace var = 0 if  Economic == 7
		gen less5 = var <= 5
		bys type less5: egen sum = sum(var) 
		replace var = sum if Economic == 7
		drop less5 sum		
		
		tempfile graph1
		splitvallabels Economic if (var > 5 | Economic == 7) & var != ., length(25) recode
		graph hbar var if (var > 5 | Economic == 7) & var != .,	///
			over(Economic, relabel(`r(relabel)'))			///
			ytitle("Share of poor population")				///
			bar(1, color("`: word 1 of ${colorpalette}'"))	///	
			name(bar_econ, replace)						
		putexcel set "`excelout2'", modify sheet("Figure16b", replace)
		graph export "`graph1'", replace as(png) name(bar_econ) wid(1500)
		putexcel A`u' = image("`graph1'")
		putexcel A1 = ""
		putexcel A2 = "Figure 16b: Profiles of the poor by economic composition"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The figure shows the composition of poor households. The poor are defined against the `lblline'. Economic compositions follow Table 14. Households are not differentiated by having children or no children. Adults are defined as 16 years of age or older. For the economic composition, earners are defined as those working and `earnage' years or older. Data is from `year'. Household typologies are an extended version of Munoz Boudet et al. (2018). `m_note'"
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"graph hbar var if (var > 5 | Economic == 7) & var != ., over(Economic, relabel(`r(relabel)')) ytitle("Share of poor population") bar(1, color("`: word 1 of ${colorpalette}'"))"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
		// Export data
		export excel year Economic var using "`excelout2'" if Economic ~= ., sheet("Figure16b", modify) cell(O11) keepcellfmt firstrow(variables) nolabel
			
		putexcel save
		cap graph close	
		
		if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"
end
