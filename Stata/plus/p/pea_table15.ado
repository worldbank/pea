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

//Table 15. Distribution of welfare by deciles

cap program drop pea_table15
program pea_table15, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Welfare(varname numeric) Year(varname numeric) excel(string) save(string) PPPyear(integer 2017)]	
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}
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
	
	//Weights
	local wvar : word 2 of `exp'
	qui if "`wvar'"=="" {
		tempvar w
		gen `w' = 1
		local wvar `w'
	}
	
	//missing observation check
	marksample touse
	local flist `"`wvar' `welfare' `year' `comparability'"'
	markout `touse' `flist' 
	
	if "`welfare'"~="" { //reset to the floor
		replace `welfare' = ${floor_} if `welfare'< ${floor_}
		noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
	}
		
	levelsof `year', local(yearlist)
	gen __decile = .
	foreach yr of local yearlist {
		tempvar qwlf
		cap _ebin `welfare' [aw=`wvar'] if `touse' & `year'==`yr', nquantiles(10) gen(`qwlf')
		if _rc!=0 {
			noi di in red "Error in creating deciles for `by1'"			
			exit `=_rc'
		} 
		else {
			replace __decile = `qwlf' if `touse' & `year'==`yr' & __decile==.
		}
		drop `qwlf'
	}
	gen double __welfweight = `welfare'*`wvar'
	tempfile dataori datalbl data2 data2b
	save `dataori', replace

	collapse (sum) __welfweight, by(`year' `comparability')
	ren __welfweight __total
	save `data2b', replace
	
	use `dataori', clear
	collapse (sum) __welfweight, by(`year' __decile)
	merge m:1 `year' using `data2b'
	gen double decile = (__welfweight/__total)*100
	drop __welfweight __total _merge
	cap ren `year' year
	la var year ""
	forval i = 1/10 {
		label define decile `i' "Decile `i'", add
	}
	label values __decile decile
collect clear
	qui collect: table (__decile) (`year'), stat(mean decile) nototal nformat(%20.1f) missing
	collect style header __decile `year', title(hide)

	collect title `"Table 15. Distribution of welfare by deciles (%)"'
	collect notes 1: `"Source: World Bank calculations using survey data accessed through the GMD."'
	collect notes 2: `"Note: The table shows the share of total welfare held by each welfare decile (%)."'
	collect style notes, font(, italic size(10))
	collect style cell, shading( background(white) )	
	collect style cell cell_type[corner], shading( background(lightskyblue) )
	collect style cell cell_type[column-header corner], font(, bold) shading( background(seashell) )
	collect style cell cell_type[item],  halign(center)
	collect style cell cell_type[column-header], halign(center)	
			
	if "`excel'"=="" {
		collect export "`dirpath'\\Table15.xlsx", sheet(Table15) modify 	
		shell start excel "`dirpath'\\Table15.xlsx"
	}
	else {
		collect export "`excelout'", sheet(Table15, replace) modify 
		putexcel set "`excelout'", modify sheet("Table15")		
		putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")	
		qui putexcel save
	}
	
end