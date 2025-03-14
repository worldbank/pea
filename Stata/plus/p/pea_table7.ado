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

//Table 7. Vulnerability to poverty

cap program drop pea_table7
program pea_table7, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Welfare(varname numeric) Povlines(varname numeric) Year(varname numeric) CORE age(varname numeric) edu(varname numeric) male(varname numeric) VULnerability(real 1.5) setting(string) excel(string) save(string) MISSING PPPyear(integer 2017)]
	
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
		//order the lines
		local lbl`povlines' : variable label `povlines'		
		
		//Weights
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		}
		
		if "`welfare'"~="" { //reset to the floor
			replace `welfare' = ${floor_} if `welfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
	
		//missing observation check
		marksample touse
		local flist `"`wvar' `welfare' `povlines' `year'"'		
		markout `touse' `flist' 
		
	} //qui
	
	//FGT
	gen _All = 1
	label define laball 1 "All sample"
	label values _All laball
	if "`core'"=="" {
		gen _vulpov_`welfare'_`povlines' = (`welfare' < `vulnerability'*`povlines') if `welfare'~=. & `touse'
		gen double _pop = `wvar'
	}
	//trigger some sub-tables
	tempfile data1 data2
	save `data1', replace
	clear
	save `data2', replace emptyok
	
	//FGT
	local byind _All `male' `agevar' `eduvar'
	foreach var of local byind {
		use `data1', clear
		gen count = 1
		groupfunction  [aw=`wvar'] if `touse', mean(_vulpov_`welfare'_`povlines') count(count) rawsum(_pop) by(`year' `var')
		ren `var' lbl`var'
		gen _variable = "`var'"
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
	ren _vulpov_`welfare'_`povlines' _fgt0_
	gen npoor = _fgt0_*_pop
	replace _fgt0_ = _fgt0_*100
	drop if group==.
	bys `year' _variable group (combined_var): egen totpoor = total(npoor)
	gen double share_poor = (npoor/totpoor)*100
	replace share_poor = . if _variable == "_All"
	
	gen indicatorlbl = 1
	la def indicatorlbl 1 "Population below 1.5* `lbl`povlines''" 
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
	ren _fgt0_ value1
	ren share_poor value2
	ren npoor value3
	
	ren group group2
	gen group = .
	replace group = 1 if _variable == "_All"
	replace group = 2 if _variable == "`male'"
	replace group = 3 if _variable == "_eduXind"
	replace group = 4 if _variable == "agecatind"
	la def group 1 "All sample" 2 "By gender" 3 "By educational attainment (16+)" 4 "By age"
	la val group group	
	sort group `year'
	
	keep `year' combined_var value* indicatorlbl count group _variable

	reshape long value, i( `year' group combined_var indicatorlbl _variable) j(ind)
	la def ind 1 "Poverty rate (%)" 2 "Share of poor (%)" 3 "Number of poor `xtxt'"
	la val ind ind
	
	local milab : value label combined_var
	if ("`minobs'" ~= "") replace value = . if count < `minobs' & combined_var ~= "Missing":`milab'
	
	collect clear
	qui collect: table (group combined_var) (ind `year'), stat(mean value) nototal nformat(%20.1f) missing
	collect style header group combined_var ind `year', title(hide)	
	collect style header combined_var[1], level(hide)
	collect title `"Table 7. Vulnerability to poverty (1.5* `lbl`povlines'')"'
	collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
	collect notes 2: `"Note: Vulnerability to poverty is defined as `vulnerability' times the `lbl`povlines''. All individual are used in the sample. Poverty statistics by educational attainment are only calculated for those aged 16 and above. `note_minobs'"'
		
	collect style notes, font(, italic size(10))
	collect style cell group[]#cell_type[row-header], font(, bold)
	collect style cell combined_var[]#cell_type[row-header], warn font(, nobold)
	collect style cell, shading( background(white) )	
	collect style cell cell_type[corner], shading( background(lightskyblue) )
	collect style cell cell_type[column-header corner], font(, bold) shading( background(seashell) )
	collect style cell cell_type[item],  halign(center)
	collect style cell cell_type[column-header], halign(center)	

	if "`excel'"=="" {
		collect export "`dirpath'\\Table7.xlsx", sheet(Table7) replace 	
		shell start excel "`dirpath'\\Table7.xlsx"
	}
	else {
		collect export "`excelout'", sheet(Table7, replace) modify 
		putexcel set "`excelout'", modify sheet("Table7")		
		putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")	
		qui putexcel save
	}
end