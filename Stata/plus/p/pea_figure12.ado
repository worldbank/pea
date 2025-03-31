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

//Figure 12. Decomposition of growth in prosperity gap
//todo: add comparability, add the combine graph option

cap program drop pea_figure12
program pea_figure12, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) ONEWelfare(varname numeric) Year(varname numeric) NOOUTPUT spells(string) excel(string) save(string) comparability(string) RELATIVECHANGE scheme(string) palette(string) PPPyear(integer 2017)]	
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}
	
	if "`comparability'"=="" {
		noi di in red "Warning: Comparability option not specified for Figure 12. Non-comparable spells may be shown."
	}
	
	if "`spells'"=="" {
		noi dis as error "Need at least two years, i.e. 2000 2004"
		error 1
	}
	_pea_export_path, excel("`excel'")
	
	// Figure colors
	local groups = 3																					// number of bars
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")						//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
		
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
	
	local x = subinstr("`spells'",";"," ",.)		
	local keepyears : list uniq x
	
	if "`onewelfare'"~="" { //reset to the floor
		replace `onewelfare' = ${floor_} if `onewelfare'< ${floor_}
		noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
	}
	
	tempfile dataori datalbl data2 data2b
	save `dataori', replace
	
	//Check years in spells()
	levelsof `year' if `touse', local(yrlist)
	local same : list yrlist === keepyears
	if `same'==0 {
		noi dis "There are different years requested, and some not available in the data."
		noi dis "Requested: `keepyears'. Available: `yrlist'"
	}
	gen _keep =. if `touse'
	foreach yr of local keepyears {
		replace _keep=1 if `year'==`yr' & `touse'
	}
	keep if _keep==1 & `touse'
	drop _keep
	save `dataori', replace
	
	// Prepare spells
	tokenize "`spells'", parse(";")	
	local i = 1
	local a = 1
	while "``i''" != "" {
		if "``i''"~=";" {
			local spell`a' "``i''"		
			dis "`spell`a''"
			local a = `a' + 1
		}	
		local i = `i' + 1
	}
	// Comparability
	local one = 1
	if "`comparability'" ~= "" {
		forv j=1(1)`=`a'-1' {
			local test
			local spell_c`j' = "`spell`j''"												// Save local
			qui levelsof `comparability', local(comp_years)								// Loop through all values of comparability
			foreach i of local comp_years {
				qui	levelsof year if `comparability' == `i', local(year_c)				// Create list of comparable years
				local year_c = "`year_c'" 
				local test_`i': list spell_c`j' in year_c								// Check if spell years are in list of comparable years
				local test "`test' `test_`i''"
			}
			local test_pos: list one in test												// Check if any spell has comparable years
			if (`test_pos' == 0) local spell`j' = ""										// If years not comparable, drop local
			if (`test_pos' == 1) local spell`j' = "`spell_c`j''"							// If years comparable, keep local			
		}
	}	// if
		
	cap frame create temp_frame
	cap frame change temp_frame
	cap frame drop decomp_results	
	frame create decomp_results strL(decomp spell) float(year mean inq_y_ybar prosgap)
	
	use `dataori', clear					  
	qui forv j=1(1)`=`a'-1' {
		local spell`j' : list sort spell`j'
		tokenize "`spell`j''"
		if "`1'"~="" & "`2'"~="" {
			dis "Spell`j': `1'-`2'"	
			
			local spelllbl "`1'-`2'"
			forv so=1(1)2 {
				su `onewelfare' [aw=`wvar'] if `year'==``so'',d
				local m1 = r(mean)
				gen inq_y_ybar = `m1'/`onewelfare' if `year'==``so''
				su inq_y_ybar [aw=`wvar'] if `year'==``so'',d
				local inq_y_ybar = r(mean)
				gen prosg = ${prosgline_}/`onewelfare' if `year'==``so''
				su prosg [aw=`wvar'] if `year'==``so'',d
				local prosg = r(mean)
				cap drop inq_y_ybar prosg
				frame decomp_results {  
					frame post decomp_results ("Pros gap decomp") ("`spelllbl'") (``so'') (`m1') (`inq_y_ybar') (`prosg')
				}
			} //so
		} //1 2
	} //j
	
	* See results
	frame change decomp_results

	foreach var of varlist prosgap inq_y_ybar mean {
		gen ln`var' = ln(`var')
		//change in ln
		bys spell (year): gen ch_ln`var' = (ln`var'[_n]- ln`var'[_n-1])/(year[_n]-year[_n-1])
	}
	
	gen zero = 0																// Needed so that figure starts at 0
	encode spell, gen(spell_num)
	qui levelsof spell_num, local(spells)
	
	if "`relativechange'" == "" {
		*bys spell (year): gen period = string(year[_n]) + "-" + string(year[_n-1])
		replace ch_lninq_y_ybar = ch_lninq_y_ybar *100
		replace ch_lnmean = -1 * ch_lnmean *100
		replace ch_lnprosgap = ch_lnprosgap *100
		//If inequality and growth go in same direction, need to add up for chart
		gen ch_lninq_y_ybar_add = .
		foreach y of local spells {
			replace ch_lninq_y_ybar_add = ch_lninq_y_ybar + ch_lnmean if spell_num == `y' & (ch_lninq_y_ybar * ch_lnmean > 0)
			replace ch_lninq_y_ybar_add = ch_lninq_y_ybar if spell_num == `y' & (ch_lninq_y_ybar * ch_lnmean <= 0)
		}
	}
	else if "`relativechange'" ~= "" {
		gen inq_share = (ch_lninq_y_ybar/ch_lnprosgap)*100
        gen grow_share = (-1 * ch_lnmean/ch_lnprosgap)*100

	}

	local gr 1
	local u  = 5

	//Figure
	if "`relativechange'" == "" {
		graph twoway bar ch_lninq_y_ybar_add ch_lnmean spell_num if ch_lninq_y_ybar_add~=.				///
			, color("${col1}" "${col2}") barwidth(0.5 0.5)												///
			|| scatter ch_lnprosgap spell_num if ch_lninq_y_ybar_add~=.									///
			, msym(D) msize(2.5) mcolor("${col3}") mlcolor(black)										///
			|| bar zero spell_num if ch_lninq_y_ybar_add~=.												///
			, yline(0) xlabel("`spells'", valuelabel)													///
			name(ngraph`gr', replace) ytitle("Annual growth (%)") xtitle("")							///
			legend(order(1 "Contribution of growth in inequality"										///
						 2 "Contribution of growth in mean growth"										///
						 3 "Growth in Prosperity Gap") rows(3) position(6))
	}
	else if "`relativechange'" ~= "" {
	graph hbar inq_share grow_share if inq_share~=., 														///
		stack over(spell) ytitle("Contribution to prosperity gap growth (%)") `colors'						///		
		title("Decomposition of growth in prosperity gap", size(medium)) 									///
		legend(order(1 "Inequality contribution" 2 "Mean contribution") rows(1) size(medium) position(6)) 	///
		name(ngraph`gr', replace)
	}	
	//Some labeling
	label var mean "Average welfare"
	label var inq_y_ybar "Average distance from mean welfare"
	label var prosgap "Prosperity Gap"
	label var ch_lnprosgap "Growth in Prosperity Gap"
	label var ch_lninq_y_ybar "Growth in mean welfare contribution"
	label var ch_lnmean "Growth in inequality contribution"
	label var ch_lninq_y_ybar "Growth in mean welfare contribution"
	label var ch_lnmean "Growth in inequality contribution"
	label var ch_lninq_y_ybar_add "For figure preparation: Additional contribution in inequality over mean welfare"

	//Export
	local figname Figure12
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\`figname'.xlsx"
		local act replace
		cap rm "`dirpath'\\`figname'.xlsx"
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}
	
	putexcel set "`excelout2'", `act'
	tempfile graph
	putexcel set "`excelout2'", modify sheet(`figname', replace)	  
	graph export "`graph'", replace as(png) name(ngraph`gr') wid(1500)		
	putexcel A`u' = image("`graph'")
	
	putexcel A1 = ""
	putexcel A2 = "Figure 12: Decomposition of growth in prosperity gap"
	putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
	putexcel A4 = "Note: The prosperity gap is defined as the average factor by which incomes need to be multiplied to bring everyone to the prosperity standard of $${prosgline_}. The figure shows the decomposition of the Prosperity Gap into income and inequality components. See Kraay et al. (2023) for more details."
	
	putexcel O10 = "Data:"
	putexcel O6	= "Code"
	putexcel N11 = "Labels:"
	putexcel N12 = "Variables:"
	if "`relativechange'" == "" {
		putexcel O7 = `"graph twoway bar ch_lninq_y_ybar_add ch_lnmean spell_num if ch_lninq_y_ybar_add~=., color("${col1}" "${col2}") barwidth(0.5 0.5) || scatter ch_lnprosgap spell_num if ch_lninq_y_ybar_add~=., msym(D) msize(2.5) mcolor("${col3}") mlcolor(black) || bar zero spell_num if ch_lninq_y_ybar_add~=., yline(0) xlabel("`spells'", valuelabel) ytitle("Annual growth (%)") xtitle("") legend(order(1 "Contribution of growth in inequality" 2 "Contribution of growth in mean growth" 3 "Growth in Prosperity Gap") rows(3) position(6))"'
	}
	else if "`relativechange'" ~= "" {
		putexcel O7 = `"graph hbar inq_share grow_share if inq_share~=., stack over(spell) ytitle("Contribution to prosperity gap growth (%)") `colors' title("Decomposition of growth in prosperity gap", size(medium)) legend(order(1 "Inequality contribution" 2 "Mean contribution") rows(1) size(medium) position(6))"'

	}	
	if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
	putexcel save							
	cap graph close	
	//Export data
	if "`relativechange'" == "" {
		export excel spell year mean inq_y_ybar prosgap lnprosgap ch_lnprosgap lninq_y_ybar ch_lninq_y_ybar lnmean ch_lnmean ch_lninq_y_ybar_add spell_num using "`excelout2'", sheet("`figname'", modify) cell(O11) keepcellfmt firstrow(varlabels) nolabel			
		export excel spell year mean inq_y_ybar prosgap lnprosgap ch_lnprosgap lninq_y_ybar ch_lninq_y_ybar lnmean ch_lnmean ch_lninq_y_ybar_add spell_num using "`excelout2'", sheet("`figname'", modify) cell(O11) keepcellfmt firstrow(variables) nolabel	 
	}
	else if "`relativechange'" ~= "" {
		export excel spell year inq_share grow_share using "`excelout2'", sheet("`figname'", modify) cell(O11) keepcellfmt firstrow(varlabels)	
		export excel spell year inq_share grow_share using "`excelout2'", sheet("`figname'", modify) cell(O12) keepcellfmt firstrow(variables) nolabel	
	}
	if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"	
end