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
	syntax [if] [in] [aw pw fw], [ONEWelfare(varname numeric) ONELine(varname numeric) Year(varname numeric) setting(string) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) married(varname numeric) hhsize(varname numeric) hhid(string) pid(string) industrycat4(varname numeric) lstatus(varname numeric) empstat(varname numeric) relationharm(varname numeric) earnage(integer 18) MISSING scheme(string) palette(string) excel(string) PPPyear(integer 2017)]
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	//house cleaning
	_pea_export_path, excel("`excel'")
	
	if "`missing'"~="" { //show missing
		foreach var of varlist `male' `relationharm' `age' `empstat' {
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
		local earnage = 18
		di "Age cut-off for earners of 18 assumed."
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
		noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
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

			// Preparation for Demographic and Economic compositions

		* Number adults
		gen _pea_adult = `age' > 17
		bys `year' `hhid' (`pid'): egen number_adults = sum(_pea_adult)	
		* Any children
		gen _pea_child = `age' < 18
		bys `year' `hhid' (`pid'): egen any_children = max(_pea_child)
		* Female adult or senior
		gen femaleolder17 = `age' > 17 &  `male' == 0
		bys `year' `hhid' (`pid'): egen female_older17 = sum(femaleolder17)
		* Male adult or senior
		gen maleolder17 = `age' > 17 & `male' == 1
		bys `year' `hhid' (`pid'): egen male_older17 = sum(maleolder17)
		* Senior
		gen _pea_senior = `age' > 64
		bys `year' `hhid' (`pid'): egen number_seniors = sum(_pea_senior)
		* Only seniors as adults
		gen only_seniors = number_seniors == number_adults & number_seniors ~= 0
		
		* Missing demographics
		gen dem_miss = 0
		if "`missing'" ~= "" {
			foreach var in `male' `age' {		
				di "`var'"
				su `var' if `var' ==`max_`var''			
				local `var'_mis = r(mean)
				replace dem_miss = 1 if `var' == ``var'_mis'
			}
		}
		
		else replace dem_miss = 1 if `male' == . | `age' == . 
		bys `year' `hhid' (`pid'): egen any_dem_miss = max(dem_miss)
		
		* Earners
		local empstat empstat
		if "`missing'" ~= "" {
			*local milab : value label `empstat'		
			*sum `empstat' if `empstat' == "Missing":`milab'									// check what missing value is (because in this table empstat missing values are changed)
			su `empstat' if `empstat' ==`max_`empstat''	
			if "`r(mean)'" ~= "" local empstat_mis = `r(mean)'
			if "`empstat_mis'" ~= "" {
				gen earner = `lstatus'== 0 | `empstat'==1 | `empstat'==3 | `empstat' == 4 if `lstatus' ~= . | `empstat' ~= `empstat_mis'				// Employed, self-employed, or employer (`lstatus' is nowork)	
			} 
			else gen earner = `lstatus'== 0 | `empstat'==1 | `empstat'==3 | `empstat' == 4 if `lstatus' ~= . | `empstat' ~= .
		}
		else gen earner = `lstatus'== 0 | `empstat'==1 | `empstat'==3 | `empstat' == 4 if `lstatus' ~= . | `empstat' ~= .
		* Female earners
		gen fearner = `age' > `earnage' & `male' == 0 & earner == 1
		bys `year' `hhid' (`pid'): egen number_fearners = sum(fearner)
		gen fadultnonearner = `age' > 17 & `male' == 0 & earner == 0
		bys `year' `hhid' (`pid'): egen number_fadultnonearners = sum(fadultnonearner)
		* Male earners
		gen mearner = `age' > `earnage' & `male' == 1 & earner == 1
		bys `year' `hhid' (`pid'): egen number_mearners = sum(mearner)
		gen madultnonearner = `age' > 17 & `male' == 1 & earner == 0
		bys `year' `hhid' (`pid'): egen number_madultnonearners = sum(madultnonearner)
		* Total number of earners
		bys `year' `hhid' (`pid'): gen number_earners = number_fearners + number_mearners
		bys `year' `hhid' (`pid'): gen number_adultnonearners = number_madultnonearners + number_fadultnonearners
		* Adult non-earners
		gen nonearner = `age' > `earnage'  & earner ~= 1
		bys `year' `hhid' (`pid'): egen any_nonearners = max(nonearner)
		* Missing earner information
		gen earner_miss = earner == . & `age' > 17
		bys `year' `hhid' (`pid'): egen any_earner_miss = max(earner_miss)
		
		// Demographic classification
		* 1) One female adult with children
		gen demographic_class1 = female_older17 == 1 & male_older17 == 0 ///
					& any_children == 1 & only_seniors == 0 & any_dem_miss ~= 1	
		* 2) One female adult without children
		gen demographic_class2 = female_older17 == 1 & male_older17 == 0 ///
					& any_children == 0 & only_seniors == 0 & any_dem_miss ~= 1							
		* 3) One male adult with children
		gen demographic_class3 = male_older17 == 1 & female_older17 == 0 ///
					& any_children == 1 & only_seniors == 0 & any_dem_miss ~= 1	
		* 4) One male adult without children
		gen demographic_class4 = male_older17 == 1 & female_older17 == 0 ///
					& any_children == 0 & only_seniors == 0 & any_dem_miss ~= 1				
		* 5) Two adults with children
		gen demographic_class5 = number_adults == 2 & any_children == 1 ///	
								& only_seniors == 0 & any_dem_miss ~= 1
		* 6) Two adults without children
		gen demographic_class6 = number_adults == 2 & any_children == 0 ///	
								& only_seniors == 0 & any_dem_miss ~= 1							
		* 7) Multiple adults with children
		gen demographic_class7 = number_adults >= 3 & any_children == 1 ///	
								& only_seniors == 0 & any_dem_miss ~= 1
		* 8) Multiple adults without children
		gen demographic_class8 = number_adults >= 3 & any_children == 0 ///	
								& only_seniors == 0 & any_dem_miss ~= 1		
		* 9) Only seniors with children
		gen demographic_class9 = only_seniors == 1 & any_children == 1 ///	
								& any_dem_miss ~= 1
		* 10) Only seniors without children
		gen demographic_class10 = only_seniors == 1 & any_children == 0 ///	
								& any_dem_miss ~= 1
		* 11) Children only households
		gen demographic_class11 = number_adults == 0 & any_children == 1  ///
								& any_dem_miss ~= 1
		* 12) Missing
		if "`missing'"~="" { //show missing
			gen demographic_class12 = any_dem_miss == 1
			label var demographic_class12 "Missing"
			for var demographic_class*: replace X = 0 if X==.		
		}
		for var demographic_class*: replace X = X*100

	// Economic classification
	* 1) One male earner, at least one adult female nonearner, with children
	gen		economic_class1 = number_mearners == 1 & number_fadultnonearners >= 1 	///
				& number_fearners == 0 & any_children == 1 if any_earner_miss ~= 1
	* 2) One male earner, at least one adult female nonearner, without children
	gen economic_class2 = number_mearners == 1 & number_fadultnonearners >= 1 		///
				& number_fearners == 0 & any_children == 0 if any_earner_miss ~= 1
	* 3) One female earner, at least one adult male nonearner, with children
	gen economic_class3 = number_fearners == 1 & number_madultnonearners >= 1 		///
				& number_mearners ==  0 & any_children == 1 if any_earner_miss ~= 1
	* 4) One female earner, at least one adult male nonearner, without children
	gen economic_class4 = number_fearners == 1 & number_madultnonearners >= 1 		///
				& number_mearners ==  0 & any_children == 0 if any_earner_miss ~= 1
	/* 5) One female earner, no other adults/seniors or earners, with children
	gen economic_class5 = number_fearners == 1  & number_mearners == 0 & any_children == 1 ///
				& ((number_adults == 1 & number_seniors == 0) ///
				| (number_adults == 0 & number_seniors == 1)) if any_earner_miss ~= 1
	* 6) Two earners that are couple, no other adults/seniors or earners, with children
	gen economic_class6 = any_adultcouple == 1 & number_earners == 2 & any_children == 1 ///
				& (number_adults + number_seniors == 2)  if any_earner_miss ~= 1
	* 7) Two earners that are couple, with other adult/senior nonearners, with children
	gen economic_class7 = any_adultcouple == 1 & number_earners == 2 & any_children == 1 ///
				& (number_adults + number_seniors > 2)  if any_earner_miss ~= 1
	* 8) Two earners that are couple, no other adults/seniors or earners, without children
	gen economic_class8 = any_adultcouple == 1 & number_earners == 2 & any_children == 0 ///
				& (number_adults + number_seniors == 2)  if any_earner_miss ~= 1
	* 9) At least two non-couple earners, no other adult/senior nonearners, with children
	gen economic_class9 = ((any_adultcouple == 0 & number_earners >= 2 & any_children == 1) ///
				| (any_adultcouple == 1 & number_earners >= 3 & any_children == 1)) ///
				& number_adultnonearners == 0 if any_earner_miss ~= 1
	* 10) At least two non-couple earners, with other adult/senior nonearners, with children
	gen economic_class10 = ((any_adultcouple == 0 & number_earners >= 2 & any_children == 1) ///
				| (any_adultcouple == 1 & number_earners >= 3 & any_children == 1)) ///
				& number_adultnonearners >= 1 if any_earner_miss ~= 1
	* 11) At least two non-couple earners, no other adult/senior nonearners, without children
	gen economic_class11 = ((any_adultcouple == 0 & number_earners >= 2 & any_children == 0) ///
				| (any_adultcouple == 1 & number_earners >= 3 & any_children == 0)) ///
				& number_adultnonearners == 0 if any_earner_miss ~= 1
	* 12) At least two non-couple earners, with other adult/senior nonearners, without children
	gen economic_class12 = ((any_adultcouple == 0 & number_earners >= 2 & any_children == 0) ///
				| (any_adultcouple == 1 & number_earners >= 3 & any_children == 0)) ///
				& number_adultnonearners >= 1 if any_earner_miss ~= 1
	* 13) Non-earning adult(s)/senior(s), no earners, without children
	gen economic_class13 = number_earners == 0 & any_children == 0 if any_earner_miss ~= 1
	* 14) Non-earning adult(s)/senior(s), no earners, with children
	gen economic_class14 = number_earners == 0 & any_children == 1 if any_earner_miss ~= 1
	* 15) One earner, no other adult/seniors, without children
	gen economic_class15 = number_earners == 1 & hsize == 1 & any_children == 0 if any_earner_miss ~= 1
	* 16) Other
	cap drop ecc_any
	egen ecc_any = rowtotal(economic_class*)
	gen economic_class16 = ecc_any == 0 if any_earner_miss ~= 1
	cap drop ecc_any
	* 17) Missing
	if "`missing'"~="" { //show missing
		gen economic_class17 = any_earner_miss == 1
		label var economic_class17 "Missing"
		local m_note "Households are classified as 'missing' if any adult has no information on labor market or employment status."
		foreach var of varlist economic_class* {
			replace `var' = 0 if `var' == .
		}
 	}
	
	foreach var of varlist economic_class* {
		replace `var' = `var' * 100
	}
	*/
	collapse (mean) economic_class* demographic_class* [aw=`wvar'], by(`year')

	reshape long economic_class demographic_class, i(year) j(group)	
	rename (economic_class*) 	(vareconomic_class*)	
	rename (demographic_class*) (vardemographic_class*)	
	reshape long var, i(year group) j(type, string)	
	gen Demographic = group if type == "demographic_class"
	gen Economic = group if type == "economic_class"
	
	label define group_d ///
		1 "One adult female with children"	///
		2 "One adult female no children"	///
		3 "One adult male with children"	///
		4 "One adult male no children"		///
		5 "Two adults with children"		///
		6 "Two adults no children"			///
		7 "Multiple adults with children"	///
		8 "Multiple adults no children"		///
		9 "Only seniors (65+) with children" ///							
		10 "Only seniors (65+) no children"	///									
		11 "Only children (‐18)"			///
		12 "Missing"
	label values Demographic group_d
	label var	 Demographic "Demographic typology"
	
	label define group_e ///
	1 "One male earner, at least one adult female nonearner, with children" ///
	2 "One male earner, at least one adult female nonearner, no children" ///
	3 "One female earner, at least one adult male nonearner, with children" ///
	4 "One female earner, at least one adult male nonearner, no children" ///
	5 "One female earner, no other earners or nonearners, with children" ///
	6 "Two earners that are couple, no other earners/nonearners, with children" ///
	7 "Two earners that are couple, with other nonearners, with children" ///
	8 "Two earners that are couple, no other earners/nonearners, no children" ///
	9 "At least two non-couple earners, no nonearners, with children" ///
	10 "At least two non-couple earners, with nonearners, with children" ///
	11 "At least two non-couple earners, no nonearners, no children" ///
	12 "At least two non-couple earners, with nonearners, no children" ///
	13 "Non-earning adult(s)/senior(s), no earners, no children" ///
	14 "Non-earning adult(s)/senior(s), no earners, with children" ///
	15 "One earner, no other adult/seniors, no children" 	///
	16 "Other"												///
	17 "Missing"											///
	18 "All Others"
	
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
/*
		// a)
		rename Demographic Poor
		treemap var, by(Poor) threshold(5) labsize(3) 		///
					 percent noval format(%3.1f) wrap(25) 	///
					 palette(tab20) name(gr_dem, replace)
		rename Poor Demographic
		
		putexcel set "`excelout2'", modify sheet("Figure16a", replace)
		graph export "`graph1'", replace as(png) name(gr_dem) wid(1500)
		putexcel A`u' = image("`graph1'")
		putexcel A1 = ""
		putexcel A2 = "Figure 16a: Profiles of the poor by demographic composition"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The figure shows the composition of poor households. The poor are defined against the `lblline'. Only groups with a share larger than 5% are shown. Demographic compositions follow Table 14. Data is from `year'. Household typologies are an extended version of Munoz Boudet et al. (2018)."
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"treemap var, by(Demographic) threshold(5) labsize(3) percent noval format(%3.1f) wrap(25) palette(tab20)"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
		// Export data
		export excel year Demographic var using "`excelout2'" if Demographic ~= ., sheet("Figure16a", modify) cell(O11) keepcellfmt firstrow(variables)	
	
		// b)
		tempfile graph1
		rename Economic Poor
		treemap var, by(Poor) threshold(5) labsize(3) 		///
					 percent noval format(%3.1f) wrap(25) 	///
					 palette(tab20) name(gr_econ, replace)
		rename Poor Economic
		
		putexcel set "`excelout2'", modify sheet("Figure16b", replace)
		graph export "`graph1'", replace as(png) name(gr_econ) wid(1500)
		putexcel A`u' = image("`graph1'")
		putexcel A1 = ""
		putexcel A2 = "Figure 16b: Profiles of the poor by economic composition"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The figure shows the composition of poor households. The poor are defined against the `lblline'. Only groups with a share larger than 5% are shown. Economic compositions follow Table 14. For the economic composition, earners are defined as those working and `earnage' years or older. Data is from `year'. Household typologies are an extended version of Munoz Boudet et al. (2018)."
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"treemap var, by(Economic) threshold(5) labsize(3) percent noval format(%3.1f) wrap(25) palette(tab20)"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
		// Export data
		export excel year Economic var using "`excelout2'" if Economic ~= ., sheet("Figure16b", modify) cell(O11) keepcellfmt firstrow(variables)	
			*/
		// c)
		
		replace var = 0 if  Demographic == 16
		gen less5 = var <= 5
		bys type less5: egen sum = sum(var) 
		replace var = sum if Demographic == 16
		drop less5 sum
		tempfile graph1

		splitvallabels Demographic if (var > 5 | Demographic == 16) & var != ., length(25)
		graph hbar var if (var > 5 | Demographic == 16) & var != .,	///
				over(Demographic, relabel(`r(relabel)'))		///
				ytitle("Share of poor population")				///
				bar(1, color("`: word 1 of ${colorpalette}'"))	///	
				name(bar_dem, replace)
				
		putexcel set "`excelout2'", modify sheet("Figure16", replace)
		graph export "`graph1'", replace as(png) name(bar_dem) wid(1500)
		putexcel A`u' = image("`graph1'")
		putexcel A1 = ""
		putexcel A2 = "Figure 16: Profiles of the poor by demographic composition"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The figure shows the composition of poor households. The poor are defined against the `lblline'. Only groups with a share larger than 5% are shown. Demographic compositions follow Table 14. Data is from `year'. Household typologies are an extended version of Munoz Boudet et al. (2018)."
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"graph hbar var if (var > 5 | Demographic == 16) & var != ., over(Demographic, relabel(`r(relabel)')) ytitle("Share of poor population") bar(1, color("`: word 1 of ${colorpalette}'"))"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
		// Export data
		export excel year Demographic var using "`excelout2'" if Demographic ~= ., sheet("Figure16", modify) cell(O11) keepcellfmt firstrow(variables)
		/*
		// d)	
		insobs 1
		replace var = 0 if  type == ""
		replace Economic = 18 if type == ""
		replace type = "economic_class" if type == ""
		gen less5 = var <= 5
		bys type less5: egen sum = sum(var) 
		replace var = sum if Economic == 18
		drop less5 sum
		tempfile graph1
		splitvallabels Economic if (var > 5 | Economic == 18) & var != ., length(25)
		graph hbar var if (var > 5 | Economic == 18) & var != .,	///
			over(Economic, relabel(`r(relabel)'))			///
			ytitle("Share of poor population")				///
			bar(1, color("`: word 1 of ${colorpalette}'"))	///	
			name(bar_econ, replace)						
		putexcel set "`excelout2'", modify sheet("Figure16d", replace)
		graph export "`graph1'", replace as(png) name(bar_econ) wid(1500)
		putexcel A`u' = image("`graph1'")
		putexcel A1 = ""
		putexcel A2 = "Figure 16d: Profiles of the poor by economic composition"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The figure shows the composition of poor households. The poor are defined against the `lblline'. Only groups with a share larger than 5% are shown. Economic compositions follow Table 14. For the economic composition, earners are defined as those working and `earnage' years or older. Data is from `year'. Household typologies are an extended version of Munoz Boudet et al. (2018). `m_note'"
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"graph hbar var if (var > 5 | Economic == 18) & var != ., over(Economic, relabel(`r(relabel)')) ytitle("Share of poor population") bar(1, color("`: word 1 of ${colorpalette}'"))"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
		// Export data
		export excel year Economic var using "`excelout2'" if Economic ~= ., sheet("Figure16d", modify) cell(O11) keepcellfmt firstrow(variables) nolabel
			*/	
		putexcel save
		cap graph close	
		
		if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"
end
