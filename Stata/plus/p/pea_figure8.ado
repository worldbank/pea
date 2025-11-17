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

//Figure 8. Poverty rates by sex and age groups

cap program drop pea_figure8
program pea_figure8, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [ONEWelfare(varname numeric) ONELine(varname numeric) Year(varname numeric) NOOUTPUT FGTVARS YRange(string) age(varname numeric) male(varname numeric) excel(string) save(string) MISSING scheme(string) palette(string) PPPyear(integer 2021)]
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all		
	
	//house cleaning	
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}
	if "`age'"=="" {
		noi di in red "Age variable must be defined in age()"
		exit 1
	}	
	if "`male'"=="" {
		noi di in red "Sex variable must be defined in male()"
		exit 1
	}	
	_pea_export_path, excel("`excel'")
	
	//Age groups
	local n1 = 0
	local n2 = 4
	gen agecatind = .
	forval num = 1/16 {
		replace agecatind = `num' if `age' >= `n1' & `age'<=`n2'
		la def agecatind `num' "`n1'-`n2'", modify
		local n1 = `n1' + 5
		local n2 = `n2' + 5
	}
	label values agecatind agecatind
	
	//Number of groups (for colors)
	local groups = 2

	// Figure colors
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")	//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)

	//Weights
	local wvar : word 2 of `exp'
	qui if "`wvar'"=="" {
		tempvar w
		gen `w' = 1
		local wvar `w'
	}

	local lblline: var label `oneline'			
	//missing observation check
	marksample touse
	local flist `"`wvar' `onewelfare' `oneline' `year' `age' `male'"'
	markout `touse' `flist' 
	
	tempfile dataori datacomp
	save `dataori', replace

	use `dataori', clear	
	
	// Generate poverty measures
	if "`fgtvars'"=="" { //only create when the fgt are not defined	
		if "`onewelfare'"~="" { //reset to the floor
			replace `onewelfare' = ${floor_} if `onewelfare'< ${floor_}
			noi di in yellow "Welfare in `pppyear' PPP is adjusted to a floor of ${floor_}"
		}
		//FGT
		if "`onewelfare'"~="" & "`oneline'"~="" _pea_gen_fgtvars if `touse', welf(`onewelfare') povlines(`oneline')
	}

	// Only last year
	tempfile data1 data2
	qui sum `year', d   // Get last year of survey data (year of scatter plot)
	local lasty `r(max)'
	keep if `year' == `lasty'
	save `data1', replace
	clear
	save `data2', replace emptyok	

	// Prepare poverty rates by groups
	use `data1', clear	
	local varlbl : value label `male'
	qui levelsof `male', local(groups)
	local k = 1
	foreach j of local groups {
		local i = 1
		use `data1', clear
		local labl`j': label `varlbl' `j'
		local legend `"`legend' `k' "`labl`j''""'
		qui levelsof agecatind, local(lclist)
		local label1 : value label agecatind
		foreach lvl of local lclist {
			use `data1', clear
			keep if `male' == `j'
			keep if agecatind==`lvl'
			local lbllvl : label `label1' `lvl'			
			groupfunction  [aw=`wvar'] if `touse', mean(_fgt0_`onewelfare'_`oneline') by(`year')
			ren _fgt0_`onewelfare'_`oneline' value`j'
			label var value`j' "`labl`j''"
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
		local k = `k' + 1
	}
	qui forv j=1(1)`=`i'-1' {
		do `labelx`j''
	}
	qui for var value*: replace X = X*100	
	
	//Axis range
		if "`yrange'" == "" {
			local m = 1
			foreach var of varlist value* {
				sum `var'													// min/max can come from different variables
				if (`m' == 1) local max = `r(max)'
				if (`m' == 1) local min = `r(min)'
				if (`r(max)' > `max') local max = `r(max)'
				if (`r(min)' < `min') local min = `r(min)'
				local m = `m' + 1
			}
			if `min' < 0 local ymin = floor(`min')
			else local ymin = 0
			if `max' > 0 local ymax = ceil(`max')
			else local ymax = 0
			nicelabels `ymin' `ymax', local(yla)
			local yrange "ylabel(`yla')"
		}
		else {
			local yrange "ylabel(`yrange')"
		}

	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure8.xlsx"
		local act replace
		cap rm "`dirpath'\\Figure8.xlsx"
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}

	//Figure		
	local gr = 1
	local u  = 5
	putexcel set "`excelout2'", `act'
	//change all legend to bottom, and maybe 2 rows
	//add comparability
	tempfile graph`gr'
	twoway scatter value* _group || line value* _group				///	
			  , legend(order("`legend'")) 							///
			  ytitle("Poverty rate (%)") mcolor(${colorpalette})	///
			  xtitle("Age group") lcolor(${colorpalette})			///
			  xlabel(1(1)16, valuelabel angle(90))					///
			  `yrange'												///
			  name(ngraph`gr', replace)	
	
	putexcel set "`excelout2'", modify sheet(Figure8, replace)	  
	graph export "`graph`gr''", replace as(png) name(ngraph`gr') wid(1500)		
	putexcel A`u' = image("`graph`gr''")
	
	putexcel A1 = ""
	putexcel A2 = "Figure 8: Poverty rates by sex and age-groups"
	putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
	putexcel A4 = "Note: Figure presents poverty rates in each age-group by sex in `lasty'. Poverty is defined by the `lblline' line. "
	putexcel O10 = "Data:"
	putexcel O6	= "Code:"
	putexcel N11 = "Labels:"
	putexcel N12 = "Variables:"	
	putexcel O7 = `"twoway line value* _group, legend(order("`legend'")) ytitle("Poverty rate (%)") xtitle("") lcolor(${colorpalette}) xlabel(1(1)16, valuelabel angle(90)) `yrange'"'
	if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
	putexcel save							
	cap graph close	
	//Export data
	decode _group, gen(agelabel)
	order year _group agelabel value*
	export excel * using "`excelout2'" , sheet("Figure8", modify) cell(O11) keepcellfmt firstrow(varlabels)
	export excel * using "`excelout2'" , sheet("Figure8", modify) cell(O12) keepcellfmt firstrow(variables) nolabel
	if "`excel'"=="" shell start excel "`dirpath'\\Figure8.xlsx"

end	
