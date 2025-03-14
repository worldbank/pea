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

//Fig 3b. Growth Incidence Curve by urban and rural areas

cap program drop pea_figure3b
program pea_figure3b, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Welfare(varname numeric) spells(string) Year(varname numeric) comparability(varname numeric) setting(string) trim(string) YRange(string) CORE excel(string) save(string) by(varname numeric) scheme(string) palette(string)]
	
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
	// Keep only last spell

	local fy = word("`spells'", `=wordcount("`spells'")-1')
	local sy = word("`spells'", `=wordcount("`spells'")')
	local spells "`fy' `sy'"
	di "`spellsnew'"
	// Prepare spells
	tokenize "`spells'", parse(";")	
	local comparability comparability
	// Comparability
	local one = 1
	if "`comparability'" ~= "" {
		qui levelsof `comparability', local(comp_years)							// Loop through all values of comparability
		foreach i of local comp_years {
			qui	levelsof year if `comparability' == `i', local(year_c)			// Create list of comparable years
			local year_c = "`year_c'" 
			local test: list spells in year_c									// Check if spell years are in list of comparable years
		}
		local test_pos: list one in test										// Check if any spell has comparable years
		if (`test_pos' == 0) local spell = ""									// If years not comparable, drop local
		if (`test_pos' == 1) local spell = "`spells'"							// If years comparable, keep spell			
	}	// if
	if "`spell'" == "" {
		noi dis as error "Last spell is not comparable"
		error 1
	}
	local keepyears : list uniq spell
	// Trimming
	if "`trim'" ~= "" {
		tokenize `trim'
		if missing("`2'") {
			noi dis as error "Trimming option needs 2 values, such as trim(5 95)"
			error 1
		}
	}
	else if "`trim'" == "" {
		local trim = "3 97"
		noi di in yellow "Default trimming below 3rd and above 97th percentile applied"
	}
	// Figure 
	qui levelsof `by', local(count)
	local groups = `=`:word count `count''+1'
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")						//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)

	//trigger some sub-tables
	qui {		
		//Weights
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		}
	
		//missing observation check
		marksample touse
		local flist `"`wvar' `welfare' `by' `year'"'
		markout `touse' `flist' 
		
		tempfile dataori datalbl
		save `dataori', replace
		
		levelsof `year' if `touse', local(yrlist)
		local same : list keepyears in yrlist
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
		levelsof `year' if `touse', local(yrlist)
		
		clear
		tempfile data2
		save `data2', replace emptyok
		
		foreach byvar of local by {
			use `dataori', clear			
			levelsof `byvar', local(byvlist)
			local lbl`byvar' : variable label `byvar'				
			local label1 : value label `byvar'
			
			foreach lvl of local byvlist {				
				local lvl`byvar'_`lvl' : label `label1' `lvl'				
				foreach yr of local yrlist {
					use `dataori', clear
					tempvar qwlf
					cap _ebin `welfare' [aw=`wvar'] if `touse' & `year'==`yr' & `byvar'==`lvl', nquantiles(100) gen(`qwlf')
					if _rc!=0 {
						noi di in red "Error in creating percentile for `byvar'==`lvl'"						
						exit `=_rc'
					} 
					else {												
						collapse (mean) `welfare' [aw=`wvar'] if `touse' & `year'==`yr' & `byvar'==`lvl', by(`qwlf')
						ren `qwlf' percentile
						gen year = `yr'
						gen var = "`byvar'"
						gen var_lvl = `lvl'
						append using `data2'
						save `data2', replace
					}					
				}
			}	
		}
		use `data2', clear
		reshape wide `welfare', i(var var_lvl percentile) j(`year')
		
		//label var and group keeping original ordering 
		local i=1
		local j=1
		gen var_order = .
		gen group_order = .
		foreach var1 of local by {
			replace var_order =`j' if var=="`var1'"
			la def var_order `j' "`lbl`var1''", add
			local j = `j'+1
			levelsof var_lvl if var=="`var1'", local(grplvl)
			foreach lv of local grplvl {
				replace group_order = `i' if var=="`var1'" & var_lvl==`lv'
				la def group_order `i' "`lvl`var1'_`lv''", add
				local i = `i' + 1
			}
		}
		la val var_order var_order
		la val group_order group_order
				
		tokenize "`spell'"
		if "`1'"~="" & "`2'"~="" {
			dis "Spell: `1'-`2'"		
			gen gic_`1'_`2' = ((`welfare'`2'/`welfare'`1')^(1/(`2'-`1'))-1)*100
			local vargic "`vargic' gic_`1'_`2'"
			la var gic_`1'_`2' "GIC Spell: `1'-`2'"
			local varlbl "`1'-`2'"
		}
		// Trim sample
		tokenize "`trim'"
		drop if percentile < `1'
		drop if percentile > `2'

		sort var_order group_order percentile
		return local vargic = "`vargic'"
		return local varlbl = `"`varlbl'"'
				
		//Axis range
		if "`yrange'" == "" {
			sum `vargic'
			if `r(min)' < 0 local ymin = floor(`r(min)')
			else local ymin = 0
			if `r(max)' > 0 local ymax = ceil(`r(max)')
			else local ymax = 0
			local yrange "ylabel(`ymin'(1)`ymax')"
		}
		else {
			local yrange "ylabel(`yrange')"
		}
		
	
		//Figure preparation
		local figname Figure3
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
		
		//Figure
		if "`core'" == "" local fnum "3b"
		else if "`core'" ~= "" local fnum "A.1" 
		putexcel set "`excelout2'", `act'
		
		levelsof group_order, local(grlist)

		foreach i of local grlist {
			local connected`i' `"connected `vargic' percentile if group_order== `i', lcolor("${col`i'}") mcolor("${col`i'}") ||"'
			local connected "`connected' `connected`i''"
			local label_`i': label(group_order) `i'
			local legend`i' `"`i' "`label_`i''""'
			local legend "`legend' `legend`i''"	
		}	
		
			tempfile graph`gr'
			local lbltitle : label group_order `gr'	
			
			twoway `connected' , yline(0, lp(-) lc(black*0.6))											///
					legend(order("`legend'") rows(1) size(medium) position(6)) 				    ///
					xtitle(Percentile, size(medium)) `yrange'									///
					ytitle("Annualized growth `varlbl' (%)", size(medium)) 						///
					name(ngraph`gr', replace)
			
			putexcel set "`excelout2'", modify sheet(Figure`fnum', replace)
			graph export "`graph`gr''", replace as(png) name(ngraph`gr') wid(1500)
			putexcel A`u' = image("`graph`gr''")
			
			putexcel A1 = ""
			putexcel A2 = "Figure `fnum': Growth Incidence Curves"
			putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
			putexcel A4 = "Note: Growth incidence curves display annualized household growth in per capita consumption or income by percentile of the welfare distribution between two periods. Growth incidence curves are only shown for years with comparable surveys, and the latest specified spell. Percentiles are trimmed below `1' and above `2'."
			
			putexcel O10 = "Data:"
			putexcel O6	= "Code:"
			putexcel O7 = `"twoway `connected', yline(0, lp(-) lc(black*0.6)) legend(order("`legend'") rows(1) size(medium) position(6)) xtitle(Percentile, size(medium)) `yrange' ytitle("Annualized growth `varlbl' (%)", size(medium))"'
			if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
			putexcel save
		cap graph close	
	} //qui	
	
	// Export data
	export excel * using "`excelout2'", sheet("Figure`fnum'", modify) cell(O11) keepcellfmt firstrow(variables)	
		
	if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"	
end