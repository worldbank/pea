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

//Figure 5a. Decomposition of poverty changes: growth and redistribution: Huppi-Ravallion (rural/urban)			

cap program drop pea_figure5a
program pea_figure5a, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [ONEWelfare(varname numeric) ONELine(varname numeric) spells(string) Year(varname numeric) urban(varname numeric) CORE LINESORTED comparability(string) setting(string) excel(string) save(string) scheme(string) palette(string) PPPyear(integer 2021)]

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
	_pea_export_path, excel("`excel'")
	
	local x = subinstr("`spells'",";"," ",.)		
	local keepyears : list uniq x
	qui {	
		local lblline : variable label `oneline'

		//Weights
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		}
		
		if "`onewelfare'"~="" { //reset to the floor
			replace `onewelfare' = ${floor_} if `onewelfare'< ${floor_}
			noi di in yellow "Welfare in `pppyear' PPP is adjusted to a floor of ${floor_}"
		}
	
		//missing observation check
		marksample touse
		local flist `"`wvar' `onewelfare' `urban' `year'"'
		markout `touse' `flist' 
		
		tempfile dataori datalbl
		
		// Check if any years don't have urban
		foreach y of local keepyears {
			sum `urban' if `year' == `y'
			if `r(N)' == 0 {
			noi disp in red "No values for `urban' for year `y'. Please select other years, or a different sector variable."
				exit
			}
		}
		
		// Check year list		
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
		
		// Number of areas
		qui levelsof `urban', local(indlev)
		local indnum = `: word count `indlev''
		
		// Prepare frames for output saving
		local totdecomp = `indnum' + 3 														// Sectors + Total + Population + Interaction 
		forval i = 1/`totdecomp' {
			local values "`values' value`i'"
		}
		
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
		frame create decomp_results2 strL(decomp spell povline) float(`values')
			  		
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
				local x = 4
				foreach rn of local rnames {
					local rlbl `"`rlbl' `x' "`rn'""'
					local x = `x' + 1
				}					
				local value1 = b[1,1]
				local value2 = b[3,1]
				local value3 = b[4,1]

				forval i = 1/`indnum' {
					local j = `i' + 3						// Name of value has to start at 4
					local value`j' = a[`i',2]
				}		
									
				local categ					
				// Get correct number values
				forval i = 1/`totdecomp' {
					local categ "`categ' (`value`i'')"
				}
				
				* Post the results to the frame
				frame decomp_results2 {  
					frame post decomp_results2 ("Huppi-Ravallion") ("`1'-`2'") ("`oneline'") `categ'
				}				
			} //1 2
		} //j
		
		* See results
		frame change decomp_results2	
		reshape long value, i(decomp spell povline) j(subind)
		la def subind 1 "Total change" 2 "Population shift" 3 "Interaction" `rlbl'		
		la val subind subind
		replace value = . if value==-9999
		replace povline = "`lblline'"

		// Spells
		encode spell, gen(spell_n)
		qui levelsof spell_n, local(spells)
		// Stacked bars
		gen subind_cat 		= subind - 1
		replace subind_cat 	= . if subind == 1
		gen value_negative 	= value < 0
		bys decomp spell_n value_negative (subind_cat): gen num = _n
		replace num 		= . if subind == 1
		gen value_add 		= value  if subind != 1
		foreach y of local spells {
			bys decomp spell_n value_negative (num) : replace value_add = value_add + value_add[_n-1] if num != . & num > 1 & spell_n == `y'			
		}
		drop subind_cat value_negative num spell

		// Reshape for stacked bars
		compress decomp
		qui levelsof subind, local(sind)
		foreach s of local sind {
			local subind`s' : label subind `s'
		}
		reshape wide value value_add, i(decomp spell_n) j(subind)
		foreach s of local sind {
			label var value`s' 		"`subind`s''"
			label var value_add`s' 	"`subind`s''"
		}
		
		order decomp spell_n value? value_add?
		gen zero = 0	// zero needed so twoway bar starts at 0..
		
		// Figure colors
		local groups = `totdecomp'																			// number of bars
		pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")						//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
			
		// Figure
		local figname Figure5a
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
		forval i = 2/`totdecomp' {
			local cols `""${col`i'}" `cols'"'
			local value_add "value_add`i' `value_add'"
			local bw	"`bw' 0.5"
			local lorder "`i' `lorder'"								// Reverse ordering in legend
		}
		local rows = ceil(`totdecomp' / 4)							// Rows in legend (max. 4 in one row)
		tempfile graph1

		twoway bar `value_add' spell_n if decomp=="Huppi-Ravallion",											/// 
				color(`cols') barwidth(`bw') 									||								///
				scatter value1 spell_n if decomp=="Huppi-Ravallion", 											///
				msym(D) msize(2.5) mcolor("${col1}") mlcolor(black)				||								///
				bar zero spell_n, yline(0) xlabel("`spells'", valuelabel) xtitle("")							///
				legend(rows(`rows') position(6) order(`lorder' 1))													///
				ytitle("Total change in poverty" "(percentage points)") 										///
				name(gr_decomp, replace)
									
		putexcel set "`excelout2'", modify sheet("Figure5a", replace)
		graph export "`graph1'", replace as(png) name(gr_decomp) wid(1500)
		putexcel A`u' = image("`graph1'")
		
		putexcel A1 = ""
		putexcel A2 = "Figure 5a: Huppi-Ravallion decomposition"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The Huppi-Ravallion decomposition shows how progress in poverty changes can be attributed to different groups. The intra-sectoral component displays how the incidence of poverty in rural and urban areas has changed, assuming the relative population size in each of these has remained constant. Population shift refers to the contribution of changes in population shares, assuming poverty incidence in each group has remained constant. The interaction between the two indicates whether there is a correlation between changes in poverty incidence and population movements using `lblline'. The decomposition follows Huppi and Ravallion (1991)."
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code"
		putexcel N11 = "Labels:"
		putexcel N12 = "Variables:"
		putexcel O7 = `"twoway bar `value_add' spell_n if decomp=="Huppi-Ravallion", color(`cols') barwidth(`bw') || scatter value1 spell_n if decomp=="Huppi-Ravallion", msym(D) msize(2.5) mcolor("${col1}") mlcolor(black) legend(rows(`rows') position(6) order(`lorder')) ytitle("Total change in poverty" "(percentage points)")"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
		putexcel save
		cap graph close	
	} //qui
	//Export data
	foreach var of varlist value_add* {
		local lbl: variable label `var'
		label var `var' `"Stacked bar: `lbl'"'									// Add so that it is clear in Excel output that this is value of stacked bar.
	}

	export excel * using "`excelout2'" if decomp=="Huppi-Ravallion", sheet("Figure5a", modify) cell(O11) keepcellfmt firstrow(varlabels)
	export excel * using "`excelout2'" if decomp=="Huppi-Ravallion", sheet("Figure5a", modify) cell(O12) keepcellfmt firstrow(variables) nolabel
	if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"
end