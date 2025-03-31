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

//Table 2. Core poverty indicators

cap program drop pea_table2
program pea_table2, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) FGTVARS using(string) Year(varname numeric) byind(varlist numeric) minobs(numlist) CORE setting(string) LINESORTED excel(string) save(string) MISSING PPPyear(integer 2017) SVY std(string)]
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}
	
	//house cleaning
	_pea_export_path, excel("`excel'")
	
	if "`missing'"~="" { //show missing
		foreach var of local byind {
			su `var'
			local max_`var' = r(max) + 10			
			replace `var' = `max_`var'' if `var'==.
			local varlbl : value label `var'
			la def `varlbl' `max_`var'' "Missing", add
			la values `var' `varlbl'
		}
	}

	if "`minobs'"~="" local note_minobs "Cells with less than `minobs' observations are dropped."
	
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
		
		foreach var of local byind {
			local lbl2`var' : variable label `var'
		}
		
		//SVY setting
		local svycheck = 0
		if "`svy'"~="" _pea_svycheck, std(`std')
		
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
		if "`pppwelfare'"~="" { //reset to the floor
			replace `pppwelfare' = ${floor_} if `pppwelfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
		
		//FGT
		if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
		if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
		gen double _pop = `wvar'
	}
	
	//variable checks
	//trigger some sub-tables
	tempfile data1 data2
	save `data1', replace
	clear
	save `data2', replace emptyok
	
	//FGT
	foreach var of local byind {
		use `data1', clear
		gen count = 1
		groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) count(count) rawsum(_pop) by(`year' `var')
		gen varname = "`var'"
		ren `var' lbl`var'
		append using `data2'
		save `data2', replace
	}
	
	//combine labels into one column, keep original sorts
	gen combined_var = .
	gen group = .
	local j=1
	local i=1
	*label define combined_label
	foreach var of local byind {
		*local lbl2`var' : variable label `var'
		replace group = `j' if lbl`var'	~=.
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
	reshape long _fgt0_ _fgt1_ _fgt2_ , i(`year' _pop combined_var group varname) j(_varname) string
	
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
	
	keep `year' combined_var _fgt0_ npoor share_poor indicatorlbl count varname

	ren _fgt0_ value1
	ren share_poor value2
	ren npoor value3

	reshape long value, i( `year' combined_var indicatorlbl varname) j(ind)
	la def ind 1 "Poverty rate (%)" 2 "Share of poor (%)" 3 "Number of poor `xtxt'"
	la val ind ind
	
	gen varlbl = .
	local i = 1
	foreach var of local byind {
		replace varlbl = `i' if varname=="`var'"
		la def varlbl `i' "`lbl2`var''", add
		local i = `i' + 1
	}
	la val varlbl varlbl
	
	if ("`minobs'" ~= "") {
		decode combined_var, gen(combined_var_str)
		replace value = . if count < `minobs' & combined_var_str ~= "Missing"
	}
	
	collect clear
	qui collect: table (indicatorlbl varlbl combined_var) (ind `year'), stat(mean value) nototal nformat(%20.1f) missing
	collect style header varlbl indicatorlbl combined_var ind `year', title(hide)	
	collect title `"Table 2. Core poverty indicators by geographic areas"'
	collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
	collect notes 2: `"Note: Poverty rates are reported for the per person per day poverty lines, expressed in `pppyear' purchasing power parity dollars. These three poverty lines reflect the typical national poverty lines of low-income countries, lower-middle-income countries, and upper-middle-income countries, respectively. National poverty lines are expressed in local currency units (LCU). `note_minobs'"'
	
	collect style cell indicatorlbl[]#cell_type[row-header], font(, bold)
	collect style cell varlbl[]#cell_type[row-header], font(, nobold italic)
	collect style cell combined_var[]#cell_type[row-header], warn font(, nobold noitalic)
	
	_pea_tbtformat
	_pea_tbt_export, filename(Table2) tbtname(Table2) excel("`excel'") dirpath("`dirpath'") excelout("`excelout'") shell
end