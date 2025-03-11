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

	syntax [if] [in] [aw pw fw], [* NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) Year(varname numeric) SETting(string) excel(string) save(string) BYInd(varlist numeric) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) married(varname numeric) school(varname numeric) services(varlist numeric) assets(varlist numeric) hhsize(varname numeric) hhid(string) pid(string) industrycat4(varname numeric) lstatus(varname numeric) empstat(varname numeric) ONELine(varname numeric) ONEWelfare(varname numeric) MISSING Country(string) within(integer 3) COMBINE COMParability(varname numeric) BENCHmark(string) spells(string) NOEQUALSPACING YRange(string) trim(string) BAR RELATIVECHANGE ineqind(string) idpl(varname numeric) earnage(integer 18) scheme(string) palette(string) welfaretype(string)]	
	
	global floor_ 0.25
	global prosgline_ 25
	
	//load setting
	qui if "`setting'"=="GMD" {
		_pea_vars_set, setting(GMD)
		local vlist age male hhhead edu urban married school hhid pid hhsize industrycat4 empstat lstatus services assets relationharm
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
	putexcel set "`excelout'", replace sheet("Figure list")
	putexcel C5 = "Poverty and Equity Assessments"
	putexcel C6 = "Additional Figures"
	putexcel C10 = "Generated Figures:"
	qui putexcel save
	
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
	global tablecount = 11
	
	//Figure 16
	qui use `dataori0', clear	
	  pea_figure16, onew(`onewelfare') onel(`oneline') year(`year')  age(`age') male(`male') edu(`edu') hhhead(`hhhead') hhid(`hhid') pid(`pid') urban(`urban') married(`married') industrycat4(`industrycat4') lstatus(`lstatus') empstat(`empstat') hhsize(`hhsize') relationharm(`relationharm') earnage(`earnage') missing scheme(`scheme') palette(`palette') excel("`excelout'")
	if _rc==0 {
		noi dis in green "Figure 16....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Figure list")
		putexcel C${tablecount} = "Figure 16a/16b/16c/16d. Share of poor by demographic and economic typologies"
		global tablecount = ${tablecount} + 1
		qui putexcel save	
	}
	else noi dis in red "Figure 16....... Not done"
	
	
	//Final open	
	if `ok'==1 {
		shell start excel "`excelout'"
		noi dis in green "Figures are done....... Loading the Excel file!"
	}
	else {
		noi dis in red "No figures are produced"
	}
end