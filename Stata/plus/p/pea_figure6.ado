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

//Figure 6. GDP per capita - Poverty elasticity

cap program drop pea_figure6
program pea_figure6, rclass
	version 18.0
syntax [if] [in] [aw pw fw], [Country(string) Year(varname numeric) ONELine(varname numeric) ONEWelfare(varname numeric) FGTVARS spells(string) comparability(string) scheme(string) palette(string) excel(string) save(string) PPPyear(integer 2017)]

	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	tempfile dataori pea_pov 

	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	
	//house cleaning
	
	if "`comparability'"=="" {
		noi di in red "Warning: Comparability option not specified for Figure 6. Non-comparable spells may be shown."
	}
	
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
	
	// Clean spells
	if "`spells'"=="" {
		noi dis as error "Need at least two years, i.e. 2000 2004"
		error 1
	}	
	
	local x = subinstr("`spells'",";"," ",.)	
	local keepyears : list uniq x
		
	//Weights
	local wvar : word 2 of `exp'	// `exp' is weight in Stata ado syntax
	qui if "`wvar'"=="" {
		tempvar w
		gen `w' = 1
		local wvar `w'
	}
	local lblline: var label `oneline'		
		
	//missing observation check
	marksample touse
	local flist `"`wvar' `onewelfare' `oneline' `year'"'
	markout `touse' `flist' 
	gen tous = 1 if `touse'
	// Keep only years of spells
	qui levelsof `year' if `touse', local(yrlist)
	local same : list yrlist === keepyears
	if `same'==0 {
		noi dis "There are different years requested, and some not available in the data."
		noi dis "Requested: `keepyears'. Available: `yrlist'"
	}
	gen _keep =. if `touse'
	foreach yr of local keepyears {
		replace _keep=1 if `year'==`yr' & `touse'
	}
	keep if _keep==1 & `touse'
	drop _keep
	
	save `dataori', replace

	// Prepare spells
	tokenize "`spells'", parse(";")	
	local i = 1																			// Loop through tokens
	local fig6 = 1
	while "``i''" != "" {
		if "``i''"~=";" {																// Forces to start new local after ";" token
			local spell`fig6' "``i''"		
			local fig6 = `fig6' + 1
		}	
		local i = `i' + 1
	}

	// Comparability
		local one = 1
		if "`comparability'" ~= "" {
			forv j=1(1)`=`fig6'-1' {
				local test
				local spell_c`j' = "`spell`j''"												// Save local
				qui levelsof `comparability', local(comp_years)								// Loop through all values of comparability
				foreach i of local comp_years {
					qui	levelsof year if `comparability' == `i', local(year_c)				// Create list of comparable years
					local year_c = "`year_c'" 
					local test_`i': list spell_c`j' in year_c								// Check if spell years are in list of comparable years
					local test "`test' `test_`i''"
				}
				local test_pos: list one in test												// Check if any spell has comparable years
				if (`test_pos' == 0) local spell`j' = ""										// If years not comparable, drop local
				if (`test_pos' == 1) local spell`j' = "`spell_c`j''"							// If years comparable, keep local			
			}
		}	// if

	// Check if PIP GDP already prepared, else download all PIP related files
	local nametodo = 0
	cap confirm file "`persdir'pea/PIP_all_GDP.dta"
	if _rc==0 {
		cap use "`persdir'pea/PIP_all_GDP.dta", clear	
		if _rc~=0 local nametodo = 1	
	}
	else local nametodo = 1
	if `nametodo'==1 {
		cap pea_dataupdate, datatype(PIP) update
		if _rc~=0 {
			noi dis as error "Unable to run pea_dataupdate, datatype(PIP) update"
			exit `=_rc'
		}
	}

	// Figure colors
	local groups = 3																	//  Total number of entries and colors
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")		//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
	
	// Preparation
	use `dataori', clear
	*qui sum `oneline', d
	*local povline `r(max)'	// Get one poverty line value
	
	// Generate poverty rate of PEA country
	if "`fgtvars'"=="" { //only create when the fgt are not defined	
		if "`onewelfare'"~="" { //reset to the floor
			replace `onewelfare' = ${floor_} if `onewelfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
		if "`onewelfare'"~="" & "`oneline'"~="" _pea_gen_fgtvars if `touse', welf(`onewelfare') povlines(`oneline') 
	}
	groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) by(`year')
	keep _fgt0* year
	gen code = "`country'"
	save `pea_pov', replace

	// Merge GDP
	merge 1:1 code year using "`persdir'pea/PIP_all_GDP.dta", keep(1 3) keepusing(gdppc)
	egen any_merge = max(_merge)
	if any_merge~=3 {
		noi di as error  "Figure 6: Unable to merge GMD with PIP (GDP) data. Check country codes."
		exit 1
	}
	drop _merge any_merge	
	
	// Reshape for easier handling of years
	reshape wide _fgt0* gdppc, i(code) j(`year')
			
	forv j=1(1)`=`fig6'-1' {				// Loop through number of spells (minus ;) [See code above under Clean spells]
		local spell`j' : list sort spell`j'													// Sort years ascending
		tokenize "`spell`j''"																// Get each year separately
		if "`1'"~="" & "`2'"~="" {	
			gen d_fgt0_`1'_`2' = ((_fgt0_`onewelfare'_`oneline'`2'/_fgt0_`onewelfare'_`oneline'`1')^(1/(`2'-`1')) - 1) * 100
			gen d_gdp_pc_`1'_`2' = ((gdppc`2'/gdppc`1')^(1/(`2'-`1')) - 1) * 100
			gen gep_`1'_`2' = d_fgt0_`1'_`2' / d_gdp_pc_`1'_`2'	
			local vargep "`vargep' gep_`1'_`2'"
		}
	}
	
	keep d_* gep*
	
	// Reshape for easier figure creation
	gen a = 1
	reshape long d_fgt0_ d_gdp_pc_ gep_, i(a) j(spell, string)
	la var d_fgt0_ 		"Change in poverty rate (`lblline')"
	la var d_gdp_pc_ 	"Change in GDP per capita"
	la var gep_ 	   	"GPD-poverty elasticity"
	
	// Prepare figure
	qui levelsof spell, local(spell_count)
	foreach i of local spell_count {
		expand 2 if spell =="`i'"												// Need two observations per spell (1 for each variable)
	}
	
	sort 			spell
	gen 			count 		= _n
	egen 			group 		= group(spell)
	gen 			count2 		= count + group - 1								// Add gap between numbers of groups
	bys spell: egen avg 		= mean(count2)
	gen 			spell_dash 	= subinstr(spell, "_", " – ", .)
	replace 		spell 		= subinstr(spell, "_", " ", .)
	qui levelsof count, local(count)
	foreach c of local count {
		local spellc = spell[`c']
		local count2 = count2[`c']
		local marker = avg[`c']
		if mod(`c', 2) {														// Odd numbers are fgt, even are gdp (i.e. statement is 0)
			local bar`c' `"bar d_fgt0_ 	 count2 if spell == "`spellc'" & count2 == `count2', color("`: word 1 of ${colorpalette}'") ||"'
			if "`c'" == "1" {
				local legend`c' `"`c' "`: variable label d_fgt0_'""'			// Only one legend entry per variable
				local legend 	`"`legend' `legend`c''"'
			}
		}
		else {
			local bar`c' `"bar d_gdp_pc_ count2 if spell == "`spellc'" & count2 == `count2', color("`: word 2 of ${colorpalette}'") ||"'
			if "`c'" == "2" {
				local legend`c' `"`c' "`: variable label d_gdp_pc_'""'
				local legend 	`"`legend' `legend`c''"'
			}
		}
		local scatter`c' `"scatter gep_ avg if spell == "`spellc'" & avg == `marker', msymbol(D) msize(medlarge) mc("`: word 3 of ${colorpalette}'") mlc(black) ||"'
		if "`c'" == `"`=wordcount("`count'")'"' {
			local legend`c' `"`=`c'+1' "`: variable label gep_'""'				// Only one legend entry per variable - Scatter is last (+1)
			local legend 	`"`legend' `legend`c''"'
		}
		local bar 		`"`bar' `bar`c''"'
		local scatter 	`"`scatter' `scatter`c''"'
	}

	// Axis label
	qui levelsof avg, local(xlab)
	foreach l of local xlab {
		local i = 1
		qui levelsof spell_dash if avg == `l', local(spell_lab)
		local spell_lab = `spell_lab'													// strip quotes
		local xlabel`i' `"`l' "`spell_lab'""'
		local xlabel `"`xlabel' `xlabel`i''"'
		local i = `i' + 1
	}
	
	// Figure
	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure6.xlsx"
		local act replace
		cap rm "`dirpath'\\Figure6.xlsx"
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
	local u = 5	
	putexcel set "`excelout2'", `act'
	tempfile graph
	twoway `bar' `scatter', 								///
			xlabel(`xlabel') yline(0)						///
			legend(order(`legend') pos(6) row(2) holes(2)) 	///
			ytitle("Annualized growth rate (percent)")		///
			name(ngraph`gr', replace)			
		
	putexcel set "`excelout2'", modify sheet(Figure6, replace)	  
	graph export "`graph'", replace as(png) name(ngraph) wid(1500)		
		putexcel A`u' = image("`graph'")
		
		putexcel A1 = ""
		putexcel A2 = "Figure 6: GDP - poverty elasticity"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: The figure shows change in poverty rates, GDP per capita, and the elasticity between poverty and GDP per capita."
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code to produce figure:"
		putexcel O7 = `"twoway `bar' `scatter', xlabel(`xlabel') yline(0) legend(order(`legend') pos(6) row(2) holes(2)) ytitle("Annualized growth rate (percent)") name(ngraph`gr', replace)"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
	putexcel save							
	cap graph close	
	//Export data
	drop a
	export excel * using "`excelout2'" , sheet("Figure6", modify) cell(O11) keepcellfmt firstrow(variables)
	if "`excel'"=="" shell start excel "`dirpath'\\Figure6.xlsx"
end