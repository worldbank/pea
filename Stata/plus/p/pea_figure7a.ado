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

//Figure 7a. Poverty rates by subgroups


cap program drop pea_figure7a
program pea_figure7a, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) Year(varname numeric) FGTVARS LINESORTED age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) setting(string) scheme(string) palette(string) excel(string) save(string)]
	
	//load setting
	qui if "`setting'"=="GMD" {
		_pea_vars_set, setting(GMD)
		local vlist age male hhhead edu urban married  
		foreach st of local vlist {
			local `st' "${pea_`st'}"
		}		
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
	
	if "`missing'"~="" { //show missing
		foreach var of varlist `male' `hhhead' `edu' {
			su `var'
			local miss = r(max)
			replace `var' = `=`miss'+10' if `var'==.
			local varlbl : value label `var'
			la def `varlbl' `=`miss'+10' "Missing", add
		}
	}
	
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
		
		//Weights
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		}
	
		//missing observation check
		marksample touse
		local flist `"`wvar' `natwelfare' `natpovlines' `pppwelfare' `ppppovlines' `year' `male' `edu' `age' `urban'"'
		markout `touse' `flist' 
	} //qui
		
	//Number of groups (for colors)
	local groups = `:word count `natpovlines' `ppppovlines''

	// Figure colors
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")	//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
		
	// Generate poverty measures
	if "`fgtvars'"=="" { //only create when the fgt are not defined			
		//FGT
		if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
		if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
		gen double _pop = `wvar'
	}
	
	// Shorten value labels 
    local lbl: value label `edu'
	if "`lbl'" == "educat4" {
		label define educat4_m 1 "No education" 2 "Primary" 3 "Secondary" 4 "Tertiary"
		label values `edu' educat4_m
	}	
	
	// Variable definitions
	if "`age'"!="" {
		su `age',d
		if r(N)>0 {
			gen agecatind = 1 if `age'>=0 & `age'<=14
			replace agecatind = 2 if `age'>=15 & `age'<=65
			replace agecatind = 3 if `age'>=66 & `age'<=.
			la def agecatind 1 "Age 0-14" 2 "Age 15-65" 3 "Age 66+"
			la val agecatind agecatind
		}
	}
	
	gen _total = 1
	la def _total 1 "Total"
	la val _total _total	
	tempfile data1 data2
	// Only last year
	qui sum `year', d   // Get last year of survey data (year of scatter plot)
	local lasty `r(max)'
	keep if `year' == `lasty'
	save `data1', replace
	clear
	save `data2', replace emptyok	

	// Prepare poverty rates by groups
	use `data1', clear	
	local byind `male' `edu' agecatind `urban' _total

	local i = 1
	foreach var of local byind {
		use `data1', clear
		qui levelsof `var', local(lclist)
		local label1 : value label `var'
		 
		foreach lvl of local lclist {
			use `data1', clear
			keep if `var'==`lvl'
			local lbllvl : label `label1' `lvl'			
			groupfunction  [aw=`wvar'] if `touse', mean(_fgt0*) rawsum(_pop) by(`year')
			gen _group = `i'			
			la def _group `i' "`lbllvl'", add
			la val _group _group
			tempfile labelx`i'
			label save _group using `labelx`i''
			la drop _group
			local i = `i' + 1			
			append using `data2'
			save `data2', replace
		}
	}
	qui forv j=1(1)`=`i'-1' {
		do `labelx`j''
	}
	qui for var _fgt0*: replace X = X*100
	la val _group _group
	
	//Prepare graph variable and legend
	local vars_graph
	local vars_label
	local o 1
	if "`natwelfare'"~="" {
		foreach var in `natpovlines' {
			local vars_graph "`vars_graph' _fgt0_`natwelfare'_`var'"
			local vars_label `"`vars_label' `o' "`lbl`var''" "'
			local o = `o' + 1
		}
	}
	if "`pppwelfare'"~="" {
		foreach var in `ppppovlines' {
			local vars_graph "`vars_graph' _fgt0_`pppwelfare'_`var'"
			local vars_label `"`vars_label' `o' "`lbl`var''" "'
			local o = `o' + 1
		}
	}
		
	// Figure
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure7a.xlsx"
		local act replace
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
	local u = 5
	
	tempfile graph
	putexcel set "`excelout2'", `act'
	graph dot `vars_graph', 				///
			over(_group) marker(1, msymbol(O) mc("${col1}")) ///
			marker(2, msymbol(D) mc("${col2}")) ///  
			marker(3, msymbol(S) mc("${col3}")) ///
			marker(4, msymbol(T) mc("${col4}")) ///
			legend(pos(6) order(`vars_label') row(2) on) 	///
			ytitle("Poverty rate (percent)") 				///
			name(ngraph`gr', replace)	

	putexcel set "`excelout2'", modify sheet(Figure7a, replace)	  
	graph export "`graph'", replace as(png) name(ngraph) wid(1500)		
	putexcel A1 = ""
	putexcel A2 = "Figure 7a: Poverty rates by demographic groups"
	putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
	putexcel A4 = "Note: Figure presents poverty rates across different poverty lines within each group. Data from all individuals is used, not only household heads."
	putexcel A`u' = image("`graph'")
	putexcel O10 = "Data:"
	putexcel O6	= "Code:"
	putexcel O7 = `"graph dot `vars_graph' over(_group) marker(1, msymbol(O) mc("${col1}")) marker(2, msymbol(D) mc("${col2}")) marker(3, msymbol(S) mc("${col3}")) marker(4, msymbol(T) mc("${col4}")) legend(pos(6) order(`vars_label') row(2) on) ytitle("Poverty rate (percent)")"'
	putexcel save								
	cap graph close	
	//Export data
	export excel `year' _group _fgt0_* using "`excelout2'" , sheet("Figure7a", modify) cell(O11) keepcellfmt firstrow(variables)
	if "`excel'"=="" shell start excel "`dirpath'\\Figure7a.xlsx"	
		
end	