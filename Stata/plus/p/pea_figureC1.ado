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

//Table C.1. Trends and nowcast of the national poverty rate


cap program drop pea_figureC1
program pea_figureC1, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) NATWelfare(varname numeric) NATPovlines(varlist numeric) Year(varname numeric) year_fcast(varname numeric) natpov_fcast(varname numeric) gdp_fcast(varname numeric) comparability_peb(varname string) NOEQUALSPACING CORE LINESORTED FGTVARS YRange(string) YRange2(string) scheme(string) palette(string) using(string) excel(string) save(string)]	
	
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all	
	
	//Comparability
	if "`comparability_peb'"~="" {
		count if !inlist(`comparability_peb', "Yes", "No") & !missing(`comparability_peb')
		if r(N) > 0 {
			display "Warning: Variable in comparability_peb() contains values other than Yes/No"
			tab `comparability_peb'
			exit 1
		}
	}
	else if "`comparability_peb'"=="" {
		cap gen comparability_peb = "Yes"
		local comparability_peb comparability_peb
	}

	if "`year_fcast'"~="" {
		qui sum `year_fcast'
		if _rc==0 {
			noi di in red "Option year_fcast() specified, but variable does not contain values."
			exit `=_rc'
		}
	}
	
	if "`natpov_fcast'"~="" {
		qui sum `natpov_fcast'
		if _rc==0 {
			noi di in red "Option natpov_fcast() specified, but variable does not contain values."
			exit `=_rc'
		}
	}
	
	if "`gdp_fcast'"~="" {
		qui sum `gdp_fcast'
		if _rc==0 {
			noi di in red "Option gdp_fcast() specified, but variable does not contain values."
			exit `=_rc'
		}
	}
	
	
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data, check using() option"
			exit `=_rc'
		}
	}
	_pea_export_path, excel("`excel'")
	
	//Number of groups (for colors)
	qui levelsof `natpovlines', local(group_num)
	local groups = `:word count `group_num'' + 1
	
	// Figure colors
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")	//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
	
	//variable checks
	//check plines are not overlapped.
	//trigger some sub-tables
	qui {		
		//order the lines
		if "`linesorted'"=="" {
			if "`natpovlines'"~="" {
				_pea_pline_order, povlines(`natpovlines')
				local natpovlines `=r(sorted_line)'
				foreach var of local natpovlines {
					local lbl`var' `=r(lbl`var')'
				}
			}
		}
		else {
			foreach var of varlist `natpovlines' {
				local lbl`var' : variable label `var'
			}
		}
	}

	//Weights
	local wvar : word 2 of `exp'
	qui if "`wvar'"=="" {
		tempvar w
		gen `w' = 1
		local wvar `w'
	}
	
	//missing observation check
	marksample touse
	local flist `"`wvar' `natwelfare' `natpovlines' `year'"'
	markout `touse' `flist' 
	
	tempfile dataori datacomp data1 data2 datafc
	save	`dataori'
	
	// Create fgt
	use `dataori'
	if "`fgtvars'"=="" { //only create when the fgt are not defined			
		//FGT
		if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
	}	
	//variable checks
	save `data1', replace
	
	//FGT national
	use `data1', clear
	groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) by(`year' `comparability_peb')
	drop _fgt1* _fgt2*
	local natline = word("`natpovlines'", wordcount("`natpovlines'"))				// use only last national poverty line
	replace _fgt0_`natwelfare'_`natline' = _fgt0_`natwelfare'_`natline' * 100
	save `data2', replace

	//Now and forecasts
	if "`year_fcast'"~="" {
		use `data1', clear
		keep if `year_fcast' ~= .	
		keep `year_fcast' `natpov_fcast' `gdp_fcast'
		save `datafc', replace
	}
	//Get PEB historical national poverty rates
	use `data2', clear
	cap gen code = "`country'"
	cap gen year = `year'
	merge 1:1 code year using "`persdir'pea/PEB_natpovrates.dta"
	drop if _merge == 2 & code ~= "`country'"
	replace _fgt0_`natwelfare'_`natline' = natpovrate if _fgt0_`natwelfare'_`natline' == .
	drop _merge natpovrate
	
	//Get GDP LCU
	merge 1:1 code year using "`persdir'pea/WDI_gdppc_lcuconst.dta", keep(1 3) nogen

	//Add forecasts
	if "`year_fcast'" ~= "" {
		append using `datafc'
		replace `year' = `year_fcast' if `year_fcast' ~= .
	}
	
	// Figure	
	//Labels
	label var gdp_pc_lcu_const "GDP per capita (constant LCU)"
	label var _fgt0_`natwelfare'_`natline' "Poverty rate (%)"

	//Axis range
		//Axis range
	if "`yrange'" == "" {
		local m = 1
		foreach var of varlist _fgt0_`natwelfare'_`natline' `natpov_fcast' {
			sum `var'													// min/max can come from different variables
			if (`m' == 1) local max = `r(max)'
			if (`r(max)' > `max') local max = `r(max)'
			local m = `m' + 1
		}
		local ymin = 0
		if `max' > 0 local ymax = ceil(`max')
		else local ymax = 0
		nicelabels `ymin' `ymax', local(yla1)
		local yrange1 "ylabel(`yla1', axis(1))"
	}
	else {
			local yrange1 "ylabel(`yrange', axis(1))"
	}
	
	* Second axis
	if "`yrange2'" == "" {
		local m = 1
		foreach var of varlist gdp_pc_lcu_const `gdp_fcast' {
			sum `var'													// min/max can come from different variables
			if (`m' == 1) local max = `r(max)'
			if (`r(max)' > `max') local max = `r(max)'
			local m = `m' + 1
		}
		local ymin = 0
		if `max' > 0 local ymax = ceil(`max')
		else local ymax = 0
		nicelabels `ymin' `ymax', local(yla2)
		local yrange2 "ylabel(`yla2', axis(2))"
	}
	else {
			local yrange2 "ylabel(`yrange2', axis(2))"
	}

	//Comparability
	gen spell_start = (`comparability_peb' == "Yes") & (`comparability_peb'[_n-1] != "Yes")
	gen spell_order = sum(spell_start) if `comparability_peb' == "Yes"
	qui levelsof spell_order, local(compval)
	drop spell_start
	
	if "`comparability_peb'"~="" local note_c "Non-connected dots indicate that survey-years are not comparable."	
	//Prepare year variable without gaps if specified
	if "`noequalspacing'"=="" {		// Year spacing option
		egen year_nogap = group(`year'), label(year_nogap)										// Generate year variable without gaps
		local year year_nogap
	}
	qui levelsof `year'		 , local(yearval)	
	
	// Scatter for poverty rates
	local scatter_cmd_pov = `"(scatter _fgt0_`natwelfare'_`natline' `year', mcolor("${col1}") lcolor("${col1}")) "'					// Colors defined in pea_figure_setup
	// Scatter for GDP
	local scatter_cmd_gdp = `"(scatter gdp_pc_lcu_const `year', mcolor("${col2}") lcolor("${col2}") yaxis(2)) "'					// Colors defined in pea_figure_setup
	// Scatter for poverty and GDP forecasts
	if "`year_fcast'" ~= "" {
		local scatter_cmd_povfc = `"(scatter `natpov_fcast' `year', mcolor("${col1}") lcolor("${col1}")) "'					// Colors defined in pea_figure_setup
		local scatter_cmd_gdpfc = `"(scatter `gdp_fcast' `year', mcolor("${col2}") lcolor("${col2}") yaxis(2)) "'					// Colors defined in pea_figure_setup	
	}
	// If comparability specified, only comparable years are connected
	foreach co of local compval {
		// Poverty
			local line_cmd_pov`co' = `"(line _fgt0_`natwelfare'_`natline' `year' if spell_order==`co', mcolor("${col1}") lcolor("${col1}"))"'
			local line_cmd_pov "`line_cmd_pov' `line_cmd_pov`co''"
	}	
		// ALl can be connected for GDP
			local line_cmd_gdp = `"(line gdp_pc_lcu_const `year', mcolor("${col2}") lcolor("${col2}") yaxis(2)) "'
		// Line for poverty and GDP forecasts (always connected)
	if "`year_fcast'" ~= "" {
		local line_cmd_povfc = `"(line `natpov_fcast' `year', mcolor("${col1}") lcolor("${col1}") lp(-)) "'					// Colors defined in pea_figure_setup
		local line_cmd_gdpfc = `"(line `gdp_fcast' `year', mcolor("${col2}") lcolor("${col2}")  lp(-) yaxis(2)) "'					// Colors defined in pea_figure_setup	
	}
	
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\FigureC1.xlsx"
		local act replace	
		cap rm "`dirpath'\\FigureC1.xlsx"		
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
		
	if "`year_fcast'" ~= "" local legend `"2 "National poverty rate" 6 "GDP per capita""'
	else					local legend `"2 "National poverty rate" 4 "GDP per capita""'
	local u  = 5

	putexcel set "`excelout2'", `act'
	tempfile graph
	
	twoway  `scatter_cmd_pov' `scatter_cmd_gdp' `line_cmd_pov' `line_cmd_gdp'		///
		`scatter_cmd_povfc' `scatter_cmd_gdpfc' `line_cmd_povfc' `line_cmd_gdpfc'	///
		, legend(order("`legend'") rows(1) position(6)) 							///
		ytitle("Poverty rate (percent, `lbltitle')") 								///
		`yrange1' `yrange2'															///
		xtitle("")																	///
		xlabel("`yearval'", valuelabel)												///
		name(ngraph, replace)		
		
	putexcel set "`excelout2'", modify sheet(FigureC.1, replace)	  
	graph export "`graph'", replace as(png) name(ngraph) wid(1500)	
	putexcel A`u' = image("`graph'")
	
	putexcel A1 = ""
	putexcel A2 = "Figure C.1: Trends and nowcasts of poverty rates and GDP per-capita"
	putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD, the World Development Indicators and Poverty and Equity Briefs."
	putexcel A4 = "Note: The figure shows national poverty rates against GDP per-capita (constant LCU). Dashed lines denote now- and forecasts. `note_c'"
	
	putexcel O10 = "Data:"
	putexcel O6	= "Code:"
	putexcel O7 = `"twoway `scatter_cmd_pov' `scatter_cmd_gdp' `line_cmd_pov' `line_cmd_gdp' `scatter_cmd_povfc' `scatter_cmd_gdpfc' `line_cmd_povfc' `line_cmd_gdpfc', legend(order("`legend'") "rows(1) position(6)") ytitle("Poverty rate (percent, `lbltitle')") xtitle("") `yrange1' `yrange2'	 xlabel("`yearval'", valuelabel)"'
	if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")	
	putexcel save							
	cap graph close	

	// Export data
	cap drop _merge
	export excel * using "`excelout2'", sheet("FigureC.1", modify) cell(O11) keepcellfmt firstrow(variables) nolabel
	
	if "`excel'"=="" shell start excel "`dirpath'\\FigureC1.xlsx"	
end	