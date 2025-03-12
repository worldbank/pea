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
	syntax [if] [in] [aw pw fw], [Welfare(varname numeric) Povlines(varname numeric) Year(varname numeric) CORE age(varname numeric) edu(varname numeric) male(varname numeric) VULnerability(string) setting(string) excel(string) save(string) MISSING]
	
	//load data if defined
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}
	
	if "`save'"=="" tempfile saveout
	
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
	
	if "`vulnerability'"=="" {
		local vulnerability = 1.5
		noi di in yellow "Default multiple of poverty line to define vulnerability is 1.5"
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
			la var agecatind "Age categories"
			clonevar _eduXind = `edu' if `age'>=16 & `age'~=.
		}
	}
	// Shorten value labels 
    local lbl: value label `edu'
	if "`lbl'" == "educat4" {
		label define educat4_m 1 "No education" 2 "Primary" 3 "Secondary" 4 "Tertiary"
		label values _eduXind educat4_m
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
	
		//missing observation check
		marksample touse
		local flist `"`wvar' `welfare' `povlines' `year'"'
		markout `touse' `flist' 
		
	} //qui
	
	//FGT
	gen _All = 1
	label define laball 1 " "
	label values _All laball
	gen _vulpov_`welfare'_`povlines' = (`welfare' < `vulnerability'*`povlines') if `welfare'~=. & `touse'
	gen double _pop1 = `wvar'

	//trigger some sub-tables
	tempfile data1 data2
	save `data1', replace
	clear
	save `data2', replace emptyok
	
	//FGT
	foreach var in _All `male' agecatind _eduXind  {
		use `data1', clear
		gen count = 1
		groupfunction  [aw=`wvar'] if `touse', mean(_vulpov_`welfare'_`povlines') count(count) rawsum(_pop1) by(`year' `var')
		decode `var', gen(lbl`var')
		drop `var'
		gen variable = "`var'"
		append using `data2'
		save `data2', replace
	}
	
	clonevar name = variable
	ren _vulpov_`welfare'_`povlines' var_
	gen npoor = var_*_pop1
	bys `year' name: egen totpoor = total(npoor)
	gen double share_poor = (npoor/totpoor)*100
	replace var_ = var_*100
	replace share_poor = . if name == "_All"
	
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
	ren var_ value1
	ren share_poor value2
	ren npoor value3
	
	replace lbl_All = lbl_eduXind if lbl_All == ""
	replace lbl_All = lblmale if lbl_All == ""
	replace lbl_All = lblagecatind if lbl_All == ""
	
	gen indicatorlbl = 1
	la def indicatorlbl 1 "Population below 1.5* `lbl`povlines''" 
	la val indicatorlbl indicatorlbl
	drop if indicatorlbl==.
	gen group = .
	replace group = 1 if name == "_All"
	replace group = 2 if name == "male"
	replace group = 3 if name == "_eduXind"
	replace group = 4 if name == "agecatind"
	la def group 1 "Whole sample" 2 "By gender" 3 "By educational attainment (16+)" 4 "By age"
	la val group group	
	sort group year
	keep year indicatorlbl group value* lbl_All
	reshape long value, i(year group indicatorlbl lbl_All) j(ind)
	la def ind 1 "Poverty rate (%)" 2 "Share of poor (%)" 3 "Number of poor `xtxt'"
	la val ind ind
	
	collect clear
	qui collect: table (indicatorlbl group lbl_All) (ind `year'), statistic(mean value) nototal nformat(%20.1f) missing
	collect style header indicatorlbl group lbl_All ind `year', title(hide)
	*collect style header subind[.], level(hide)
	collect title `"Table 7. Vulnerability to poverty"'
	collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
	collect notes 2: `"Note: Vulnerability to poverty is defined as `vulnerability' times the `lbl`povlines''. All individual are used in the sample. Poverty statistics by educational attainment are only calculated for those aged 16 and above."'
	collect style notes, font(, italic size(10))
		
	if "`excel'"=="" {
		collect export "`dirpath'\\Table7.xlsx", sheet("Table7") replace 	
		shell start excel "`dirpath'\\Table7.xlsx"
	}
	else {
		collect export "`excelout'", sheet("Table7", replace) modify 
	}
end