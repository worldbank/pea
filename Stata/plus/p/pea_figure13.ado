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

//Figure 13. Distribution of welfare by deciles
//todo: add comparability, add the combine graph option

cap program drop pea_figure13
program pea_figure13, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) ONEWelfare(varname numeric) Year(varname numeric) setting(string) NOOUTPUT excel(string) save(string) MISSING scheme(string) palette(string) COMParability(varname numeric)]	
	
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
	
	//Comparability
	if "`comparability'"=="" {
		gen __comp = 1
		local comparability __comp
	}
	qui ta `year'
	local nyear = r(r)
	qui ta `comparability'
	local ncomp = r(r)
	if `ncomp' > `nyear' {
		noi dis as error "Inconsistency between number of years and number of comparable data points."
		error 1
	}
	
	//missing observation check
	marksample touse
	local flist `"`wvar' `onewelfare' `year' `comparability'"'
	markout `touse' `flist' 
	
	levelsof `year', local(yearlist)
	gen __decile = .
	foreach yr of local yearlist {
		tempvar qwlf
		cap _ebin `onewelfare' [aw=`wvar'] if `touse' & `year'==`yr', nquantiles(10) gen(`qwlf')
		if _rc!=0 {
			noi di in red "Error in creating deciles for `by1'"			
			exit `=_rc'
		} 
		else {
			replace __decile = `qwlf' if `touse' & `year'==`yr' & __decile==.
		}
		drop `qwlf'
	}
	gen double __welfweight = `onewelfare'*`wvar'
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
	reshape wide decile, i(`year' `comparability') j(__decile)
	cap ren `year' year
	la var year ""
	
	// Figure colors
	pea_figure_setup, groups("10")
	
	** Distribution of welfare across groups
	gen l0=0
	gen l100 = 100
	forv i=1(1)10 {
		gen l`i' = decile`i'+ l`=`i'-1'
	}

	local mid = l1[_N]/2 
	local yaxis `"`mid' "Decile 1""'

	local mid = (l2[_N]-l1[_N])/2 + l1[_N] 
	local yaxis `"`yaxis' `mid' "Decile 2""'

	local mid = (l3[_N]-l2[_N])/2 + l2[_N] 
	local yaxis `"`yaxis' `mid' "Decile 3""'

	local mid = (l4[_N]-l3[_N])/2 + l3[_N] 
	local yaxis `"`yaxis' `mid' "Decile 4""'

	local mid = (100-l9[_N])/2 + l9[_N] 
	local yaxis `"`yaxis' `mid' "Decile 10""'
	levelsof year, local(yrlbl)
	sort year
	local gr = 1
	local u  = 5
	
	twoway rarea l0 l1 year, yaxis(1) || /// 
		rarea l1 l2 year, yaxis(2) || /// 
		rarea l2 l3 year || /// 
		rarea l3 l4 year || /// 
		rarea l4 l5 year || /// 
		rarea l5 l6 year || /// 
		rarea l6 l7 year || /// 
		rarea l7 l8 year || /// 
		rarea l8 l9 year || /// 
		rarea l9 l100 year, ///		
		ytitle("Percentage of population") /// 
		ylab(`yaxis', axis(2) angle(-45)) /// 
		yscale(range(0 100) axis(1)) /// 
		yscale(range(0 100) axis(2)) /// 
		ytitle("", axis(2)) xlabel(`yrlbl') xtitle("") /// 
		plotregion(margin(zero)) /// 
		aspect(1) /// 		
		legend(off) name(ngraph`gr', replace)	
		
		*title("Distribution of `wefltype' by deciles" "`yrange'", size(medium)) note("Source: World Bank using GMD" "(`wefltype'-based from `sur' surveys)")

	// Figure
	local figname Figure13
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\`figname'.xlsx"
		local act replace
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}
	
	putexcel set "`excelout2'", `act'
	tempfile graph
	putexcel set "`excelout2'", modify sheet(`figname', replace)	  
	graph export "`graph'", replace as(png) name(ngraph`gr') wid(3000)		
	putexcel A`u' = image("`graph'")
	putexcel save							
	cap graph close	
	if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"	
end