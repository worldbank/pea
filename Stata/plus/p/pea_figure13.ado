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

cap program drop pea_figure13
program pea_figure13, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [ONEWelfare(varname numeric) Year(varname numeric) NOOUTPUT NOEQUALSPACING excel(string) save(string) scheme(string) palette(string) COMParability(varname numeric) PPPyear(integer 2021)]	
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}
	_pea_export_path, excel("`excel'")
	
	// Figure colors
	local groups = 10																					// number of areas
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")						//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
	
	//Weights
	local wvar : word 2 of `exp'
	qui if "`wvar'"=="" {
		tempvar w
		gen `w' = 1
		local wvar `w'
	}
	
	if "`onewelfare'"~="" { //reset to the floor
		replace `onewelfare' = ${floor_} if `onewelfare'< ${floor_}
		noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
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
	drop if decile==.
	drop __welfweight __total _merge
	reshape wide decile, i(`year' `comparability') j(__decile)
	cap ren `year' year
	la var year ""
	
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
	local gr = 1
	local u  = 5
	
	//Prepare Notes
	if "`comparability'"~="__comp" local note2 "Non-connected areas indicate that survey-years are not comparable."	
	
	//Prepare year variable without gaps
	if "`noequalspacing'"=="" {																	// Year spacing option
		egen year_nogap = group(`year'), label(year_nogap)										// Generate year variable without gaps
		local year year_nogap
	}	
	qui levelsof `year'		 , local(yearval)	
	sort `year'
	
	//Comparability between years
	levelsof `comparability', local(compval)
	
	local pcspike
	local rarea
	foreach co of local compval {
		qui sum if `comparability' == `co'
		local ncount = r(N)
		if `ncount' == 1 {														// If only one year, spike chart
			#delimit ;
			local pcspike_`co' "pcspike l0 `year' l1 `year'		if `comparability'==`co', color("${col1}") lwidth(8pt) yaxis(1)	||  
								pcspike l1 `year' l2 `year'		if `comparability'==`co', color("${col2}") lwidth(8pt) yaxis(2) || 
								pcspike l2 `year' l3 `year'		if `comparability'==`co', color("${col3}") lwidth(8pt)			|| 
								pcspike l3 `year' l4 `year'		if `comparability'==`co', color("${col4}") lwidth(8pt)			||  
								pcspike l4 `year' l5 `year'		if `comparability'==`co', color("${col5}") lwidth(8pt)			||  
								pcspike l5 `year' l6 `year'		if `comparability'==`co', color("${col6}") lwidth(8pt)			||  
								pcspike l6 `year' l7 `year'		if `comparability'==`co', color("${col7}") lwidth(8pt)			||  
								pcspike l7 `year' l8 `year'		if `comparability'==`co', color("${col8}") lwidth(8pt)			||  
								pcspike l8 `year' l9 `year'		if `comparability'==`co', color("${col9}") lwidth(8pt)			||  
								pcspike l9 `year' l100 `year'	if `comparability'==`co', color("${col10}") lwidth(8pt)			||";
			#delimit cr			
		}
		else if `ncount' > 1 {													// If multiple years, area chart
			#delimit ;
			local rarea_`co'	"rarea l0 l1 `year'		if `comparability'==`co', color("${col1}") yaxis(1) ||  
								rarea l1 l2 `year'		if `comparability'==`co', color("${col2}") yaxis(2) || 
								rarea l2 l3 `year'		if `comparability'==`co', color("${col3}")			|| 
								rarea l3 l4 `year'		if `comparability'==`co', color("${col4}")			||  
								rarea l4 l5 `year'		if `comparability'==`co', color("${col5}")			||  
								rarea l5 l6 `year'		if `comparability'==`co', color("${col6}")			||  
								rarea l6 l7 `year'		if `comparability'==`co', color("${col7}")			||  
								rarea l7 l8 `year'		if `comparability'==`co', color("${col8}")			||  
								rarea l8 l9 `year'		if `comparability'==`co', color("${col9}")			||  
								rarea l9 l100 `year'	if `comparability'==`co', color("${col10}")			||";
			#delimit cr
		}
		local pcspike "`pcspike' `pcspike_`co''" 
		local rarea "`rarea' `rarea_`co''" 
	}
	//Figure

	twoway 	`pcspike' `rarea' , ///		
			ytitle("Share of population (%)") /// 
			ylab(`yaxis', axis(2) angle(-45)) /// 
			yscale(range(0 100) axis(1)) /// 
			yscale(range(0 100) axis(2)) /// 
			ytitle("", axis(2)) xlabel(`yearval', valuelabel) xtitle("") /// 
			plotregion(margin(zero)) /// 
			aspect(1) /// 		
			legend(off) name(ngraph`gr', replace)
		
	//Figure export
	local figname Figure13
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\`figname'.xlsx"
		local act replace
		cap rm "`dirpath'\\`figname'.xlsx"
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}

	putexcel set "`excelout2'", `act'
	tempfile graph
	putexcel set "`excelout2'", modify sheet(`figname', replace)	  
	graph export "`graph'", replace as(png) name(ngraph`gr') wid(1500)	
	putexcel A`u' = image("`graph'")
	putexcel A1 = ""
	putexcel A2 = "Figure 13: Distribution of welfare by deciles"
	putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
	putexcel A4 = "Note: The figure shows the share of total welfare held by each welfare decile (%). `note2'"	
	
	putexcel O10 = "Data:"
	putexcel O6	= "Code"
	putexcel O7 = `"twoway 	`pcspike' `rarea', ytitle("Share of population (%)") ylab(`yaxis', axis(2) angle(-45)) yscale(range(0 100) axis(1)) yscale(range(0 100) axis(2)) ytitle("", axis(2)) xlabel(`yearval', valuelabel) xtitle("") plotregion(margin(zero)) aspect(1) legend(off)"'
	if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
	putexcel save							
	cap graph close	
	
	//Export data
	export excel year decile* using "`excelout2'", sheet("`figname'", modify) cell(O11) keepcellfmt firstrow(variables)	nolabel
	if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"	
end