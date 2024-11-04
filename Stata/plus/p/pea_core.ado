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

cap program drop pea_core
program pea_core, rclass
	version 18.0	
	syntax [if] [in] [aw pw fw], [* NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric)  Year(varname numeric) SETting(string) excel(string) save(string) BYInd(varlist numeric) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) married(varname numeric) school(varname numeric) services(varlist numeric) assets(varlist numeric) hhsize(varname numeric) hhid(string) pid(string) industrycat4(varname numeric) lstatus(varname numeric) empstat(varname numeric) ONELine(varname numeric) ONEWelfare(varname numeric) MISSING Country(string) LATEST WITHIN3 BENCHmark(string) spells(string)]	
		
	//load setting
	qui if "`setting'"=="GMD" {
		_pea_vars_set, setting(GMD)
		local vlist age male hhhead edu urban married school hhid pid hhsize industrycat4 empstat lstatus services assets
		foreach st of local vlist {
			local `st' "${pea_`st'}"
		}		
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
		putexcel set "`excelout'", replace sheet("Table list")
		putexcel C10 = "Tables and graphs"
		putexcel C11 = "PEA Data Annex"
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
	
	
	//trigger
	
	//table 1
	qui use `data1', clear
	cap pea_table1 [aw=`wvar'],  c(`country') natw(`natwelfare') natp(`natpovlines') pppw(`pppwelfare') pppp(`ppppovlines') year(`year') fgtvars linesorted excel("`excelout'") core oneline(`oneline') onewelfare(`onewelfare')
	if _rc==0 {
		noi dis in green "Table A.1....... Done"
		local ok = 1
	}
	else noi dis in red "Table A.1....... Not done"
	
	//table 2
	qui use `dataori', clear	
	*if "`oneline'"~="" local maxline `oneline'
	*else local maxline = word("`ppppovlines'", -1)
	cap pea_table_A2 [aw=`wvar'], pppw(`onewelfare') pppp(`oneline') year(`year') byind(`byind') age(`age') male(`male') edu(`edu') `missing' excel("`excelout'")
	if _rc==0 {
		noi dis in green "Table A.2....... Done"
		local ok = 1
	}
	else noi dis in red "Table A.2....... Not done"
	
	//table 3
	qui use `dataori', clear	
	cap pea_table10 [aw=`wvar'], c(`country') welfare(`pppwelfare') povlines(`ppppovlines') year(`year') benchmark(`benchmark') `latest' `within3' linesorted excel("`excelout'") core
	if _rc==0 {
		noi dis in green "Table A.3....... Done"
		local ok = 1
	}
	else noi dis in red "Table A.3....... Not done"
	
	//table 4
	qui use `dataori', clear		
	cap pea_table14 [aw=`wvar'], welfare(`onewelfare') povlines(`oneline') year(`year') `missing' age(`age') male(`male') edu(`edu') hhhead(`hhhead')  urban(`urban') married(`married') school(`school') services(`services') assets(`assets') hhsize(`hhsize') hhid(`hhid') pid(`pid') industrycat4(`industrycat4') lstatus(`lstatus') empstat(`empstat') core excel("`excelout'")
	if _rc==0 {
		noi dis in green "Table A.4....... Done"
		local ok = 1
	}
	else noi dis in red "Table A.4....... Not done"
	
	//GIC graph
	tempfile gicdata
	qui use `dataori', clear
	cap pea_table11 [aw=`wvar'], welfare(`onewelfare') spells(`spells') year(`year') nooutput save(`gicdata') 
	qui if _rc==0 {
		local vargic = r(vargic)
		local varlbl = r(varlbl)
		
		use `gicdata', clear
		putexcel set "`excelout'", modify
		tempfile graph2	
		twoway (connected `vargic' percentile) if  percentile>=1 & percentile<=99, scheme(white_tableau) ///
			legend(order(`"`varlbl'"') rows(1) size(medium) position(6)) ///
			xtitle(Percentile) ytitle("Annualized growth, %") name(gr_gic, replace)
		
		putexcel set "`excelout'", modify sheet("Figure A.1. GIC", replace)
		graph export "`graph2'", replace as(png) name(gr_gic) wid(3000)
		putexcel A25 = image("`graph2'")
		putexcel save
		cap graph close		
		noi dis in green "Graph A.1....... Done"
		local ok = 1
	}
	else noi dis in red "Graph A.1....... Not done"
	
	//Datt-Ravallion graph
	tempfile decomp
	qui use `dataori', clear
	cap pea_table12 [aw=`wvar'], pppwelfare(`onewelfare') ppppovlines(`oneline') spells(`spells') year(`year') nooutput save(`decomp') core
	qui if _rc==0 {		
		use `decomp', clear
		putexcel set "`excelout'", modify
		tempfile graph1
		local note : label indicatorlbl 1	
		graph bar value if decomp=="Datt-Ravallion" & subind<=3, over(subind) over(spell) asyvar legend(rows(1) size(medium) position(6)) ytitle("Total change in poverty in percentage point") name(gr_decomp, replace) scheme(white_tableau) title("Datt-Ravallion decomposition") note("Using `note'") blabel(bar, position(center) format(%9.2f))
		
		putexcel set "`excelout'", modify sheet("Figure A2 Datt-Ravallion", replace)
		graph export "`graph1'", replace as(png) name(gr_decomp) wid(3000)
		putexcel A25 = image("`graph1'")
		putexcel save
		cap graph close	
		noi dis in green "Graph A.2....... Done"
		local ok = 1
	}
	else noi dis in red "Graph A.2....... Not done"
	
	//Final open	
	if `ok'==1 {
		shell start excel "`excelout'"
		noi dis in green "Tables and Graphs are done....... Loading the Excel file!"
	}
	else {
		noi dis in red "No tables and graphs are produced"
	}
end