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

//Figure 2. Poverty and GDP per capita scatter
//Note on helpfile: only work for the international poverty lines, to be exact 2.15, 3.65, 6.85, 2017 PPP

cap program drop pea_figure2
program pea_figure2, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) Year(varname numeric) BENCHmark(string) ONELine(varname numeric) ONEWelfare(varname numeric) FGTVARS YRange(string) scheme(string) palette(string) save(string) excel(string) PPPyear(integer 2017)]	
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	//Check value of poverty lines (international ones)
	_pea_povlines_check, ppp(`pppyear') povlines(`oneline')
	local vlinetxt = r(vlinetxt)
	local vlineval = r(vlineval)

	tempfile dataori pea_pov 

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
	local lblline: var label `oneline'		
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
	qui sum `oneline', d
	local povline `r(max)'	// Get one poverty line value
	local povline = round(`povline',0.01)
	//missing observation check
	marksample touse
	local flist `"`wvar' `onewelfare' `oneline' `year'"'
	markout `touse' `flist' 
	
	// Generate poverty rate of PEA country
	if "`fgtvars'"=="" { //only create when the fgt are not defined			
		if "`onewelfare'"~="" { //reset to the floor
			replace `onewelfare' = ${floor_} if `onewelfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
		if "`onewelfare'"~="" & "`oneline'"~="" _pea_gen_fgtvars if `touse', welf(`onewelfare') povlines(`oneline') 
	}

	groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) by(`year')
	keep _fgt0* `year'
	cap gen year = `year'
	gen country_code = "`country'"
	save `pea_pov', replace
	
	// Load GDP and other countries from PIP
	use "`persdir'pea/PIP_all_countrylineup.dta", clear
	keep if year == `lasty'
	local povline_100 = floor(`povline' * 100)
	
	// Recount benchmark countries to get total number of legend entries, as some benchmark countries might not have data
	gen b_in_list = ""
	foreach b of local benchmark {
		replace b_in_list = code if code == "`b'"
	}
	qui levelsof b_in_list, local(benchmark_data)
	local b_data_count = `:word count `benchmark_data''
	
	// Merge regions
	merge m:1 code using "`persdir'pea/PIP_list_name.dta", keep(1 3) keepusing(region country_name)
	levelsof _merge, local(mcode)
	assert _merge != 1			// Check if region codes merge
	drop _merge 
	
	// Merge GDP
	merge m:1 code year using "`persdir'pea/PIP_all_GDP.dta", keep(1 3) keepusing(gdppc)
	levelsof _merge, local(mcode)
	assert _merge != 1			// Check if GDP merges
	drop _merge 
	
	// Merge in PEA poverty rate
	merge 1:1 country_code year using `pea_pov'
	replace headcount`povline_100' = _fgt0_`onewelfare'_`oneline' * 100 if country_code == "`country'"	// Get PEA poverty rate for PEA country
	assert _merge != 2
	// Get region
	gen count = _n
	qui sum count if country_code == "`country'"
	local region_name `=region[r(min)]'

	// Figure colors
	local groupcount = 1
	local groups = `b_data_count' + 3																	//  Total number of entries and colors (benchmark countries, PEA country, region, and others)
	local leg_elem = `groups'
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")						//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
	
	// Figure preparation
	* PEA country
	gen   group = `groupcount' if country_code == "`country'"
	qui sum count if country_code == "`country'"
	local cname `=country_name[r(min)]'
	local legend `"`legend' `leg_elem' "`cname'""'														// PEA country last and so on, so that PEA marker is on top
	local grcolor`groupcount': word `groupcount' of ${colorpalette}										// Palette defined in pea_figure_setup
	gen   mlabel = "{bf:" + country_code + "}" if country_code == "`country'"
	local msym`groupcount' "D"

	* Region
	local groupcount = `groupcount' + 1
	local leg_elem 	 = `leg_elem' - 1
	replace group 	 = `groupcount' if region  == "`region_name'" & group == .	 
	local legend `"`legend' `leg_elem' "Other `region_name'""'		
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
		local scatter_cmd`i' `"scatter headcount`povline_100' ln_gdp_pc if group == `i', mc("`grcolor`i''") msymbol("`msym`i''") ml(mlabel) msize(medlarge) mlabpos(9) || "'
		local scatter_cmd "`scatter_cmd`i'' `scatter_cmd' "						// PEA country comes last and marker is on top
	}
	 
	//Axis range
	if "`yrange'" == "" {
		local ymin = 0
		qui sum headcount`povline_100'
		local max = round(`r(max)',10)
		if `max' < `r(max)' local max = `max' + 10								// round up to nearest 10
		local yrange "ylabel(0(10)`max')"
	}
	else {
		local yrange "ylabel(`yrange')"
	}
	
	// Data Preparation 
	gen ln_gdp_pc = ln(gdppc)
	format headcount`povline_100' %5.0f
	
	// Figure
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure2.xlsx"
		local act replace
		cap rm "`dirpath'\\Figure2.xlsx"		
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
		
	local u  = 5

	putexcel set "`excelout2'", `act'
	tempfile graph
	twoway `scatter_cmd'													///		
		qfit 	headcount`povline_100' ln_gdp_pc, lpattern(-) lcolor(gray) 	///
		 legend(order(`legend')) 											///
		  `yrange'															///
		  ytitle("Poverty rate (percent)") 									///
		  xtitle("LN(GDP per capita, PPP, US$)")							///
		  name(ngraph`gr', replace)		
		
	putexcel set "`excelout2'", modify sheet(Figure2, replace)	  
	graph export "`graph'", replace as(png) name(ngraph) wid(1500)	
	putexcel A`u' = image("`graph'")
	
	putexcel A1 = ""
	putexcel A2 = "Figure 2: Poverty rates and GDP per-capita"
	putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
	putexcel A4 = "Note: The figure shows poverty rates using `lblline' against GDP per-capita (in logs). Data is for year `lasty' and lined-up estimates are used for the non-PEA countries. Benchmark countries are shown separately from the countries in the same region as `country'. Dashed line is a fitted quadratic line."
	
	putexcel O10 = "Data:"
	putexcel O6	= "Code"
	putexcel O7 = `"twoway `scatter_cmd' qfit headcount`povline_100' ln_gdp_pc, lpattern(-) lcolor(gray) legend(order(`legend')) ytitle("Poverty rate (percent)") xtitle("LN(GDP per capita, PPP, US$)") `yrange'"'
	if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")	
	putexcel save							
	cap graph close	

	// Export data
	cap drop _merge
	export excel * using "`excelout2'", sheet("Figure2", modify) cell(O11) keepcellfmt firstrow(variables)	
	
	if "`excel'"=="" shell start excel "`dirpath'\\Figure2.xlsx"	
	
end