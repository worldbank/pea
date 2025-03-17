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

//Figure 9c. Gini ranking by benchmark countries

cap program drop pea_figure9c
program pea_figure9c, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) Year(varname numeric) BENCHmark(string) ONEWelfare(varname numeric) within(integer 3) YRange(string) scheme(string) palette(string) save(string) excel(string) welfaretype(string) PPPyear(integer 2017)]	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	tempfile dataori pea_gini

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
	_pea_export_path, excel("`excel'")
	
	if "`within'"=="" local within 3
	if `within'>10 {
		noi dis as error "Surveys older than 10 years should not be used for comparisons. Please use a different value in within()"
		error 1
	}
	
	if "`welfaretype'"=="" {
		noi di in red "Please define welfare type as INC or CONS in welfaretype()"
		exit 1
	}
	else {
		local welfaretype "`=upper("`welfaretype'")'"
		if "`welfaretype'" ~= "INC" & "`welfaretype'" ~= "CONS" {	// Check that values are correct
			noi di in red "Please define welfare type as INC or CONS in welfaretype()"
			exit 1
		}
	}
			
	//Weights
	local wvar : word 2 of `exp'	// `exp' is weight in Stata ado syntax
	qui if "`wvar'"=="" {
		tempvar w
		gen `w' = 1
		local wvar `w'
	}
	
	if "`onewelfare'"~="" { //reset to the floor
		replace `onewelfare' = ${floor_} if `onewelfare'< ${floor_}
		noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
	}
	save `dataori', replace
	
	// Check if PIP already prepared, else download all PIP related files
	local nametodo = 0
	cap confirm file "`persdir'pea/PIP_all_country.dta"
	if _rc==0 {
		cap use "`persdir'pea/PIP_all_country.dta", clear	
		if _rc~=0 local nametodo = 1	
	}
	else local nametodo = 1
	if `nametodo'==1 {
		cap pea_dataupdate, datatype(PIP) update
		if _rc~=0 {
			noi dis "Unable to run pea_dataupdate, datatype(PIP) update"
			exit `=_rc'
		}
	}
	
	//Check if country list and region_code already prepared, else download 
	local nametodo = 0
	cap confirm file "`persdir'pea/PIP_list_name.dta"
	if _rc==0 {
		cap use "`persdir'pea/PIP_list_name.dta", clear	
		if _rc~=0 local nametodo = 1	
	}
	else local nametodo = 1
	if `nametodo'==1 {
		cap pea_dataupdate, datatype(LIST) update
		if _rc~=0 {
			noi dis "Unable to run pea_dataupdate, datatype(LIST) update"
			exit `=_rc'
		}
	}
	
	// Preparation
	use `dataori', clear
	qui sum `year', d   // Get last year of survey data (year of plot)
	local lasty `r(max)'
	keep if `year' == `lasty'
	//missing observation check
	marksample touse
	local flist `"`wvar' `onewelfare' `year'"'
	markout `touse' `flist' 
	
	// Generate Gini of PEA country
	clonevar _Gini_`onewelfare' = `onewelfare' if `touse'
	if "`onewelfare'"~="" groupfunction  [aw=`wvar'] if `touse', gini(_Gini_`onewelfare') by(`year')
	gen country_code = "`country'"
	cap gen year = `year'
	save `pea_gini', replace
		
	// Load other countries from PIP
	use "`persdir'pea/PIP_all_country.dta", clear
	gen y_d = abs(`lasty' - year)												// year closest to PEA year
	bys country_code (year): egen min_d = min(y_d)
	keep if (y_d == min_d) & y_d < `within' & gini ~= .
	bys country_code (year): keep if _n == _N 									// use latest year if there are two with equal distance
	keep country_code year gini code welfaretype
	// Insert PEA country manually, because survey could be newer than data in PIP
	drop if country_code == "`country'"
	insobs 1
	replace country_code = "`country'"		if country_code == ""
	replace year  		 = `lasty' 			if country_code == "`country'"
	replace code 		 = "`country'"		if country_code == "`country'"
	replace welfaretype  = "`welfaretype'"	if country_code == "`country'"
	
	// Merge in PEA GINI
	merge 1:1 country_code year using `pea_gini'
	replace gini = _Gini_`onewelfare'   if country_code == "`country'"			// Get PEA Gini for PEA country
	replace gini = gini * 100
	replace welfaretype = "`welfaretype'" if country_code == "`country'"
	assert _merge != 2
	
	// Figure colors
	local groups = 2				
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")	//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
	
	// Keep PEA and benchmark countries
	gen keep = 1 if country_code == "`country'"
	foreach b of local benchmark {
		replace keep = 1 if country_code == "`b'"
	}
	keep if keep == 1
	drop keep
	
	//Axis range
	if "`yrange'" == "" {
		local ymin = 0
		qui sum gini
		local max = round(`r(max)',10)
		if `max' < `r(max)' local max = `max' + 10								// round up to nearest 10
		local yrange "ylabel(0(10)`max')"
	}
	else {
		local yrange "ylabel(`yrange')"
	}
	
	// Bar look options
	sort country_code
	gen rank = _n
	qui levelsof rank, local(rank_num)
	qui sum rank if country_code == "`country'"
	local rank_pea `r(min)'

	* First for other welfare type (not filled)
	foreach i of local rank_num {
		local is_pea: list rank_pea == i
	 	if 		(`is_pea' ~= 1 & "`=welfaretype[`i']'"=="`welfaretype'") local bar`i' "bar(`i', color(${col1}))"
	 	else if (`is_pea' ~= 1 & "`=welfaretype[`i']'"~="`welfaretype'") local bar`i' "bar(`i', lcolor(${col1}) lp(dash))"
		else if (`is_pea' == 1) local bar`i' "bar(`i', color(${col2}))"
		local bars "`bars' `bar`i''"			
	} 
	drop rank
	
	// Figure note depending on welfare type
	if "`welfaretype'" == "CONS" {
		local w_note   = "consumption" 
		local w_note_o = "income" 
	}
	if "`welfaretype'" == "INC" {
		local w_note   = "income" 
		local w_note_o = "consumption" 
	}
	// Data Preparation 
	format  gini %5.1f
	
	// Figure
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure9c.xlsx"
		local act replace
		cap rm "`dirpath'\\Figure9c.xlsx"
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
	local u = 5
	
	putexcel set "`excelout2'", `act'
	tempfile graph
	graph bar gini, over(country_code, sort(gini)) `bars'		///
				ytitle("Gini index") asyvars showyvars			///
				legend(off) name(ngraph`gr', replace)	

	putexcel set "`excelout2'", modify sheet(Figure9c, replace)	  
	graph export "`graph'", replace as(png) name(ngraph) wid(1500)		
	putexcel A`u' = image("`graph'")
	
	putexcel A1 = ""
	putexcel A2 = "Figure 9c: Gini index across benchmark countries"
	putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD and PIP."
	putexcel A4 = "Note: The figure shows the Gini index across benchmark countries. Data is from the closest available survey within `within' years to `lasty'. Solid bars indicate a `w_note'-based welfare aggregate and dashed bars a `w_note_o'-based welfare aggregate."
	
	putexcel O10 = "Data:"
	putexcel O6	= "Code"
	putexcel O7 = `"graph bar gini, over(code, sort(gini)) `bars' ytitle("Gini index") asyvars showyvars legend(off)"'
	if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
	putexcel save							
	cap graph close	
	//Export data
	export excel country_code year using "`excelout2'" , sheet("Figure9c", modify) cell(O11) keepcellfmt firstrow(variables)
	if "`excel'"=="" shell start excel "`dirpath'\\Figure9c.xlsx"	
end