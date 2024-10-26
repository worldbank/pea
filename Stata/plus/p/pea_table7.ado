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
	syntax [if] [in] [aw pw fw], [Welfare(varname numeric) Povlines(varname numeric) Year(varname numeric) core setting(string) excel(string) save(string) missing]
	
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
	
	qui {
		//order the lines
		local lbl`povlines' : variable label `povlines'		
		su `povlines',d
		if `=r(sd)'==0 local lbloneline: display %9.2f `=r(mean)'				
		else local lbloneline `oneline'	
				
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
		
		tempfile dataori datalbl
		save `dataori', replace
		des, replace clear
		save `datalbl', replace
		use `dataori', clear
	} //qui
	
	//FGT
	gen _vulpovl15_`welfare'_`povlines' = (`welfare' < 1.5*`povlines') if `welfare'~=. & `touse'
	gen _vulpov2_`welfare'_`povlines' = (`welfare' < 2*`povlines') if `welfare'~=. & `touse'
	gen double _pop1 = `wvar'
	
	//FGT
	tempfile data2
	groupfunction  [aw=`wvar'] if `touse', mean(_vulpov*) rawsum(_pop1) by(`year')
	ren _* var_*
	reshape long var_, i(year) j(_varname) string
	ren var_ value
	split _varname, parse("_")
	replace value = value*100 if _varname1=="vulpovl15"|_varname1=="vulpov2"
	
	gen indicatorlbl = .
	replace indicatorlbl = 1 if _varname1=="vulpovl15"
	replace indicatorlbl = 2 if _varname1=="vulpov2"
	la def indicatorlbl 1 "Share of population below 1.5*PL (`lbloneline')" 2 "Share of population below 2*PL (`lbloneline')"
	la val indicatorlbl indicatorlbl
	drop if indicatorlbl==.
	
	collect clear
	qui collect: table (indicatorlbl) (`year') ,statistic(mean value) nototal nformat(%20.2f) missing
	collect style header indicatorlbl  `year', title(hide)
	*collect style header subind[.], level(hide)
	collect title `"Table 7. Vulnerability to poverty"'
	collect notes 1: `"Source: ABC"'
	collect notes 2: `"Note: The global ..."'
	collect style notes, font(, italic size(10))
		
	if "`excel'"=="" {
		collect export "`dirpath'\\Table7.xlsx", sheet("Table7") replace 	
		shell start excel "`dirpath'\\Table7.xlsx"
	}
	else {
		collect export "`excelout'", sheet("Table7", replace) modify 
	}
end