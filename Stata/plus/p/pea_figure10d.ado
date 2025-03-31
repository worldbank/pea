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

//Figure 10d. Prosperity gap over time against benchmark countries (line-up)

cap program drop pea_figure10d
program pea_figure10d, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) Year(varname numeric) BENCHmark(string) ONEWelfare(varname numeric) YRange(string) scheme(string) palette(string) save(string) excel(string) PPPyear(integer 2017)]	

	tempfile dataori pea_pg
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
	_pea_export_path, excel("`excel'")
		
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
	
	// Check if PIP lineup already prepared, else download all PIP related files
	local nametodo = 0
	cap confirm file "`persdir'pea/PIP_all_countrylineup.dta"
	if _rc==0 {
		cap use "`persdir'pea/PIP_all_countrylineup.dta", clear	
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
	qui sum `year', d   // Get last year of survey data
	local lasty `r(max)'
	keep if `lasty' == year
	//missing observation check
	marksample touse
	local flist `"`wvar' `onewelfare' `year'"'
	markout `touse' `flist' 
	
	// Generate PG of PEA country
	clonevar _pgtemp_`onewelfare' = `onewelfare' if `touse'	
	*replace _pgtemp_`onewelfare' = ${floor_} if _pgtemp_`onewelfare' < ${floor_} & _pgtemp_`onewelfare' ~= .	// Bottom code PG
	if "`onewelfare'"~="" {
		gen double _prosgap_`onewelfare' = ${prosgline_}/_pgtemp_`onewelfare' if `touse'
		groupfunction [aw=`wvar'] if `touse', mean(_prosgap_`onewelfare') by(`year')
	}
	gen country_code = "`country'"
	save `pea_pg'
		
	// Load other countries from PIP
	use "`persdir'pea/PIP_all_countrylineup.dta", clear
	keep if `lasty' - year < 21 & `lasty' - year >= 0

	// Recount benchmark countries to get total number of legend entries, as some benchmark countries might not have data
	gen b_in_list = ""
	foreach b of local benchmark {
		replace b_in_list = code if code == "`b'"
	}
	qui levelsof b_in_list, local(benchmark_data)
	local b_data_count = `:word count `benchmark_data''
	keep if code == "`country'" | code == b_in_list

	// Merge in PEA PG
	merge 1:1 country_code year using `pea_pg'
	replace pg = _prosgap_`onewelfare'	if country_code == "`country'" & _prosgap_`onewelfare' != .	// Get PEA PG for PEA country
	assert _merge != 2
	drop _merge 
	
	// Merge country names
	merge m:1 code using "`persdir'pea/PIP_list_name.dta", keep(1 3) keepusing(country_name)
	assert _merge != 1															// Check if region codes merge
	drop _merge 
	
	// Figure colors
	local groupcount = 1
	local groups = `b_data_count' + 1			//  Total number of entries and colors (benchmark countries, PEA country, region, and others)
	local leg_elem = `groups'
	di `leg_elem'
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")	//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
	
	// Figure preparation
	* PEA country
	gen count = _n
	gen   group = `groupcount' if country_code == "`country'"
	qui sum count if country_code == "`country'"
	local cname `=country_name[r(min)]'
	local cname_l `=country_name[r(min)]'
	local legend `"`legend' `leg_elem' "`cname'""'								// PEA country last and so on, so that PEA marker is on top
	local grcolor`groupcount': word `groupcount' of ${colorpalette}				// Palette defined in pea_figure_setup
	local lp`groupcount' "l"
	
	* Benchmark countries
	local b_count = 1
	foreach c of local benchmark_data {
		local groupcount = `groupcount' + 1	
		local leg_elem 	 = `leg_elem' - 1
		replace group    = `groupcount' if country_code == "`c'"
		qui sum count if country_code == "`c'"
		local cname `=country_name[r(min)]'
		local legend `"`legend' `leg_elem' "`cname'""'
		local b_count = `b_count' + 1
		local grcolor`groupcount': word `groupcount' of ${colorpalette}
		local lp`groupcount' "-"
	}
	
	// Line command
	qui levelsof group, local(group_num)
	foreach i of local group_num {
		local line_cmd`i' `"line pg year if group == `i', lc("`grcolor`i''") lw(medthick) lp(`lp`i'') || "'
		local line_cmd "`line_cmd`i'' `line_cmd' "						// PEA country comes last and marker is on top
	}	 

	//Axis range
	if "`yrange'" == "" {
		local ymin = 0
		qui sum pg
		nicelabels `ymin' `r(max)', local(yla)
		local yrange "ylabel(`yla')"
	}
	else {
		local yrange "ylabel(`yrange')"
	}
	// Figure
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure10d.xlsx"
		local act replace
		cap rm "`dirpath'\\Figure10d.xlsx"
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
	local u = 5
	
	putexcel set "`excelout2'", `act'
	tempfile graph
	twoway `line_cmd'														///		
		, legend(order(`legend')) 											///
		  ytitle("Prosperity Gap")		 									///
		  xtitle("") xlabel(`=`lasty'-20'(4)`lasty')		 				///
		  `yrange'															///
		  name(ngraph`gr', replace)
		
	putexcel set "`excelout2'", modify sheet(Figure10d, replace)	  
	graph export "`graph'", replace as(png) name(ngraph) wid(1500)		
	putexcel A`u' = image("`graph'")
	
	putexcel A1 = ""
	putexcel A2 = "Figure 10d: Prosperity gap over time in benchmark countries (line-up)"
	putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD and line-up estimates from PIP."
	putexcel A4 = "Note: The prosperity gap for `cname_l' for `lasty' comes from the survey, while the rest of the data points are from line-up year estimates. The prosperity gap is defined as the average factor by which incomes need to be multiplied to bring everyone to the prosperity standard of $${prosgline_}. See Kraay et al. (2023) for more details on the prosperity gap."
	
	putexcel O10 = "Data:"
	putexcel O6	= "Code:"
	putexcel O7 = `"twoway `line_cmd', legend(order(`legend')) ytitle("Prosperity Gap") xtitle("") xlabel(`=`lasty'-20'(4)`lasty') `yrange'"'
	if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
	putexcel save							
	cap graph close	
	//Export data
	export excel country_code year pg using "`excelout2'" , sheet("Figure10d", modify) cell(O11) keepcellfmt firstrow(variables) nolabel
	if "`excel'"=="" shell start excel "`dirpath'\\Figure10d.xlsx"	
	
end
