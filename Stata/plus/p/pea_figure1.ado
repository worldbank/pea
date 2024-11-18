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

//Figure 1. Poverty rates by year lines
//todo: add comparability, add the combine graph option

cap program drop pea_figure1
program pea_figure1, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) FGTVARS Year(varname numeric) urban(varname numeric)  LINESORTED setting(string) NOOUTPUT excel(string) save(string) MISSING scheme(string) palette(string)]	

	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all		
	
	//house cleaning	
	if "`urban'"=="" {
		noi di in red "Sector/urban variable must be define in urban()"
		exit 1
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
	local flist `"`wvar' `natwelfare' `natpovlines' `pppwelfare' `ppppovlines' `year'"'
	markout `touse' `flist' 
	
	tempfile dataori datalbl

	// Create fgt
	if "`fgtvars'"=="" { //only create when the fgt are not defined			
		//FGT
		if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
		if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
	}	

	//variable checks
	tempfile data1 data2
	save `data1', replace
	
	//FGT national
	use `data1', clear
	groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) by(`year')
	gen `urban' = 2 //change this, to add more flexible, by var and within var groups
	save `data2', replace
	
	//FGT urban-rural
	foreach var of local urban {
		use `data1', clear
		groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) by(`year' `var')
		append using `data2'
		save `data2', replace
	}	
	
	// Clean and label
	keep `year' `urban' _fgt0*
	label values `urban' urban
	if "`ppppovlines'"~="" {
		foreach var of local ppppovlines {
			label var _fgt0_`pppwelfare'_`var' "`lbl`var''"
		}
	}
	
	if "`natpovlines'"~="" {
		foreach var of local natpovlines {
			label var _fgt0_`natwelfare'_`var' "`lbl`var''"

		}
	}
		
	// Figure	
	qui levelsof `urban', local(group_num)
	local cat_count = `:word count `group_num'' - 1								// -1 as indicator starts at 0
	label define urban `cat_count' "Total", add									// Add Total as last entry

	foreach i of local group_num {
		local j = `i' + 1			
		local scatter_cmd`i' = `"scatter var year if `urban'== `i', connect(l) mcolor("${col`j'}") lcolor("${col`j'}") || "'										// Colors defined in pea_figure_setup
		local scatter_cmd "`scatter_cmd' `scatter_cmd`i''"
		local label_`i': label(`urban') `i'
		local legend`i' `"`j' "`label_`i''""'
		local legend "`legend' `legend`i''"	
	}				
	qui levelsof `year', local(yearval)

	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure1.xlsx"
		local act replace
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
	
	local gr = 1
	local u  = 1
	putexcel set "`excelout2'", `act'
	//change all legend to bottom, and maybe 2 rows
	//add comparability
	foreach var of varlist _fgt* {
		rename `var' var
		tempfile graph`gr'
		local lbltitle : variable label var
		twoway `scatter_cmd'											///	
				  , legend(order("`legend'")) 							///
				  ytitle("Poverty rate (percent)") 						///
				  xtitle("")											///
				  title("`lbltitle'")									///
				  xlabel("`yearval'")									///
				  name(ngraph`gr', replace)							

		putexcel set "`excelout2'", modify sheet(Figure1_`gr', replace)	  
		graph export "`graph`gr''", replace as(png) name(ngraph`gr') wid(3000)		
		putexcel A`u' = image("`graph`gr''")
		putexcel save							
		local gr = `gr' + 1
		rename var `var'
	}
	cap graph close	
	if "`excel'"=="" shell start excel "`dirpath'\\Figure1.xlsx"

end	
