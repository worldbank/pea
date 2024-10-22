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
	syntax [if] [in] [aw pw fw], [PPPWelfare(varname numeric) PPPPovlines(varlist numeric) Year(varname numeric) BENCHmark(string) excel(string)]
	
	//GDP
	pip tables, table(gdp) clear
	ren country_code code
	keep if data_level=="national"
	ren value gdppc
	tempfile gdppc
	save `gdppc', replace
	
	//PIP poverty and pros gap
	tempfile povdata
	pip, country(all) year(all) ppp(2017) povline(2.15) clear
	ren headcount headcount215	
	drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")
	keep country_code year  headcount215 pg gini survey_acronym welfare_type
	save `povdata', replace
	
	pip, country(all) year(all) ppp(2017) povline(3.65) clear
	ren headcount headcount365
	*ren pg pg365
	drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")
	keep country_code year  headcount365  survey_acronym welfare_type
	merge 1:1 country_code year survey_acronym welfare_type using `povdata'
	ta _merge
	drop _merge
	save `povdata', replace
	
	pip, country(all) year(all) ppp(2017) povline(6.85) clear
	ren headcount headcount685
	*ren pg pg685
	drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
	drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")
	keep country_code year  headcount685  survey_acronym welfare_type
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
	
	
	
end