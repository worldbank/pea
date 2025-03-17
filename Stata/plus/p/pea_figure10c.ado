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

//Figure 10c. PG (survey) and GDP per capita scatter

cap program drop pea_figure10c
program pea_figure10c, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) Year(varname numeric) BENCHmark(string) ONEWelfare(varname numeric) YRange(string) scheme(string) palette(string) save(string) excel(string) within(integer 3) PPPyear(integer 2017)]	

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
	
	if "`within'"=="" local within 3
	if `within'>10 {
		noi dis as error "Surveys older than 10 years should not be used for comparisons. Please use a different value in within()"
		error 1
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
	qui sum `year', d   // Get last year of survey data (year of scatter plot)
	local lasty `r(max)'
	keep if `year' == `lasty'
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
				
	// Load GDP and other countries from PIP
	use "`persdir'pea/PIP_all_country.dta", clear
	gen y_d = abs(`lasty' - year)												// year closest to PEA year
	bys country_code (year): egen min_d = min(y_d)
	keep if (y_d == min_d) & y_d < `within' & pg ~= .
	bys country_code (year): keep if _n == _N 									// use latest year if there are two with equal distance
	keep country_code year pg code welfaretype
	// Insert PEA country manually, because survey could be newer than data in PIP
	drop if country_code == "`country'"
	insobs 1
	replace country_code = "`country'"		if country_code == ""
	replace year  		 = `lasty' 			if country_code == "`country'"
	replace code 		 = "`country'"		if country_code == "`country'"
	replace welfaretype  = "`welfaretype'"	if country_code == "`country'"
	
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
	replace pg = _prosgap_`onewelfare'		if country_code == "`country'"		// Get PEA PG for PEA country
	assert _merge != 2
	
	// Get region
	gen count = _n
	qui sum count if country_code == "`country'"
	local region_name `=region[r(min)]'
	
	// Figure colors
	local groupcount = 1
	local groups = `b_data_count' + 3		//  Total number of entries and colors (benchmark countries, PEA country, region, and others)
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
	local grcolor`groupcount': word `lastcol' of ${colorpalette}				// Last color (grey in default)
	local msym`groupcount' "s" 
	
	//Axis range
	if "`yrange'" == "" {
		local ymin = 0
		qui sum pg
		local max = round(`r(max)',5)
		if `max' < `r(max)' local max = `max' + 5								// round up to nearest 5
		local yrange "ylabel(0(5)`max')"
	}
	else {
		local yrange "ylabel(`yrange')"
	}
		
	// Scatter command
	qui levelsof group, local(group_num)
	foreach i of local group_num {
		local scatter_cmd`i' `"scatter pg ln_gdp_pc if group == `i', mc("`grcolor`i''") msymbol("`msym`i''") ml(mlabel) msize(medlarge) mlabpos(9) || "'
		local scatter_cmd "`scatter_cmd`i'' `scatter_cmd' "						// PEA country comes last and marker is on top
	}	 

	// Data Preparation 
	gen 	ln_gdp_pc = ln(gdppc)
	format  pg %5.0f
	
	// Figure
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure10c.xlsx"
		local act replace
		cap rm "`dirpath'\\Figure10c.xlsx"
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
	local u = 5
	putexcel set "`excelout2'", `act'
	tempfile graph
	twoway `scatter_cmd'													///		
		qfit 	pg ln_gdp_pc, lpattern(-) lcolor(gray) 						///
		, legend(order(`legend')) 											///
		  ytitle("Prosperity Gap")		 									///
		  xtitle("LN(GDP per capita, PPP, US$)")							///
		  `yrange'															///
		  name(ngraph`gr', replace)	

	putexcel set "`excelout2'", modify sheet(Figure10c, replace)	  
	graph export "`graph'", replace as(png) name(ngraph) wid(1500)		
	putexcel A`u' = image("`graph'")
	
	putexcel A1 = ""
	putexcel A2 = "Figure 10c: Prosperity gap and GDP per-capita (observed data)"
	putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD and PIP."
	putexcel A4 = "Note: Data is from the closest available survey within `within' years to `lasty'. The prosperity gap is defined as the average factor by which incomes need to be multiplied to bring everyone to the prosperity standard of $${prosgline_}. Benchmark countries are shown separately from the countries in the same region as `country'. See Kraay et al. (2023) for more details on the prosperity gap."
	
	putexcel O10 = "Data:"
	putexcel O6	= "Code:"
	putexcel O7 = `"twoway `scatter_cmd' qfit pg ln_gdp_pc, lpattern(-) lcolor(gray) legend(order(`legend')) ytitle("Prosperity Gap") xtitle("LN(GDP per capita, PPP, US$)") `yrange'"'
	if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
	putexcel save							
	cap graph close	
	//Export data
	export excel country_code year pg ln_gdp_pc group using "`excelout2'" , sheet("Figure10c", modify) cell(O11) keepcellfmt firstrow(variables)
	if "`excel'"=="" shell start excel "`dirpath'\\Figure10c.xlsx"	
end