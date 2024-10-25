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

cap program drop pea_core
program pea_core, rclass
	version 18.0	
	syntax [if] [in] [aw pw fw], [* NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric)  Year(varname numeric) SETting(string) excel(string) save(string) BYInd(varlist numeric) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) married(varname numeric) school(varname numeric) services(varlist numeric) assets(varlist numeric) hhsize(varname numeric) hhid(string) pid(string) industrycat4(varname numeric) lstatus(varname numeric) empstat(varname numeric) ONELine(varname numeric) ONEWelfare(varname numeric) missing Country(string) latest within3 BENCHmark(string)]	
	
	//house cleaning
	if "`excel'"=="" {
		tempfile xlsxout 	
		local path "`xlsxout'"		
		local lastslash = strrpos("`path'", "\") 				
		local dirpath = substr("`path'", 1, `lastslash')
		//random string generator to filename
		local excelout "`dirpath'\\__Tables_.xlsx"
		putexcel set `excelout', replace sheet("Table list")
		putexcel A1 = "Tables"
		putexcel save
	}
	else {
		cap confirm file "`excel'"
		if _rc~=0 {
			noi dis as error "Unable to confirm the file in excel()"
			error `=_rc'	
		}
		else local excelout "`excel'"
	}
	
	//load setting
	if "`setting'"=="GMD" {
		_pea_vars_set, setting(GMD)
		local vlist age male hhhead edu urban married school hhid pid hhsize industrycat4 empstat lstatus services assets
		foreach st of local vlist {
			local `st' "${pea_`st'}"
		}		
	}
	
	if "`latest'"~="" & "`within3'"~="" {
		noi dis as error "Either latest or wtihin3, not both options"
		error 1
	}
	if "`latest'"=="" & "`within3'"=="" local latest latest
	
	qui {
		local country "`=upper("`country'")'"
		cap drop code
		gen code = "`country'"
		//order the lines
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
	
	//FGT
	if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
	if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
	
	//B40 T60 Mean - only for one distribution
	if "`natwelfare'"~="" & "`pppwelfare'"~="" local distwelf `natwelfare'
	if "`natwelfare'"=="" & "`pppwelfare'"~="" local distwelf `pppwelfare'
	_pea_gen_b40 [aw=`wvar'] if `touse', welf(`distwelf') by(`year')
	clonevar _Gini_`distwelf' = `distwelf' if `touse'
	gen double _prosgap_`pppwelfare' = 25/`pppwelfare' if `touse'
	gen double _pop = `wvar'
	
	tempfile data1 data2
	save `data1', replace
	
	//house cleaning
	//variable checks
	//trigger
	//order the lines , then pass sorted line to table commands
	//table 1
	use `data1', clear
	pea_table1 [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') fgtvars linesorted excel(`excelout') core
	
	//table 2
	use `dataori', clear	
	*if "`oneline'"~="" local maxline `oneline'
	*else local maxline = word("`ppppovlines'", -1)
	pea_table_A2 [aw=`wvar'], pppw(`onewelfare') pppp(`oneline') year(`year') byind(`byind') age(`age') male(`male') edu(`edu') `missing' excel(`excelout')
	
	//table 3
	use `dataori', clear
	pea_table10 [aw=`wvar'], c(`country') welfare(`pppwelfare') povlines(`ppppovlines') year(`year') benchmark(`benchmark') `latest' `within3' linesorted fgtvars excel(`excelout') core

	//table 4
	use `dataori', clear	
	*if "`oneline'"~="" local maxline `oneline'
	*else local maxline = word("`ppppovlines'", -1)	
	pea_table14 [aw=weight_p], welfare(`onewelfare') povlines(`oneline') year(`year') `missing' age(`age') male(`male') edu(`edu') hhhead(`hhhead')  urban(`urban') married(`married') school(`school') services(`services') assets(`assets') hhsize(`hhsize') hhid(`hhid') pid(`pid') industrycat4(`industrycat4') lstatus(`lstatus') empstat(`empstat') core excel(`excelout')
	
	shell start excel "`excelout'"
	
end