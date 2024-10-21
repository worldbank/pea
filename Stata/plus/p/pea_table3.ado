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

cap program drop pea_table3
program pea_table3, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) fgtvars using(string) Year(varname numeric) core setting(string) linesorted excel(string) save(string) missing age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric)]
	
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
		local flist `"`wvar' `natwelfare' `natpovlines' `pppwelfare' `ppppovlines' `year' `byind'"'
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
			replace agecatind = 2 if `age'>=15 & `age'<=29
			replace agecatind = 3 if `age'>=30 & `age'<=44
			replace agecatind = 4 if `age'>=45 & `age'<=59
			replace agecatind = 5 if `age'>=60 & `age'<=.
			la def agecatind 1 "Age 0-14" 2 "Age 15-29" 3 "Age 30-44" 4 "Age 45-59" 5 "Age 60+"
			la val agecatind agecatind
			
			clonevar _eduXind = `edu' if `age'>=16 & `age'~=.
			
			if "`hhhead'"~="" {
				gen agecathead = 1 if `age'>=18 & `age'<=29 & `hhhead'==1
				replace agecathead = 2 if `age'>=39 & `age'<=54 & `hhhead'==1
				replace agecathead = 3 if `age'>=55 & `age'<=. & `hhhead'==1
				la def agecathead 1 "18-29" 2 "39-54" 3 "55+"
				la val agecathead agecathead
				la var agecathead "By age group of household head"
				clonevar _eduXhh = `edu' if `hhhead'==1 & `age'>=18 & `age'~=.
				clonevar _maleXhh = `male' if `hhhead'==1 & `age'>=18 & `age'~=.
				la var _eduXhh "By education of household head"
				la var _maleXhh "By gender of household head"
			} //head		
		} //rn
	} //age
	
	gen _total = 1
	la def _total 1 "Total"
	la val _total _total
	
	//trigger some sub-tables
	tempfile data1 data2
	save `data1', replace
	clear
	save `data2', replace emptyok
	
	//Table 3a - FGT individual agecatind
	{
		use `data1', clear
		local byind `male' _total
		local i = 1
		//agecatind _eduXind
		foreach var of local byind {
			use `data1', clear
			levelsof `var', local(lclist)
			local label1 : value label `var'		
			foreach lvl of local lclist {
				use `data1', clear
				keep if `var'==`lvl'
				local lbllvl : label `label1' `lvl'			
				groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) rawsum(_pop) by(`year' agecatind)
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
		la val _group _group
		reshape long _fgt0_ _fgt1_ _fgt2_, i(`year' agecatind _group _pop) j(_varname) string
		split _varname, parse("_")
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
		replace _fgt0_ = _fgt0_*100
		su `year',d
		local ymax = r(max)
		
		collect clear
		qui collect: table (indicatorlbl agecatind) (_group) if `year'==`ymax', stat(mean _fgt0_) nototal nformat(%20.2f) missing
		collect style header indicatorlbl agecatind _group `year', title(hide)
		*collect style header subind[.], level(hide)
		*collect style cell, result halign(center)
		collect title `"Table 3a. Subgroup poverty rates (`ymax')"'
		collect notes 1: `"Source: ABC"'
		collect notes 2: `"Note: The global ..."'
		collect style notes, font(, italic size(10))
		*collect preview
		*set trace on
		
		if "`excel'"=="" {
			collect export "`dirpath'\\Table3.xlsx", sheet(Table3a) replace 	
			*shell start excel "`dirpath'\\Table3.xlsx"
		}
		else {
			collect export "`excelout'", sheet(Table3a, replace) modify 
		}
	}
	
	//Table 3b - FGT individual educat
	{
		clear
		save `data2', replace emptyok
		use `data1', clear
		drop if `age'<16
		groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) rawsum(_pop) by(`year' _eduXind)
		reshape long _fgt0_ _fgt1_ _fgt2_, i(`year' _eduXind _pop) j(_varname) string
		split _varname, parse("_")
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
		replace _fgt0_ = _fgt0_*100
		
		collect clear
		qui collect: table (indicatorlbl _eduXind) (`year'), stat(mean _fgt0_) nototal nformat(%20.2f) missing
		collect style header indicatorlbl _eduXind `year', title(hide)
		*collect style header subind[.], level(hide)
		*collect style cell, result halign(center)
		collect title `"Table 3b. Subgroup poverty rates (age 16+)"'
		collect notes 1: `"Source: ABC"'
		collect notes 2: `"Note: The global ..."'
		collect style notes, font(, italic size(10))
			
		if "`excel'"=="" {
			collect export "`dirpath'\\Table3.xlsx", sheet(Table3b) modify 	
			*shell start excel "`dirpath'\\Table3.xlsx"
		}
		else {
			collect export "`excelout'", sheet(Table3b, replace) modify 
		}
	} //3b
	
	//Table 3c - FGT HH head agecat male educat
	{	
		clear
		save `data2', replace emptyok
		local byind agecathead _maleXhh _eduXhh  
		
		foreach var of local byind {
		use `data1', clear
			keep if `hhhead'==1
			drop if `age'<18
			local lbl0`var' : variable label `var'
			if "`lbl0`var''"=="" local lbl0`var' "`var'"
			groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) rawsum(_pop) by(`year' `var')
			*gen vsd = "`var'"
			ren `var' lbl`var'
			append using `data2'
			save `data2', replace
		}
		
		//combine labels into one column, keep original sorts
		gen combined_var = .
		gen group = .
		local j=1
		local i=1		
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
		replace _fgt0_ = _fgt0_*100
				 
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
		drop if group==.
		
		collect clear
		qui collect: table (group indicatorlbl combined_var) (`year'), stat(mean _fgt0_) nototal nformat(%20.2f) missing
		collect style header group indicatorlbl combined_var `year', title(hide)
		*collect style header subind[.], level(hide)
		*collect style cell, result halign(center)
		collect title `"Table 3c. Subgroup poverty rates of household head"'
		collect notes 1: `"Source: ABC"'
		collect notes 2: `"Note: The global ..."'
		collect style notes, font(, italic size(10))
			
		if "`excel'"=="" {
			collect export "`dirpath'\\Table3.xlsx", sheet(Table3c) modify 	
			shell start excel "`dirpath'\\Table3.xlsx"
		}
		else {
			collect export "`excelout'", sheet(Table3c, replace) modify 
		}
		
	} //3c
		
end 