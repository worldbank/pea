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

//Figure 5. Decomposition of poverty changes: growth and redistribution: Huppi-Ravallion 			

cap program drop pea_figure5
program pea_figure5, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [ONEWelfare(varname numeric) ONELine(varname numeric) spells(string) Year(varname numeric) urban(varname numeric) CORE LINESORTED comparability(string) setting(string) excel(string) save(string) scheme(string) palette(string) PPPyear(integer 2017)]

	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	//load data if defined
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}
	
	if "`save'"=="" {
		tempfile saveout
		local save `saveout'
	}
	if "`nooutput'"~="" & "`excel'"~="" {
		noi dis as error "Cant have both nooutput and excel() options"
		error 1
	}
	if "`spells'"=="" {
		noi dis as error "Need at least two years in spells(), i.e. 2000 2004"
		error 1
	}
	//house cleaning
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
	
	local x = subinstr("`spells'",";"," ",.)		
	local keepyears : list uniq x
	qui {	
		foreach var of varlist `oneline' {
			local lbl`var' : variable label `var'
		}
		
		// Figure colors
		local groups = 5																					// number of bars
		pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")						//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
	
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
		local flist `"`wvar' `onewelfare' `by' `year'"'
		markout `touse' `flist' 
		
		tempfile dataori datalbl
		save `dataori', replace
		
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
		gen _all_ = 1 if `touse'
		la var _all_ "All sample"
		la def _all_ 1 "All sample"
		la val _all_ _all_
		local by "_all_ `by'"		
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
		cap frame drop decomp_results2			
		frame create decomp_results2 strL(decomp spell povline) float(value1 value2 value3 value4 value5)
			  		
		use `dataori', clear					  
		forv j=1(1)`=`a'-1' {
			local spell`j' : list sort spell`j'
			tokenize "`spell`j''"
			if "`1'"~="" & "`2'"~="" {
				dis "Spell`j': `1'-`2'"	
				
				tempfile data_y2
				use `dataori' if `year'==`2', clear
				save `data_y2', replace
				
				//Huppi-Ravallion decomposition
				use `dataori' if `year'==`1', clear					
				sedecomposition using `data_y2' [aw=`wvar'], sector(`urban') pline1(`oneline') pline2(`oneline') var1(`onewelfare') var2(`onewelfare') hc
				mat a = r(b_sec)
				mat b = r(b_tot)					
				local rnames : rowfullnames a
				local rlbl
				local x = 2
				foreach rn of local rnames {
					local rlbl `"`rlbl' `x' "`rn'""'
					local x = `x' + 1
				}					
				local value1 = b[1,1]
				local value2 = a[1,2]
				local value3 = a[2,2]
				local value4 = b[3,1]
				local value5 = b[4,1]
				
				* Post the results to the frame
				frame decomp_results2 {  
					frame post decomp_results2 ("Huppi-Ravallion") ("`1'-`2'") ("`var'") (`value1') (`value2') (`value3') (`value4') (`value5')
				}				
			} //1 2
		} //j
		
		* See results
		frame change decomp_results2	
		reshape long value, i(decomp spell povline) j(subind)
		la def subind 1 "Total change in p.p." `rlbl' 4 "Population shift" 5 "Interaction"		
		la val subind subind
		replace value = . if value==-9999
		gen indicatorlbl = .
		local i = 1
		
		foreach var of local oneline {
			replace indicatorlbl = `i' if povline=="`var'"
			la def indicatorlbl `i' "`lbl`var''", add
			local i = `i' + 1
		}
		// Spells
		encode spell, gen(spell_n)
		qui levelsof spell_n, local(spells)
		// Stacked bars
		gen subind_cat 		= subind - 1
		replace subind_cat = . if subind == 1
		gen value_negative 	= value < 0
		bys decomp spell_n value_negative (subind_cat): gen num = _n
		replace num = . if subind == 1
		gen value_add = value  if subind != 1
		foreach y of local spells {
			bys decomp spell_n value_negative (num) : replace value_add = value_add + value_add[_n-1] if value_negative == 0 & num != . & num > 1 & spell_n == `y'			
			bys decomp spell_n value_negative (num) : replace value_add = value_add - value_add[_n-1] if value_negative == 1 & num != . & num > 1 & spell_n == `y'				
		}
		drop subind_cat value_negative num spell
		local x = 4										
		foreach rn of local rnames {					// Need different numbers for urban/rural label for figure
			local rlbl2 `"`rlbl2' `x' "`rn'""'
			local x = `x' - 1
		}

		// Reshape for stacked bars
		compress decomp
		reshape wide value value_add, i(decomp spell_n) j(subind)
		order decomp spell_n value? value_add?
		gen zero = 0	// zero needed so twoway bar starts at 0..
		
		// Figure
		local figname Figure5
		if "`excel'"=="" {
			local excelout2 "`dirpath'\\`figname'.xlsx"
			local act replace
			cap rm "`dirpath'\\`figname'.xlsx"
		}
		else {
			local excelout2 "`excelout'"
			local act modify
		}
		
		local gr 1
		local u  = 5		
		putexcel set "`excelout2'", `act'
		
		//Huppi-Ravallion
		tempfile graph1
		local note : label indicatorlbl 1	

		twoway bar value_add5 value_add4 value_add3 value_add2 spell_n if decomp=="Huppi-Ravallion",			/// 
				color("${col5}" "${col4}" "${col3}" "${col2}") barwidth(0.5 0.5 0.5 0.5) ||						///
				scatter value1 spell_n if decomp=="Huppi-Ravallion", 											///
				msym(D) msize(2.5) mcolor("${col1}") mlcolor(black)		||										///
				bar zero spell_n, yline(0) xlabel("`spells'", valuelabel) xtitle("")							///
				legend(rows(1) size(medium) position(6)															///
				order(`rlbl2' 2 "Population shift" 1 "Interaction" 5 "Total change"))							///
				ytitle("Total change in poverty" "(percentage points)", size(medium)) 							///
				name(gr_decomp, replace)
									
		putexcel set "`excelout2'", modify sheet("Figure5", replace)
		graph export "`graph1'", replace as(png) name(gr_decomp) wid(1500)
		putexcel A`u' = image("`graph1'")
		
		putexcel A1 = ""
		putexcel A2 = "Figure 5: Huppi-Ravallion decomposition"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The Huppi-Ravallion decomposition shows how progress in poverty changes can be attributed to different groups. The intra-sectoral component displays how the incidence of poverty in rural and urban areas has changed, assuming the relative population size in each of these has remained constant. Population shift refers to the contribution of changes in population shares, assuming poverty incidence in each group has remained constant. The interaction between the two indicates whether there is a correlation between changes in poverty incidence and population movements using `note'. The decomposition follows Huppi and Ravallion (1991)."
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code"
		putexcel O7 = `"twoway bar value_add5 value_add4 value_add3 value_add2 spell_n if decomp=="Huppi-Ravallion", color("${col5}" "${col4}" "${col3}" "${col2}") barwidth(0.5 0.5 0.5 0.5) || scatter value1 spell_n if decomp=="Huppi-Ravallion", msym(D) msize(2.5) mcolor("${col1}") mlcolor(black) legend(rows(1) size(medium) position(6) order(`rlbl2' 2 "Population shift" 1 "Interaction" 5 "Total change")) ytitle("Total change in poverty" "(percentage points)", size(medium))"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
		putexcel save
		cap graph close	
	} //qui
	//Export data
	export excel * using "`excelout2'" if decomp=="Huppi-Ravallion", sheet("Figure5", modify) cell(O11) keepcellfmt firstrow(variables)
	if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"
end