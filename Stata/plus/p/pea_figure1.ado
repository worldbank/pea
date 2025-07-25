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
	syntax [if] [in] [aw pw fw], [NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) FGTVARS Year(varname numeric) urban(varname numeric) LINESORTED setting(string) COMParability(varname numeric) COMBINE NOOUTPUT NOEQUALSPACING YRange(string) BAR excel(string) save(string) MISSING scheme(string) palette(string) PPPyear(integer 2021)]

	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all	
	
	//house cleaning	
	if "`urban'"=="" {
		noi di in red "Sector/urban variable must be defined in urban()"
		exit 1
	}
	
	//Comparability
	if "`comparability'"=="" {
		gen __comp = 1
		local comparability __comp
	}
	qui ta `year'
	local nyear = r(r)
	qui ta `comparability'
	local ncomp = r(r)
	if `ncomp' > `nyear' {
		noi dis as error "Inconsistency between number of years and number of comparable data points."
		error 1
	}
	
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}
	_pea_export_path, excel("`excel'")
	
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
	
	tempfile dataori datacomp data1 data2
	save	`dataori'
	qui sum `urban', d
	local max_val = r(max) + 1
	
	// Create fgt
	use `dataori'
	if "`fgtvars'"=="" { //only create when the fgt are not defined			
		if "`pppwelfare'"~="" { //reset to the floor
			replace `pppwelfare' = ${floor_} if `pppwelfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
		
		//FGT
		if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
		if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
	}	

	//variable checks
	save `data1', replace
	
	//FGT national
	use `data1', clear
	groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) by(`year' `comparability')
	gen `urban' = `max_val' 			
	save `data2', replace
	
	//FGT urban-rural
	foreach var of local urban {
		use `data1', clear
		groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) by(`year' `comparability' `var')
		append using `data2'
		save `data2', replace
	}	
	
	keep `year' `urban' `comparability' _fgt0*
	for var _fgt0*: replace X = X*100
	
	//Axis range
	if "`yrange'" == "" {
		local ymin = 0
		foreach var of varlist _fgt* {											// maximum y value of fgt variables
			qui sum `var'
			nicelabels `ymin' `r(max)', local(yla)
			local yrange`var' "ylabel(`yla')"
		}
	}
	else {
		foreach var of varlist _fgt* {
			local yrange`var' "ylabel(`yrange')"
		}
	}
	
	// Clean and label
	*label values `urban' urban
	if "`ppppovlines'"~="" {
		foreach var of local ppppovlines {
			label var _fgt0_`pppwelfare'_`var' "`lbl`var''"
		}
	}
	
	if "`natpovlines'"~="" {
		foreach var of local natpovlines {
			local natvnum = 1
			*label var _fgt0_`natwelfare'_`var' "`lbl`var''"
			label var _fgt0_`natwelfare'_`var' "National poverty line `natvnum'"
			local natvnum = `natvnum' + 1
		}
	}
	
	// Figure	
	qui levelsof `urban'		, local(group_num)
	qui levelsof `comparability', local(compval)
	local varlblurb : value label `urban'
	label define `varlblurb' `max_val' "Total", add  											// Add Total as last entry
	//Prepare year variable without gaps if specified
	if "`noequalspacing'"=="" {		// Year spacing option
		egen year_nogap = group(`year'), label(year_nogap)										// Generate year variable without gaps
		local year year_nogap
	}
	qui levelsof `year'		 , local(yearval)	

	foreach i of local group_num {
		local j = `i' + 1			
		local scatter_cmd`i' = `"scatter var `year' if `urban'== `i', mcolor("${col`j'}") lcolor("${col`j'}") || "'					// Colors defined in pea_figure_setup
		local scatter_cmd "`scatter_cmd' `scatter_cmd`i''"
		local label_`i': label(`urban') `i'
		local legend`i' `"`j' "`label_`i''""'
		local legend "`legend' `legend`i''"	
		
		// If comparability specified, only comparable years are connected
		foreach co of local compval {
			local line_cmd`i'`co' = `"line var `year' if `urban'== `i' & `comparability'==`co', mcolor("${col`j'}") lcolor("${col`j'}") || "'
			local line_cmd "`line_cmd' `line_cmd`i'`co''"
		}
		local bcolors "`bcolors' bar(`j', color(${col`j'}))"		
	}		

	if "`comparability'"~="__comp" local note_c "Non-connected dots indicate that survey-years are not comparable."	

	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure1.xlsx"
		local act replace	
		cap rm "`dirpath'\\Figure1.xlsx"		
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
	
	local gr = 1
	local u  = 5
	putexcel set "`excelout2'", `act'
	
	//change all legend to bottom, and maybe 2 rows
	if "`combine'" ~= "" local botlbl "rows(1) position(6)"
		
	foreach var of varlist _fgt* {
		rename `var' var
		tempfile graph`gr'
		local lbltitle : variable label var
		
		if "`bar'" == "" {
		twoway `scatter_cmd' `line_cmd'									///	
				  , legend(order("`legend'") `botlbl') 				    ///
				  ytitle("Poverty rate (percent, `lbltitle')") 			///
				  xtitle("")											///
				  xlabel("`yearval'", valuelabel)						///
				  `yrange`var''											///
				  name(ngraph`gr', replace)								
		}
		else if "`bar'" ~= "" {
			graph bar var, over(`urban') over(`year') `bcolors'			///
				ytitle("Poverty rate (percent)") asyvars				///
				`yrange`var''											///
				name(ngraph`gr', replace)								
		}
		
		local graphnames "`graphnames' ngraph`gr'"
		if "`combine'" == "" {
			putexcel set "`excelout2'", modify sheet(Figure1_`gr', replace)	  
			graph export "`graph`gr''", replace as(png) name(ngraph`gr') wid(1200)			
			putexcel A`u' = image("`graph`gr''")
			
			putexcel A2 = "Figure 1: Poverty rates (`lbltitle')"
			putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
			putexcel A4 = "Note: The figure shows the poverty rates against international and national poverty lines. `note_c'"
			
			putexcel O10 = "Data:"
			putexcel O6	= "Code to produce figure:"
			putexcel O7 = "rename `var' var"
			putexcel O8 = `"twoway `scatter_cmd' `line_cmd', legend(order("`legend'") `botlbl') ytitle("Poverty rate (percent, `lbltitle')") xtitle("") xlabel("`yearval'", valuelabel) `yrange`var''"'
						
			if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")	
					
			putexcel save	
			// Export data
			export excel * using "`excelout2'", sheet("Figure1_`gr'", modify) cell(O11) keepcellfmt firstrow(variables)	
		}
		local gr = `gr' + 1
		rename var `var'
	}

	if "`combine'" ~= "" {  // If combine specified, export combined graph
		tempfile graph`gr'
		grc1leg2  `graphnames', ycommon lrows(1) ytol1title rows(2) legscale(*0.8) name(ngraphcomb, replace)		
		*graph combine `graphnames', note(`note') name(ngraphcomb, replace)
		putexcel set "`excelout2'", modify sheet(Figure1, replace)	  
		graph export "`graph`gr''", replace as(png) name(ngraphcomb) wid(1600)
		putexcel A`u' = image("`graph`gr''")
				
		putexcel A1 = ""
		putexcel A2 = "Figure 1: Poverty rates"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The figure shows the poverty rates against international and national poverty lines. `note_c'"
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		if "`bar'" == "" putexcel O7 = `"twoway `scatter_cmd' `line_cmd', legend(order("`legend'") `botlbl') ytitle("Poverty rate (percent)") xtitle("") xlabel("`yearval'", valuelabel) `yrange`var''"'
		else if "`bar'" ~= "" putexcel O7 = `"graph bar var, over(`urban') over(`year') `bcolors' ytitle("Poverty rate (percent)") asyvars `yrange`var''"'
		putexcel O8 = `"grc1leg2  `graphnames', ycommon lrows(1) ytol1title rows(2) legscale(*0.8) name(ngraphcomb, replace)"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")	
		putexcel save
		export excel * using "`excelout2'", sheet("Figure1", modify) cell(O11) keepcellfmt firstrow(variables) nolabel
	}
	
	cap graph close	
	
	if "`excel'"=="" shell start excel "`dirpath'\\Figure1.xlsx"	
end	