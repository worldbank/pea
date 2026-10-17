cap program drop pea_tables
program pea_tables, rclass
version 18.0

*==============================================================================
* pea_tables
*
* Generate the standard PEA table package and compile outputs into a
* single Excel workbook.
*   1. Validate user inputs and poverty-line definitions.
*   2. Prepare welfare, poverty, and benchmarking indicators.
*   3. Create and initialize the Excel workbook.
*   4. Run individual table modules.
*   5. Assemble outputs and hyperlinks in the Contents sheet.

*==============================================================================
* Disclaimers & credits 

	*! version 0.1.2  29Sep2026
	*! Copyright (C) World Bank 2017-2024 
	*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Sandra Carolina Segovia Juarez 
	*<ssegoviajuarez@worldbank.org>; Henry Stemmler <hstemmler@worldbank.org>.
	*! Modifications by Daylan Alberto Salmeron Gomez; Maria Fernanda Gonzalez Icaza

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
*==============================================================================
	
syntax [if] [in] [aw pw fw], [* NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric)  Year(varname numeric) SETting(string) excel(string) save(string) BYInd(varlist numeric) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) married(varname numeric) school(varname numeric) services(varlist numeric) assets(varlist numeric) hhsize(varname numeric) hhid(string) pid(string) industrycat4(varname numeric) industrycat10(varname numeric) lstatus(varname numeric) empstat(varname numeric) relationharm(varname numeric) missing ONELine(varname numeric) ONEWelfare(varname numeric) Country(string) LATEST WITHIN3 BENCHmark(string) spells(string) earnage(integer 15) minobs(numlist) SVY std(string) PPPyear(integer 2021) VULnerability(real 1.5)]	
	
*----------------------------------------------------------------------
* Validate PPP round and international poverty line definitions.
*----------------------------------------------------------------------
	_pea_ppp_check, ppp(`pppyear')
	_pea_povlines_check, ppp(`pppyear') povlines(`ppppovlines')
	
*----------------------------------------------------------------------
* Initialize output workbook.
* Create a temporary workbook if excel() is not specified; otherwise
* verify that the supplied workbook exists.
*----------------------------------------------------------------------
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
	
* Apply default vulnerability threshol* if not specified.
	if "`vulnerability'"=="" {
		local vulnerability = 1.5
		noi di in yellow "Default multiple of poverty line to define vulnerability is 1.5"
	}
	
*----------------------------------------------------------------------
* Create Contents sheet and workbook structure.
*----------------------------------------------------------------------
	qui {
		putexcel set "`excelout'", replace sheet("Contents")
		putexcel C5 = "Poverty and Equity Assessments 3.0", bold font( "", 16)
		putexcel C7 = "List of detailed tables", bold font( "", 14)
		putexcel C10 = "Generated Tables:"
		putexcel (A1:AZ100), fpattern(solid, white)
		putexcel save
	}
	* Benchmarking options are mutually exclusive.
	if "`latest'"~="" & "`within3'"~="" {
		noi dis as error "Either latest or within3, not both options"
		error 1
	}
	if "`latest'"=="" & "`within3'"=="" local latest latest
	
*----------------------------------------------------------------------
* Load standard variable mappings for predefined settings.
*----------------------------------------------------------------------
	qui if "`setting'"=="GMD" {
		_pea_vars_set, setting(GMD)
		local vlist age male hhhead edu urban married school hhid pid hhsize industrycat4 empstat lstatus services assets relationharm
		foreach st of local vlist {
			local `st' "${pea_`st'}"
		}	
	}
	
*----------------------------------------------------------------------
* Prepare analysis dataset.
*   - standardize poverty-line ordering
*   - identify survey weights,
*   - validate survey settings,
*   - create poverty and inequality indicators,
*   - generate variables used across multiple tables.
*----------------------------------------------------------------------
	qui {
		local country "`=upper("`country'")'"
		cap drop code
		gen code = "`country'"
		
* Sort poverty lines from lowest to highest threshold.	
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
* Extract survey weights; use equal weights if none are supplied.
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		}
		
* Verify survey design settings when svy is specified.
		local svycheck = 0
		if "`svy'"~="" _pea_svycheck, std(`std')
		
* Define the analysis sample and exclude observations with missing values 
* in required welfare, poverty-line, weight, and year variables.
		marksample touse
		local flist `"`wvar' `natwelfare' `natpovlines' `pppwelfare' `ppppovlines' `year'"'
		markout `touse' `flist' 
		
* Apply the minimum PPP welfare floor.
		if "`pppwelfare'"~="" {
			replace `pppwelfare' = ${floor_} if `pppwelfare'< ${floor_}
			noi di in yellow "Welfare in `pppyear' PPP is adjusted to a floor of ${floor_}"
		}
		
		tempfile dataori datalbl
		save `dataori', replace
		des, replace clear
		save `datalbl', replace
		use `dataori', clear

* Generate poverty indicators (FGT measures).
		if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
		if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
		
* Generate shared prosperity and distributi*nal indicators.
		if "`natwelfare'"~="" & "`pppwelfare'"~="" local distwelf `natwelfare'
		if "`natwelfare'"=="" & "`pppwelfare'"~="" local distwelf `pppwelfare'
		_pea_gen_b40 [aw=`wvar'] if `touse', welf(`distwelf') by(`year')
		clonevar _Gini_`distwelf' = `distwelf' if `touse'
		gen double _prosgap_`pppwelfare' = ${prosgline_}/`pppwelfare' if `touse'
		gen _pov_`onewelfare'_`oneline' = `onewelfare'< `oneline'  if `onewelfare'~=. &`touse'
		gen _vulpov_`onewelfare'_`oneline' = `onewelfare'< `oneline'*`vulnerability'  if `onewelfare'~=. & `touse'
		replace _vulpov_`onewelfare'_`oneline' = 0 if _pov_`onewelfare'_`oneline' == 1 & `onewelfare'~=. & `touse'	//	Only between poverty lines
		gen double _pop = `wvar'
		
		tempfile data1 data2
		save `data1', replace
	} //qui

	global tablecount = 11
	local ok = 0
	
*----------------------------------------------------------------------
* Generate PEA tables.
* Each table is executed independently so that failure of one module
* does not prevent the remaining tables from being produced.
*----------------------------------------------------------------------
	
	//table 1
	qui use `data1', clear
	cap pea_table1 [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') fgtvars linesorted excel("`excelout'") oneline(`oneline') onewelfare(`onewelfare') `svy' std(`std') pppyear(`pppyear') vulnerability(`vulnerability')
	qui if _rc==0 {
		noi dis in green "Table 1. Core poverty indicators ......................................... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table1!A1", "Table 1. Core poverty indicators")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table 1. Core poverty indicators ......................................... Not done"
	
	//table 2
	qui use `data1', clear
	cap pea_table2 [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') byind(`byind') minobs(`minobs') fgtvars linesorted excel("`excelout'") `missing' pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Table 2. Core poverty indicators by geographic areas ..................... Done"
		local ok = 1
		di "`excelout'"
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table2!A1", "Table 2. Core poverty indicators by geographic areas")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table 2. Core poverty indicators by geographic areas ..................... Not done"

	//table 3
	qui use `data1', clear
	cap pea_table3 [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') fgtvars linesorted excel("`excelout'") age(`age') male(`male') hhhead(`hhhead') edu(`edu') minobs(`minobs') `missing' pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Table 3. Subgroup poverty rates by gender, age and education ............. Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")
		putexcel C${tablecount} = hyperlink("#Table3a!A1", "Table 3a. Subgroup poverty rates by gender and age-group")
		global tablecount = ${tablecount} + 1
		
		putexcel C${tablecount} = hyperlink("#Table3b!A1", "Table 3b. Subgroup poverty rates by education (age 16+, %)")
		global tablecount = ${tablecount} + 1
		
		putexcel C${tablecount} = hyperlink("#Table3c!A1", "Table 3c. Subgroup poverty rates of household head (%)")
		global tablecount = ${tablecount} + 1
		
		putexcel save	
	}
	else noi dis in red "Table 3. Subgroup poverty rates by gender, age and education ............. Not done"
	
	//table 4
	qui use `dataori', clear		
	cap pea_table4 [aw=`wvar'], welfare(`onewelfare') povlines(`oneline') year(`year') `missing' age(`age') male(`male') edu(`edu') hhhead(`hhhead') urban(`urban') married(`married') school(`school') services(`services') assets(`assets') hhsize(`hhsize') hhid(`hhid') pid(`pid') industrycat4(`industrycat4') industrycat10(`industrycat10') lstatus(`lstatus') empstat(`empstat') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Table 4. Demographic and labor market profiles of the poor ............... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table4a!A1", "Table 4a. Demographic profiles of the poor")
		global tablecount = ${tablecount} + 1
		
		putexcel C${tablecount} = hyperlink("#Table4b!A1", "Table 4b. Labor market profiles of the poor")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table 4. Demographic and labor market profiles of the poor ............... Not done"
	
	//table 5 
	qui use `data1', clear
	cap pea_table5 [aw=`wvar'], welfare(`onewelfare') year(`year') povlines(`oneline') excel("`excelout'") age(`age') male(`male') urban(`urban') edu(`edu') industrycat4(`industrycat4') lstatus(`lstatus') empstat(`empstat') `missing'
	qui if _rc==0 {
		noi dis in green "Table 5. Key labor market outcomes by population group ................... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table5!A1", "Table 5. Key labor market outcomes by population group")
		global tablecount = ${tablecount} + 1	
		putexcel save	
	}
	else noi dis in red "Table 5. Key labor market outcomes by population group ................... Not done"
	
	//table 6
	qui use `data1', clear
	cap pea_table6 [aw=`wvar'], c(`country') welfare(`pppwelfare') year(`year')  benchmark(`benchmark') last3 excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Table 6. Multidimensional poverty measure and components ................. Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table6a!A1", "Table 6a. Multidimensional poverty: Multidimensional Poverty Measure (World Bank) (%)")
		global tablecount = ${tablecount} + 1	
		
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table6b!A1", "Table 6b. Multidimensional poverty: Multidimensional poverty components (%) (World Bank)")
		global tablecount = ${tablecount} + 1	
		putexcel save	
	}
	else noi dis in red "Table 6. Multidimensional poverty measure and components ................. Not done"

	//table 7
	qui use `data1', clear
	cap pea_table7 [aw=`wvar'], welfare(`onewelfare') povlines(`oneline') year(`year') excel("`excelout'") age(`age') male(`male') vul(`vulnerability') edu(`edu') `missing' pppyear(`pppyear') core
	qui if _rc==0 {
		noi dis in green "Table 7. Poverty vulnerability ........................................... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table7!A1", "Table 7. Poverty vulnerability")
		global tablecount = ${tablecount} + 1	
		putexcel save	
	}
	else noi dis in red "Table 7. Poverty vulnerability ........................................... Not done"
	
	//table 8
	qui use `data1', clear
	cap pea_table8 [aw=`wvar'], welfare(`onewelfare') year(`year') excel("`excelout'") `missing' pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Table 8. Core inequality indicators ...................................... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table8!A1", "Table 8. Core inequality indicators")
		global tablecount = ${tablecount} + 1	
		putexcel save	
	}
	else noi dis in red "Table 8. Core inequality indicators ...................................... Not done"
	
	//table 9
	qui use `data1', clear
	cap pea_table9, c(`country') year(`year') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Table 9. Scorecard Vision Indicators ..................................... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")
		putexcel C${tablecount} = hyperlink("#Table9!A1", "Table 9. Scorecard Vision Indicators")
		global tablecount = ${tablecount} + 1	
		putexcel save	
	}
	else noi dis in red "Table 9. Scorecard Vision Indicators ..................................... Not done"
	
	//table 10
	qui use `dataori', clear
	cap pea_table10 [aw=`wvar'], c(`country') welfare(`pppwelfare') povlines(`ppppovlines') year(`year') benchmark(`benchmark') `latest' `within3' linesorted excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Table 10. Benchmarking of poverty and inequality ......................... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table10!A1", "Table 10. Benchmarking of poverty and inequality")
		global tablecount = ${tablecount} + 1	
		putexcel save	
	}
	else noi dis in red "Table 10. Benchmarking of poverty and inequality ......................... Not done"

	//table 12
	qui use `dataori', clear
	cap pea_table12 [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') spells(`spells') year(`year') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Table 12. Decomposition of poverty changes: growth and redistribution .... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table12a!A1", "Table 12a. Decomposition of poverty changes: growth and redistribution - Datt-Ravallion decomposition")
		global tablecount = ${tablecount} + 1	
		
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table12b!A1", "Table 12b. Decomposition of poverty changes: growth and redistribution - Shorrocks-Kolenikov decomposition")
		global tablecount = ${tablecount} + 1	
		putexcel save	
	}
	else noi dis in red "Table 12. Decomposition of poverty changes: growth and redistribution .... Not done"
	
	//table 13a
	if "`urban'"~="" {
		qui use `dataori', clear
		cap pea_table13a [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') spells(`spells') year(`year') urban(`urban') excel("`excelout'") pppyear(`pppyear')
		qui if _rc==0 {
			noi dis in green "Table 13a. Huppi-Ravallion decomposition (urban/rural) ................... Done"
			local ok = 1
			putexcel set "`excelout'", modify sheet("Contents")		
			putexcel C${tablecount} = hyperlink("#Table13a!A1", "Table 13a. Huppi-Ravallion decomposition (urban/rural)")
			global tablecount = ${tablecount} + 1	
			putexcel save	
		}
		else noi dis in red "Table 13a. Huppi-Ravallion decomposition (urban/rural) ................... Not done"
	}
	
	//table 13b
	if "`industrycat4'"~="" {
		qui use `dataori', clear
		cap pea_table13b [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') spells(`spells') year(`year') industrycat4(`industrycat4') hhhead(`hhhead') hhid(`hhid') excel("`excelout'") pppyear(`pppyear')
		qui if _rc==0 {
			noi dis in green "Table 13b. Huppi-Ravallion decomposition (sectoral) ...................... Done"
			local ok = 1
			putexcel set "`excelout'", modify sheet("Contents")		
			putexcel C${tablecount} = hyperlink("#Table13b!A1", "Table 13b. Huppi-Ravallion decomposition (sectoral)")
			global tablecount = ${tablecount} + 1	
			putexcel save	
		}
		else noi dis in red "Table 13b. Huppi-Ravallion decomposition (sectoral) ...................... Not done"
	}	
	
	//table 14 relationharm(`relationharm')
	qui use `dataori', clear		
	cap pea_table14 [aw=`wvar'], welfare(`onewelfare') povlines(`oneline') year(`year') `missing' age(`age') male(`male') hhsize(`hhsize') hhid(`hhid') pid(`pid') lstatus(`lstatus') empstat(`empstat') earnage(`earnage') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Table 14. Demographic and economic household typologies .................. Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table14!A1", "Table 14. Demographic and economic household typologies")
		global tablecount = ${tablecount} + 1	
		putexcel save	
	}
	else noi dis in red "Table 14. Demographic and economic household typologies .................. Not done"

	//table 15
	qui use `dataori', clear		
	cap pea_table15 [aw=`wvar'], welfare(`onewelfare') year(`year') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Table 15. Distribution of welfare by deciles ............................. Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table15!A1", "Table 15. Distribtion of welfare by deciles")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table 15. Distribution of welfare by deciles ............................. Not done"

	//table 16
	qui use `dataori', clear		
	cap pea_table16, c(`country') year(`year') benchmark(`benchmark') excel("`excelout'") 
	qui if _rc==0 {
		noi dis in green "Table 16. Social Protection Coverage and Adequacy ........................ Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Table16!A1", "Table 16. Social Protection Coverage and Adequacy")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
		else {
		noi dis in red "Table 16. Social Protection Coverage and Adequacy ........................ Not done"
		* Explain the usual cause instead of leaving the user guessing.       // v0.1.3
		local persdir : sysdir PERSONAL
		if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
		cap confirm file "`persdir'pea/ASPIRE performance indicators.dta"
		if _rc~=0 noi di in yellow "Note Table 16: file 'ASPIRE performance indicators.dta' was not found in the personal sysdir folder."
		else {
			preserve
			qui use "`persdir'pea/ASPIRE performance indicators.dta", clear
			qui count if Country_Code == "`country'"
			local naspire = r(N)
			restore
			if `naspire'==0 noi di in yellow "Note Table 16: `country' does not have ASPIRE indicators, so Table 16 cannot be produced."
		}
	}
	
	//Final open	
	//Final open	
	if "`missing'"=="" {                                                     // v0.1.3
		noi di in yellow "Note: option missing not specified. Observations with missing values are excluded from the denominators in Tables 2, 3, 4, 5, 7, 8 and 14. Specify missing to count them toward the total."
	}
	if `ok'==1 {
		if "`excel'"=="" {
			shell start excel "`excelout'"
			noi dis in green "Tables and Graphs are done....... Loading the Excel file!"
		}
		else noi dis in green "Tables and Graphs are done....... Output: `excelout'"
	}
	
end