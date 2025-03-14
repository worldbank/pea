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
	syntax [if] [in] [aw pw fw], [Country(string) NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) FGTVARS using(string) Year(varname numeric) CORE setting(string) LINESORTED excel(string) save(string) ONELine(varname numeric) ONEWelfare(varname numeric) SVY std(string) PPPyear(integer 2017) VULnerability(real 1.5)]	
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')

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
	
	if "`vulnerability'"=="" {
		local vulnerability = 1.5
		noi di in yellow "Default multiple of poverty line to define vulnerability is 1.5"
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
		
		//SVY setting
		local svycheck = 0
		if "`svy'"~="" {
			cap svydescribe
			if _rc~=0 {
				noi dis "SVY is not set. Please do svyset to get the correct standard errors"
				exit `=_rc'
				//or svyset [w= `wvar'],  singleunit(certainty)
			}
			else {
				//check on singleton, remove?
				//std option: inside, below, right
				if "`std'"=="" local std inside
				else {
					local std = lower("`std'")
					if "`std'"~="inside" & "`std'"~="right" {
						//"`std'"~="below"
						noi dis "Wrong option for std(). Available options: inside, right"
						exit 198
					}
				}	
				local svycheck = 1
			} //else svydescribe
		} //svy
		
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
		if "`pppwelfare'"~="" { //reset to the floor
			replace `pppwelfare' = ${floor_} if `pppwelfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
		
		//FGT
		if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
		if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
		
		//B40 T60 Mean - only for one distribution
		if "`natwelfare'"~="" & "`pppwelfare'"~="" local distwelf `natwelfare'
		if "`natwelfare'"=="" & "`pppwelfare'"~="" local distwelf `pppwelfare'
		_pea_gen_b40 [aw=`wvar'] if `touse', welf(`distwelf') by(`year')
		
		gen double _pop = `wvar'
		clonevar _Gini_`distwelf' = `distwelf' if `touse'
		
		gen double _prosgap_`pppwelfare' = ${prosgline_}/`pppwelfare' if `touse'
		gen _vulpov_`onewelfare'_`oneline' = `onewelfare'< `oneline'*`vulnerability'  if `touse'
	}
	
	tempfile data1 data2 atriskdata data2a
	save `data1', replace
	
	clear
	save `data2a', replace emptyok

	//FGT - estimate points
	use `data1', clear
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
	
	//standard errors
	if `svycheck'==1 {
		use `data1', clear
		levelsof `year', local(datalist)
		qui foreach dat of local datalist {
			use `data1', clear
			keep if `year'==`dat'
			tempvar single		
			svydescribe, gen(`single')
			drop if `single'==1
			clonevar _mB40_`distwelf' = _WELFMEAN_`distwelf' if _B40_`distwelf'==1
			clonevar _mT60_`distwelf' = _WELFMEAN_`distwelf' if _B40_`distwelf'==0
			
			//standard
			svy: mean _fgt* _prosgap_`pppwelfare' _vulpov_`onewelfare'_`oneline' _WELFMEAN_`distwelf'  if `touse'
			local names : colfullnames e(b)
			mata: V = diagonal(st_matrix("e(V)"))
			mata: st_matrix("varst", V)
			mat rownames varst = `names'
			mat varst1 = varst'
			
			//b40
			svy: mean  _mB40_`distwelf' if `touse'
			local names : colfullnames e(b)
			mata: V = diagonal(st_matrix("e(V)"))
			mata: st_matrix("varst", V)
			mat rownames varst = `names'
			mat varst2 = varst'
			
			//t60
			svy: mean  _mT60_`distwelf' if `touse'
			local names : colfullnames e(b)
			mata: V = diagonal(st_matrix("e(V)"))
			mata: st_matrix("varst", V)
			mat rownames varst = `names'
			mat varst3 = varst'
			
			//gini
			svylorenz _Gini_`distwelf'
			mat ginist = e(se_gini)^2
			mat colnames ginist = _Gini_`distwelf'
			
			mat allst = varst1, varst2, varst3, ginist
			clear
			svmat allst, names(col)
			xpose, varname clear
			gen double std = sqrt(v1)
			cap drop v1
			gen `year' = `dat'
			append using `data2a'
			save `data2a', replace
		} //each dat
	} //svycheck
	
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
	if `svycheck'==1 {
		//merge with STD data
		merge 1:1 _varname `year' using `data2a', nogen		
		//check on standard error for number of poors -need or not.
	}
	
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
	replace value = value*100 if _varname2=="fgt0"|_varname2=="fgt1"|_varname2=="fgt2"|_varname2=="vulpov"|_varname2=="Gini"
	gen subind = .
	replace subind = 1 if _varname2=="fgt0"
	replace subind = 2 if _varname2=="fgt1"
	replace subind = 3 if _varname2=="fgt2"
	replace subind = 4 if _varname2=="npoor0"	
	replace subind = 10 if _varname2 =="WELFMEAN" & _varname3=="`distwelf'" //total
	replace subind = 11 if _varname2 =="WELFMEAN" & _varname3=="`distwelf'1"
	replace subind = 12 if _varname2 =="WELFMEAN" & _varname3=="`distwelf'2"
	replace subind = 13 if _varname2 =="WELFMEAN" & _varname3=="`distwelf'3"
	replace subind = 14 if _varname2 =="WELFMEAN" & _varname3=="`distwelf'4"
	replace subind = 15 if _varname2 =="WELFMEAN" & _varname3=="`distwelf'5"
	replace subind = 16 if _varname2 =="mB40"
	replace subind = 17 if _varname2 =="mT60"

	la def subind 1 "Headcount (%)" 2 "Gap (%)" 3 "Severity (%)" 4 "Number of poor `xtxt'" 10 "Total" 11 "Q1 (poorest 20%)" 12 "Q2" 13 "Q3" 14 "Q4" 15 "Q5 (richest 20%)" 16 "B40" 17 "T60"	
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
	
	//convert to same unit
	if `svycheck'==1 {
		replace std = std*100 if _varname2=="vulpov"|_varname2=="fgt0"|_varname2=="fgt1"|_varname2=="fgt2"|_varname2=="Gini"
	}
	
	//setup	
	if "`core'"=="" {
		drop if _varname2=="vulpov"
		*replace indicatorlbl = 90 if indicatorlbl=="Income/consumption (LCU)"
		replace indicatorlbl = 91 if _varname2=="WELFMEAN"
		replace indicatorlbl = 91 if _varname2=="mT60"
		replace indicatorlbl = 91 if _varname2=="mB40"
		replace indicatorlbl = 92 if _varname2=="Median"
		*replace indicatorlbl = 93 if _varname2=="Min"							// Remove min/max for now
		*replace indicatorlbl = 94 if _varname2=="Max"
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
		la def indicatorlbl 50 "Poverty vulnerability - `vulnerability'*PL (`lbloneline', %)" 55 "Percentage of people at high risk from climate-related hazards (2021*)" 60 "Gini index" 70 "Prosperity Gap" 80 "Multidimensional poverty (%, World Bank)" , add
	
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
	
	qui if `svycheck'==0 {
		collect: table (indicatorlbl subind) (`year') ,statistic(mean value) nototal nformat(%20.1f) missing
	}
	else {
		qui if "`std'"=="right" { //wide-form			
			table (indicatorlbl subind) (`year') ,statistic(mean value) nototal nformat(%20.1f) missing
			table (indicatorlbl subind) (`year') if std!=. ,statistic(mean std) nototal nformat(%20.1f) missing append			
			collect layout (indicatorlbl#subind) (`year'#var) (result)
			collect style cell var[std], sformat((%s))
			collect label levels var value "Estimate", modify
			collect label levels var std "Standard error", modify
		} //right
	
		qui if "`std'"=="inside" {
			table (indicatorlbl subind) (`year') ,statistic(mean value) nototal nformat(%20.1f) missing
			table (indicatorlbl subind) (`year') if std!=. ,statistic(mean std) nototal nformat(%20.1f) missing append
			collect remap result[mean] = result[estimate], fortags(var[value])
			collect remap result[mean] = result[sd], fortags(var[std])
			collect style cell result[sd], sformat((%s))
			collect composite define new = estimate sd, trim
			collect layout (indicatorlbl#subind) (`year') (result[new])
			local stdtext "Standard errors are reported in parentheses."
		} //inside
	}
	
	collect style header indicatorlbl subind `year', title(hide)
	collect style header subind[.], level(hide)
	collect title `"`tabtitle'"'
	collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
	collect notes 2: `"Note: Poverty rates reported for the poverty lines (per person per day), which are expressed in `pppyear' purchasing power parity dollars. These three poverty lines reflect the typical national poverty lines of low-income countries, lower-middle-income countries, and upper-middle-income countries, respectively. National poverty lines are expressed in local currency units (LCU). `stdtext'"'
	collect style notes, font(, italic size(10))
	collect style cell indicatorlbl[1 2 3 4]#cell_type[row-header], font(, bold)
	collect style cell subind[]#cell_type[row-header], warn font(, nobold)
	*collect style cell indicatorlbl[]#cell_type[row-header], warn font(, nobold)
	
	collect style cell, shading( background(white) )	
	collect style cell cell_type[corner], shading( background(lightskyblue) )	
	collect style cell cell_type[column-header corner], font(, bold) shading( background(seashell) )	
	collect style cell cell_type[item],  halign(center)
	collect style cell cell_type[column-header], halign(center)	
	
	if "`excel'"=="" {
		collect export "`dirpath'\\Table1.xlsx", sheet("`tabname'") replace
		shell start excel "`dirpath'\\Table1.xlsx"
	}
	else {
		collect export "`excelout'", sheet("`tabname'", replace) modify 
		putexcel set "`excelout'", modify sheet("`tabname'")		
		putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")	
		qui putexcel save
	}
end
