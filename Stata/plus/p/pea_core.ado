*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 
*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Sandra Carolina Segovia Juarez <ssegoviajuarez@worldbank.org>; Henry Stemmler <hstemmler@worldbank.org>
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
	syntax [if] [in] [aw pw fw], [* NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric)  Year(varname numeric) SETting(string) excel(string) save(string) BYInd(varlist numeric) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) married(varname numeric) school(varname numeric) services(varlist numeric) assets(varlist numeric) hhsize(varname numeric) hhid(string) pid(string) industrycat4(varname numeric) industrycat10(varname numeric) lstatus(varname numeric) empstat(varname numeric) ONELine(varname numeric) ONEWelfare(varname numeric) comparability(varname numeric) comparability_peb(varname string) YRange(string) YRange2(string) year_fcast(varname numeric) natpov_fcast(varname numeric) gdp_fcast(varname numeric)  MISSING Country(string) trim(string) aggregate(string) LATEST WITHIN3 BENCHmark(string) spells(string) minobs(numlist) earnage(integer 18) SVY std(string) PPPyear(integer 2021) VULnerability(real 1.5) NOEQUALSPACING scheme(string) palette(string) CORE]	
	
	//Check PPPyear
	qui _pea_ppp_check, ppp(`pppyear')
	
	//Check value of poverty lines (international ones)
	qui _pea_povlines_check, ppp(`pppyear') povlines(`ppppovlines')
	
	//load setting
	qui if "`setting'"=="GMD" {
		_pea_vars_set, setting(GMD)
		local vlist age male hhhead edu urban married school hhid pid hhsize industrycat4 industrycat10 empstat lstatus services assets
		foreach st of local vlist {
			local `st' "${pea_`st'}"
		}		
	}
	if "`vulnerability'"=="" {
		local vulnerability = 1.5
		noi di in yellow "Default multiple of poverty line to define vulnerability is 1.5"
	}
	//house cleaning	
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
		local excelout "`dirpath'\\PEA_core_`date'_`time'.xlsx"
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
	qui {
		putexcel set "`excelout'", replace sheet("Contents")
		putexcel C5 = "Poverty and Equity Assessments 3.0", bold font( "", 16)
		putexcel C7 = "Core Tables and Figures", bold font( "", 14)
		putexcel C10 = "Generated Outputs:"
		putexcel (A1:AZ100), fpattern(solid, white)
		putexcel save
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
		
		//SVY setting
		local svycheck = 0
		if "`svy'"~="" _pea_svycheck, std(`std')
		
		//missing observation check
		marksample touse
		local flist `"`wvar' `natwelfare' `natpovlines' `pppwelfare' `ppppovlines' `year'"'
		markout `touse' `flist' 
		
		//reset to the floor
		if "`pppwelfare'"~="" {
			replace `pppwelfare' = ${floor_} if `pppwelfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
		
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
		gen double _prosgap_`pppwelfare' = ${prosgline_}/`pppwelfare' if `touse'
		gen _pov_`onewelfare'_`oneline' = `onewelfare'< `oneline'  if `touse'
		gen _vulpov_`onewelfare'_`oneline' = `onewelfare'< `oneline'*`vulnerability'  if `touse'
		replace _vulpov_`onewelfare'_`oneline' = 0 if _pov_`onewelfare'_`oneline' == 1 & `touse'	//	Only between poverty lines
		gen double _pop = `wvar'
		
		tempfile data1 data2
		save `data1', replace
	} //qui
	
	//trigger
	global tablecount = 11
	
	//figure C1
	qui use `data1', clear
	cap pea_figureC1 [aw=`wvar'],  c(`country') natw(`natwelfare') natp(`natpovlines') year(`year') year_fcast(`year_fcast') natpov_fcast(`natpov_fcast') gdp_fcast(`gdp_fcast')  comparability_peb(`comparability_peb') yrange(`yrange') yrange2(`yrange2') fgtvars linesorted scheme(`scheme') palette(`palette') excel("`excelout'") core 
	qui if _rc==0 {
		noi dis in green "Figure C.1....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#FigureC1!A1", "Figure C.1. Trends and nowcast of the national poverty rate")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure C.1....... Not done"
	
	//table C1
	qui use `data1', clear
	cap pea_tableC1 [aw=`wvar'],  c(`country') natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') fgtvars linesorted excel("`excelout'") core oneline(`oneline') onewelfare(`onewelfare') lstatus(`lstatus') empstat(`empstat') industrycat4(`industrycat4') age(`age') male(`male') aggregate(`aggregate') pppyear(`pppyear') vulnerability(`vulnerability') benchmark(`benchmark')
	qui if _rc==0 {
		noi dis in green "Table C.1....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#TableC1!A1", "Table C.1. Key Poverty, Shared Prosperity and Labor Market Indicators")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table C.1....... Not done"
	
	//table C2
	qui use `data1', clear
	cap pea_table5 [aw=`wvar'], welfare(`onewelfare') year(`year') povlines(`oneline') excel("`excelout'") age(`age') male(`male') urban(`urban') edu(`edu') industrycat4(`industrycat4') lstatus(`lstatus') empstat(`empstat') core `missing'
	qui if _rc==0 {
		noi dis in green "Table C.2....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#TableC2!A1", "Table C.2. Key labor market indicators")
		global tablecount = ${tablecount} + 1	
		putexcel save	
	}
	else noi dis in red "Table C.2....... Not done"	

	//Figure C.2 GIC graph
	qui use `dataori', clear
	cap pea_figure3b [aw=`wvar'], year(`year') welfare(`onewelfare') spells(`spells') trim(`trim') by(`urban') scheme(`scheme') palette(`palette') comparability(`comparability') core excel("`excelout'")
	qui if _rc==0 {
		noi dis in green "Figure C.2....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#FigureC.2!A1", "Figure C.2 Growth Incidence Curves")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure C.2....... Not done"

	//Figure C.3 Datt-Ravallion graph
	qui use `dataori', clear
	cap pea_figure4 [aw=`wvar'], year(`year') onew(`onewelfare') onel(`oneline') comparability(`comparability') spells(`spells') scheme(`scheme') palette(`palette') core excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure C.3....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#FigureC.3!A1", "Figure C.3 Datt-Ravallion decomposition")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure C.3....... Not done"
	
	//table A1
	qui use `data1', clear
	cap pea_table1 [aw=`wvar'],  c(`country') natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') fgtvars linesorted excel("`excelout'") core oneline(`oneline') onewelfare(`onewelfare') `svy' std(`std') pppyear(`pppyear') vulnerability(`vulnerability')
	qui if _rc==0 {
		noi dis in green "Table A.1....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#TableA1!A1", "Table A.1. Core poverty and equity indicators")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table A.1....... Not done"
	
	//table A2
	qui use `dataori', clear		
	cap pea_tableA2 [aw=`wvar'], pppw(`onewelfare') pppp(`oneline') year(`year') byind(`byind') age(`age') male(`male') edu(`edu') `missing' minobs(`minobs') excel("`excelout'") pppyear(`pppyear') core
	qui if _rc==0 {
		noi dis in green "Table A.2....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#TableA2!A1", "Table A.2. Poverty indicators by subgroup")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table A.2....... Not done"
	
	//table A3
	qui use `dataori', clear	
	cap pea_table10 [aw=`wvar'], c(`country') welfare(`pppwelfare') povlines(`ppppovlines') year(`year') benchmark(`benchmark') `latest' `within3' linesorted excel("`excelout'") core pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Table A.3....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#TableA3!A1", "Table A.3. Benchmarking of poverty and inequality")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table A.3....... Not done"
	
	//table A4a, A4b
	qui use `dataori', clear		
	cap pea_table4 [aw=weight_p], welfare(`onewelfare') povlines(`oneline') year(`year') `missing' age(`age') male(`male') edu(`edu') hhhead(`hhhead') urban(`urban') married(`married') school(`school') services(`services') assets(`assets') hhsize(`hhsize') hhid(`hhid') pid(`pid') industrycat4(`industrycat4') industrycat10(`industrycat10') lstatus(`lstatus') empstat(`empstat') excel("`excelout'") pppyear(`pppyear') core
	qui if _rc==0 {
		noi dis in green "Table A.4....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		
		putexcel C${tablecount} = hyperlink("#TableA4a!A1", "Table A.4a. Demographic profiles of the poor")
		global tablecount = ${tablecount} + 1
		
		putexcel C${tablecount} = hyperlink("#TableA4b!A1", "Table A.4b. Labor market profiles of the poor")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table A.4....... Not done"
	
	//Final open	
	if `ok'==1 {
		shell start excel "`excelout'"
		noi dis in green "Tables and Graphs are done....... Loading the Excel file!"
	}
	else {
		noi dis in red "No tables and graphs are produced"
	}
end