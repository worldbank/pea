*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 
*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Henry Stemmler <hstemmler@worldbank.org>; Sandra Carolina Segovia Juarez <ssegoviajuarez@worldbank.org>
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

cap program drop pea_figures
program pea_figures, rclass
	version 18.0	

	syntax [if] [in] [aw pw fw], [* NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) Year(varname numeric) SETting(string) excel(string) save(string) BYInd(varlist numeric) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) married(varname numeric) school(varname numeric) services(varlist numeric) assets(varlist numeric) hhsize(varname numeric) hhid(string) pid(string) industrycat4(varname numeric) lstatus(varname numeric) empstat(varname numeric) ONELine(varname numeric) ONEWelfare(varname numeric) MISSING Country(string) within(integer 3) COMBINE NONOTES COMParability(varname numeric) BENCHmark(string) spells(string) EQUALSPACING YRange0 scheme(string) palette(string) welfaretype(string)]	
	
	global floor_ 0.25
	global prosgline_ 25
	
	//load setting
	qui if "`setting'"=="GMD" {
		_pea_vars_set, setting(GMD)
		local vlist age male hhhead edu urban married school hhid pid hhsize industrycat4 empstat lstatus services assets
		foreach st of local vlist {
			local `st' "${pea_`st'}"
		}		
	}
	
	//house cleaning
	if "`within'"=="" local within 3
	if `within'>10 {
		noi dis as error "Surveys older than 10 years should not be used for comparisons. Please use a different value in within()"
		error 1
	}
	if "`welfaretype'"=="" {
		noi di in red "Please define welfare type as INC or CONS in welfaretype()"
		exit 1
	}
	else {
		local welfaretype "`=upper("`welfaretype'")'"
		if "`welfaretype'" ~= "INC" & "`welfaretype'" ~= "CONS" {	// Check that values are correct
			noi di in red "Please define welfare type as INC or CONS in welfaretype()"
			exit 1
		}
	}
		
	//variable checks
	//missing rate of key variables
	qui if "`excel'"=="" {
		tempfile xlsxout 	
		local path "`xlsxout'"		
		local lastslash = strrpos("`path'", "\") 				
		local dirpath = substr("`path'", 1, `lastslash')
		local date = c(current_date)
		local time = c(current_time) 
		local time : subinstr local time ":" "_", all		
		local excelout "`dirpath'\\PEA_figures_`date'_`time'.xlsx"
		putexcel set "`excelout'", replace sheet("Table list")
		putexcel C10 = "Graphs"
		putexcel C11 = "PEA - Poverty analytics"
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
		
		tempfile dataori0 datalbl
		save `dataori0', replace
		des, replace clear
		save `datalbl', replace
		use `dataori0', clear
	
		//FGT
		if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
		if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
		
		//Gini and PG
		if "`natwelfare'"~="" & "`pppwelfare'"~="" local distwelf `natwelfare'
		if "`natwelfare'"=="" & "`pppwelfare'"~="" local distwelf `pppwelfare'
		clonevar _Gini_`distwelf' = `distwelf' if `touse'
		noi dis "Replace the bottom for Prosperity gap at $0.25 2017 PPP"
		replace `pppwelfare' = ${floor_} if `pppwelfare'< ${floor_}		
		gen double _prosgap_`pppwelfare' = ${prosgline_}/`pppwelfare' if `touse'
		gen double _pop = `wvar'
		
		//B40 T60 Mean - only for one distribution
		_pea_gen_b40 [aw=`wvar'] if `touse', welf(`distwelf') by(`year')
		gen _vulpov_`onewelfare'_`oneline' = `onewelfare'< `oneline'*1.5  if `touse'
		
		tempfile data1 data2
		save `data1', replace
	} //qui
	
	//trigger
	
	//Figure 1
	qui use `data1', clear	
	cap pea_figure1 [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') fgtvars linesorted urban(`urban') comparability(`comparability') `combine' `nonotes' `equalspacing' `yrange0' scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 1....... Done"
		local ok = 1
	}
	else noi dis in red "Figure 1....... Not done"
	
	//Figure 2
	qui use `data1', clear
	cap pea_figure2 [aw=`wvar'], c(`country') year(`year') benchmark(`benchmark') fgtvars onewelfare(`onewelfare') oneline(`oneline') `nonotes' scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 2....... Done"
		local ok = 1
	}
	else noi dis in red "Figure 2....... Not done"
	
	//Figure 3
	qui use `dataori0', clear
	cap pea_figure3 [aw=`wvar'], year(`year') welfare(`onewelfare') comparability(`comparability') spells(`spells') `nonotes' scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 3....... Done"
		local ok = 1
	}
	else noi dis in red "Figure 3....... Not done"
	
	//Figure 4
	qui use `dataori0', clear
	cap pea_figure4 [aw=`wvar'], year(`year') onew(`onewelfare') onel(`oneline') `nonotes' comparability(`comparability') spells(`spells') scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 4....... Done"
		local ok = 1
	}
	else noi dis in red "Figure 4....... Not done"
	
	//Figure 5
	qui use `dataori0', clear
	cap pea_figure5 [aw=weight_p], year(`year') onew(`onewelfare') onel(`oneline') `nonotes' comparability(`comparability') spells(`spells') urban(`urban') scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 5....... Done"
		local ok = 1
	}
	else noi dis in red "Figure 5....... Not done"
	
	//Figure 6
	qui use `dataori0', clear	
	cap pea_figure6 [aw=`wvar'], c(`country') year(`year') oneline(`oneline') onewelfare(`onewelfare') comparability(`comparability') spells(`spells')  `nonotes' scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 6....... Done"
		local ok = 1
	}
	else noi dis in red "Figure 6....... Not done"
	
	//Figure 7
	qui use `data1', clear	
	cap pea_figure7 [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') fgtvars linesorted `nonotes' age(`age') male(`male') edu(`edu') urban(`urban') scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 7....... Done"
		local ok = 1
	}
	else noi dis in red "Figure 7....... Not done"
	
	//Figure 8 - TBC
	
	//Figure 9a
	qui use `dataori0', clear	
	cap pea_figure9a [aw=`wvar'], year(`year') onewelfare(`onewelfare') urban(`urban') comparability(`comparability') `nonotes' `equalspacing' `yrange0' scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 9a...... Done"
		local ok = 1
	}
	else noi dis in red "Figure 9a...... Not done"
	
	//Figure 9b
	qui use `dataori0', clear	
	cap pea_figure9b [aw=`wvar'], c(`country') year(`year') benchmark(`benchmark') onewelfare(`onewelfare') welfaretype(`welfaretype') within(`within') `nonotes' scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 9b...... Done"
		local ok = 1
	}
	else noi dis in red "Figure 9b...... Not done"
	
	//Figure 10a
	qui use `dataori0', clear	
	cap pea_figure10a [aw=`wvar'], year(`year') onewelfare(`onewelfare') urban(`urban') comparability(`comparability') `nonotes' `equalspacing' `yrange0' scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 10a...... Done"
		local ok = 1
	}
	else noi dis in red "Figure 10a...... Not done"
	
	//Figure 10b
	qui use `dataori0', clear	
	cap pea_figure10b [aw=`wvar'], c(`country') year(`year') benchmark(`benchmark') onewelfare(`onewelfare') `nonotes' scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 10b...... Done"
		local ok = 1
	}
	else noi dis in red "Figure 10b...... Not done"
	
	//Figure 10c
	qui use `dataori0', clear	
	cap pea_figure10c [aw=`wvar'], c(`country') year(`year') benchmark(`benchmark') onewelfare(`onewelfare') within(`within') `nonotes' scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 10c...... Done"
		local ok = 1
	}
	else noi dis in red "Figure 10c...... Not done"

	//Figure 11 TBC
	
	//Figure 12
	qui use `dataori0', clear
	cap pea_figure12 [aw=`wvar'], c(`country') year(`year') onew(`onewelfare') comparability(`comparability') spells(`spells')  `nonotes' palette(`palette') scheme(`scheme') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 12....... Done"
		local ok = 1
	}
	else noi dis in red "Figure 12....... Not done"
	
	//Figure 13
	qui use `dataori0', clear
	cap pea_figure13 [aw=`wvar'], year(`year') onew(`onewelfare') comparability(`comparability') `nonotes' `equalspacing' palette(`palette') scheme(`scheme') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 13....... Done"
		local ok = 1
	}
	else noi dis in red "Figure 13....... Not done"
	
	//Figure 14
	if "`setting'"=="GMD" {
		qui use `dataori0', clear
		cap pea_figure14 [aw=`wvar'], c(`country') welfare(welfppp) year(`year') benchmark(`benchmark') within(`within') `nonotes' palette(`palette') scheme(`scheme') excel("`excelout'")
		if _rc==0 {
			noi dis in green "Figure 14....... Done"
			local ok = 1
		}
		else noi dis in red "Figure 14....... Not done"
	}
	
	//Figure 15
	qui use `dataori0', clear	
	cap pea_figure15, c(`country') `nonotes' scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 15....... Done"
		local ok = 1
	}
	else noi dis in red "Figure 15....... Not done - no data for `country'"
	
	//Final open	
	if `ok'==1 {
		shell start excel "`excelout'"
		noi dis in green "Figures are done....... Loading the Excel file!"
	}
	else {
		noi dis in red "No figures are produced"
	}
end