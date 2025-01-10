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

//Figure 10b. Prosperity gap scatter (line-up)

cap program drop pea_figure10b
program pea_figure10b, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) Year(varname numeric) BENCHmark(string) ONEWelfare(varname numeric) NONOTES YRange0 scheme(string) palette(string) save(string) excel(string)]	

	tempfile dataori pea_pg
	global floor_ 0.25
	global prosgline_ 25

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
		
	//Weights
	local wvar : word 2 of `exp'	// `exp' is weight in Stata ado syntax
	qui if "`wvar'"=="" {
		tempvar w
		gen `w' = 1
		local wvar `w'
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
	qui sum `year', d   // Get last year of survey data (year of scatter plot)
	local lasty `r(max)'
	keep if `year' == `lasty'
	//missing observation check
	marksample touse
	local flist `"`wvar' `onewelfare' `year'"'
	markout `touse' `flist' 
	
	// Generate PG of PEA country
	clonevar _pgtemp_`onewelfare' = `onewelfare' if `touse'	
	replace _pgtemp_`onewelfare' = ${floor_} if _pgtemp_`onewelfare' < ${floor_} & _pgtemp_`onewelfare' ~= .	// Bottom code PG
	if "`onewelfare'"~="" {
		gen double _prosgap_`onewelfare' = ${prosgline_}/_pgtemp_`onewelfare' if `touse'
		groupfunction [aw=`wvar'] if `touse', mean(_prosgap_`onewelfare') by(`year')
	}
	gen country_code = "`country'"
	save `pea_pg'
		
	// Load GDP and other countries from PIP
	use "`persdir'pea/PIP_all_countrylineup.dta", clear
	keep if year == `lasty'
	
	// Recount benchmark countries to get total number of legend entries, as some benchmark countries might not have data
	gen b_in_list = ""
	foreach b of local benchmark {
		replace b_in_list = code if code == "`b'"
	}
	qui levelsof b_in_list, local(benchmark_data)
	local b_data_count = `:word count `benchmark_data''
	
	// Merge regions
	merge 1:1 code using "`persdir'pea/PIP_list_name.dta", keep(1 3) keepusing(region country_name)
	qui levelsof _merge, local(mcode)
	assert _merge != 1															// Check if region codes merge
	drop _merge 
	
	// Merge GDP
	merge m:1 code year using "`persdir'pea/PIP_all_GDP.dta", keep(1 3) keepusing(gdppc)
	qui levelsof _merge, local(mcode)
	assert _merge != 1															// Check if GDP merges
	drop _merge 
	
	// Merge in PEA PG
	merge 1:1 country_code year using `pea_pg'
	replace pg = _prosgap_`onewelfare'			if country_code == "`country'"	// Get PEA PG for PEA country
	assert _merge != 2
	
	// Get region
	gen count = _n
	qui sum count if country_code == "`country'"
	local region_name `=region[r(min)]'
	
	// Figure colors
	local groupcount = 1
	local groups = `b_data_count' + 3			//  Total number of entries and colors (benchmark countries, PEA country, region, and others)
	local leg_elem = `groups'
	di `leg_elem'
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")	//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
	
	// Figure preparation
	* PEA country
	gen   group = `groupcount' if country_code == "`country'"
	qui sum count if country_code == "`country'"
	local cname `=country_name[r(min)]'
	local legend `"`legend' `leg_elem' "`cname'""'								// PEA country last and so on, so that PEA marker is on top
	local grcolor`groupcount': word `groupcount' of ${colorpalette}				// Palette defined in pea_figure_setup
	gen   mlabel = "{bf:" + country_code + "}" if country_code == "`country'"
	local msym`groupcount' "D"
	
	* Region
	local groupcount = `groupcount' + 1
	local leg_elem 	 = `leg_elem' - 1
	replace group 	 = `groupcount' if region  == "`region_name'" & group == .	 
	local legend `"`legend' `leg_elem' "`region_name'""'		
	local grcolor`groupcount': word `groupcount' of ${colorpalette}
	local msym`groupcount' "o"
	
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
		local msym`groupcount' "t"
	}

	* Rest
	local groupcount = `groupcount' + 1
	local leg_elem 	 = `leg_elem' - 1
	replace group 	 = `groupcount' if group == .										
	local legend `"`legend' `leg_elem' "Other countries" "'	
	local lastcol: word count ${colorpalette}
	local grcolor`groupcount': word `lastcol' of ${colorpalette}								// Last color (grey in default)
	local msym`groupcount' "s" 
	
	// Scatter command
	qui levelsof group, local(group_num)
	foreach i of local group_num {
		local scatter_cmd`i' `"scatter pg ln_gdp_pc if group == `i', mc("`grcolor`i''") msymbol("`msym`i''") ml(mlabel) msize(medlarge) mlabpos(9) || "'
		local scatter_cmd "`scatter_cmd`i'' `scatter_cmd' "						// PEA country comes last and marker is on top
	}	 

	// Data Preparation 
	gen 	ln_gdp_pc = ln(gdppc)
	format  pg %5.0f
	
	//Prepare Notes
	local notes "Source: World Bank calculations using survey data accessed through the GMD."
	local notes `"`notes'" "Note: Data is for year `lasty' and lined-up estimates are used for the non-PEA countries." "The prosperity gap is defined as the average factor by which incomes need to be multiplied" "to bring everyone to the prosperity standard of $25."'
	if "`nonotes'" ~= "" local notes ""
	
	// Figure
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure10b.xlsx"
		local act replace
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
		
	putexcel set "`excelout2'", `act'
	tempfile graph
	twoway `scatter_cmd'													///		
		qfit 	pg ln_gdp_pc, lpattern(-) lcolor(gray) 	///
		, legend(order(`legend')) 											///
		  ytitle("Prosperity Gap")		 									///
		  xtitle("LN(GDP per capita, PPP, US$)")							///
		  name(ngraph`gr', replace)											///
		  note("`notes'", size(small))
		
	putexcel set "`excelout2'", modify sheet(Figure10b, replace)	  
	graph export "`graph'", replace as(png) name(ngraph) wid(3000)		
	putexcel A1 = image("`graph'")
	putexcel save							
	cap graph close	
	if "`excel'"=="" shell start excel "`dirpath'\\Figure10b.xlsx"	
	
end