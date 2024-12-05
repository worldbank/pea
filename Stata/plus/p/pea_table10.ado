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

//Table 10 _ Benchmark of countries
//WDI, PIP, Data latest
cap program drop pea_table10
program pea_table10, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) Welfare(varname numeric) Povlines(varlist numeric) Year(varname numeric) BENCHmark(string) CORE setting(string) LINESORTED excel(string) save(string) FGTVARS LATEST WITHIN3]
	
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	
	//Country
	if "`country'"=="" {
		noi dis as error "Please specify the country code of analysis"
		error 1
	}
	local country "`=upper("`country'")'"
	cap drop code
	gen code = "`country'"
	
	if "`latest'"~="" & "`within3'"~="" {
		noi dis as error "Either latest or within3, not both options"
		error 1
	}
	if "`latest'"=="" & "`within3'"=="" local latest latest
	
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
		//Keep only the latest data
		su `year',d
		local ymax = r(max)
		keep if `year'==`ymax'
		
		//order the lines
		if "`linesorted'"=="" {
			if "`povlines'"~="" {
				_pea_pline_order, povlines(`povlines')
				//sorted_pppline
				local povlines `=r(sorted_line)'
				foreach var of local povlines {
					local lbl`var' `=r(lbl`var')'
				}
			}
		}
		else {
			foreach var of varlist `povlines' {
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
		local flist `"`wvar' `welfare' `povlines' `year'"'
		markout `touse' `flist' 
		
		tempfile dataori datalbl
		save `dataori', replace
		des, replace clear
		save `datalbl', replace
		use `dataori', clear
	} //qui
	
	if "`fgtvars'"=="" { //only create when the fgt are not defined			
		if "`welfare'"~="" & "`povlines'"~="" _pea_gen_fgtvars if `touse', welf(`welfare') povlines(`povlines')		
	}	
	cap drop _fgt1* _fgt2*	
	clonevar _Gini_`welfare' = `welfare' if `touse'
	gen double _prosgap_`welfare' = 25/`welfare' if `touse'
	
	//FGT
	tempfile data2
	groupfunction  [aw=`wvar'] if `touse', mean(_fgt0_`welfare'* _prosgap_`welfare') gini(_Gini_`welfare') by(code `year')
	gen gdppc = .
	ren _fgt0_welfppp_pline215 headcount215
	ren _fgt0_welfppp_pline365 headcount365
	ren _fgt0_welfppp_pline685 headcount685
	for var headcount*: replace X = X*100
	ren _prosgap_welfppp pg
	ren _Gini_welfppp gini
	save `data2', replace
	
	//obtain the data then move to cache so next time running is faster	
	//country list and region_code
	local nametodo = 0
	cap confirm file "`persdir'pea/PIP_list_name.dta"
	if _rc==0 {
		cap use "`persdir'pea/PIP_list_name.dta", clear	
		if _rc~=0 local nametodo = 1	
	}
	else local nametodo = 1
	if `nametodo'==1 {
		cap pea_dataupdate, datatype(LIST) update
		if _rc~=0 {
			noi dis "Unable to run pea_dataupdate, datatype(LIST) update"
			exit `=_rc'
		}
	}
		
	use "`persdir'pea/PIP_list_name.dta", clear
	keep if code=="`country'"
	if _N==0 {
		noi dis in y "Warning: wrong country code"
		error 1
	}
	else {
		local regcode `=region_code[1]'
		local ctryname `=country_name[1]'
	}
	
	//PIP poverty and pros gap and all data from PIP	
	local nametodo = 0
	cap confirm file "`persdir'pea/PIP_all_country.dta"
	if _rc==0 {
		cap use "`persdir'pea/PIP_all_country.dta", clear	
		if _rc~=0 local nametodo = 1	
	}
	else local nametodo = 1
	if `nametodo'==1 {
		cap pea_dataupdate, datatype(PIP) update
		if _rc~=0 {
			noi dis "Unable to run pea_dataupdate, datatype(PIP) update"
			exit `=_rc'
		}
	}
	
	//From here, all PIP data should be available.
	//GDP https://data.worldbank.org/indicator/NY.GDP.PCAP.KD.
	use "`persdir'pea/PIP_all_GDP.dta", clear
	keep if code=="`country'" & year==`ymax'
	if _N==0 {
		noi dis in y "Warning: no GDPPC data for `ymax' yet or wrong country code"
		local gdpv .
	}
	else {
		local gdpv `=gdppc[1]'
	}
	
	//Survey year estimates
	clear
	tempfile povben
	save `povben', replace emptyok
	
	use "`persdir'pea/PIP_all_country.dta", clear
	foreach cc of local benchmark {
		local cc "`=upper("`cc'")'"
		use "`persdir'pea/PIP_all_country.dta" if code=="`cc'", clear
		if "`latest'"~="" {
			su year,d			
			local ymax1 = r(max)
			keep if year==`ymax1'
			ren country_name name
			keep name code year survey_acronym welfaretype headcount* gini pg gdppc
			append using `povben'
			save `povben', replace			
			if _N>0 local povb = 1
		}
		
		if "`within3'"~="" {
			keep if year>=`=`ymax'-3' & year<=`=`ymax'+3'
			if _N==0 {
				noi dis in y "No data for `code' within +-3 years from `ymax' of `country'."				
			}
			else if _N==1 {
				ren country_name name
				keep name code year survey_acronym welfaretype headcount* gini pg gdppc
				append using `povben'
				save `povben', replace				
				if _N>0 local povb = 1
			}
			else {
				gen diff = abs(year - `ymax')
				su diff,d
				local rmin = r(min)
				keep if diff==`rmin'
				*if _N==1 { //showing whatevery is available
					ren country_name name
					keep name code year survey_acronym welfaretype headcount* gini pg gdppc
					append using `povben'
					save `povben', replace	
					if _N>0 local povb = 1
				*}
			} //else
		} //within3		
	} //benchmark
	
	//lineup estimates `povlineup'
	*save `povlineup', replace
	
	//regional, get the closest regional number
	tempfile regdata	
	use "`persdir'pea/PIP_regional_estimate.dta", clear
	keep if region_code=="`regcode'" //& year==`ymax'
	gen diff = abs(year - `ymax')
	su diff,d
	local rmin = r(min)
	keep if diff==`rmin'
	ren region_name name
	ren region_code code
	keep code name year headcount* pg
	save `regdata', replace
	
	//income group
	tempfile povincgr	
	use "`persdir'pea/PIP_incgroup_estimate.dta", clear
	keep if code=="`country'" //& year==`ymax'
	gen diff = abs(year - `ymax')
	su diff,d
	local rmin = r(min)
	keep if diff==`rmin'
	ren incgroup_historical name	
	replace code = "Incgroup"
	keep code name year headcount*
	save `povincgr', replace
	
	//Bring all back
	use `data2', clear	
	replace gdppc = `gdpv'
	gen region_code = "`regcode'"
	gen name = "`ctryname'"
	
	append using `regdata'
	*if `povb'==1 append using `povben'
	append using `povben'
	append using `povincgr'
	
	drop region_code
	ren * var_*
	ren var_code code
	ren var_survey_acronym survey_acronym
	ren var_welfaretype welfaretype
	*replace var_name = "Country of analysis" if code=="`country'"
	replace var_name = "Peer " + var_name if code~="`regcode'" & code~="`country'" & code~="Incgroup"
	gen name = var_name + " (" + string(var_year) +")" if code=="`regcode'" | code=="`country'" | code=="Incgroup"
	replace name = var_name + " (" + survey_acronym + "," + string(var_year) + "," + welfaretype +")" if code~="`regcode'" & code~="`country'" & code~="Incgroup"
	
	drop var_year var_name
	reshape long var_, i(code name survey_acronym) j(var) string
	ren var_ value
	gen indicatorlbl = .
	replace indicatorlbl = 1 if var=="gdppc"
	replace indicatorlbl = 2 if var=="headcount215"
	replace indicatorlbl = 3 if var=="headcount365"
	replace indicatorlbl = 4 if var=="headcount685"
	replace indicatorlbl = 5 if var=="gini"
	replace indicatorlbl = 6 if var=="pg"
	 
	la def indicatorlbl 1 "GDP per capita" 2 "$2.15" 3 "$3.65" 4 "$6.85" 5 "Gini" 6 "Prosperity Gap"
	la val indicatorlbl indicatorlbl
	gen group = 0 if var=="gdppc"
	replace group = 1 if var=="headcount215" | var=="headcount365" | var=="headcount685"
	replace group = 2 if var=="gini" |  var=="pg"
	la def group 1 "Poverty line (per day, 2017 PPP)" 2 "Shared Prosperity"
	la val group group
	
	gen order = .
	replace order = 1 if code=="`country'"
	local i =2
	foreach cc of local benchmark {
		replace order = `i' if code=="`cc'"
		local i = `i' + 1
	}
	if "`core'"=="" {
		local tbltxt "Table 10. Benchmarking of poverty and inequality"
		local tblname Table10
	}
	else {
		local tbltxt "Table A.3. Benchmarking of poverty and inequality"
		local tblname TableA3
	}
	
	collect clear
	qui collect: table (order name) (group indicatorlbl), stat(mean value) nototal nformat(%20.2f) missing
	collect style header order name group indicatorlbl, title(hide)
	collect style header order, level(hide)
	collect style header group[0], level(hide)
	*collect style cell, result halign(center)
	collect title `"`tbltxt'"'
	collect notes 1: `"Source: World Bank calculations using survey data accessed from the Global Monitoring Database and the World Development Indicators."'
	collect notes 2: `"Note: Poverty rates reported for the $2.15, $3.65, and $6.85 per person per day poverty lines are expressed in 2017 purchasing power parity dollars. These three poverty lines reflect the typical national poverty lines of low-income countries, lower-middle-income countries, and upper-middle-income countries, respectively. The Gini index is a measure of inequality ranging from 0 (perfect equality) to 100 (perfect inequality). The Prosperity Gap captures how far a society is from $25 per person per day (expressed in 2017 purchasing power parity dollars), which is close to the average per capita household income when countries reach high-income status."'
	collect style notes, font(, italic size(10))
	collect preview
	
	if "`excel'"=="" {
		collect export "`dirpath'\\`tblname'.xlsx", sheet(`tblname') modify 	
		shell start excel "`dirpath'\\`tblname'.xlsx"
	}
	else {
		collect export "`excelout'", sheet(`tblname', replace) modify 
	}	
end