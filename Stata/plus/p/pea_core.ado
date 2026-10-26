/* Potential problems: The syntax declares several inputs as optional, but the preparation block assumes they exist
pppwelfare() is used even if it was not supplied.
onewelfare() is used even if it was not supplied.
oneline() is used even if it was not supplied.
Solution: Validate variables required for the core package near the beginning.
 Alternatively, if all these inputs are genuinely required, remove their optional status through explicit validation. */

cap program drop pea_core
program pea_core, rclass
version 18.0

*================================================================
* Main PEA driver program.
*
* This program: 
*   1. Validates user inputs.
*   2. Prepares welfare and poverty variables.
*   3. Generates common indicators used across outputs.
*   4. Executes core PEA tables and figures.
*   5. Assembles results into a single Excel workbook.
*================================================================

* Disclaimers & credits 
	
	*! version 0.1.1  29Sep2026
	*! Copyright (C) World Bank 2017-2024 
	*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Sandra Carolina Segovia Juarez 
	* <ssegoviajuarez@worldbank.org>; Henry Stemmler <hstemmler@worldbank.org>.
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

*================================================================

syntax [if] [in] [aw pw fw], [* NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric)  Year(varname numeric) SETting(string) excel(string) save(string) BYInd(varlist numeric) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) married(varname numeric) school(varname numeric) services(varlist numeric) assets(varlist numeric) hhsize(varname numeric) hhid(string) pid(string) industrycat4(varname numeric) industrycat10(varname numeric) lstatus(varname numeric) empstat(varname numeric) ONELine(varname numeric) ONEWelfare(varname numeric) comparability(varname numeric) comparability_peb(varname string) PEB YRange(string) YRange2(string) year_fcast(varname numeric) natpov_fcast(varlist numeric) gdp_fcast(varname numeric)  MISSING Country(string) trim(string) aggregate(string) LATEST WITHIN3 BENCHmark(string) spells(string) minobs(numlist) SVY std(string) PPPyear(integer 2021) VULnerability(real 1.5) NOEQUALSPACING scheme(string) palette(string) CORE]	
		
foreach opt in pppwelfare ppppovlines onewelfare oneline year {
		if "``opt''"=="" {
			noi dis as error "Option `opt'() is required"
			error 198
		}
	}
		
//-----------------------------------------------------------------------
// Validate PPP assumptions and international poverty lines
//-----------------------------------------------------------------------
	qui _pea_ppp_check, ppp(`pppyear')
	qui _pea_povlines_check, ppp(`pppyear') povlines(`ppppovlines')
	
//-----------------------------------------------------------------------
// Load standard GMD variable mappings when requested
//-----------------------------------------------------------------------
	qui if "`setting'"=="GMD" {
		_pea_vars_set, setting(GMD)
		local vlist age male hhhead edu urban married school hhid pid hhsize industrycat4 industrycat10 empstat lstatus services assets
		foreach st of local vlist {
			local `st' "${pea_`st'}"
		}		
	}
	
//-----------------------------------------------------------------------
// Apply default vulnerability threshold if not specified
//-----------------------------------------------------------------------	
	if "`vulnerability'"=="" {
		local vulnerability = 1.5
		noi di in yellow "Default multiple of poverty line to define vulnerability is 1.5"
	}
	
//-----------------------------------------------------------------------
// Initialize output workbook and create the contents page
//-----------------------------------------------------------------------
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
		
//-----------------------------------------------------------------------
// Data preparation
//   - Standardize poverty-line ordering.
//   - Identify the survey weight variable.
//   - Define the estimation sample.
//   - Apply welfare-floor adjustments.
//   - Generate intermediate indicators used by multiple outputs.
//-----------------------------------------------------------------------
	qui {
		local country "`=upper("`country'")'"
		cap drop code
		gen code = "`country'"

 // Ensure international poverty lines are processed in ascending order
		if "`ppppovlines'"~="" {
			_pea_pline_order, povlines(`ppppovlines')
			local ppppovlines `=r(sorted_line)'
			foreach var of local ppppovlines {
				local lbl`var' `=r(lbl`var')'
			}
		}
 /*	* National poverty lines are currently not ordered.
		if "`natpovlines'"~="" {
			_pea_pline_order, povlines(`natpovlines')
			local natpovlines `=r(sorted_line)'
			foreach var of local natpovlines {
				local lbl`var' `=r(lbl`var')'
			}
		} */	
		
// Extract weight variable; use equal weights if none provided
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			di in red "No survey weights provided; using equal weights"
			local wvar `w'
		}
		
// Define survey sample structure
		local svycheck = 0
		if "`svy'"~="" _pea_svycheck, std(`std')
		
// Missing observations check
		marksample touse
		local flist `"`wvar' `natwelfare' `natpovlines' `pppwelfare' `ppppovlines' `year'"'
		markout `touse' `flist' 
		
// Apply minimum welfare floor required by PPP methodology
		if "`pppwelfare'"~="" {
			replace `pppwelfare' = ${floor_} if `pppwelfare'< ${floor_}
			noi di in yellow "Welfare in `pppyear' PPP is adjusted to a floor of ${floor_}"
		}
		
		tempfile dataori datalbl
		save `dataori', replace
		des, replace clear
		save `datalbl', replace
		use `dataori', clear
	
//-------------------------------------------------------------------
// Generate poverty measures and auxiliary variables shared across tables and figures
//-------------------------------------------------------------------

// Select welfare aggregate used for inequality and prosperity metrics
		if "`natwelfare'"~="" & "`natpovlines'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natpovlines')
		if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
		if "`natwelfare'"~="" & "`pppwelfare'"~="" local distwelf `natwelfare'
		if "`natwelfare'"=="" & "`pppwelfare'"~="" local distwelf `pppwelfare'
		
// Create core indicators used throughout the PEA package:
// poverty, vulnerability, prosperity gap, and population counts
		_pea_gen_b40 [aw=`wvar'] if `touse', welf(`distwelf') by(`year')
		clonevar _Gini_`distwelf' = `distwelf' if `touse'
		gen double _prosgap_`pppwelfare' = ${prosgline_}/`pppwelfare' if `touse'
		gen _pov_`onewelfare'_`oneline' = `onewelfare'< `oneline'  if `touse'
		gen _vulpov_`onewelfare'_`oneline' = `onewelfare'< `oneline'*`vulnerability'  if `touse'
		replace _vulpov_`onewelfare'_`oneline' = 0 if _pov_`onewelfare'_`oneline' == 1 & `touse' //	Only between poverty lines
		gen double _pop = `wvar'
		tempfile data1 data2
		save `data1', replace
	} 
		
//trigger
	local ok = 0
	global tablecount = 11
	
//-----------------------------------------------------------------------
// Generate core PEA outputs
// Each module runs independently so that failure of one table or figure
// does not prevent the remaining outputs from being produced.
//-----------------------------------------------------------------------
	
// Figure C1
	qui use `dataori', clear
	cap pea_figureC1 [aw=`wvar'],  c(`country') natw(`natwelfare') natp(`natpovlines') year(`year') year_fcast(`year_fcast') natpov_fcast(`natpov_fcast') gdp_fcast(`gdp_fcast')  comparability_peb(`comparability_peb') `peb' yrange(`yrange') yrange2(`yrange2') linesorted scheme(`scheme') palette(`palette') excel("`excelout'") core 
	qui if _rc==0 {
		noi dis in green "Figure C.1. Trends and nowcast of the national poverty rate .............. Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#FigureC.1!A1", "Figure C.1. Trends and nowcast of the national poverty rate")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure C.1. Trends and nowcast of the national poverty rate .............. Not done"
	
// Table C1
	qui use `data1', clear
	cap pea_tableC1 [aw=`wvar'],  c(`country') natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') fgtvars linesorted excel("`excelout'") core oneline(`oneline') onewelfare(`onewelfare') lstatus(`lstatus') empstat(`empstat') industrycat4(`industrycat4') age(`age') male(`male') aggregate(`aggregate') pppyear(`pppyear') vulnerability(`vulnerability') benchmark(`benchmark')
	qui if _rc==0 {
		noi dis in green "Table C.1. Key Poverty, Shared Prosperity and Labor Market Indicators .... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#TableC.1!A1", "Table C.1. Key Poverty, Shared Prosperity and Labor Market Indicators")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table C.1. Key Poverty, Shared Prosperity and Labor Market Indicators .... Not done"
	
// Table C2
	qui use `data1', clear
	cap pea_table5 [aw=`wvar'], welfare(`onewelfare') year(`year') povlines(`oneline') excel("`excelout'") age(`age') male(`male') urban(`urban') edu(`edu') industrycat4(`industrycat4') lstatus(`lstatus') empstat(`empstat') core `missing'
	qui if _rc==0 {
		noi dis in green "Table C.2. Key labor market indicators ................................... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#TableC.2!A1", "Table C.2. Key labor market indicators")
		global tablecount = ${tablecount} + 1	
		putexcel save	
	}
	else noi dis in red "Table C.2. Key labor market indicators ................................... Not done"	

//Figure C2 GIC graph
	qui use `dataori', clear
	cap pea_figure3b [aw=`wvar'], year(`year') welfare(`onewelfare') spells(`spells') trim(`trim') by(`urban') scheme(`scheme') palette(`palette') comparability(`comparability') core excel("`excelout'")
	qui if _rc==0 {
		noi dis in green "Figure C.2. Growth Incidence Curves ...................................... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#FigureC.2!A1", "Figure C.2 Growth Incidence Curves")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure C.2. Growth Incidence Curves ...................................... Not done"

// Figure C3 Datt-Ravallion graph
	qui use `dataori', clear
	cap pea_figure4 [aw=`wvar'], year(`year') onew(`onewelfare') onel(`oneline') comparability(`comparability') spells(`spells') scheme(`scheme') palette(`palette') core excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure C.3. Datt-Ravallion decomposition ................................. Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#FigureC.3!A1", "Figure C.3 Datt-Ravallion decomposition")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure C.3. Datt-Ravallion decomposition ................................. Not done"
	
// Table A1
	qui use `data1', clear
	cap pea_table1 [aw=`wvar'],  c(`country') natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') fgtvars linesorted excel("`excelout'") core oneline(`oneline') onewelfare(`onewelfare') `svy' std(`std') pppyear(`pppyear') vulnerability(`vulnerability')
	qui if _rc==0 {
		noi dis in green "Table A.1. Core poverty and equity indicators ............................ Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#TableA1!A1", "Table A.1. Core poverty and equity indicators")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table A.1. Core poverty and equity indicators ............................ Not done"
	
// Table A2
	qui use `dataori', clear		
	cap pea_tableA2 [aw=`wvar'], pppw(`onewelfare') pppp(`oneline') year(`year') byind(`byind') age(`age') male(`male') edu(`edu') `missing' minobs(`minobs') excel("`excelout'") pppyear(`pppyear') core
	qui if _rc==0 {
		noi dis in green "Table A.2. Poverty indicators by subgroup ................................ Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#TableA2!A1", "Table A.2. Poverty indicators by subgroup")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table A.2. Poverty indicators by subgroup ................................ Not done"
	
// Table A3
	qui use `dataori', clear	
	cap pea_table10 [aw=`wvar'], c(`country') welfare(`pppwelfare') povlines(`ppppovlines') year(`year') benchmark(`benchmark') `latest' `within3' linesorted excel("`excelout'") core pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Table A.3. Benchmarking of poverty and inequality ........................ Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#TableA3!A1", "Table A.3. Benchmarking of poverty and inequality")		
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table A.3. Benchmarking of poverty and inequality ........................ Not done"
	
// Table A4a, A4b
	qui use `dataori', clear		
	cap pea_table4 [aw=`wvar'], welfare(`onewelfare') povlines(`oneline') year(`year') `missing' age(`age') male(`male') edu(`edu') hhhead(`hhhead') urban(`urban') married(`married') school(`school') services(`services') assets(`assets') hhsize(`hhsize') hhid(`hhid') pid(`pid') industrycat4(`industrycat4') industrycat10(`industrycat10') lstatus(`lstatus') empstat(`empstat') excel("`excelout'") pppyear(`pppyear') core
	qui if _rc==0 {
		noi dis in green "Table A.4. Demographic and labor market profiles of the poor ............. Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		
		putexcel C${tablecount} = hyperlink("#TableA4a!A1", "Table A.4a. Demographic profiles of the poor")
		global tablecount = ${tablecount} + 1
		
		putexcel C${tablecount} = hyperlink("#TableA4b!A1", "Table A.4b. Labor market profiles of the poor")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Table A.4. Demographic and labor market profiles of the poor ............. Not done"
	
//Final open	
	if `ok'==1 {
		if "`excel'"=="" {
			shell start excel "`excelout'"
			noi dis in green "Tables and Graphs are done....... Loading the Excel file!"
		}
		else noi dis in green "Tables and Graphs are done....... Output: `excelout'"
	}
end

*================================================================
