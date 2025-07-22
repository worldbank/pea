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

	syntax [if] [in] [aw pw fw], [* NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) Year(varname numeric) SETting(string) excel(string) save(string) BYInd(varlist numeric) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) married(varname numeric) school(varname numeric) services(varlist numeric) assets(varlist numeric) hhsize(varname numeric) hhid(string) pid(string) industrycat4(varname numeric) lstatus(varname numeric) empstat(varname numeric) ONELine(varname numeric) ONEWelfare(varname numeric) MISSING Country(string) within(integer 3) COMBINE COMParability(varname numeric) BENCHmark(string) spells(string) NOEQUALSPACING YRange(string) trim(string) BAR RELATIVECHANGE ineqind(string) idpl(varname numeric) earnage(integer 16) scheme(string) palette(string) welfaretype(string) PPPyear(integer 2021)]
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
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
		putexcel C7 = "List of detailed figures", bold font( "", 14)
		putexcel C10 = "Generated Figures:"
		putexcel (A1:AZ100), fpattern(solid, white)
		putexcel save
	
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
		
		//reset to the floor
		if "`pppwelfare'"~="" {
			replace `pppwelfare' = ${floor_} if `pppwelfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
		
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
		*noi dis "Replace the bottom for Prosperity gap at $0.25 2017 PPP"
		*replace `pppwelfare' = ${floor_} if `pppwelfare'< ${floor_}		
		gen double _prosgap_`pppwelfare' = ${prosgline_}/`pppwelfare' if `touse'
		gen double _pop = `wvar'
		
		//B40 T60 Mean - only for one distribution
		_pea_gen_b40 [aw=`wvar'] if `touse', welf(`distwelf') by(`year')

		tempfile data1 data2
		save `data1', replace
	} //qui
	
	//trigger
	global tablecount = 11
	
	//Figure 1
	qui use `data1', clear	
	cap pea_figure1 [aw=`wvar'], natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') fgtvars linesorted urban(`urban') comparability(`comparability') `combine' `noequalspacing' yrange(`yrange') `bar' scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 1....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")	
		if "`combine'"~="" {
			putexcel C${tablecount} = hyperlink("#Figure1!A1", "Figure 1. Poverty rates by year")
			global tablecount = ${tablecount} + 1
		}
		else {
			local nlines : word count `natpovlines' `ppppovlines'
			forv n=1(1)`nlines' {
				putexcel C${tablecount} = hyperlink("#Figure1_`n'!A1", "Figure 1.`n' Poverty rates by year - poverty line `n'")
				global tablecount = ${tablecount} + 1
			}
		}
		putexcel save	
	}
	else noi dis in red "Figure 1....... Not done"
	
	//Figure 2
	qui use `data1', clear
	cap pea_figure2 [aw=`wvar'], c(`country') year(`year') benchmark(`benchmark') fgtvars yrange(`yrange') pppw(`pppwelfare') oneline(`oneline') scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 2....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure2!A1", "Figure 2. Poverty and GDP per capita in benchmark countries")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else {
		noi dis in red "Figure 2....... Not done"
		if _rc == 200 noi dis in red  "Value of poverty line in  oneline() option is not among the standard poverty lines for the `pppyear' PPP. Please enter a valid international poverty line for Figure 2."
	}
	
	//Figure 3a
	qui use `dataori0', clear
	cap pea_figure3a [aw=`wvar'], year(`year') welfare(`onewelfare') comparability(`comparability') spells(`spells') yrange(`yrange') trim(`trim') scheme(`scheme') palette(`palette') excel("`excelout'")
	qui if _rc==0 {
		noi dis in green "Figure 3a....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure3a!A1", "Figure 3a. Growth Incidence Curves over time")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 3a....... Not done"
	
	//Figure 3b
	qui use `dataori0', clear
	cap pea_figure3b [aw=`wvar'], year(`year') welfare(`onewelfare') comparability(`comparability') spells(`spells') yrange(`yrange') trim(`trim') by(`urban') scheme(`scheme') palette(`palette') excel("`excelout'")
	qui if _rc==0 {
		noi dis in green "Figure 3b....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure3b!A1", "Figure 3b. Growth Incidence Curves by area")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 3b....... Not done"
	
	//Figure 4
	qui use `dataori0', clear
	cap pea_figure4 [aw=`wvar'], year(`year') onew(`onewelfare') onel(`oneline') comparability(`comparability') spells(`spells') idpl(`idpl') scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 4....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure4a!A1", "Figure 4a. Datt-Ravallion decompositions")
		global tablecount = ${tablecount} + 1
		
		putexcel C${tablecount} = hyperlink("#Figure4b!A1", "Figure 4b. Shorrocks-Kolenikov decompositions")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 4....... Not done"
	
	//Figure 5a
	qui use `dataori0', clear
	cap pea_figure5a [aw=weight_p], year(`year') onew(`onewelfare') onel(`oneline') comparability(`comparability') spells(`spells') urban(`urban') scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 5a....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure5a!A1", "Figure 5a. Huppi-Ravallion decomposition (urban/rural)")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 5a....... Not done"
	
	//Figure 5b
	qui use `dataori0', clear
	cap pea_figure5b [aw=weight_p], year(`year') onew(`onewelfare') onel(`oneline') comparability(`comparability') spells(`spells') industrycat4(`industrycat4') hhhead(`hhhead') hhid(`hhid') scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 5b....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure5b!A1", "Figure 5b. Huppi-Ravallion decomposition (sectoral)")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 5b....... Not done"	
	
	//Figure 6
	qui use `dataori0', clear	
	cap pea_figure6 [aw=`wvar'], c(`country') year(`year') oneline(`oneline') onewelfare(`onewelfare') comparability(`comparability') spells(`spells')  scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 6....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure6!A1", "Figure 6. GDP - Poverty elasticity")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 6....... Not done"
	
	//Figure 7a
	qui use `data1', clear	
	cap pea_figure7a [aw=`wvar'], onewelfare(`onewelfare') oneline(`oneline') year(`year') fgtvars age(`age') male(`male') edu(`edu') urban(`urban') scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 7a....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure7a!A1", "Figure 7a. Share of poor and population by demographic groups")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 7a....... Not done"
	
	//Figure 7b
	qui use `data1', clear	
	cap pea_figure7b [aw=`wvar'], onewelfare(`onewelfare') oneline(`oneline') year(`year') fgtvars age(`age') male(`male') edu(`edu') urban(`urban') scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 7b....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure7b!A1", "Figure 7b. Share of poor and non-poor by demographic groups")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 7b....... Not done"	
	
	//Figure 8
	qui use `data1', clear	
	cap pea_figure8 [aw=`wvar'], onewelfare(`onewelfare') oneline(`oneline') year(`year') fgtvars yrange(`yrange') age(`age') male(`male') scheme(`scheme') palette(`palette') pppyear(`pppyear') excel("`excelout'") 
		qui if _rc==0 {
		noi dis in green "Figure 8....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure8!A1", "Figure 8. Poverty rates by sex and age groups")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 8....... Not done"	
	
	//Figure 9a
	qui use `dataori0', clear	
	cap pea_figure9a [aw=`wvar'], year(`year') onewelfare(`onewelfare') comparability(`comparability') `noequalspacing' yrange(`yrange') ineqind(`ineqind') `bar' scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 9a...... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure9a!A1", "Figure 9a. Inequality by year")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 9a...... Not done"
	
	//Figure 9b
	qui use `dataori0', clear	
	cap pea_figure9b [aw=`wvar'], c(`country') year(`year') benchmark(`benchmark') onewelfare(`onewelfare') welfaretype(`welfaretype') within(`within') yrange(`yrange') scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 9b...... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure9b!A1", "Figure 9b. Gini and GDP per capita scatter")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 9b...... Not done"
	
	//Figure 9c
	qui use `dataori0', clear	
	cap pea_figure9c [aw=`wvar'], c(`country') year(`year') benchmark(`benchmark') onewelfare(`onewelfare') welfaretype(`welfaretype') within(`within') yrange(`yrange') scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 9c...... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure9c!A1", "Figure 9c. Benchmark countries ranked by Gini index")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 9c...... Not done"

	//Figure 9d
	qui use `dataori0', clear	
	cap pea_figure9d [aw=`wvar'], year(`year') onewelfare(`onewelfare') comparability(`comparability') `noequalspacing' yrange(`yrange') `bar' scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 9d...... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure9d!A1", "Figure 9d. Welfare percentiles over time")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 9d...... Not done"
	
	//Figure 10a
	qui use `dataori0', clear	
	cap pea_figure10a [aw=`wvar'], year(`year') onewelfare(`onewelfare') urban(`urban') comparability(`comparability') `noequalspacing' yrange(`yrange') `bar' scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 10a...... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure10a!A1", "Figure 10a. Prosperity gap by year and area")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 10a...... Not done"
	
	//Figure 10b
	qui use `dataori0', clear	
	cap pea_figure10b [aw=`wvar'], c(`country') year(`year') benchmark(`benchmark') onewelfare(`onewelfare') yrange(`yrange') scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 10b...... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure10b!A1", "Figure 10b: Prosperity gap (line-up) and GDP per capita scatter")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 10b...... Not done"
	
	//Figure 10c
	qui use `dataori0', clear	
	cap pea_figure10c [aw=`wvar'], c(`country') year(`year') benchmark(`benchmark') onewelfare(`onewelfare') yrange(`yrange') within(`within') scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 10c...... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure10c!A1", "Figure 10c: Prosperity gap (survey) and GDP per capita scatter")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 10c...... Not done"
	
	//Figure 10d
	qui use `dataori0', clear	
	cap pea_figure10d [aw=`wvar'], c(`country') year(`year') benchmark(`benchmark') onewelfare(`onewelfare') scheme(`scheme') yrange(`yrange') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 10d...... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure10d!A1", "Figure 10d: Prosperity gap over time in benchmark countries (line-up)")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 10d...... Not done"
	
	//Figure 11 TBC
	
	//Figure 12
	qui use `dataori0', clear
	cap pea_figure12 [aw=`wvar'], c(`country') year(`year') onew(`onewelfare') comparability(`comparability') spells(`spells') `relativechange' palette(`palette') scheme(`scheme') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 12....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure12!A1", "Figure 12. Decomposition of growth in prosperity gap")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 12....... Not done"
	
	//Figure 13
	qui use `dataori0', clear
	cap pea_figure13 [aw=`wvar'], year(`year') onew(`onewelfare') comparability(`comparability') `noequalspacing' palette(`palette') scheme(`scheme') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 13....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure13!A1", "Figure 13. Distribution of welfare by deciles")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 13....... Not done"
	
	//Figure 14
	qui use `dataori0', clear
	cap pea_figure14 [aw=`wvar'], c(`country') welfare(welfppp) year(`year') benchmark(`benchmark') within(`within') palette(`palette') scheme(`scheme') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 14....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		putexcel C${tablecount} = hyperlink("#Figure14a!A1", "Figure 14a. Multidimensional Poverty Measure, by components, versus benchmark countries")
		global tablecount = ${tablecount} + 1
		
		putexcel C${tablecount} = hyperlink("#Figure14b!A1", "Figure 14b. Multidimensional poverty and poverty rates, versus benchmark countries")
		global tablecount = ${tablecount} + 1
		
		putexcel C${tablecount} = hyperlink("#Figure14c!A1", "Figure 14c. Multidimensional poverty and poverty rates, contributions")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 14....... Not done"
	
	//Figure 15
	qui use `dataori0', clear	
	cap pea_figure15, c(`country') scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 15....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")
		putexcel C${tablecount} = hyperlink("#Figure15!A1", "Figure 15: Climate risk and vulnerability")
		global tablecount = ${tablecount} + 1
		putexcel save	
	}
	else noi dis in red "Figure 15....... Not done - no data for `country'"

	qui use `dataori0', clear	
	cap pea_figure16, onew(`onewelfare') onel(`oneline') year(`year')  age(`age') male(`male') edu(`edu') hhhead(`hhhead') hhid(`hhid') pid(`pid') urban(`urban') married(`married') industrycat4(`industrycat4') lstatus(`lstatus') empstat(`empstat') hhsize(`hhsize') earnage(`earnage') missing scheme(`scheme') palette(`palette') excel("`excelout'") pppyear(`pppyear')
	qui if _rc==0 {
		noi dis in green "Figure 16....... Done"
		local ok = 1
		putexcel set "`excelout'", modify sheet("Contents")		
		
		putexcel C${tablecount} = hyperlink("#Figure16!A1", "Figure 16: Profiles of the poor by demographic composition")
		global tablecount = ${tablecount} + 1
		/* Only one figure currently
		putexcel C${tablecount} = hyperlink("#Figure16b!A1", "Figure 16b: Profiles of the poor by economic composition (treemap)")
		global tablecount = ${tablecount} + 1
		
		putexcel C${tablecount} = hyperlink("#Figure16c!A1", "Figure 16c: Profiles of the poor by demographic composition (bar)")
		global tablecount = ${tablecount} + 1
		
		putexcel C${tablecount} = hyperlink("#Figure16d!A1", "Figure 16d: Profiles of the poor by economic composition (bar)")
		global tablecount = ${tablecount} + 1
		*/
		putexcel save	
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