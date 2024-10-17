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

cap program drop _pea_gen_fgtvars
program _pea_gen_fgtvars, rclass
	version 16.0
	syntax [if] [in], [welf(varname numeric) povlines(varlist numeric)]	
	
	//missing observation check
	marksample touse
	local flist `"`welf' `povlines'"'
	markout `touse' `flist' 
	
	*_gen_fgt_vars, welf(`natwelfare') povlines(`natpovlines')
	if "`welf'"~="" & "`povlines'"~="" {
		foreach var of local welf {
			foreach pl of local povlines {
				forval a=0/2 {
					cap gen _fgt`a'_`var'_`pl' = (`var' < `pl')*((1-(`var'/`pl'))^`a') if `var'~=. & `touse'
					if _rc~=0 {
						noi di in red "Variable (_fgt`a'_`var'_`pl') is already created before, drop the variable"
						return local _pea_gen_fgtvars = 0
						exit 1
					}
				}
			}	
		}
		return local _pea_gen_fgtvars = 1
	}
end