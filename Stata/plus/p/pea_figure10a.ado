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

//Figure 10a. Prosperity gap by year and area lines

cap program drop pea_figure10a
program pea_figure10a, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [ONEWelfare(varname numeric) Year(varname numeric) urban(varname numeric) setting(string) comparability(string) NOEQUALSPACING YRange(string) BAR scheme(string) palette(string) save(string) excel(string) PPPyear(integer 2017)]

	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all		
	
	global floor_ 0.25
	global prosgline_ 25

	//house cleaning	
	if "`urban'"=="" {
		noi di in red "Sector/urban variable must be defined in urban()"
		exit 1
	}
	if "`comparability'"=="" {
		noi di in red "Warning: Comparability option not specified for Figure 10a. Non-comparable spells may be shown."	// Not a strict condition
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
	_pea_export_path, excel("`excel'")
	
	//Number of groups (for colors)
	qui levelsof `urban', local(group_num)
	local groups = `:word count `group_num'' + 1

	// Figure colors
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")	//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)

	//variable checks

	//Weights
	local wvar : word 2 of `exp'
	qui if "`wvar'"=="" {
		tempvar w
		gen `w' = 1
		local wvar `w'
	}
	
	if "`onewelfare'"~="" { //reset to the floor
		replace `onewelfare' = ${floor_} if `onewelfare'< ${floor_}
		noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
	}
	
	//missing observation check
	marksample touse
	local flist `"`wvar' `onewelfare' `year'"'
	markout `touse' `flist' 
	
	//more preparations
	clonevar _pg_`onewelfare' = `onewelfare' if `touse'	
	replace _pg_`onewelfare' = ${floor_} if _pg_`onewelfare' < ${floor_} & _pg_`onewelfare' ~= .	// Bottom code PG
	tempfile dataori datacomp data2
	save	`dataori'
	qui sum `urban', d
	local max_val = r(max) + 1
	local varlblurb : value label `urban'
	
	//store comparability
	if "`comparability'"~="" {
		bys  `year': keep if _n == 1
		keep `year' `comparability'
		save `datacomp'
	}	
	
	//PG national
	use `dataori'
	// Generate prosperity gap of PEA country
	if "`onewelfare'"~="" {
		gen double _prosgap_`onewelfare' = ${prosgline_}/_pg_`onewelfare' if `touse'
		groupfunction [aw=`wvar'] if `touse', mean(_prosgap_`onewelfare') by(`year')
	}
	gen `urban' = `max_val' 			
	save `data2', replace
	
	//FGT urban-rural
	foreach var of local urban {
		use `dataori', clear
		if "`onewelfare'"~="" {
			gen double _prosgap_`onewelfare' = ${prosgline_}/_pg_`onewelfare' if `touse'
			groupfunction [aw=`wvar'] if `touse', mean(_prosgap_`onewelfare') by(`year' `var')
		}
		append using `data2'
		save `data2', replace
	}	
	
	// Add comparability variable
	if "`comparability'"~="" {
		merge m:1 `year' using `datacomp', nogen
	}
	
	// Clean and label
	*label values `urban' urban
	if "`onewelfare'"~="" {
		label var _prosgap_`onewelfare' "Prosperity Gap"
	}
	
	//Prepare year variable without gaps
	if "`noequalspacing'"=="" {																	// Year spacing option
		egen year_nogap = group(`year'), label(year_nogap)										// Generate year variable without gaps
		local year year_nogap
	}	
	qui levelsof `year'		 , local(yearval)	
	sort `year'
	
	qui levelsof `urban'		, local(group_num)
	if ("`comparability'"~="") qui levelsof `comparability', local(compval)
	label define `varlblurb' `max_val' "Total", add 									// Add Total as last entry
	label values `urban' `varlblurb'
	
	foreach i of local group_num {
		local j = `i' + 1			
		local scatter_cmd`i' = `"scatter _prosgap_`onewelfare' `year' if `urban'== `i', mcolor("${col`j'}") lcolor("${col`j'}") || "'								// Colors defined in pea_figure_setup
		local scatter_cmd "`scatter_cmd' `scatter_cmd`i''"
		local label_`i': label(`urban') `i'
		local legend`i' `"`j' "`label_`i''""'
		local legend "`legend' `legend`i''"	
		// Connect years (only if comparable if option is specified)
		if "`comparability'"~="" {																											// If comparability specified, only comparable years are connected
			foreach co of local compval {
				local line_cmd`i'`co' = `"line _prosgap_`onewelfare' `year' if `urban'== `i' & `comparability'==`co', mcolor("${col`j'}") lcolor("${col`j'}") || "'
				local line_cmd "`line_cmd' `line_cmd`i'`co''"
			}
			local note_c "Non-connected dots indicate that survey-years are not comparable."
		}
		else if "`comparability'"=="" {
			local line_cmd`i' = `"line _prosgap_`onewelfare' `year' if `urban'== `i', mcolor("${col`j'}") lcolor("${col`j'}") || "' 					
			local line_cmd "`line_cmd' `line_cmd`i''"
		}
		local bcolors "`bcolors' bar(`j', color(${col`j'}))"		
	}		

	//Axis range
	if "`yrange'" == "" {
		local ymin = 0
		qui sum _prosgap_`onewelfare'
		nicelabels `ymin' `r(max)', local(yla)
		local yrange "ylabel(`yla')"
	}
	else {
		local yrange "ylabel(`yrange')"
	}
	
	
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure10a.xlsx"
		local act replace
		cap rm "`dirpath'\\Figure10a.xlsx"
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	

	// Figure	
	local gr = 1
	local u  = 5
	putexcel set "`excelout2'", `act'
	//change all legend to bottom, and maybe 2 rows
	//add comparability
	tempfile graph`gr'
	local lbltitle : variable label _prosgap_`onewelfare'
	if "`bar'" == "" {
		twoway `scatter_cmd' `line_cmd'									///	
			  , legend(order("`legend'") pos(6) row(1)) 			///
			  ytitle("`lbltitle'") 									///
			  xtitle("")											///
			  xlabel(`yearval', valuelabel)							///
			  `yrange'												///
			  name(ngraph`gr', replace)	
	}
	else if "`bar'" ~= "" {
		graph bar _prosgap_`onewelfare', over(`urban') over(`year') `bcolors'		///
				ytitle("`lbltitle'") asyvars			///
				`yrange' name(ngraph`gr', replace)								
	}	
	
	putexcel set "`excelout2'", modify sheet(Figure10a, replace)	  
	graph export "`graph`gr''", replace as(png) name(ngraph`gr') wid(1500)	
	putexcel A`u' = image("`graph`gr''")
	
	putexcel A1 = ""
	putexcel A2 = "Figure 10a: Prosperity gap by area over time"
	putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
	putexcel A4 = "Note: The figure shows the prosperity gap over time. The prosperity gap is defined as the average factor by which incomes need to be multiplied to bring everyone to the prosperity standard of $${prosgline_}. `note_c' See Kraay et al. (2023) for more details on the prosperity gap."
	putexcel O10 = "Data:"
	putexcel O6	= "Code:"
	
	if "`bar'" == "" putexcel O7 = `"twoway `scatter_cmd' `line_cmd', legend(order("`legend'") pos(6) row(1)) ytitle("`lbltitle'") xtitle("") xlabel(`yearval', valuelabel) `yrange'"'
	else if "`bar'" ~= "" putexcel O7 = `"graph bar _prosgap_`onewelfare', over(`urban') over(`year') `bcolors' ytitle("`lbltitle'") asyvars `yrange'"'
	if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
	putexcel save							
	cap graph close	
	//Export data
	export excel `year' `urban' _prosgap_* using "`excelout2'" , sheet("Figure10a", modify) cell(O11) keepcellfmt firstrow(variables) nolabel
	if "`excel'"=="" shell start excel "`dirpath'\\Figure10a.xlsx"

end	