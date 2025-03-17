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

//Table 2 and 3. Core poverty indicators

cap program drop pea_table3
program pea_table3, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) FGTVARS using(string) Year(varname numeric) CORE setting(string) LINESORTED excel(string) save(string) MISSING age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) minobs(numlist) PPPyear(integer 2017)]
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	//house cleaning
	_pea_export_path, excel("`excel'")
	
	if "`missing'"~="" { //show missing
		foreach var of varlist `male' `hhhead' `edu' {
			su `var'
			local miss = r(max)
			replace `var' = `=`miss'+10' if `var'==.
			local varlbl : value label `var'
			la def `varlbl' `=`miss'+10' "Missing", add
		}
	}

	if "`minobs'"~="" { 
		local note_minobs "Cells with less than `minobs' observations are dropped."
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
		local flist `"`wvar' `natwelfare' `natpovlines' `pppwelfare' `ppppovlines' `year' `byind' `age'"'
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
	if "`age'"!="" {
		su `age',d
		if r(N)>0 {
			gen agecatind = 1 if `age'>=0 & `age'<=14
			replace agecatind = 2 if `age'>=15 & `age'<=29
			replace agecatind = 3 if `age'>=65 & `age'<=.
			qui sum agecatind
			local agemax = `r(max)'
			clonevar _eduXind = `edu' if `age'>=16 & `age'~=.
			
			if "`hhhead'"~="" {
				gen agecathead = 1 if `age'>=18 & `age'<=34 & `hhhead'==1
				replace agecathead = 2 if `age'>=35 & `age'<=49 & `hhhead'==1
				replace agecathead = 2 if `age'>=50 & `age'<=64 & `hhhead'==1
				replace agecathead = 3 if `age'>=65 & `age'<=. & `hhhead'==1
				la def agecathead 1 "18-34" 2 "35-49" 3 "50-64" 4 "65+"
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
				gen count = 1
				groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) count(count) rawsum(_pop) by(`year' agecatind)
				gen _group = `i'			
				la def _group `i' "`lbllvl'", add
				la val _group _group
				tempfile labelx`i'
				label save _group using `labelx`i''
				la drop _group
				append using `data2'
				save `data2', replace
				* Add totals
				use `data1', clear
				keep if `var'==`lvl'
				local lbllvl : label `label1' `lvl'			
				groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) rawsum(_pop) by(`year')
				gen agecatind = `=`agemax'+1'
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
		sort _group year agecat
		la def agecatind 1 "Age 0-14" 2 "Age 15-64" 3 "Age 65+" 4 "All"
		la val agecatind agecatind
			
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
		drop if agecatind==.		
		if ("`minobs'" ~= "") {
			decode agecatind, gen(_agecatind_str)			
			replace _fgt0_ = . if count < `minobs' & agecatind_str ~= "Missing"
		}
		collect clear
		qui collect: table (indicatorlbl agecatind) (_group) if `year'==`ymax', stat(mean _fgt0_) nototal nformat(%20.1f) missing
		collect style header indicatorlbl agecatind _group `year', title(hide)		
		collect title `"Table 3a. Subgroup poverty rates by gender and age-group (`ymax', %)"'
		collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
		collect notes 2: `"Note: Poverty rates are reported for the per person per day poverty lines, expressed in `pppyear' purchasing power parity dollars. These three poverty lines reflect the typical national poverty lines of low-income countries, lower-middle-income countries, and upper-middle-income countries, respectively. National poverty lines are expressed in local currency units (LCU). `note_minobs'"'
		
		collect style cell indicatorlbl[1 2 3 4]#cell_type[row-header], font(, bold)
		collect style cell agecatind[]#cell_type[row-header], warn font(, nobold)
		_pea_tbtformat
		_pea_tbt_export, filename(Table3) tbtname(Table3a) excel("`excel'") dirpath("`dirpath'") excelout("`excelout'")				
	}
	
	//Table 3b - FGT individual educat
	{
		clear
		save `data2', replace emptyok
		use `data1', clear
		drop if `age'<16
		gen count = 1
		groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) count(count) rawsum(_pop) by(`year' _eduXind)
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
		drop if _eduXind==.		
		if ("`minobs'" ~= "") {
			decode _eduXind, gen(_eduXind_str)			
			replace _fgt0_ = . if count < `minobs' & _eduXind_str ~= "Missing"
		}
		collect clear
		qui collect: table (indicatorlbl _eduXind) (`year'), stat(mean _fgt0_) nototal nformat(%20.1f) missing
		collect style header indicatorlbl _eduXind `year', title(hide)
		
		collect title `"Table 3b. Subgroup poverty rates by education (age 16+, %)"'
		collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
		collect notes 2: `"Note: Poverty rates reported for individuals, age 16 or older. Poverty rates are reported for the per person per day poverty lines, expressed in `pppyear' purchasing power parity dollars. These three poverty lines reflect the typical national poverty lines of low-income countries, lower-middle-income countries, and upper-middle-income countries, respectively. National poverty lines are expressed in local currency units (LCU). Education level refers to the highest level attended, complete or incomplete. `note_minobs'"'
		
		collect style cell indicatorlbl[1 2 3 4]#cell_type[row-header], font(, bold)
		collect style cell _eduXind[]#cell_type[row-header], warn font(, nobold)
		_pea_tbtformat
		_pea_tbt_export, filename(Table3) tbtname(Table3b) excel("`excel'") dirpath("`dirpath'") excelout("`excelout'")	modify		
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
			gen count = 1
			groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) count(count) rawsum(_pop) by(`year' `var')			
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
		if ("`minobs'" ~= "") {
			decode combined_var, gen(combined_var_str)			
			replace _fgt0_ = . if count < `minobs' & combined_var_str ~= "Missing"
		}
		
		collect clear
		qui collect: table (group  combined_var) (indicatorlbl `year'), stat(mean _fgt0_) nototal nformat(%20.1f) missing
		collect style header group indicatorlbl combined_var `year', title(hide)
		
		collect title `"Table 3c. Subgroup poverty rates of household head (%)"'
		collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
		collect notes 2: `"Note: Poverty rates reported for household heads 18 or older. Poverty rates are reported for the per person per day poverty lines, expressed in `pppyear' purchasing power parity dollars. These three poverty lines reflect the typical national poverty lines of low-income countries, lower-middle-income countries, and upper-middle-income countries, respectively. National poverty lines are expressed in local currency units (LCU). `note_minobs'"'
		
		collect style cell group[]#cell_type[row-header], font(, bold)
		collect style cell indicatorlbl[1 2 3 4]#cell_type[row-header], font(, bold)
		collect style cell combined_var[]#cell_type[row-header], warn font(, nobold)
		_pea_tbtformat
		_pea_tbt_export, filename(Table3) tbtname(Table3c) excel("`excel'") dirpath("`dirpath'") excelout("`excelout'")	shell modify
	} //3c
end 