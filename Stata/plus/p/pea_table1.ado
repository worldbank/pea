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

//Table 1. Core poverty indicators

cap program drop pea_table1
program pea_table1, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) fgtvars(varlist numeric) using(string) Year(varname numeric) core gmd excel(string)]	
	
	*max=1 varlist
	//load data if defined
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
	
	//variable checks
	//trigger some sub-tables
	
	//order the lines
	qui {
		gen _x = _n
		if "`ppppovlines'"~="" {
			gen __varname = ""
			gen __mean = .

			local i = 1
			foreach var of varlist `ppppovlines' {
				quietly sum `var'
				if r(mean) < . {
					replace __varname = "`var'" in `i'
					replace __mean = r(mean) in `i'
					local lbl`var' : variable label `var'
					if "`lbl`var''"=="" local lbl`var' "`var'"
					local i = `i' + 1				
				}
			}
			local sorted_pppline
			sort __mean
			forv j=1(1)`i' {
				local x = __varname[`j']
				local sorted_pppline `sorted_pppline' `x'
			}
			drop __varname __mean	
		}
		
		if "`natpovlines'"~="" {
			gen __varname = ""
			gen __mean = .

			local i = 1
			foreach var of varlist `natpovlines' {
				quietly sum `var'
				if r(mean) < . {
					replace __varname = "`var'" in `i'
					replace __mean = r(mean) in `i'
					local lbl`var' : variable label `var'
					if "`lbl`var''"=="" local lbl`var' "`var'"
					local i = `i' + 1
				}
			}
			local sorted_natline
			sort __mean
			forv j=1(1)`i' {
				local x = __varname[`j']
				local sorted_natline `sorted_natline' `x'
			}
			drop __varname __mean
		}
		sort _x
		drop _x
	
		//Weights
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		}
		
		*tempvar  _pop
		gen double _pop = `wvar'
		
		//missing observation check
		marksample touse
		local flist `"`wvar' `natwelfare' `natpovlines' `pppwelfare' `ppppovlines' `year'"'
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
		
		//B40 T60 Mean - only for one distribution
		if "`natwelfare'"~="" & "`pppwelfare'"~="" local distwelf `natwelfare'
		if "`natwelfare'"=="" & "`pppwelfare'"~="" local distwelf `pppwelfare'
		_pea_gen_b40 [aw=`wvar'] if `touse', welf(`distwelf') by(`year')
	}
	* gini(a1) theil(a2)
	clonevar _Gini_`distwelf' = `distwelf' if `touse'
	tempfile data1 data2
	save `data1', replace
	
	//FGT
	groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) gini(_Gini_`distwelf') rawsum(_pop _popB40_`distwelf' _popT60_`distwelf') by(`year')
	save `data2', replace
	
	//mean, min, max, sd
	use `data1', clear
	clonevar _mB40_`distwelf' = _WELFMEAN_`distwelf' if _B40_`distwelf'==1
	clonevar _mT60_`distwelf' = _WELFMEAN_`distwelf' if _B40_`distwelf'==0
	collapse (mean) _WELFMEAN_`distwelf' _mB40_`distwelf' _mT60_`distwelf' (median) _Median_`distwelf'=_WELFMEAN_`distwelf' (min) _Min_`distwelf'=_WELFMEAN_`distwelf' (max) _Max_`distwelf'=_WELFMEAN_`distwelf' (sd) _SD_`distwelf'=_WELFMEAN_`distwelf'  [aw=`wvar'] if `touse', by(`year')
	merge 1:1 `year' using `data2'
	drop _merge
	save `data2', replace
	
	//Quintile
	use `data1', clear
	collapse (mean) _WELFMEAN_`distwelf' [aw=`wvar'] if `touse', by(`year' __quintile)
	*ren _welfLCU 
	reshape wide _WELFMEAN_`distwelf', i(`year') j(__quintile)
	merge 1:1 `year' using `data2'
	drop _merge
	save `data2', replace
	
	for var _fgt0*: gen double _nX = X*_pop
	ren _n_fgt* _npoor*
	order `year'
	xpose, varname clear promote
	ds 
	local vlist = r(varlist)
	local v0 _varname
	local vlist : list vlist - v0
	foreach var of local vlist {
		local tmp = `var'[1]
		ren `var' d`tmp'
	}
	drop in 1
	reshape long d, i(_varname) j(year)
	ren d value
	split _varname, parse("_")
	drop _varname1
	/*
	gen label = ""
	//add label welfare
	ren _varname3 name
	merge m:1 name using `datalbl', keepus(varlab)
	drop if _merge==2
	replace label = varlab if _merge==3
	drop _merge varlab
	ren name _varname3 
	
	//add label povlines
	ren _varname4 name
	merge m:1 name using `datalbl', keepus(varlab)
	drop if _merge==2
	replace label = varlab if _merge==3
	drop _merge varlab
	ren name _varname4
	*/
	su value if _varname2=="npoor0"
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
	replace value = value/`xscale' if _varname2=="npoor0"
	replace value = value*100 if _varname2=="fgt0"|_varname2=="fgt1"|_varname2=="fgt2"
	gen subind = .
	replace subind = 1 if _varname2=="fgt0"
	replace subind = 2 if _varname2=="fgt1"
	replace subind = 3 if _varname2=="fgt2"
	replace subind = 4 if _varname2=="npoor0"	
	replace subind = 10 if _varname2 =="WELFMEAN" & _varname3=="welfare" //total
	replace subind = 11 if _varname2 =="WELFMEAN" & _varname3=="welfare1"
	replace subind = 12 if _varname2 =="WELFMEAN" & _varname3=="welfare2"
	replace subind = 13 if _varname2 =="WELFMEAN" & _varname3=="welfare3"
	replace subind = 14 if _varname2 =="WELFMEAN" & _varname3=="welfare4"
	replace subind = 15 if _varname2 =="WELFMEAN" & _varname3=="welfare5"
	replace subind = 16 if _varname2 =="mB40"
	replace subind = 17 if _varname2 =="mT60"

	la def subind 1 "Headcount" 2 "Gap" 3 "Severity" 4 "Number of poor `xtxt'" ///
	10 "Total" 11 "Q1 (poorest 20%)" 12 "Q2" 13 "Q3" 14 "Q4" 15 "Q5 (richest 20%)" 16 "B40" 17 "T60"	
	la val subind subind

	gen indicatorlbl = .
	local i = 1
	if "`ppppovlines'"~="" {
		foreach var of local ppppovlines {
			replace indicatorlbl = `i' if _varname4=="`var'"
			la def indicatorlbl `i' "`lbl`var''", add
			local i = `i' + 1
		}
	}
	
	if "`natpovlines'"~="" {
		foreach var of local natpovlines {
			replace indicatorlbl = `i' if _varname4=="`var'"
			la def indicatorlbl `i' "`lbl`var''", add
			local i = `i' + 1
		}
	}
	
	//setup	
	if "`core'"=="" {
		*replace indicatorlbl = 90 if indicatorlbl=="Income/consumption (LCU)"
		replace indicatorlbl = 91 if _varname2=="WELFMEAN"
		replace indicatorlbl = 91 if _varname2=="mT60"
		replace indicatorlbl = 91 if _varname2=="mB40"
		replace indicatorlbl = 92 if _varname2=="Median"
		replace indicatorlbl = 93 if _varname2=="Min"
		replace indicatorlbl = 94 if _varname2=="Max"
		replace indicatorlbl = 95 if _varname2=="SD"		
		la def indicatorlbl 90 "Income/consumption (LCU)" 91 "Mean" 92 "Median" 93 "Min" 94 "Max" 95 "SD", add
	}
	else {
		*replace indicatorlbl = 50 if indicatorlbl=="Poverty vulnerability"
		replace indicatorlbl = 60 if _varname2=="Gini"
		*replace indicatorlbl = 70 if indicatorlbl=="Prosperity Gap"
		*replace indicatorlbl = 80 if indicatorlbl=="Multidimensional poverty"
		la def indicatorlbl 50 "Poverty vulnerability" 60 "Gini index" 70 "Prosperity Gap" 80 "Multidimensional poverty" , add
	
		replace indicatorlbl = 90 if _varname2 =="WELFMEAN"
		replace indicatorlbl = 90 if _varname2=="mT60"
		replace indicatorlbl = 90 if _varname2=="mB40"
		la def indicatorlbl 90 "Mean income/consumption (LCU)", add		
		drop if subind>=11 & subind<=15
	}
	la val indicatorlbl indicatorlbl
	drop if indicatorlbl==.
	
	collect clear
	qui collect: table (indicatorlbl subind) (`year') ,statistic(mean value) nototal nformat(%20.2f) missing
	collect style header indicatorlbl subind `year', title(hide)
	collect style header subind[.], level(hide)
	collect title `"Table A.1. Core poverty and equity indicators"'
	collect notes 1: `"Source: ABC"'
	collect notes 2: `"Note: The global ..."'
	collect style notes, font(, italic size(10))
	*collect preview
	*set trace on
	
	if "`excel'"=="" {
		collect export "`dirpath'\\Table1.xlsx", sheet(Table1) replace 	
		shell start excel "`dirpath'\\Table1.xlsx"
	}
	else {
		collect export "`excelout'", sheet(Table1, replace) modify 
	}
end
