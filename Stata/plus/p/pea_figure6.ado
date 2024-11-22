

cap program drop pea_figure6
program pea_figure6, rclass
	version 18.0
syntax [if] [in] [aw pw fw], [Year(varname numeric) ONELine(varname numeric) ONEWelfare(varname numeric) FGTVARS spells(string) comparability(string) scheme(string) palette(string) excel(string) save(string)]

	
	tempfile dataori pea_pov 

	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	
	//house cleaning
	
	if "`comparability'"=="" {
		noi di in red "Warning: Comparability option not specified for Figure 7. Non-comparable spells may be shown."
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
	local fig7a = 1
	while "``i''" != "" {
		if "``i''"~=";" {																// Forces to start new local after ";" token
			local spell`fig7a' "``i''"		
			local fig7a = `fig7a' + 1
		}	
		local i = `i' + 1
	}

	// Comparability
	if "`comparability'" ~= "" {
		forv j=1(1)`=`fig7a'-1' {
			local spell_c`j' = "`spell`j''"												// Save local
			qui levelsof `comparability', local(comp_years)								// Loop through all values of comparability
			foreach i of local comp_years {
				qui	levelsof year if `comparability' == `i', local(year_c)				// Create list of comparable years
				local year_c = "`year_c'" 
				local test : list spell_c`j' in year_c									// Check if spell years are in list of comparable years
				if (`test' == 0) local spell`j' = ""									// If years not comparable, drop local
				if (`test' == 1) local spell`j' = "`spell_c`j''"						// If years comparable, keep local
			}
		}
	}	// if
	else{
		}

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
			noi dis "Unable to run pea_dataupdate, datatype(PIP) update"
			exit `=_rc'
		}
	}

	// Figure colors
	local groups = 3																	//  Total number of entries and colors
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")		//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
	
	// Preparation
	use `dataori', clear

	qui sum `oneline', d
	local povline `r(max)'	// Get one poverty line value
	
	// Generate poverty rate of PEA country
	if "`onewelfare'"~="" & "`oneline'"~="" _pea_gen_fgtvars if `touse', welf(`onewelfare') povlines(`oneline') 
	groupfunction  [aw=`wvar'] if `touse', mean(_fgt*) by(`year')
	keep _fgt0* year
	gen code = "`country'"
	save `pea_pov'
	
	// Merge GDP
	merge 1:1 code year using "`persdir'pea/PIP_all_GDP.dta", keep(1 3) keepusing(gdppc)
	levelsof _merge, local(mcode)
	assert _merge != 1																		// Check if GDP merges
	drop _merge 	
	
	// Reshape for easier handling of years
	reshape wide _fgt0* gdppc, i(code) j(`year')
			
	forv j=1(1)`=`fig7a'-1' {																// Loop through number of spells (minus ;) [See code above under Clean spells]
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
		expand 2 if spell =="`i'"													// Need to observations per spell (1 for each variable)
	}
	
	sort 			spell
	gen 			count 		= _n
	egen 			group 		= group(spell)
	gen 			count2 		= count + group - 1											// Add gap between numbers of groups
	bys spell: egen avg 		= mean(count2)
	gen 			spell_dash 	= subinstr(spell, "_", " – ", .)
	replace 		spell 		= subinstr(spell, "_", " ", .)
	qui levelsof count, local(count)
	foreach c of local count {
		local spellc = spell[`c']
		local count2 = count2[`c']
		local marker = avg[`c']
		if mod(`c', 2) {																	// Odd numbers are fgt, even are gdp (i.e. statement is 0)
			local bar`c' `"bar d_fgt0_ 	 count2 if spell == "`spellc'" & count2 == `count2', color("`: word 1 of ${colorpalette}'") ||"'
			if "`c'" == "1" {
				local legend`c' `"`c' "`: variable label d_fgt0_'""'						// Only one legend entry per variable
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
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}	
		
	putexcel set "`excelout2'", `act'
	tempfile graph
	twoway `bar' `scatter', 								///
			xlabel(`xlabel') yline(0)						///
			legend(order(`legend') pos(6) row(2) holes(2)) 	///
			ytitle("Annualized growth rate (percent)")		///
			name(ngraph`gr', replace)						
		
	putexcel set "`excelout2'", modify sheet(Figure6, replace)	  
	graph export "`graph'", replace as(png) name(ngraph) wid(3000)		
	putexcel A1 = image("`graph'")
	putexcel save							
	cap graph close	
	if "`excel'"=="" shell start excel "`dirpath'\\Figure6.xlsx"	
	
end