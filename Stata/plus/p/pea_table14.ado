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

//Table 14. Household typologies

cap program drop pea_table14
program pea_table14, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Welfare(varname numeric) Povlines(varname numeric) Year(varname numeric) CORE setting(string)  excel(string) save(string) age(varname numeric) male(varname numeric) hhsize(varname numeric) hhid(string) pid(string) lstatus(varname numeric) empstat(varname numeric) relationharm(varname numeric) earnage(integer 18) MISSING PPPyear(integer 2017)]
	
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
	qui {
		//order the lines
		local lbl`povlines' : variable label `povlines'		
		local lblline: var label `povlines'		
		
		//Weights
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		}
	
		//missing observation check
		marksample touse
		*local flist `"`wvar' `welfare' `povlines' `year' `hhid' `pid'"'
		local flist `"`wvar' `welfare' `povlines' `year'"'
		markout `touse' `flist' 
		
		if "`core'"~="" { //reset to the floor PPP lines
			replace `welfare' = ${floor_} if `welfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
		
		tempfile dataori datalbl
		save `dataori', replace
		des, replace clear
		save `datalbl', replace
		use `dataori', clear
		
		//check values	
		local tmp
		foreach var of local services {
			su `var' if `touse',d
			if r(N)>0 local tmp "`tmp' `var'"
		}
		local services `tmp'
		
		local tmp
		foreach var of local assets {
			su `var' if `touse',d
			if r(N)>0 local tmp "`tmp' `var'"
		}
		local assets `tmp'
		
		//FGT
		gen _fgt0_`welfare'_`povlines' = (`welfare' < `povlines') if `welfare'~=. & `touse'
		gen double _pop = `wvar' if `touse'
			
		gen _total = 1 if `touse'
		la def _total 1 "Total"
		la val _total _total
		
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
		
		* Label 
		cap label var demographic_class1 "One adult female with children"	
		cap label var demographic_class2 "One adult female no children"	
		cap label var demographic_class3 "One adult male with children"	
		cap label var demographic_class4 "One adult male no children"	
		cap label var demographic_class5 "Two adults with children"	
		cap label var demographic_class6 "Two adults no children"
		cap label var demographic_class7 "Multiple adults with children"	
		cap label var demographic_class8 "Multiple adults no children"	
		cap label var demographic_class9 "Only seniors (65+) with children"							
		cap label var demographic_class10 "Only seniors (65+) no children"										
		cap label var demographic_class11 "Only children (‐18)"			
		cap label var demographic_class12 "Missing"
		
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
		/*
		* 5) One female earner, no other adults/seniors or earners, with children
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
		gen economic_class15 = number_earners == 1 & `hhsize' == 1 & any_children == 0 if any_earner_miss ~= 1
		* 16) Other
		cap drop ecc_any
		egen ecc_any = rowtotal(economic_class*)
		gen economic_class16 = ecc_any == 0 if any_earner_miss ~= 1
		cap drop ecc_any
		* 17) Missing
		if "`missing'"~="" { //show missing
			gen economic_class17 = any_earner_miss == 1
			label var economic_class17 "Missing"
			local m_note "Households are classified as 'missing' in the economic typology if any adult has no information on labor market or employment status."
			for var economic_class*: replace X = 0 if X==.			
		}
		
		* Label 
		cap label var economic_class1 "One male earner, at least one adult female nonearner, with children"						
		cap label var economic_class2 "One male earner, at least one adult female nonearner, no children"					
		cap label var economic_class3 "One female earner, at least one adult male nonearner, with children"						
		cap label var economic_class4 "One female earner, at least one adult male nonearner, no children"					
		cap label var economic_class5 "One female earner, no other earners or nonearners, with children"					
		cap label var economic_class6 "Two earners that are couple, no other earners/nonearners, with children"			
		cap label var economic_class7 "Two earners that are couple, with other nonearners, with children"			
		cap label var economic_class8 "Two earners that are couple, no other earners/nonearners, no children"		
		cap label var economic_class9 "At least two non-couple earners, no nonearners, with children"		
		cap label var economic_class10 "At least two non-couple earners, with nonearners, with children"			
		cap label var economic_class11 "At least two non-couple earners, no nonearners, no children"	
		cap label var economic_class12 "At least two non-couple earners, with nonearners, no children"		
		cap label var economic_class13 "Non-earning adult(s)/senior(s), no earners, no children"								
		cap label var economic_class14 "Non-earning adult(s)/senior(s), no earners, with children"								
		cap label var economic_class15 "One earner, no other adult/seniors, no children"									
		cap label var economic_class16 "Other"
		cap label var economic_class17 "Missing"
		*/
		for var economic_class* : replace X = X*100
		
		unab demographic_comp: demographic_class*
		unab economic_comp: economic_class*

		//bys `year' `hhid' (`pid'): egen double hhwgt = total(`wvar')
		//household can have more than one head, that is data problem, we dont fix this.
		//the indicators are defined at the household level, thus using weight.
		tempfile data1 data2 data3 datalbl
		save `data1', replace
		des, clear replace
		save `datalbl', replace
		clear
		save `data2', replace emptyok
		
		local byind _fgt0_`welfare'_`povlines'  _total
			
		foreach var of local byind {
			use `data1', clear
			
			groupfunction  [aw=`wvar'] if `touse', mean(`demographic_comp' `economic_comp') rawsum(_pop) by(`year' `var')
			ren `var' _bygroup
			gen _varname = "`var'"
			save `data3', replace
			foreach var in `demographic_comp' `economic_comp' {
				use `data3', clear
				keep `year' _bygroup _pop `var' _varname
				ren `var' value
				gen variable = "`var'"
				append using `data2'
				save `data2', replace
			}		
		}
		gen _bygroup2 = 1 if _bygroup==1 & _varname=="_fgt0_`welfare'_`povlines'"
		replace _bygroup2 = 2 if _bygroup==0 & _varname=="_fgt0_`welfare'_`povlines'"
		replace _bygroup2 = 3 if _bygroup==1 & _varname=="_total"
		la def _bygroup2 1 "Poor" 2 "Nonpoor" 3 "Total"
		la val _bygroup2 _bygroup2
		
		clonevar name = variable
		merge m:1 name using `datalbl', keepus(varlab)
		drop if _merge==2
		drop _merge
		
		//
		gen group1 = .
		foreach var of local demographic_comp {
			replace group1 = 1 if name=="`var'"
		}
		foreach var of local economic_comp {
			replace group1 = 2 if name=="`var'"
		}
		
		la def group1 1 "Demographic composition (%)" 2 "Economic composition (%)"
		la val group1 group1
		
		// Keep only demographic composition for now
		keep if group1 == 1
		
		local i = 1
		gen order = .
		foreach var in `demographic_comp' `economic_comp' {
			replace order = `i' if name=="`var'"
			local i = `i' + 1
		}
	} //qui

	collect clear
	qui collect: table (group1 order   varlab) (`year' _bygroup2), statistic(mean value) nototal nformat(%20.1f) missing	
	collect style header group1 order   varlab `year' _bygroup2, title(hide)
	collect title `"Table 14. Demographic and economic household typologies"'
	*collect style header group2[.], level(hide)
	collect style header order, level(hide)
	collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."' 
	collect notes 2: `"Note: Poverty profiles are presented as shares of poor, nonpoor and total populations. The poor are defined using `lblline'. Household typologies build on the classification vof Munoz Boudet et al. (2018). `m_note'"' 
	// For the economic composition, earners are defined as those working and `earnage' years or older.
	collect style cell group1[]#cell_type[row-header], font(, bold)
	collect style cell varlab[]#cell_type[row-header], warn font(, nobold)
	_pea_tbtformat
	_pea_tbt_export, filename(Table14) tbtname(Table14) excel("`excel'") dirpath("`dirpath'") excelout("`excelout'") shell
	
end