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

//Figure 9d. Welfare percentiles over time

cap program drop pea_figure9d
program pea_figure9d, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Year(varname numeric) ONEWelfare(varname numeric) YRange(string) comparability(varname numeric) NOEQUALSPACING BAR scheme(string) palette(string) save(string) excel(string) PPPyear(integer 2021)]	
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
	
	//Comparability
	if "`comparability'"=="" {
		gen __comp = 1
		local comparability __comp
	}
	
	if "`onewelfare'"~="" { //reset to the floor
		replace `onewelfare' = ${floor_} if `onewelfare'< ${floor_}
		noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		local lbltitle : variable label `onewelfare' 
	}
		
	//missing observation check
	marksample touse
	local flist `"`wvar' `onewelfare' `year'"'
	markout `touse' `flist' 
	
	tempfile dataori datacomp
	save `dataori', replace	
		
	//Number of groups (for colors)
	local groups = 5

	// Figure colors
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")	//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
		
	//store comparability
	if "`comparability'"~="" {
		bys  `year': keep if _n == 1
		keep `year' `comparability'
		save `datacomp'
	}	
	
	use `dataori', clear
	* Loop through each year
	collapse (p10) p10_`onewelfare' = `onewelfare' (p25) p25_`onewelfare' = `onewelfare' ///
				 (p50) p50_`onewelfare' = `onewelfare' (p75) p75_`onewelfare' = `onewelfare' ///
				 (p90) p90_`onewelfare' = `onewelfare' [w=`wvar'], by(`year')

	//Axis range
	if "`yrange'" == "" {
		local m = 1
		foreach var of varlist p* {
			sum `var'													// min/max can come from different variables
			if (`m' == 1) local max = `r(max)'
			if (`m' == 1) local min = `r(min)'
			if (`r(max)' > `max') local max = `r(max)'
			if (`r(min)' < `min') local min = `r(min)'
			local m = `m' + 1
		}
		if `min' < 0 local ymin = floor(`min')
		else local ymin = 0
		if `max' > 0 local ymax = ceil(`max')
		else local ymax = 0
		nicelabels `ymin' `ymax', local(yla)
		local yrange "ylabel(`yla')"
	}
	else {
		local yrange "ylabel(`yrange')"
	}
		
	// Add comparability variable
	if "`comparability'"~="" {
		merge m:1 `year' using `datacomp', nogen
	}
	
	//Prepare year variable without gaps if specified
	if "`noequalspacing'"=="" {																	// Year spacing option
		egen year_nogap = group(`year'), label(year_nogap)										// Generate year variable without gaps
		local year year_nogap
	}	
	qui levelsof `year'		 , local(yearval)	
	sort `year'
	qui levelsof `comparability', local(compval)
	if "`comparability'"~="__comp" local note_c "Non-connected dots indicate that survey-years are not comparable."	
	
	local scatter_cmd = `"scatter p* `year', mcolor("${col1}" "${col2}" "${col3}" "${col4}" "${col5}") lcolor("${col1}" "${col2}" "${col3}" "${col4}" "${col5}") || "'					// Colors defined in pea_figure_setup
		
	// If comparability specified, only comparable years are connected
	foreach co of local compval {
		local line_cmd`co' = `"line p* `year' if `comparability'==`co', mcolor("${col1}" "${col2}" "${col3}" "${col4}" "${col5}") lcolor("${col1}" "${col2}" "${col3}" "${col4}" "${col5}") || "'
		local line_cmd "`line_cmd' `line_cmd`co''"
	}

	// Figure
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure9d.xlsx"
		local act replace
		cap rm "`dirpath'\\Figure9d.xlsx"
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}
	local gr = 1
	local u  = 5
	putexcel set "`excelout2'", `act'
	tempfile graph`gr'
	
	if "`bar'" == "" {
		twoway `scatter_cmd' `line_cmd'									///	
				  , legend(order(1 "10th percentile" 2 "25th percentile" 3 "50th percentile" 4 "75th percentile" 5 "90th percentile"))				    ///
				  ytitle("Welfare aggregate") 						///
				  xtitle("")											///
				  xlabel("`yearval'", valuelabel)						///
				  `yrange'												///
				  name(ngraph`gr', replace)								
	}
	else if "`bar'" ~= "" {
		forval b = 1/5 {
			local bcolors "`bcolors' bar(`b', color(${col`b'}))"		
		}
		graph bar p*, over(`year')									///	
					`bcolors' asyvars `yrange'	    			///
					ytitle("Welfare aggregate") 					///
					legend(order(1 "10th percentile" 2 "25th percentile" 3 "50th percentile" 4 "75th percentile" 5 "90th percentile"))	///
					name(ngraph`gr', replace)								
	}
	putexcel set "`excelout2'", modify sheet(Figure9d, replace)	  
	graph export "`graph`gr''", replace as(png) name(ngraph`gr') wid(1500)		
	putexcel A`u' = image("`graph`gr''")
	
	putexcel A1 = ""
	putexcel A2 = "Figure 9d: Welfare percentiles over time"
	putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
	putexcel A4 = "Note: The figure shows the level of income/consumption at selected percentiles of the distribution over time. Welfare percentiles are based on `lbltitle', to allow for comparability to other countries. `note_c'"
	
	putexcel O10 = "Data:"
	putexcel O6	= "Code:"
	if "`bar'" == "" putexcel O7 = `"twoway `scatter_cmd' `line_cmd', legend(order(1 "10th percentile" 2 "25th percentile" 3 "50th percentile" 4 "75th percentile" 5 "90th percentile"))	ytitle("Welfare aggregate") xtitle("") xlabel(`yearval', valuelabel) `yrange'"'
	else if "`bar'" ~= "" putexcel O7 = `"graph bar p*, over(`year') `bcolors' `yrange' asyvars ytitle("Welfare aggregate") legend(order(1 "10th percentile" 2 "25th percentile" 3 "50th percentile" 4 "75th percentile" 5 "90th percentile"))"'
	if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
	putexcel save							
	cap graph close	
	//Export data
	export excel * using "`excelout2'" , sheet("Figure9d", modify) cell(O11) keepcellfmt firstrow(variables) nolabel
	if "`excel'"=="" shell start excel "`dirpath'\\Figure9d.xlsx"	

end