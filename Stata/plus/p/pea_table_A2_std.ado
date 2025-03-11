*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 

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

//Table 2 and 3. Core poverty indicators - test

cap program drop pea_table_A2_std
program pea_table_A2_std, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) FGTVARS using(string) Year(varname numeric) byind(varlist numeric) CORE setting(string) LINESORTED excel(string) save(string) age(varname numeric) male(varname numeric) edu(varname numeric) MISSING]
	
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
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
	
	qui {
		if "`missing'"~="" { //show missing
			foreach var of varlist `byind' `male' `edu' {
				su `var'
				local miss = r(max)
				replace `var' = `=`miss'+10' if `var'==.
				local varlbl : value label `var'
				la def `varlbl' `=`miss'+10' "Missing", add
			}
		}
	
		//order the lines (assume one pline is used)
		su `ppppovlines',d
		if `=r(sd)'==0 local lbloneline: display %9.2f `=r(mean)'				
		else local lbloneline `oneline'	
		local lbloneline `=trim("`lbloneline'")'
		
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
		local flist `"`wvar' `natwelfare' `natpovlines' `pppwelfare' `ppppovlines' `year' `byind' `age'"'
		markout `touse' `flist' 
		
		tempfile dataori datalbl
		save `dataori', replace
		des, replace clear
		save `datalbl', replace
		use `dataori', clear
	} //qui
	
	if "`fgtvars'"=="" { //only create when the fgt are not defined			
		//FGT
		if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
		if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
		gen double _pop = `wvar'
	}
	
	//variable checks
	if "`age'"!="" {
		su `age',d
		if r(N)>0 {
			gen agecatind = 1 if `age'>=0 & `age'<=14
			replace agecatind = 2 if `age'>=15 & `age'<=64
			replace agecatind = 3 if `age'>=65 & !missing(`age')
			la def agecatind 1 "Children (less than age 15)" 2 "Adults (age 15 to 64)" 3 "Elderly (age 65 and older)" 
			la val agecatind agecatind
			la var agecatind "By age group"
			clonevar _eduXind = `edu' if `age'>=16 & !missing(`age')
			la var _eduXind "By education (age 16+)"				
		} //rn
	} //age
	
	//trigger some sub-tables
	tempfile data1 data2 data2a data2b
	save `data1', replace
	clear
	save `data2', replace emptyok
	save `data2a', replace emptyok
	
	//FGT
	local byind agecatind `male' _eduXind `byind'
	foreach var of local byind {
		use `data1', clear
		local lbl0`var' : variable label `var'
		if "`lbl0`var''"=="" local lbl0`var' "`var'"
		groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) rawsum(_pop) by(`year' `var')
		ren `var' lbl`var'
		append using `data2'
		save `data2', replace
	}
	s
	/*
	//standard errors
	use `data1', clear
	noi dis "`byind'"
	
	levelsof `year', local(datalist)
	qui foreach dat of local datalist {
		use `data1', clear
		keep if `year'==`dat'
		tempvar single		
		svydescribe, gen(`single')
		drop if `single'==1
		save `data2b', replace
		foreach var of local byind {
			use `data2b', clear
			local lbl0`var' : variable label `var'
			svy: mean _fgt*   if `touse'
			
		}
	}
	*/
	//combine labels into one column, keep original sorts
	gen combined_var = .
	gen group = .
	local j=1
	local i=1
	*label define combined_label
	foreach var of local byind {
		replace group = `j' if lbl`var'	~=.
		la def group `j' "`lbl0`var''", add
		local label1 : value label lbl`var'		
		levelsof lbl`var', local(levels1)
		
		foreach l1 of local levels1 {
			local labelname1 : label `label1' `l1'
			label define combined_label `i' "`labelname1'", add
			replace combined_var = `i' if lbl`var'==`l1'
			local i = `i'+1
		}
		drop lbl`var'
		local j = `j'+1
	}	
	label values combined_var combined_label
	label val group group
	
	reshape long _fgt0_ _fgt1_ _fgt2_ , i(`year' _pop combined_var group) j(_varname) string
	split _varname, parse("_")
	drop _varname1
	gen npoor = _fgt0_*_pop
	replace _fgt0_ = _fgt0_*100
	bys `year' _varname group (combined_var): egen totpoor = total(npoor)
	gen double share_poor = (npoor/totpoor)*100
	 
	gen indicatorlbl = .
	local i = 1
	if "`ppppovlines'"~="" {
		foreach var of local ppppovlines {
			replace indicatorlbl = `i' if _varname2=="`var'"
			la def indicatorlbl `i' "`lbl`var''", add
			local i = `i' + 1
		}
	}
	
	if "`natpovlines'"~="" {
		foreach var of local natpovlines {
			replace indicatorlbl = `i' if _varname2=="`var'"
			la def indicatorlbl `i' "`lbl`var''", add
			local i = `i' + 1
		}
	}
	la val indicatorlbl indicatorlbl
	
	su npoor 
	local xmin = r(min)
	local xmax = r(max)
	if `xmin' < 1000000 {
		local xscale 1000
		local xtxt "(in thousands)"
	}
	else {
		local xscale 1000000
		local xtxt "(in millions)"
	}
	replace npoor = npoor/`xscale' 
	la var _fgt0_ "Poverty rate"
	la var npoor "Number of poor `xtxt'"
	la var share_poor "Share of poor"
	
	keep `year' combined_var _fgt0_ npoor share_poor indicatorlbl group

	ren _fgt0_ value1
	ren share_poor value2
	ren npoor value3

	reshape long value, i( `year' combined_var indicatorlbl group) j(ind)
	la def ind 1 "Poverty rate" 2 "Share of poor" 3 "Number of poor `xtxt'"
	la val ind ind
	drop if group==.
	drop if ind==2
	
	collect clear
	qui collect: table ( group combined_var) (ind `year') (indicatorlbl), stat(mean value) nototal nformat(%20.2f) missing
	collect style header indicatorlbl group combined_var ind `year', title(hide)
	*collect style header subind[.], level(hide)
	*collect style cell, result halign(center)
	collect title `"Table A.2. Poverty indicators by subgroup"'
	collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
	collect notes 2: `"Note: Poverty rates are reported for the $`lbloneline' per person per day poverty line, expressed in 2017 purchasing power parity dollars."'
	collect style notes, font(, italic size(10))
		
	if "`excel'"=="" {
		collect export "`dirpath'\\TableA2.xlsx", sheet(TableA2) replace 	
		shell start excel "`dirpath'\\TableA2.xlsx"
	}
	else {
		collect export "`excelout'", sheet(TableA2, replace) modify 
	}
end