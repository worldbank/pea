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
	syntax [if] [in] [aw pw fw], [ONEWelfare(varname numeric) ONELine(varname numeric) Year(varname numeric) setting(string) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) married(varname numeric) hhsize(varname numeric) hhid(string) pid(string) industrycat4(varname numeric) lstatus(varname numeric) empstat(varname numeric) relationharm(varname numeric) earnage(integer 18) MISSING scheme(string) palette(string) excel(string)]
	
	//house cleaning
	if "`excel'"=="" {
		tempfile xlsxout 
		local excelout `xlsxout'		
		local path "`xlsxout'"		
		local lastslash = strrpos("`path'", "\") 				
		local dirpath = substr("`path'", 1, `lastslash')		
	}
	else {
		cap confirm file "`excel'"
		if _rc~=0 {
			noi dis as error "Unable to confirm the file in excel()"
			error `=_rc'	
		}
		else local excelout "`excel'"
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
	
	* Identify households with couples (i.e. spouses, non-relatives does not count)
	gen anyspouse = `relationharm' == 2 & `age' > 17 & `age' < 65
	gen hhheadisadult = `relationharm' == 1 & `age' > 17 & `age' < 65
	bys `year' `hhid' (`pid'): egen num_spouse = sum(anyspouse)
	bys `year' `hhid' (`pid'): egen any_spouse = max(anyspouse)
	bys `year' `hhid' (`pid'): egen any_adulthhead = max(hhheadisadult)
	gen any_adultcouple = num_spouse == 1 & any_adulthhead == 1
	* Identify households with couples below 18
	gen anyspousebelow18 = `relationharm' == 2 & `age' < 18
	gen hhheadisbelow18 = `relationharm' == 1 & `age' < 18
	bys `year' `hhid' (`pid'): egen any_spousebelow18 = max(anyspousebelow18)
	bys `year' `hhid' (`pid'): egen any_hhheadbelow18 = max(hhheadisbelow18)
	* Identify number of adults
	gen adult = `age' > 17 & `age' < 65
	bys  `year' `hhid' (`pid'): egen number_adults = sum(adult)
	* Identify children
	gen child = `age' < 18
	bys `year' `hhid' (`pid'): egen any_children = max(child)
	* Female adult or senior
	gen femaleolder17 = `age' > 17 &  `male' == 0
	bys `year' `hhid' (`pid'): egen female_older17 = sum(femaleolder17)
	* Male adult or senior
	gen maleolder17 = `age' > 17 & `male' == 1
	bys `year' `hhid' (`pid'): egen male_older17 = sum(maleolder17)
	* Senior
	gen senior = `age' > 64
	bys `year' `hhid' (`pid'): egen number_seniors = sum(senior)
	* Earners
	local empstat empstat
	local lstatus lstatus
	local varlbl : value label empstat
	sum `empstat' if `varlbl' == "Missing":`empstat'									// check what missing value is
	cap local empstat_mis = `r(mean)'
	gen earner = `lstatus'== 0 | `empstat'==1 | `empstat'==3 | `empstat' == 4 if `lstatus' ~= . | `empstat' ~= .				// Employed, self-employed, or employer (`lstatus' is nowork)
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
	* Adult nonearners
	gen nonearner = `age' > `earnage'  & earner ~= 1
	bys `year' `hhid' (`pid'): egen any_nonearners = max(nonearner)
	* Missing earner information
	gen earner_miss = earner == . & `age' > 17
	bys `year' `hhid' (`pid'): egen any_earner_miss = max(earner_miss)
	
	// Demographic classification
	* 1) Adult couple, with children, no other adults/seniors
	gen demographic_class1 = any_adultcouple == 1 & any_children == 1 ///	
							& number_adults == 2 & number_seniors == 0
	* 2) Adult couple, with children, and other adults/seniors
	gen demographic_class2 = any_adultcouple == 1 & any_children == 1 ///
							& (number_adults > 2 | number_seniors > 0)
	* 3) Adult couple, no children, no other adults/seniors
	gen demographic_class3 = any_adultcouple == 1 & any_children == 0 ///
							& number_adults == 2 & number_seniors == 0
	* 4) Couple (at least one spouse below 18), with children, no other adult/seniors
	gen demographic_class4 = (any_spousebelow18 == 1 | (any_hhheadbelow18 == 1 & any_spouse ==1)) ///	
							& any_children == 1 & `hhsize' > 2 & (number_adults < 2 & number_seniors == 0)
	* 5) Couple (at least one spouse below 18), no children, no other adult/seniors
	gen demographic_class5 = (any_spousebelow18 == 1 | (any_hhheadbelow18 == 1 & any_spouse ==1)) ///
							& any_children == 0 & `hhsize' == 2 & (number_adults < 2 & number_seniors == 0)
	* 6) One female adult (no couple), with children, no other adult/seniors
	gen demographic_class6 = female_older17 == 1 & any_spouse == 0 & any_children == 1 ///
							& (number_adults == 1 & number_seniors == 0) 
	* 7) One male adult (no couple), with children, no other adult/seniors
	gen demographic_class7 = male_older17 == 1 & any_spouse == 0 & any_spousebelow18 == 0 ///
							& any_children == 1 & (number_adults == 1 & number_seniors == 0)
	* 8) One adult, no children, no other adult/seniors
	gen demographic_class8 = any_children == 0 & (number_adults == 1 & number_seniors == 0)
	* 9) Multiple female only adults, with children
	gen demographic_class9 = male_older17 == 0 & any_children == 1 & number_adults > 1 ///
							& number_senior == 0 & any_spousebelow18 == 0 & any_spouse == 0
	* 10) Other adults combinations with children
	cap drop dem_any
	egen dem_any = rowtotal(demographic_class*)
	gen demographic_class10 = number_adults > 0 & any_children == 1 & dem_any == 0
	* 11) Other adults combinations no children
	cap drop dem_any
	egen dem_any = rowtotal(demographic_class*)
	gen demographic_class11 = number_adults > 0 & any_children == 0 & dem_any == 0
	cap drop dem_any
	* 12) Senior(s), with children, no adults
	gen demographic_class12 = number_adults == 0 & any_children == 1 & number_senior > 0
	* 13) Senior(s), no children, no adults
	gen demographic_class13 = number_adults == 0 & any_children == 0 & number_senior > 0
	* 14) Children only households
	gen demographic_class14 = number_adults == 0 & any_children == 1 & number_senior == 0 ///
							& any_spousebelow18 ~= 1
	* 15) Missing
	if "`missing'"~="" { //show missing
		cap drop dem_any
		egen dem_any = rowtotal(demographic_class*)
		gen demographic_class15 = dem_any == 0
		replace demographic_class15 = 1 if demographic_class15==1
		label var demographic_class15 "Missing"
 	}
	
	foreach var of varlist demographic_class* {
		replace `var' = `var' * 100
	}
	
	
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
	* 5) One female earner, no other adults/seniors or earners, with children
	gen economic_class5 = number_fearners == 1  & number_mearners == 0 & any_children == 1 ///
				& ((number_adults == 1 & number_seniors == 0) ///
				| (number_adults == 0 & number_seniors == 1)) if any_earner_miss ~= 1
	* 6) Two earners that are couple, no other adults/seniors or earners, with children
	gen economic_class6 = any_adultcouple == 1 & number_earners == 2 & any_children == 1 ///
				& (number_adults + number_seniors == 2)  if any_earner_miss ~= 1
	* 7) Two earners that are couple, with other adult/senior nonearners, with children
	gen economic_class7 = any_adultcouple == 1 & number_earners == 2 & any_children == 1 ///
				& (number_adults + number_seniors > 2)
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
 	}

	
	foreach var of varlist economic_class* {
		replace `var' = `var' * 100
	}
	
	collapse (mean) economic_class* demographic_class* [aw=`wvar'], by(`year')

	reshape long economic_class demographic_class, i(year) j(group)	
	rename (economic_class*) 	(vareconomic_class*)	
	rename (demographic_class*) (vardemographic_class*)	
	reshape long var, i(year group) j(type, string)	
	gen Demographic = group if type == "demographic_class"
	gen Economic = group if type == "economic_class"
	
	label define group_d ///
	1 "Adult couple, with children, no other adults/seniors" ///
	2 "Adult couple, with children, and other adults/seniors" ///
	3 "Adult couple, no children, no other adults/seniors" ///
	4 "Couple (at least one spouse below 18), with children, no other adult/seniors" ///
	5 "Couple (at least one spouse below 18), no children, no other adult/seniors" ///
	6 "One female adult (no couple), with children, no other adult/seniors" ///
	7 "One male adult (no couple), with children, no other adult/seniors" ///
	8 "One adult or senior, no children, no other adult/seniors" ///
	9 "Multiple female only adults (no couple), with children" ///
	10 "Other adults combinations, with children" ///
	11 "Other adults combinations, no children" ///
	12 "Senior(s), with children, no adults" ///
	13 "Senior(s), no children, no adults" ///
	14 "Children only households (no couple)" ///
	15 "All other"
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
	15 "One earner, no other adult/seniors, no children" ///
	16 "Other"												///
	17 "All other"
	label values Economic group_e
	label var	 Economic "Economic typology"
	drop group
	
	// Figure
		local figname Figure16
		if "`excel'"=="" {
			local excelout2 "`dirpath'\\`figname'.xlsx"
			local act replace
		}
		else {
			local excelout2 "`excelout'"
			local act modify
		}
		local u  = 5	
		tempfile graph1

		// a)
		rename Demographic Poor
		treemap var, by(Poor) threshold(25) labsize(3) 		///
					 percent noval format(%3.1f) wrap(25) 	///
					 palette(tab20) name(gr_dem, replace)
		rename Poor Demographic
		
		putexcel set "`excelout2'", modify sheet("Figure16a", replace)
		graph export "`graph1'", replace as(png) name(gr_dem) wid(1500)
		putexcel A1 = ""
		putexcel A2 = "Figure 16a: Profiles of the poor by demographic composition"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The figure shows the composition of poor households. The poor are defined against the `lblline'. Only groups with a share larger than 5% are shown. Demographic compositions follow Table 14. Data is from `year'. Household typologies are an extended version of Munoz Boudet et al. (2018)."
		putexcel A`u' = image("`graph1'")
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"treemap var, by(Demographic) threshold(5) labsize(3) percent noval format(%3.1f) wrap(25) palette(tab20)"'
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
		putexcel A1 = ""
		putexcel A2 = "Figure 16b: Profiles of the poor by economic composition"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The figure shows the composition of poor households. The poor are defined against the `lblline'. Only groups with a share larger than 5% are shown. Economic compositions follow Table 14. For the economic composition, earners are defined as those working and `earnage' years or older. Data is from `year'. Household typologies are an extended version of Munoz Boudet et al. (2018)."
		putexcel A`u' = image("`graph1'")
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"treemap var, by(Economic) threshold(5) labsize(3) percent noval format(%3.1f) wrap(25) palette(tab20)"'
		// Export data
		export excel year Economic var using "`excelout2'" if Economic ~= ., sheet("Figure16b", modify) cell(O11) keepcellfmt firstrow(variables)	
			
		// c)
		
		replace var = 0 if  Demographic == 15
		gen less5 = var <= 5
		bys type less5: egen sum = sum(var) 
		replace var = sum if Demographic == 15
		drop less5 sum
		tempfile graph1

		splitvallabels Demographic if (var > 5 | Demographic == 15) & var != ., length(25)
		graph hbar var if (var > 5 | Demographic == 15) & var != .,	///
				over(Demographic, relabel(`r(relabel)'))		///
				ytitle("Share of poor population")				///
				bar(1, color("`: word 1 of ${colorpalette}'"))	///	
				name(bar_dem, replace)
				
		putexcel set "`excelout2'", modify sheet("Figure16c", replace)
		graph export "`graph1'", replace as(png) name(bar_dem) wid(1500)
		putexcel A1 = ""
		putexcel A2 = "Figure 16c: Profiles of the poor by demographic composition"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The figure shows the composition of poor households. The poor are defined against the `lblline'. Only groups with a share larger than 5% are shown. Demographic compositions follow Table 14. Data is from `year'. Household typologies are an extended version of Munoz Boudet et al. (2018)."
		putexcel A`u' = image("`graph1'")
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"graph hbar var if var > 5 & var != ., over(Demographic, relabel(`r(relabel)')) ytitle("Share of poor population") bar(1, color("`: word 1 of ${colorpalette}'"))"'
		// Export data
		export excel year Demographic var using "`excelout2'" if Demographic ~= ., sheet("Figure16c", modify) cell(O11) keepcellfmt firstrow(variables)
		
		// d)	
		insobs 1
		replace var = 0 if  type == ""
		replace Economic = 17 if type == ""
		replace type = "economic_class" if type == ""
		gen less5 = var <= 5
		bys type less5: egen sum = sum(var) 
		replace var = sum if Economic == 17
		drop less5 sum
		tempfile graph1
		splitvallabels Economic if (var > 5 | Economic == 17) & var != ., length(25)
		graph hbar var if (var > 5 | Economic == 17) & var != .,	///
			over(Economic, relabel(`r(relabel)'))			///
			ytitle("Share of poor population")				///
			bar(1, color("`: word 1 of ${colorpalette}'"))	///	
			name(bar_econ, replace)						
		putexcel set "`excelout2'", modify sheet("Figure16d", replace)
		graph export "`graph1'", replace as(png) name(bar_econ) wid(1500)
		putexcel A1 = ""
		putexcel A2 = "Figure 16d: Profiles of the poor by economic composition"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The figure shows the composition of poor households. The poor are defined against the `lblline'. Only groups with a share larger than 5% are shown. Economic compositions follow Table 14. For the economic composition, earners are defined as those working and `earnage' years or older. Data is from `year'. Household typologies are an extended version of Munoz Boudet et al. (2018)."
		putexcel A`u' = image("`graph1'")
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"graph hbar var if var > 5 & var != ., over(Economic, relabel(`r(relabel)')) ytitle("Share of poor population") bar(1, color("`: word 1 of ${colorpalette}'"))"'
		// Export data
		export excel year Economic var using "`excelout2'" if Economic ~= ., sheet("Figure16d", modify) cell(O11) keepcellfmt firstrow(variables)
				
		putexcel save
		cap graph close	
		
		if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"
		
end
