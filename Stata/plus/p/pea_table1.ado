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

//Table 1. Core poverty indicators, tables 1 and 8 (long annex)

cap program drop pea_table1
program pea_table1, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) FGTVARS using(string) Year(varname numeric) CORE setting(string) LINESORTED excel(string) save(string) ONELine(varname numeric) ONEWelfare(varname numeric)]	
	
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	
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
	
	//variable checks
	//check plines are not overlapped.
	//trigger some sub-tables
	qui {
		su `year',d
		local ymax = r(max)
		levelsof `year', local(ylist)
		local atrisk0 2021		
		local atcheck : list ylist & atrisk0
		if "`atcheck'"=="" local yatrisk `ymax'
		else local yatrisk `atcheck'
		
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
		
		if "`oneline'"~="" {
			su `oneline',d
			if `=r(sd)'==0 local lbloneline: display %9.2f `=r(mean)'				
			else local lbloneline `oneline'
			local lbloneline `=trim("`lbloneline'")'
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
		
		gen double _pop = `wvar'
		clonevar _Gini_`distwelf' = `distwelf' if `touse'
		gen double _prosgap_`pppwelfare' = 25/`pppwelfare' if `touse'
		gen _vulpov_`onewelfare'_`oneline' = `onewelfare'< `oneline'*1.5  if `touse'
	}
	
	tempfile data1 data2
	save `data1', replace
	
	//FGT
	groupfunction  [aw=`wvar'] if `touse', mean(_fgt* _prosgap_`pppwelfare' _vulpov_`onewelfare'_`oneline') gini(_Gini_`distwelf') rawsum(_pop _popB40_`distwelf' _popT60_`distwelf') by(`year')
	save `data2', replace
	
	//mean, min, max, sd
	use `data1', clear
	clonevar _mB40_`distwelf' = _WELFMEAN_`distwelf' if _B40_`distwelf'==1
	clonevar _mT60_`distwelf' = _WELFMEAN_`distwelf' if _B40_`distwelf'==0
	collapse (mean) _WELFMEAN_`distwelf' _mB40_`distwelf' _mT60_`distwelf' (median) _Median_`distwelf'=_WELFMEAN_`distwelf' (min) _Min_`distwelf'=_WELFMEAN_`distwelf' (max) _Max_`distwelf'=_WELFMEAN_`distwelf' (sd) _SD_`distwelf'=_WELFMEAN_`distwelf'  [aw=`wvar'] if `touse', by(`year')
	merge 1:1 `year' using `data2'
	drop _merge
	save `data2', replace
	
	//MPM WB
	if "`core'"~="" {		
		use `data1', clear
		_pea_mpm [aw=`wvar'], c(`country') year(`year') welfare(`pppwelfare') 
		keep `year' mdpoor_i1
		replace mdpoor_i1 = mdpoor_i1*100
		ren mdpoor_i1 _mpmwb_`pppwelfare'
		merge 1:1 `year' using `data2'
		drop _merge
		save `data2', replace
	}
		
	// Check if folder exists
	local cwd `"`c(pwd)'"'														// store current wd
	quietly capture cd "`persdir'pea/Scorecard_Summary_Vision/"
	if _rc~=0 {
		noi di in red "Scorecard_Summary_Vision folder does not exist."
	}
	quietly cd `"`cwd'"'

	
	cap import excel "`persdir'pea/Scorecard_Summary_Vision/EN_CLM_VULN.xlsx", firstrow clear
	if _rc==0 {
		qui destring Time_Period, gen(year)
		ren Geography_Code code
		keep if code=="`country'"
		if _N==0 {
			noi dis in y "Warning: no data for high risk of climate-related hazards or wrong country code"		
			local atriskdo = 0
		}
		else {
			ren Value value
			gen indicatorlbl = 55
			replace year = `yatrisk'
			keep year value indicatorlbl
			save `atriskdata', replace
			local atriskdo = 1		
		}
	} //rc excel
	else {
		noi dis as error "Unable to load the Scorecard EN_CLM_VULN.xlsx"
		error `=_rc'
	}
	
	//Quintile
	use `data1', clear
	collapse (mean) _WELFMEAN_`distwelf' [aw=`wvar'] if `touse', by(`year' __quintile)	
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
	replace value = value*100 if _varname2=="fgt0"|_varname2=="fgt1"|_varname2=="fgt2"|_varname2=="vulpov"
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
		drop if _varname2=="vulpov"
		*replace indicatorlbl = 90 if indicatorlbl=="Income/consumption (LCU)"
		replace indicatorlbl = 91 if _varname2=="WELFMEAN"
		replace indicatorlbl = 91 if _varname2=="mT60"
		replace indicatorlbl = 91 if _varname2=="mB40"
		replace indicatorlbl = 92 if _varname2=="Median"
		replace indicatorlbl = 93 if _varname2=="Min"
		replace indicatorlbl = 94 if _varname2=="Max"
		replace indicatorlbl = 95 if _varname2=="SD"		
		la def indicatorlbl 90 "Income/consumption (LCU)" 91 "Mean" 92 "Median" 93 "Min" 94 "Max" 95 "SD", add
		local tabtitle "Table 1. Core poverty indicators"
		local tabname Table1
	}
	else {
		if `atriskdo'==1 append using `atriskdata'
		replace indicatorlbl = 50 if _varname2=="vulpov"
		replace indicatorlbl = 55 if _varname2=="atrisk"
		replace indicatorlbl = 60 if _varname2=="Gini"
		replace indicatorlbl = 70 if _varname2=="prosgap"
		replace indicatorlbl = 80 if _varname2=="mpmwb"
		la def indicatorlbl 50 "Poverty vulnerability - 1.5*PL (`lbloneline')" 55 "Percentage of people at high risk from climate-related hazards (2021*)" 60 "Gini index" 70 "Prosperity Gap" 80 "Multidimensional poverty (World Bank)" , add
	
		replace indicatorlbl = 90 if _varname2 =="WELFMEAN"
		replace indicatorlbl = 90 if _varname2=="mT60"
		replace indicatorlbl = 90 if _varname2=="mB40"
		la def indicatorlbl 90 "Mean income/consumption (LCU)", add		
		drop if subind>=11 & subind<=15
		local tabtitle "Table A.1. Core poverty and equity indicators"
		local tabname TableA1
	}
	la val indicatorlbl indicatorlbl
	drop if indicatorlbl==.
	
	collect clear
	qui collect: table (indicatorlbl subind) (`year') ,statistic(mean value) nototal nformat(%20.2f) missing
	collect style header indicatorlbl subind `year', title(hide)
	collect style header subind[.], level(hide)
	collect title `"`tabtitle'"'
	collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
	collect notes 2: `"Note: Poverty rates reported for the $2.15, $3.65, and $6.85 per person per day poverty lines are expressed in 2017 purchasing power parity dollars. These three poverty lines reflect the typical national poverty lines of low-income countries, lower-middle-income countries, and upper-middle-income countries, respectively. National poverty lines are expressed in 2017 local currency units (LCU)."'
	collect style notes, font(, italic size(10))
	
	if "`excel'"=="" {
		collect export "`dirpath'\\Table1.xlsx", sheet("`tabname'") replace 	
		shell start excel "`dirpath'\\Table1.xlsx"
	}
	else {
		collect export "`excelout'", sheet("`tabname'", replace) modify 
	}
end
