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

//Table 10 _ Benchmark of countries
//WDI, PIP, Data latest
cap program drop pea_table10
program pea_table10, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) Welfare(varname numeric) Povlines(varlist numeric) Year(varname numeric) BENCHmark(string) core setting(string) linesorted excel(string) save(string) fgtvars latest within3 fgtvars]
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
		//FGT
		if "`welfare'"~="" & "`povlines'"~="" _pea_gen_fgtvars if `touse', welf(`welfare') povlines(`povlines')		
	}	
	drop _fgt1* _fgt2*	
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
	
	//obtain the data then move to frames so next time running is faster
	//GDP https://data.worldbank.org/indicator/NY.GDP.PCAP.KD.
	pip tables, table(gdp) clear
	ren country_code code
	keep if data_level=="national"
	ren value gdppc
	tempfile gdppc
	save `gdppc', replace
	keep if code=="`country'" & year==`ymax'
	if _N==0 {
		noi dis in y "Warning: no GDPPC data or wrong country code"
		local gdpv .
	}
	else {
		local gdpv `=gdppc[1]'
	}
	
	//country list and region_code
	tempfile codereglist
	pip tables, table(countries) clear
	ren country_code code
	replace region_code = africa_split_code if africa_split_code~=""
	save `codereglist'
	
	keep if code=="`country'"
	
	if _N==0 {
		noi dis in y "Warning: wrong country code"
		error 1
	}
	else {
		local regcode `=region_code[1]'
		local ctryname `=country_name[1]'
	}
	
	//PIP poverty and pros gap
	clear
	tempfile povdata povben
	save `povben', replace emptyok
	
	pip, country(all) year(all) ppp(2017) povline(2.15) clear
	ren headcount headcount215	
	drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")
	keep country_code country_name year headcount215 pg gini survey_acronym welfare_type
	save `povdata', replace
	
	pip, country(all) year(all) ppp(2017) povline(3.65) clear
	ren headcount headcount365	
	drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")
	keep country_code year headcount365 survey_acronym welfare_type
	merge 1:1 country_code year survey_acronym welfare_type using `povdata'
	ta _merge
	drop _merge
	save `povdata', replace
	
	pip, country(all) year(all) ppp(2017) povline(6.85) clear
	ren headcount headcount685
	drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")
	keep country_code year headcount685 survey_acronym welfare_type
	merge 1:1 country_code year survey_acronym welfare_type using `povdata'
	ta _merge
	drop _merge
	
	gen code = country_code
	gen welfaretype= "CONS" if welfare_type==1
	replace welfaretype= "INC" if welfare_type==2
	for var headcount*: replace X = X*100
	
	merge m:1 code year using `gdppc', keepus(gdppc)
	drop if _merge==2
	drop _merge
	save `povdata', replace
	
	foreach cc of local benchmark {
		local cc "`=upper("`cc'")'"
		use `povdata' if code=="`cc'", clear
		if "`latest'"~="" {
			su year,d			
			local ymax1 = r(max)
			keep if year==`ymax1'
			ren country_name name
			keep name code year survey_acronym headcount* gini pg gdppc
			append using `povben'
			save `povben', replace
		}
		
		if "`within3'"~="" {
			keep if year>=`=`ymax'-3' & year<=`=`ymax'+3'
			if _N==0 {
				noi dis in y "No data for `code'."
			}
			else if _N==1 {
				ren country_name name
				keep name code year survey_acronym headcount* gini pg gdppc
				append using `povben'
				save `povben', replace
			}
			else {
				gen diff = abs(year - `ymax')
				su diff,d
				local rmin = r(min)
				keep if diff==`rmin'
				*if _N==1 {
					ren country_name name
					keep name code year survey_acronym headcount* gini pg gdppc
					append using `povben'
					save `povben', replace
				*}
			} //else
		} //within3		
	} //benchmark
	
	//lineup estimates
	tempfile povlineup	
	pip, country(all) year(all) ppp(2017) povline(2.15) clear fillgap
	ren headcount headcount215	
	drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")
	keep country_code year  headcount215 pg   welfare_type
	save `povlineup', replace
	
	pip, country(all) year(all) ppp(2017) povline(3.65) clear fillgap
	ren headcount headcount365
	*ren pg pg365
	drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")
	keep country_code year  headcount365   welfare_type
	merge 1:1 country_code year  welfare_type using `povlineup'
	ta _merge
	drop _merge
	save `povlineup', replace
	
	pip, country(all) year(all) ppp(2017) povline(6.85) clear fillgap
	ren headcount headcount685
	*ren pg pg685
	drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")
	keep country_code year  headcount685   welfare_type
	merge 1:1 country_code year  welfare_type using `povlineup'
	ta _merge
	drop _merge
	
	gen code = country_code
	gen welfaretype= "CONS" if welfare_type==1
	replace welfaretype= "INC" if welfare_type==2
	for var headcount*: replace X = X*100
	save `povlineup', replace
	
	//regional
	tempfile regional regdata
	pip wb, region(all)  ppp(2017) povline(2.15) 
	ren headcount headcount215		
	keep region_name region_code year  headcount215 pg 
	save `regional', replace
	
	pip wb, region(all)  ppp(2017) povline(3.65) 
	ren headcount headcount365		
	keep region_code year  headcount365
	merge 1:1 region_code year using `regional'
	drop _merge
	save `regional', replace
	
	pip wb, region(all)  ppp(2017) povline(6.85) 
	ren headcount headcount685	
	keep region_code year  headcount685
	merge 1:1 region_code year using `regional'
	drop _merge
	for var headcount*: replace X = X*100
	save `regional', replace
	
	keep if region_code=="`regcode'" & year==`ymax'
	ren region_name name
	ren region_code code
	keep code name year headcount* pg
	save `regdata', replace
	
	//Bring all back
	use `data2', clear	
	replace gdppc = `gdpv'
	gen region_code = "`regcode'"
	gen name = "`ctryname'"
	
	append using `regdata'
	append using `povben'
	
	drop region_code
	ren * var_*
	ren var_code code
	ren var_survey_acronym survey_acronym
	replace var_name = "Country of analysis" if code=="`country'"
	replace var_name = "Peer " + var_name if code~="`regcode'" & code~="`country'"
	gen name = var_name + " (" + string(var_year) +")" if code=="`regcode'" | code=="`country'"
	replace name = var_name + " (" + survey_acronym + "," + string(var_year) +")" if code~="`regcode'" & code~="`country'"
	
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
	collect notes 1: `"Source: ABC"'
	collect notes 2: `"Note: The global ..."'
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