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

cap program drop _pea_povlines_check
program _pea_povlines_check, rclass
	version 16.0
	
	syntax [if] [in], [povlines(varlist numeric) PPPyear(integer 2017)]	
	
	if `pppyear'==2017 {
		local vlinecheck "2.15, 3.65, 6.85"
		local vlinetxt "$2.15, $3.65, and $6.85"
		local vlineval "215 365 685"
	}
	else if `pppyear'==2011 {
		local vlinecheck "1.90, 3.20, 5.50"
		local vlinetxt "$1.90, $3.20, and $5.50"
		local vlineval "190 320 550"
	}
	else if `pppyear'==2021 {
		local vlinecheck "3.00, 4.20, 8.30"	
		local vlinetxt "$3.00, $4.20, and $8.30"
		local vlineval "300 420 830"
	}
	*else if `pppyear'==2005 local vlinecheck "1.25, 4.20, 8.30"
	else {
		noi disp in red "This is new PPP, we dont have it yet. Or it is very old PPP and we dont use it anymore."
		error 198
	}
	//check value of poverty lines
	foreach var of varlist `povlines' {
		quietly sum `var'
		local xval = r(mean)
		local xval : display %4.2f `xval'
		if !inlist(`=trim("`xval'")', `vlinecheck') {
			noi disp in red "Value of poverty line (`=trim("`xval'")') is not among the standard poverty lines (`vlinecheck') for the `pppyear' PPP. Please check again the variables in Povlines() option."
			error 198
		}
	}
	return local vlinetxt "`vlinetxt'"
	return local vlineval "`vlineval'"
end