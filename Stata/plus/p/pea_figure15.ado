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
syntax [if] [in] [aw pw fw], [Country(string) scheme(string) palette(string) excel(string) save(string) PPPyear(integer 2017)]
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	
	//house cleaning
	_pea_export_path, excel("`excel'")
	
	//Check if data exists
	cap confirm file "`persdir'pea/exposure_vulnerability_2021.dta"
	if _rc~=0 {
		noi dis as error "Unable to find exposure_vulnerability_2021.dta file."
		error `=_rc'	
	}
	
	// Check if PIP already prepared, else download all PIP related files
	local nametodo = 0
	cap confirm file "`persdir'pea/PIP_all_countrylineup.dta"
	if _rc==0 {
		cap use "`persdir'pea/PIP_all_countrylineup.dta", clear	
		if _rc~=0 local nametodo = 1	
	}
	else local nametodo = 1
	if `nametodo'==1 {
		cap pea_dataupdate, datatype(PIP) update
		if _rc~=0 {
			noi dis "Unable to run pea_dataupdate, datatype(PIP) update"
			exit `=_rc'
		}
	}

	// Figure Setup
	local groups = 2																	//  Total number of entries and colors
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")		//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)	
	
	//Prepare data
	local varlist 	exp_any risk_any poor215_any dep_educ_com_expany ///
					dep_infra_elec_expany dep_infra_impw_expany ///
					dep_fin_expany dep_sp_expany exprai_any
					
	//Call data
	use "`persdir'pea/exposure_vulnerability_2021.dta", 
	qui count if code == "`country'"
	if r(N) == 0 {
		noi dis as error "Country `country' does not have climate-risk data, Figure 15 not produced."
		error 1	
	}

	gen year = 2021																		// adjust if year of data gets adapted
	keep year `varlist' totalpop code region economy
	tempfile dataori
	save	`dataori'
	
	// Get regional estimates
	//Merge in population
	rename code country_code
	merge 1:1 country_code year using "`persdir'pea/PIP_all_countrylineup.dta", keepusing(pop) nogen
	gen count = _n
	qui sum count if country_code == "`country'"
	local region_name `=region[r(min)]'
	local cname		`=economy[r(min)]'
	keep if region == "`region_name'"
	rename country_code code
	keep if year == 2021
	rename year year_data
 	collapse (sum) `varlist'  totalpop , by(region)
	drop if region == ""
	rename region code
	
	// Put together
	append using `dataori'
	keep if code == "`country'" | code == "`region_name'"
	gen group = 1 if code == "`country'"
	replace group = 2 if code == "`region_name'"
	foreach var of varlist `varlist' { 
		gen share_`var' = `var' / totalpop
	}
	keep share* group
	
	//Reshape and labels
	gen over_group = " "
	
	reshape long share_, i(over_group group) j(ind, string)
	replace share_ = share_ * 100
	reshape wide share_, i(over_group ind) j(group)
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
	
	//Figure
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure15.xlsx"
		local act replace
		cap rm "`dirpath'\\Figure15.xlsx"
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
		
	putexcel set "`excelout2'", `act'
	tempfile graph
	local u = 5
	
	graph hbar share_1 share_2, 												///
	over(ind, sort((mean) share_1) descending) 									///
	over(over_group, label(angle(90))) nofill									///
	ytitle("Share of population (percent)")										///
	legend(order(1 "`cname'" 2 "`region_name'")) 								///
	bar(1, color("`: word 1 of ${colorpalette}'")) 								///
	bar(2, color("`: word 2 of ${colorpalette}'"))	name(ngraph`gr', replace)
		
	putexcel set "`excelout2'", modify sheet(Figure15, replace)	  
	graph export "`graph'", replace as(png) name(ngraph) wid(1500)	
	putexcel A`u' = image("`graph'")
	putexcel A1 = ""
	putexcel A2 = "Figure 15: Climate risk and vulnerability dimensions"
	putexcel A3 = "Source: World Bank calculations using data from the World Bank Scorecard Vision Indicators."
	putexcel A4 = "Note: Population at risk is defined as the share of population exposed to any hazard, and vulnerable in any of the dimensions. Data is from circa 2021."
	
	putexcel O10 = "Data:"
	putexcel O6	= "Code:"
	putexcel O7 = `"graph hbar share_1 share_2, over(ind, sort((mean) share_1) descending) over(over_group, label(angle(90))) nofill ytitle("Share of population (percent)") legend(order(1 "`cname'" 2 "`region_name'")) bar(1, color("`: word 1 of ${colorpalette}'")) bar(2, color("`: word 2 of ${colorpalette}'"))"'
	if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
	putexcel save							
	//Export data
	export excel share_1 share_2 ind over_group using "`excelout2'", sheet("Figure15", modify) cell(O11) keepcellfmt firstrow(variables)	nolabel
	cap graph close	
	
	if "`excel'"=="" shell start excel "`dirpath'\\Figure15.xlsx"	
	
end
