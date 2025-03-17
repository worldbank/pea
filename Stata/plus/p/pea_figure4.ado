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

//Figure 4. Decomposition of poverty changes: growth and redistribution: Datt-Ravallion and Shorrocks-Kolenikov 			

cap program drop pea_figure4
program pea_figure4, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [ONEWelfare(varname numeric) ONELine(varname numeric) spells(string) Year(varname numeric) CORE LINESORTED comparability(string) idpl(string) setting(string) excel(string) save(string) scheme(string) palette(string) PPPyear(integer 2017)]

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
		noi dis as error "Need at least two years, i.e. 2000 2004"
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
	
	// Check if there are multiple poverty lines
	foreach y of local keepyears {
		qui sum `oneline' if year == `y'
		if "`idpl'" == "" & `r(min)' ~= `r(max)' {
			noi dis as error "Different poverty lines for one year: Please use option idpl() to specify the grouping of poverty lines (e.g. urban)."
			error `=_rc'	
		}
	}
	
	if "`idpl'" ~= "" {
		local idplgroup "idpl(`idpl')"
		local idpl_lab: variable label `idpl'
		local idpl_note "Different poverty lines are used by `idpl_lab'."
	}
	
	// Figure colors
	local groups = 4										// number of bars
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")						//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
	
	qui {	
		foreach var of varlist `oneline' {
			local lbl`var' : variable label `var'
		}
		
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
		cap frame drop decomp_results	
		frame create decomp_results strL(decomp spell povline) float(value1 value2 value3 value4)
							  		
		use `dataori', clear					  
		forv j=1(1)`=`a'-1' {
			local spell`j' : list sort spell`j'
			tokenize "`spell`j''"
			if "`1'"~="" & "`2'"~="" {
				dis "Spell`j': `1'-`2'"	
								
				//Datt-Ravallion decomposition
				drdecomp `onewelfare' [aw=`wvar'] if `year'==`1'|`year'==`2', by(`year') varpl(`oneline')
				mat a = r(b)
				local value1 = a[1,3]
				local value2 = a[2,3]
				local value3 = a[3,3]
				* Post the results to the frame
				frame decomp_results {  
					frame post decomp_results ("Datt-Ravallion") ("`1'-`2'") ("`var'") (`value3') (`value1') (`value2') (-9999)
				}
				
				//Shorrocks-Kolenikov 
				skdecomp `onewelfare' [aw=`wvar'] if `year'==`1'|`year'==`2', by(`year') varpl(`oneline') `idplgroup'
				mat a = r(b)
				local value1 = a[1,3]
				local value2 = a[2,3]
				local value3 = a[3,3]
				local value4 = a[4,3]
				* Post the results to the frame
				frame decomp_results {  
					frame post decomp_results ("Shorrocks-Kolenikov") ("`1'-`2'") ("`var'") (`value4') (`value1') (`value2') (`value3') 
				}
			} //1 2
		} //j
		
		* See results
		frame change decomp_results	
		reshape long value, i(decomp spell povline) j(subind)
		la def subind 1 "Total change in p.p." 2 "Growth" 3 "Redistribution" 4 "Line"
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
			bys decomp spell_n value_negative (num) : replace value_add = value_add + value_add[_n-1] if num != . & num > 1 & spell_n == `y'			
		}
		drop subind_cat value_negative num spell
		// Reshape for stacked bars
		compress decomp
		reshape wide value value_add, i(decomp spell_n) j(subind)
		order decomp spell_n value? value_add?
		gen zero = 0	// zero needed so twoway bar starts at 0..
		// Figure
		local figname Figure4
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
		
		//Datt-Ravallion
		if "`core'" == "" local fnum "4a"
		else if "`core'" ~= "" local fnum "A.2" 
		tempfile graph1
		local note : label indicatorlbl 1	
		twoway bar value_add3 value_add2 spell_n if decomp=="Datt-Ravallion", color("${col3}" "${col2}") barwidth(0.5 0.5)  ||	///
				scatter value1 spell_n if decomp=="Datt-Ravallion", 										///
				msym(D) msize(2.5) mcolor("${col1}") mlcolor(black)						||	///
				bar zero spell_n, yline(0)  xlabel("`spells'", valuelabel) xtitle("")						///
			legend(rows(1) size(medium) position(6) order(2 "Growth" 1 "Redistribution" 3 "Total change"))	///
			ytitle("Change in poverty" "(percentage points)", size(medium)) 								///
			name(gr_decomp, replace)
			
		putexcel set "`excelout2'", modify sheet("Figure`fnum'", replace)
		graph export "`graph1'", replace as(png) name(gr_decomp) wid(1500)
		putexcel A`u' = image("`graph1'")
		
		putexcel A1 = ""
		putexcel A2 = "Figure `fnum': Datt-Ravallion decomposition"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The Datt-Ravallion decomposition shows how much changes in total poverty can be attributed to income or consumption growth and redistribution using `note', following Datt and Ravallion (1992)."
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"twoway bar value_add3 value_add2 spell_n if decomp=="Datt-Ravallion", color("${col1}" "${col2}") barwidth(0.5 0.5) || scatter value1 spell_n if decomp=="Datt-Ravallion", msym(D) msize(2.5) mcolor("${col3}") mlcolor(black) legend(rows(1) size(medium) position(6) order(2 "Growth" 1 "Redistribution" 3 "Total change")) ytitle("Change in poverty" "(percentage points)", size(medium))"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
		
		//Export data
		export excel * using "`excelout2'" if decomp=="Datt-Ravallion", sheet("Figure`fnum'", modify) cell(O11) keepcellfmt firstrow(variables)	
			
		//Shorrocks-Kolenikov
		if "`core'" == "" {
			local gr 1
			local u  = 5
			tempfile graph1
			local note : label indicatorlbl 1
			twoway bar value_add4 value_add3 value_add2 spell_n if decomp=="Shorrocks-Kolenikov",					/// 
					color("${col4}" "${col3}" "${col2}") barwidth(0.5 0.5 0.5)	||									///
					scatter value1 spell_n if decomp=="Shorrocks-Kolenikov", 										///
					msym(D) msize(2.5) mcolor("${col1}") mlcolor(black) 		||									///
					bar zero spell_n, yline(0) xlabel("`spells'", valuelabel) xtitle("")							///
					legend(rows(1) size(medium) position(6)															///
					order(3 "Growth" 2 "Redistribution" 1 "Price" 4 "Total change"))								///
					ytitle("Total change in poverty" "(percentage points)", size(medium)) 								///
					name(gr_decomp, replace)
										
			putexcel set "`excelout2'", modify sheet("Figure4b", replace)
			graph export "`graph1'", replace as(png) name(gr_decomp) wid(1500)
			putexcel A`u' = image("`graph1'")
			
			putexcel A1 = ""
			putexcel A2 = "Figure 4b: Shorrocks-Kolenikov decomposition"
			putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
			putexcel A4 = "Note: The Shorrocks-Kolenikov decomposition shows how much changes in total poverty can be attributed to income or consumption growth, redistribution, and price changes using `note', following Kolenikov and Shorrocks (2005). Note that there are no changes in prices if poverty lines are in constant terms. `idpl_note'."
			
			putexcel O10 = "Data:"
			putexcel O6	= "Code:"
			putexcel O7 = `"twoway bar value_add4 value_add3 value_add2 spell_n if decomp=="Shorrocks-Kolenikov", color("${col1}" "${col2}" "${col3}") barwidth(0.5 0.5 0.5) || scatter value1 spell_n if decomp=="Shorrocks-Kolenikov", msym(D) msize(2.5) mcolor("${col4}") mlcolor(black) legend(rows(1) size(medium) position(6) order(3 "Growth" 2 "Redistribution" 1 "Price" 4 "Total change")) ytitle("Total change in poverty" "(percentage points)", size(medium))"'
			if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")			
			putexcel save
			//Export data
			export excel * using "`excelout2'" if decomp=="Shorrocks-Kolenikov", sheet("Figure4b", modify) cell(O11) keepcellfmt firstrow(variables)	
		}
		cap graph close	
	} //qui

	if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"
end