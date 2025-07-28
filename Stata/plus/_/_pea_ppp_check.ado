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

cap program drop _pea_ppp_check
program _pea_ppp_check, rclass
	version 16.0
	
	syntax [if] [in], [PPPyear(integer 2021)]
	if !inlist(`pppyear', 2005, 2011, 2017, 2021) {
		noi disp in red "PPP must be either 2005 or 2011 or 2017 or 2021. Default 2021."
		error 198
	}
	else {
		if `pppyear'==2017 {
			global floor_ 0.25
			global prosgline_ 25
		}
		else if `pppyear'==2021 {
			global floor_ 0.28
			global prosgline_ 28
		}
		else {
			noi disp in red "No floor and prosperity gap for this `pppyear'. Assumed the latest one in 2017 PPP."
			global floor_ 0.25
			global prosgline_ 25
		}		
	}
	
end