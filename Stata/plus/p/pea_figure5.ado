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
	syntax [if] [in] [aw pw fw], [ONEWelfare(varname numeric) ONELine(varname numeric) spells(string) Year(varname numeric) urban(varname numeric) CORE LINESORTED NONOTES comparability(string) setting(string) excel(string) save(string) scheme(string) palette(string)]

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
		if "`comparability'" ~= "" {
			forv j=1(1)`=`a'-1' {
				local spell_c`j' = "`spell`j''"												// Save local
				qui levelsof `comparability', local(comp_years)								// Loop through all values of comparability
				foreach i of local comp_years {
					qui	levelsof year if `comparability' == `i', local(year_c)				// Create list of comparable years
					local year_c = "`year_c'" 
					local test : list spell_c`j' in year_c									// Check if spell years are in list of comparable years
					if (`test' == 0) local spell`j' = ""									// If years not comparable, drop local
					if (`test' == 1) local spell`j' = "`spell_c`j''"						// If years comparable, keep local
				}
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
		
		// Figure
		local figname Figure5
		if "`excel'"=="" {
			local excelout2 "`dirpath'\\`figname'.xlsx"
			local act replace
		}
		else {
			local excelout2 "`excelout'"
			local act modify
		}
		
		// Coloring of bars
		qui levelsof subind, local(subind_list)
		foreach i of local subind_list {
			local colors "`colors' bar(`i', color(${col`i'}))"		
		}
		
		local gr 1
		local u  = 5		
		putexcel set "`excelout2'", `act'
		
		//Huppi-Ravallion
		tempfile graph1
		//Prepare Notes
		local note : label indicatorlbl 1	
		local notes "Source: World Bank calculations using survey data accessed through the GMD."
		local notes `"`notes'" "Note: The Huppi-Ravallion decomposition shows how progress in poverty changes can be" "attributed to different groups. The intra-sectoral component displays how the incidence of poverty" "in rural and urban areas has changed, assuming the relative population size in each of these has" "remained constant. Population shift refers to the contribution of changes in population shares," "assuming poverty incidence in each group has remained constant. The interaction between" "the twoindicates whether there is a correlation between changes in poverty incidence" "and population movements using `note'"'
		if "`nonotes'" ~= "" local notes ""
		
		graph bar value if decomp=="Huppi-Ravallion", over(subind) over(spell) asyvar legend(rows(1) size(small) position(6)) ytitle("Total change in poverty" "(percentage points)", size(medium)) name(gr_decomp, replace) title("Huppi-Ravallion decomposition", size(medium)) blabel(bar, position(center) format(%9.2f)) `colors' ///
		note("`notes'", size(small))
		
		putexcel set "`excelout2'", modify sheet("Figure5", replace)
		graph export "`graph1'", replace as(png) name(gr_decomp) wid(3000)
		putexcel A`u' = image("`graph1'")
		putexcel save
		cap graph close	
	} //qui
	if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"
end