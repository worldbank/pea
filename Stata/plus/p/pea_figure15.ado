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

//Figure 15. Climate risk and vulnerability

cap program drop pea_figure15
program pea_figure15, rclass
	version 18.0
syntax [if] [in] [aw pw fw], [Country(string) NONOTES scheme(string) palette(string) excel(string) save(string)]

	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	
	//house cleaning
	if "`excel'"=="" {
		tempfile xlsxout 
		local excelout `xlsxout'		
		local path "`xlsxout'"		
		local lastslash = strrpos("`path'", "\") 				
		local dirpath = substr("`path'", 1, `lastslash')		
	}
	else {
		cap confirm file "`excel'"
		if _rc~=0 {
			noi dis as error "Unable to confirm the file in excel()"
			error `=_rc'	
		}
		else local excelout "`excel'"
	}
	
	//Check if data exists
	cap confirm file "`persdir'pea/exposure_vulnerability_2021.dta"
	if _rc~=0 {
		noi dis as error "Unable to find exposure_vulnerability_2021.dta file."
		error `=_rc'	
	}
	
	// Figure Setup
	local groups = 2																	//  Total number of entries and colors
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")		//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)	
	
	//Call data
	use "`persdir'pea/exposure_vulnerability_2021.dta", clear
	keep if code == "`country'"
	qui count
	if r(N) == 0 {
		noi dis as error "Country `country' does not have climate-risk data, Figure 15 not produced."
		error 1	
	}

	//Prepare data
	local varlist 	exp_any risk_any poor215_any dep_educ_com_expany ///
					dep_infra_elec_expany dep_infra_impw_expany ///
					dep_fin_expany dep_sp_expany exprai_any
					
	foreach var of varlist `varlist' { 
		gen share_`var' = `var' / totalpop
	}
	keep share*
	
	//Reshape and labels
	gen over_group = " "
	reshape long share_, i(over_group) j(ind, string)
	replace share_ = share_ * 100
	replace over_group = "Exposed to any hazard and ..." if ind != "exp_any"  &  ind != "risk_any"
	
	replace ind = "Exposed to any hazard" 		if ind == "exp_any"
	replace ind = "At risk from any hazard" 	if ind == "risk_any"
	replace ind = "Less than $2.15 per day" 	if ind == "poor215_any"
	replace ind = "Low education level" 		if ind == "dep_educ_com_expany"
	replace ind = "No access to electricity" 	if ind == "dep_infra_elec_expany"
	replace ind = "No access to improved water" if ind == "dep_infra_impw_expany"
	replace ind = "No financial access" 		if ind == "dep_fin_expany"
	replace ind = "No social protection" 		if ind == "dep_sp_expany"
	replace ind = "Low access to markets" 		if ind == "exprai_any"
	
	//Prepare Notes
	local notes "Source: World Bank calculations using data from the Scorecard Vision Indicators."
	local notes `"`notes'" "Note: Population at risk is defined as the share of population" "exposed to any hazard, and vulnerable in any of the dimensions."'
	if "`nonotes'" ~= "" {
		local notes = ""
	}
	else if "`nonotes'" == "" {
		local notes `notes'
	}
	
	//Figure
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure15.xlsx"
		local act replace
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
		
	putexcel set "`excelout2'", `act'
	tempfile graph
	
	separate share_, by(over_group)												// Separate for different coloring of bars by group
	graph hbar share_1 share_2, 												///
	over(ind, sort((mean) share_) descending) 									///
	over(over_group, label(angle(90))) nofill									///
	ytitle("Share of population (percent)")										///
	legend(off)	name(ngraph`gr', replace)										///
	bar(1, color("`: word 1 of ${colorpalette}'")) 								///
	bar(2, color("`: word 2 of ${colorpalette}'"))								///
	note("`notes'", size(small))
		
	putexcel set "`excelout2'", modify sheet(Figure15, replace)	  
	graph export "`graph'", replace as(png) name(ngraph) wid(3000)		
	putexcel A1 = image("`graph'")
	putexcel save							
	cap graph close	
	if "`excel'"=="" shell start excel "`dirpath'\\Figure15.xlsx"	
	
end