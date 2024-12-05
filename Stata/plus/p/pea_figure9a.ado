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

//Figure 9a. Inequality by year lines

cap program drop pea_figure9a
program pea_figure9a, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [ONEWelfare(varname numeric) Year(varname numeric) urban(varname numeric) setting(string) comparability(string) NOOUTPUT NONOTES EQUALSPACING excel(string) save(string) MISSING scheme(string) palette(string)]

	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all		
	
	//house cleaning	
	if "`urban'"=="" {
		noi di in red "Sector/urban variable must be defined in urban()"
		exit 1
	}
	if "`comparability'"=="" {
		noi di in red "Warning: Comparability option not specified for Figure 9a. Non-comparable spells may be shown."	// Not a strict condition
	}
	else if "`comparability'"~="" {
		qui ta `year'
		local nyear = r(r)
		qui ta `comparability'
		local ncomp = r(r)
		if `ncomp' > `nyear' {
			noi dis as error "Inconsistency between number of years and number of comparable data points."
			error 1
		}
	}	
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
	
	//Number of groups (for colors)
	qui levelsof `urban', local(group_num)
	local groups = `:word count `group_num'' + 1

	// Figure colors
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")	//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)

	//variable checks
	//check plines are not overlapped.
	//trigger some sub-tables
	qui {		
		//order the lines
		if "`linesorted'"=="" {
			if "`ppppovlines'"~="" {
				_pea_pline_order, povlines(`ppppovlines')			
				local ppppovlines `=r(sorted_line)'
				foreach var of local ppppovlines {
					local lbl`var' `=r(lbl`var')'
				}
			}
			
			if "`natpovlines'"~="" {
				_pea_pline_order, povlines(`natpovlines')
				local natpovlines `=r(sorted_line)'
				foreach var of local natpovlines {
					local lbl`var' `=r(lbl`var')'
				}
			}
		}
		else {
			foreach var of varlist `natpovlines' `ppppovlines' {
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
	local flist `"`wvar' `onewelfare' `year'"'
	markout `touse' `flist' 
	
	//more preparations
	clonevar _Gini_`onewelfare' = `onewelfare' if `touse'	
	tempfile dataori datacomp data2
	save	`dataori'
	qui sum urban, d
	local max_val = r(max) + 1
	local varlblurb : value label `urban'
	
	//store comparability
	if "`comparability'"~="" {
		bys  `year': keep if _n == 1
		keep `year' `comparability'
		save `datacomp'
	}	
	
	//GINI national
	use `dataori'
	if "`onewelfare'"~="" groupfunction  [aw=`wvar'] if `touse', gini(_Gini_`onewelfare') by(`year')
	gen `urban' = `max_val' 			
	save `data2', replace
	
	//GINI urban-rural
	foreach var of local urban {
		use `dataori', clear
		if "`onewelfare'"~="" groupfunction  [aw=`wvar'] if `touse', gini(_Gini_`onewelfare') by(`year' `var')
		append using `data2'
		save `data2', replace
	}	
	
	// Add comparability variable
	if "`comparability'"~="" {
		merge m:1 `year' using `datacomp', nogen
	}
	
	// Clean and label
	label values `urban' urban
	if "`onewelfare'"~="" {
		label var _Gini_`onewelfare' "GINI index"
		replace   _Gini_`onewelfare' = _Gini_`onewelfare' * 100
	}
	
	//Prepare year variable without gaps if specified
	if "`equalspacing'"~="" {																	// Year spacing option
		egen year_nogap = group(`year'), label(year_nogap)										// Generate year variable without gaps
		local year year_nogap
	}	
	qui levelsof `year'		 , local(yearval)	
	sort `year'
	
	qui levelsof `urban'		, local(group_num)
	if ("`comparability'"~="") qui levelsof `comparability', local(compval)
	label define `varlblurb' `max_val' "Total", add								// Add Total as last entry
	label values `urban' `varlblurb'

	foreach i of local group_num {
		local j = `i' + 1			
		local scatter_cmd`i' = `"scatter _Gini_`onewelfare' `year' if `urban'== `i', mcolor("${col`j'}") lcolor("${col`j'}") || "'								// Colors defined in pea_figure_setup
		local scatter_cmd "`scatter_cmd' `scatter_cmd`i''"
		local label_`i': label(`urban') `i'
		local legend`i' `"`j' "`label_`i''""'
		local legend "`legend' `legend`i''"	
		// Connect years (only if comparable if option is specified)
		if "`comparability'"~="" {																											// If comparability specified, only comparable years are connected
			foreach co of local compval {
				local line_cmd`i'`co' = `"line _Gini_`onewelfare' `year' if `urban'== `i' & `comparability'==`co', mcolor("${col`j'}") lcolor("${col`j'}") || "'
				local line_cmd "`line_cmd' `line_cmd`i'`co''"
			}
			local note_c "Note: Non-connected dots indicate that survey-years are not comparable."
		}
		else if "`comparability'"=="" {
			local line_cmd`i' = `"line _Gini_`onewelfare' `year' if `urban'== `i', mcolor("${col`j'}") lcolor("${col`j'}") || "' 					
			local line_cmd "`line_cmd' `line_cmd`i''"
		}
	}		

	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure9a.xlsx"
		local act replace
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}
	
	//Prepare Notes
	local notes "Source: World Bank calculations using survey data accessed through the GMD."
	local notes `"`notes'" "`note_c'"'
	if "`nonotes'" ~= "" local notes ""
	
	//Figure		
	local gr = 1
	putexcel set "`excelout2'", `act'
	//change all legend to bottom, and maybe 2 rows
	//add comparability
	tempfile graph`gr'
	local lbltitle : variable label _Gini_`onewelfare'
	twoway `scatter_cmd' `line_cmd'									///	
			  , legend(order("`legend'") pos(6) row(1)) 			///
			  ytitle("`lbltitle'") 									///
			  xtitle("")											///
			  xlabel(`yearval', valuelabel)							///
			  name(ngraph`gr', replace)								///
			  note("`notes'", size(small))

	putexcel set "`excelout2'", modify sheet(Figure9a_`gr', replace)	  
	graph export "`graph`gr''", replace as(png) name(ngraph`gr') wid(3000)		
	putexcel A1 = image("`graph`gr''")
	putexcel save							
	cap graph close	
	if "`excel'"=="" shell start excel "`dirpath'\\Figure9a.xlsx"

end	
