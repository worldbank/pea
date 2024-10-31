*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 
*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Sandra Carolina Segovia Juarez <ssegoviajuarez@worldbank.org>
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

//Table 13. Decomposition of poverty changes: Huppi-Ravallion decomposition				

cap program drop pea_table13
program pea_table13, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) spells(string) Year(varname numeric) urban(varname numeric) CORE LINESORTED setting(string) NOOUTPUT excel(string) save(string) MISSING GRAPH]

	//load data if defined
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}
	if "`urban'"=="" {
		noi di in red "Sector/urban variable must be define in urban()"
		exit 1
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
		//order the lines
		if "`linesorted'"=="" {
			if "`ppppovlines'"~="" {
				_pea_pline_order, povlines(`ppppovlines')
				//sorted_pppline
				local ppppovlines `=r(sorted_line)'
				foreach var of local ppppovlines {
					local lbl`var' `=r(lbl`var')'
				}
			}
			
			if "`natpovlines'"~="" {
				_pea_pline_order, povlines(`natpovlines')
				//sorted_natline
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
		local flist `"`wvar' `welfare' `by' `year'"'
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
		
		cap frame create temp_frame
		cap frame change temp_frame
		cap frame drop decomp_results2	
		frame create decomp_results2 strL(decomp spell povline) float(value1 value2 value3 value4 value5)
							  		
		forv j=1(1)`=`a'-1' {
			local spell`j' : list sort spell`j'
			tokenize "`spell`j''"
			if "`1'"~="" & "`2'"~="" {
				dis "Spell`j': `1'-`2'"	
				tempfile data_y2
				use `dataori' if `year'==`2', clear
				save `data_y2', replace
				foreach var of local ppppovlines {
					//Huppi-Ravallion decomposition
					use `dataori' if `year'==`1', clear					
					sedecomposition using `data_y2' [aw=`wvar'], sector(`urban') pline1(`var') pline2(`var') var1(`pppwelfare') var2(`pppwelfare') hc
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
				}
				foreach var of local natpovlines {
					//Huppi-Ravallion decomposition
					use `dataori' if `year'==`1', clear					
					sedecomposition using `data_y2' [aw=`wvar'], sector(`urban') pline1(`var') pline2(`var') var1(`natwelfare') var2(`natwelfare') hc
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
		if "`ppppovlines'"~="" {
			foreach var of local ppppovlines {
				replace indicatorlbl = `i' if povline=="`var'"
				la def indicatorlbl `i' "`lbl`var''", add
				local i = `i' + 1
			}
		}
		
		if "`natpovlines'"~="" {
			foreach var of local natpovlines {
				replace indicatorlbl = `i' if povline=="`var'"
				la def indicatorlbl `i' "`lbl`var''", add
				local i = `i' + 1
			}
		}
		la val indicatorlbl indicatorlbl
		drop if indicatorlbl==.
		
		if "`nooutput'"~="" {
			save `save', replace
		}
		else {			
			collect clear
			qui collect: table ( indicatorlbl subind) ( spell) if decomp=="Huppi-Ravallion", statistic(mean value) nototal nformat(%20.2f) missing
			collect style header indicatorlbl subind spell, title(hide)
			*collect style header value[.], level(hide)
			collect title `"Table 13. Decomposition of poverty changes: Huppi-Ravallion decomposition"'
			collect notes 1: `"Source: ABC"'
			collect notes 2: `"Note: The global ..."'
			collect style notes, font(, italic size(10))
			*collect preview
				
			local tabname Table13
			if "`excel'"=="" {
				collect export "`dirpath'\\Table13.xlsx", sheet("`tabname'") replace 	
				shell start excel "`dirpath'\\Table13.xlsx"
			}
			else {
				collect export "`excelout'", sheet("`tabname'", replace) modify 
			}
		}
	} //qui
end