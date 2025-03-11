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

cap program drop pea_tables
program pea_tables, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [* NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric)  Year(varname numeric) SETting(string) excel(string) save(string) BYInd(varlist numeric) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) married(varname numeric) school(varname numeric) services(varlist numeric) assets(varlist numeric) hhsize(varname numeric) hhid(string) pid(string) industrycat4(varname numeric) lstatus(varname numeric) empstat(varname numeric) relationharm(varname numeric) missing ONELine(varname numeric) ONEWelfare(varname numeric) Country(string) vulnerability(string) LATEST WITHIN3 BENCHmark(string) spells(string) earnage(integer 18) minobs(numlist)]	
	
	global floor_ 0.25
	global prosgline_ 25
	
	//house cleaning
	qui if "`excel'"=="" {
		tempfile xlsxout 	
		local path "`xlsxout'"		
		local lastslash = strrpos("`path'", "\") 				
		local dirpath = substr("`path'", 1, `lastslash')
		local date = c(current_date)
		local time = c(current_time) 
		local time : subinstr local time ":" "_", all		
		local excelout "`dirpath'\\PEA_tables_`date'_`time'.xlsx"		
	}
	else {
		cap confirm file "`excel'"
		if _rc~=0 {
			noi dis as error "Unable to confirm the file in excel()"
			error `=_rc'	
		}
		else local excelout "`excel'"
	}
	//Title sheet
	putexcel set "`excelout'", replace sheet("Table list")
	putexcel C5 = "Poverty and Equity Assessments"
	putexcel C6 = "Additional Tables"
	putexcel C10 = "Generated Tables:"
	qui putexcel save
		
	if "`latest'"~="" & "`within3'"~="" {
		noi dis as error "Either latest or wtihin3, not both options"
		error 1
	}
	if "`latest'"=="" & "`within3'"=="" local latest latest
	
	//load setting
	qui if "`setting'"=="GMD" {
		_pea_vars_set, setting(GMD)
		local vlist age male hhhead edu urban married school hhid pid hhsize industrycat4 empstat lstatus services assets relationharm
		foreach st of local vlist {
			local `st' "${pea_`st'}"
		}	
	}
	//check oneline and onewelfare goes together?
	
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

		//FGT
		if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
		if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
		
		//B40 T60 Mean - only for one distribution
		if "`natwelfare'"~="" & "`pppwelfare'"~="" local distwelf `natwelfare'
		if "`natwelfare'"=="" & "`pppwelfare'"~="" local distwelf `pppwelfare'
		_pea_gen_b40 [aw=`wvar'] if `touse', welf(`distwelf') by(`year')
		clonevar _Gini_`distwelf' = `distwelf' if `touse'
		gen double _prosgap_`pppwelfare' = 25/`pppwelfare' if `touse'
		gen _vulpov_`onewelfare'_`oneline' = `onewelfare'< `oneline'*1.5  if `touse'	
		gen double _pop = `wvar'
		
		tempfile data1 data2
		save `data1', replace
	} //qui


	global tablecount = 11
	//table 1
	qui use `data1', clear
	cap pea_table1 [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') fgtvars linesorted excel("`excelout'") oneline(`oneline') onewelfare(`onewelfare')
	if _rc==0 {
		noi dis in green "Table 1....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Table list")
		putexcel C${tablecount} = "Table 1. Core poverty indicators"
		global tablecount = ${tablecount} + 1
		qui putexcel save	
	}
	else noi dis in red "Table 1....... Not done"
	
	//table 2
	qui use `data1', clear
	cap pea_table2 [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') byind(`byind') minobs(`minobs') fgtvars linesorted excel("`excelout'") `missing'
	if _rc==0 {
		noi dis in green "Table 2....... Done"
		local ok = 1
		di "`excelout'"
		putexcel set "`excelout'", modify sheet("Table list")
		putexcel C${tablecount} = "Table 2. Core poverty indicators by geographic areas"
		global tablecount = ${tablecount} + 1
		qui putexcel save	
	}
	else noi dis in red "Table 2....... Not done"

	//table 3
	qui use `data1', clear
	cap pea_table3 [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') fgtvars linesorted excel("`excelout'") age(`age') male(`male') hhhead(`hhhead') edu(`edu') minobs(`minobs') `missing'
	if _rc==0 {
		noi dis in green "Table 3....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Table list")
		putexcel C${tablecount} = "Table 3. Subgroup poverty rates"
		global tablecount = ${tablecount} + 1
		qui putexcel save	
	}
	else noi dis in red "Table 3....... Not done"
	
	//table 6
		qui use `data1', clear
		cap pea_table6 [aw=`wvar'], c(`country') welfare(`pppwelfare') year(`year')  benchmark(`benchmark') last3 excel("`excelout'")
		if _rc==0 {
			noi dis in green "Table 6....... Done"
			local ok = 1
			putexcel set "`excelout'", modify sheet("Table list")
			putexcel C${tablecount} = "Table 6a/6b. Multidimensional Poverty Measure across benchmark countries and by component"
			global tablecount = ${tablecount} + 1	
			qui putexcel save	
		}
		else noi dis in red "Table 6....... Not done"
	
	
	//table 7
	qui use `data1', clear
	cap pea_table7 [aw=`wvar'], welfare(`onewelfare') povlines(`oneline') year(`year') vulnerability(`vulnerability') excel("`excelout'") 
	if _rc==0 {
		noi dis in green "Table 7....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Table list")
		putexcel C${tablecount} = "Table 7. Poverty vulnerability"
		global tablecount = ${tablecount} + 1	
		qui putexcel save	
	}
	else noi dis in red "Table 7....... Not done"
	
	//table 8
	qui use `data1', clear
	cap pea_table8 [aw=`wvar'], welfare(`onewelfare') year(`year') excel("`excelout'") missing
	if _rc==0 {
		noi dis in green "Table 8....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Table list")
		putexcel C${tablecount} = "Table 8. Core inequality indicators"
		global tablecount = ${tablecount} + 1	
		qui putexcel save	
	}
	else noi dis in red "Table 8....... Not done"
	
	//table 9
	qui use `data1', clear
	cap pea_table9, c(`country') year(`year') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Table 9....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Table list")
		putexcel C${tablecount} = "Table 9. Scorecard Vision Indicators"
		global tablecount = ${tablecount} + 1	
		qui putexcel save	
	}
	else noi dis in red "Table 9....... Not done"
	
	//table 10
	qui use `dataori', clear
	cap pea_table10 [aw=`wvar'], c(`country') welfare(`pppwelfare') povlines(`ppppovlines') year(`year') benchmark(`benchmark') `latest' `within3' linesorted excel("`excelout'") 
	if _rc==0 {
		noi dis in green "Table 10...... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Table list")
		putexcel C${tablecount} = "Table 10. Benchmarking of poverty and inequality"
		global tablecount = ${tablecount} + 1	
		qui putexcel save	
	}
	else noi dis in red "Table 10...... Not done"

	//table 12
	qui use `dataori', clear
	cap pea_table12 [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') spells(`spells') year(`year') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Table 12...... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Table list")
		putexcel C${tablecount} = "Table 12. Datt-Ravallion and Shorroks-Kolenikov decompositions"
		global tablecount = ${tablecount} + 1	
		qui putexcel save	
	}
	else noi dis in red "Table 12...... Not done"
	
	//table 13
	if "`urban'"~="" {
		qui use `dataori', clear
		cap pea_table13 [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') spells(`spells') year(`year') urban(`urban') excel("`excelout'")
		if _rc==0 {
			noi dis in green "Table 13...... Done"
			local ok = 1
		putexcel set "`excelout'", modify sheet("Table list")
		putexcel C${tablecount} = "Table 13. Huppi-Ravallion decomposition"
		global tablecount = ${tablecount} + 1	
		qui putexcel save	
		}
		else noi dis in red "Table 13....... Not done"
	}
	
	//table 14a
	qui use `dataori', clear		
	cap pea_table14a [aw=weight_p], welfare(`onewelfare') povlines(`oneline') year(`year') `missing' age(`age') male(`male') edu(`edu') hhhead(`hhhead')  urban(`urban') married(`married') school(`school') services(`services') assets(`assets') hhsize(`hhsize') hhid(`hhid') pid(`pid') industrycat4(`industrycat4') lstatus(`lstatus') empstat(`empstat') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Table 14...... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Table list")
		putexcel C${tablecount} = "Table 14a. Profiles of the poor"
		global tablecount = ${tablecount} + 1	
		qui putexcel save	
	}
	else noi dis in red "Table 14...... Not done"
	
	//table 14b
	qui use `dataori', clear		
	cap pea_table14b [aw=weight_p], welfare(`onewelfare') povlines(`oneline') year(`year') `missing' age(`age') male(`male') hhsize(`hhsize') hhid(`hhid') pid(`pid') lstatus(`lstatus') empstat(`empstat') relationharm(`relationharm') earnage(`earnage') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Table 14b...... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Table list")
		putexcel C${tablecount} = "Table 14b. Demographic and economic household typologies"
		global tablecount = ${tablecount} + 1	
		qui putexcel save	
	}
	else noi dis in red "Table 14b...... Not done"
	
	//table 15
	qui use `dataori', clear		
	cap pea_table15 [aw=weight_p], welfare(`onewelfare') year(`year') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Table 15...... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Table list")
		putexcel C${tablecount} = "Table 15. Distribtion of welfare by deciles"
		global tablecount = ${tablecount} + 1
		qui putexcel save	
	}
	else noi dis in red "Table 15...... Not done"
	
	//Final open	
	if `ok'==1 {
		shell start excel "`excelout'"
		noi dis in green "Tables and Graphs are done....... Loading the Excel file!"
	}
	else {
		noi dis in red "No tables and graphs are produced"
	}
end