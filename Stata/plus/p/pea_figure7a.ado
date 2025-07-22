*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 
*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Henry Stemmler <hstemmler@worldbank.org>; Sandra Carolina Segovia Juarez <ssegoviajuarez@worldbank.org>
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

//Figure 7a. Share of poor and population by demographic groups


cap program drop pea_figure7a
program pea_figure7a, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [ONEWelfare(varname numeric) ONELine(varlist numeric) Year(varname numeric) FGTVARS LINESORTED age(varname numeric) male(varname numeric) edu(varname numeric) urban(varname numeric) setting(string) MISSING scheme(string) palette(string) excel(string) save(string) PPPyear(integer 2021)]
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	//house cleaning
	_pea_export_path, excel("`excel'")
	
	if "`missing'"~="" { //show missing
		foreach var of varlist `male' `edu' {
			su `var'
			local miss = r(max)
			replace `var' = `=`miss'+10' if `var'==.
			local varlbl : value label `var'
			la def `varlbl' `=`miss'+10' "Missing", add
		}
	}
	local lblline: var label `oneline'		
	
	//Weights
	local wvar : word 2 of `exp'
	qui if "`wvar'"=="" {
		tempvar w
		gen `w' = 1
		local wvar `w'
	}
	
	//missing observation check
	marksample touse
	local flist `"`wvar' `onewelfare' `oneline'"' // `male' `edu' `age' `urban'
	markout `touse' `flist' 
		
	//Number of groups (for colors)
	local groups = 2

	// Figure colors
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")	//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
		
	// Generate poverty measures
	if "`fgtvars'"=="" { //only create when the fgt are not defined	
		if "`onewelfare'"~="" { //reset to the floor
			replace `onewelfare' = ${floor_} if `onewelfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
		//FGT
		if "`onewelfare'"~="" & "`oneline'"~="" _pea_gen_fgtvars if `touse', welf(`onewelfare') povlines(`oneline')
		gen double _pop = `wvar'
	}
	
	// Shorten value labels 
    local lbl: value label `edu'
	if "`lbl'" == "educat4" {
		label define educat4_m 1 "No education" 2 "Primary" 3 "Secondary" 4 "Tertiary" 14 "Missing education"
		label values `edu' educat4_m
	}	
	replace `edu' = . if `age'<16 & `age'==.

	// Variable definitions
	if "`age'"!="" {
		su `age',d
		if r(N)>0 {
			gen agecatind = 1 if `age'>=0 & `age'<=14
			replace agecatind = 2 if `age'>=15 & `age'<=64
			replace agecatind = 3 if `age'>=65 & `age'<=.
			la def agecatind 1 "Age 0-14" 2 "Age 15-64" 3 "Age 65+"
			la val agecatind agecatind
		}
	}
	
	tempfile data1 data2
	
	// Only last year
	qui sum `year', d   // Get last year of survey data (year of scatter plot)
	local lasty `r(max)'
	keep if `year' == `lasty'
	save `data1', replace
	clear
	save `data2', replace emptyok	

	// Prepare poverty rates by groups
	use `data1', clear	
	local byind `male' `edu' agecatind `urban'
	local i = 1
	foreach var of local byind {
		use `data1', clear
		qui levelsof `var', local(lclist)
		local label1 : value label `var'
		 
		foreach lvl of local lclist {
			use `data1', clear
			keep if `var'==`lvl'
			local lbllvl : label `label1' `lvl'			
			groupfunction  [aw=`wvar'] if `touse', mean(_fgt0_`onewelfare'_`oneline') rawsum(_pop) by(`year')
			gen _cat = "`var'"
			gen _group = `i'			
			la def _group `i' "`lbllvl'", add
			la val _group _group
			tempfile labelx`i'
			label save _group using `labelx`i''
			la drop _group
			local i = `i' + 1			
			append using `data2'
			save `data2', replace
		}
	}
	qui forv j=1(1)`=`i'-1' {
		do `labelx`j''
	}
	la val _group _group
	
	gen npoor = _fgt0_`onewelfare'_`oneline'*_pop
	bys `year' _cat (_group): egen totpoor = total(npoor)
	bys `year' _cat (_group): egen totpop = total(_pop)
	gen double share_poor = (npoor/totpoor)*100
	gen double share_pop = (_pop/totpop)*100

	// Figure
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure7a.xlsx"
		local act replace
		cap rm "`dirpath'\\Figure7a.xlsx"
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
	local u = 5
	decode _group, gen(group)
	tempfile graph
	putexcel set "`excelout2'", `act'
	graph hbar share_poor share_pop, 				///
			over(_group) bar(1, color("${col1}")) bar(2, color("${col2}")) ///  
			legend(pos(6) order(1 "Share of poor" ///
			2 "Share of population") row(1) on) 	///
			ytitle("Share of poor or population (percent)") 				///
			name(ngraph`gr', replace)	

	putexcel set "`excelout2'", modify sheet(Figure7a, replace)	  
	graph export "`graph'", replace as(png) name(ngraph) wid(1500)	
	putexcel A`u' = image("`graph'")
	
	putexcel A1 = ""
	putexcel A2 = "Figure 7a: Share of poor and population by demographic groups"
	putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
	putexcel A4 = "Note: Figure presents the share of poor disaggregated into different subgroups, using `lblline', for `year'. Data from all individuals is used, not only household heads. Poverty rates by educational attainment are calculated only for individuals aged 16 and above. Education level refers to the highest level attended, complete or incomplete."
	
	putexcel O10 = "Data:"
	putexcel O6	= "Code:"
	putexcel O7 = `"graph hbar share_poor share_pop, over(_group) bar(1, color("${col1}")) bar(2, color("${col2}")) legend(pos(6) order(1 "Share of poor" 2 "Share of population") row(1) on) ytitle("Share of poor or population (percent)")""'
	if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
	putexcel save								
	cap graph close	
	//Export data
	export excel `year' group share_poor share_pop using "`excelout2'" , sheet("Figure7a", modify) cell(O11) keepcellfmt firstrow(variables) nolabel
	if "`excel'"=="" shell start excel "`dirpath'\\Figure7a.xlsx"	
		
end	