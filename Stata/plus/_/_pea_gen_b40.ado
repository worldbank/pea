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

cap program drop _pea_gen_b40
program _pea_gen_b40, rclass
	version 16.0
	syntax [if] [in] [aw pw fw], [welf(varname numeric) by(varname numeric)]	

	//Weights
	local wvar : word 2 of `exp'
	if "`wvar'"=="" {
		tempvar w
		gen `w' = 1
		local wvar `w'
	}
	
	//missing observation check
	marksample touse
	local flist `"`by' `wvar' `welf'"'
	markout `touse' `flist' 
	
	if "`welf'"=="" {
		noi di in red "Variable welf() is missing. Please specify it"
		return local _pea_gen_b40 = 0
		exit 1
	}
	
	if "`by'"=="" {
		gen __by = 1
		local by __by
	}
	
	levelsof `by', local(bylist)
	gen __quintile = .
	foreach by1 of local bylist {
		tempvar qwlf
		cap _ebin `welf' [aw=`wvar'] if `touse' & `by'==`by1', nquantiles(5) gen(`qwlf')
		if _rc!=0 {
			noi di in red "Error in creating B40/T60 in _pea_gen_b40 for `by1'"
			return local _pea_gen_b40 = 0
			exit `=_rc'
		} 
		else {
			replace __quintile = `qwlf' if `touse' & `by'==`by1' & __quintile==.
		}
		drop `qwlf'
	}
	cap drop __by
	clonevar _WELFMEAN_`welf' = `welf' if `touse'
	gen _B40_`welf' = __quintile <= 2 if `touse'
	gen _T60_`welf' = _B40_`welf' ==0 if _B40_`welf'!=. & `touse'
	gen _popB40_`welf' = `wvar' if _B40_`welf'==1 & `touse'
	gen _popT60_`welf' = `wvar' if _B40_`welf'==0 & `touse'
	return local _pea_gen_b40 = 1
end