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

//Fig 14. Multidimensional poverty: Multidimensional Poverty Measure components(World Bank)

cap program drop pea_figure14
program pea_figure14, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) Welfare(varname numeric) Year(varname numeric) setting(string) excel(string) save(string) BENCHmark(string) within(integer 3) scheme(string) palette(string) PPPyear(integer 2017)]
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
    //Country
	if "`country'"=="" {
		noi dis as error "Please specify the country code of analysis"
		error 1
	}
	local country "`=upper("`country'")'"
	cap drop code
	gen code = "`country'"	
	
	if "`within'"=="" local within 3
	if `within'>10 {
		noi dis as error "Surveys older than 10 years should not be used for comparisons. Please use a different value in within()"
		error 1
	}
	
	local benchmark0 "`benchmark'"
	
	//house cleaning
	_pea_export_path, excel("`excel'")
	
	// Figure colors
	local groups = 7																					// number of bars
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")						//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
	
	 qui {
		//Save latest year of survey data
		su `year',d
		local lasty `r(max)'
		
		//Weights
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		}
				
		//missing observation check
		marksample touse
		local flist `"`wvar' `welfare' `year'"'
		markout `touse' `flist' 
		
		tempfile dataori datalbl
		save `dataori', replace		
			
		_pea_mpm [aw=`wvar'], c(`country') year(`year') welfare(`welfare') setting(`setting') pppyear(`pppyear')
		save `dataori', replace			
		
		//benchmark and other countries
		clear
		local persdir : sysdir PERSONAL	
		if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
			
		//Update MPM data
		local dl 0
		local returnfile "`persdir'pea/WLD_GMI_MPM.dta"
		cap confirm file "`returnfile'"
		if _rc==0 {
			cap use "`returnfile'", clear	
			if _rc==0 {
				local dtadate : char _dta[version]			
				if (date("$S_DATE", "DMY")-date("`dtadate'", "DMY")) > 30 local dl 1
				else return local cachefile "`returnfile'"
			}
			else local dl 1
		}
		else {
			cap mkdir "`persdir'pea"
			local dl 1
		}
		
		if `dl'==1 {
			cap pea_dataupdate, datatype(MPM) update
			if _rc~=0 {
				noi dis as error "Unable to run pea_dataupdate, datatype(MPM) update"
				exit `=_rc'
			}
		}
		
		use "`persdir'pea/WLD_GMI_MPM.dta", clear
		//drop current countries
		drop if code=="`country'"

		gen y_d = abs(`lasty' - year)											// year closest to PEA year
		bys code (year): egen min_d = min(y_d)
		keep if (y_d == min_d) & y_d < 3 & mdpoor_i1 ~= .
		bys code (year): keep if _n == _N 										// use latest year if there are 
		if _N>0 {				
			ren dep_infra_impw2 dep_infra_impw
			keep code year dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw mdpoor_i1 survname welftype	
			append using `dataori'
			save `dataori', replace
		}
		
		for var dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw mdpoor_i1: replace X = X*100
	
		la var mdpoor_i1 "Multidimensional Poverty Measure headcount (%)"
		la var dep_poor1 "Daily income less than US$2.15 per person"
		la var dep_educ_com "No adult has completed primary education"
		la var dep_educ_enr "At least one school-aged child is not enrolled in school"
		la var dep_infra_elec "No access to electricity"
		la var dep_infra_imps "No access to limited-standard sanitation"
		la var dep_infra_impw "No access to limited-standard drinking water"

		// Recount benchmark countries to get total number of legend entries, as some benchmark countries might not have data
		gen b_in_list = ""
		foreach b of local benchmark {
			replace b_in_list = code if code == "`b'"
		}
		qui levelsof b_in_list, local(benchmark_data)
		local b_data_count = `:word count `benchmark_data''
		
		// Merge regions
		merge m:1 code using "`persdir'pea/PIP_list_name.dta", keep(1 3) keepusing(region country_name)
		qui levelsof _merge, local(mcode)
		assert _merge != 1														// Check if region codes merge
		drop _merge 
		// Get region
		gen count = _n
		qui sum count if code == "`country'"
		local region_name `=region[r(min)]'		
		
	
	//Figure14a Bar chart
		frame pwf 
		frame copy `r(currentframe)' mpmmain, replace 	// copy current data to frame, just in case 
		frame copy `r(currentframe)' `country', replace
		frame change `country'
		keep if code == "`country'"
		qui levelsof year, local(year_count)
		local v "dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw"
		local vlab `" "Monetary" "Education attainment" "Education enrollment" "Electricity" "Sanitation" "Water" "MPM aggregate" "'	// Legend entries
		foreach i of local year_count {
			expand 6 if year ==`i', gen(expand`i')												// Need one observations per year for each variable
			local varlist "`varlist' `v'"														// List of variables x years
		}
		bys code year:	 gen vcount = _n 		
		bys code (year): gen ycount = _n 		
		egen ygroup = group(year)				
		gen ycount2 = ycount + ygroup - 1														// Add gap between numbers of groups
		bys code year: egen avg = mean(ycount2)		
		// bars
		qui levelsof ycount, local(ycount)
		foreach c of local ycount {
			local yearc = year[`c']
			local ycount2 = ycount2[`c']
			local marker = avg[`c']
			local vcount = vcount[`c']
			local bar`c' `"bar `: word `c' of `varlist'' ycount2 if year == `yearc' & ycount2 == `ycount2', color("${col`vcount'}") ||"'
			local bar 	`"`bar' `bar`c''"'
			if `c' < 7 {
				local legbar`c' `"`c' "`: word `c' of `vlab''""'										// Only one legend entry per variable
				local legbar 	`"`legbar' `legbar`c''"'
			}
		}
		// lines (mpm aggregate)

		qui levelsof ygroup, local(ygroup)
		foreach c of local ycount {
			local yearc = year[`c']
			local line`c' `"line mdpoor_i1 ycount2 if year == `yearc', color("${col7}") ||"'
			local line 	`"`line' `line`c''"'
		}
		qui sum ycount
		local lmax = `=`r(max)'+1'
		local legbar`lmax' `"`lmax' "`: word 7 of `vlab''""'									// Only one legend entry per variable - MPM aggregate is last
		local legbar 	`"`legbar' `legbar`lmax''"'
		
		// Axis label
		qui levelsof avg, local(xlab)
		foreach l of local xlab {
			local i = 1
			qui levelsof year if avg == `l', local(year_lab)
			local year_lab = `year_lab'													// strip quotes
			local xlabel`i' `"`l' "`year_lab'""'
			local xlabel `"`xlabel' `xlabel`i''"'
			local i = `i' + 1
		}
		//Figure
		local figname Figure14
		if "`excel'"=="" {
			local excelout2 "`dirpath'\\`figname'.xlsx"
			local act replace
			cap rm "`dirpath'\\`figname'.xlsx"
		}
		else {
			local excelout2 "`excelout'"
			local act modify
		}
				
		local gr 1
		local u  = 5		
		putexcel set "`excelout2'", `act'
		tempfile graph1
		
		twoway `bar' `line', 								///
			xlabel(`xlabel') xtitle("")						///
			legend(order(`legbar') pos(6) row(2) holes(2)) 	///
			ytitle("Share of population, %")				///
			name(gr_mpm1, replace)	
			
		putexcel set "`excelout2'", modify sheet("Figure14a", replace)
		graph export "`graph1'", replace as(png) name(gr_mpm1) wid(1500)
		putexcel A`u' = image("`graph1'")
		
		putexcel A1 = ""
		putexcel A2 = "Figure 14a: Multidimensional poverty measure components"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the Global Monitoring Indicator database."
		putexcel A4 = "Note: The figure shows the share of population deprived in each of the components of the Multidimensional Poverty Measure (MPM) as bars, and the aggregate MPM measure as a horizontal line. See Table 6a for the weights of each MPM component."	
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"twoway `bar' `line', xlabel(`xlabel') xtitle("") legend(order(`legbar') pos(6) row(2) holes(2)) ytitle("Share of population, %")"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
		//Export data
		export excel code dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw mdpoor_i1 year ycount2 using "`excelout2'" if code=="`country'", sheet("Figure14a", modify) cell(O11) keepcellfmt firstrow(variables)	
		
	//Figure14b Scatter many countries - update to the scatter style
		// Back to main data
		frame change mpmmain
		// Scatter preparation
		* PEA country
		local groupcount = 1
		local leg_elem = `b_data_count' + 1									// Number of legend elements
		gen   group = `groupcount' if code == "`country'"
		qui sum count if code == "`country'"
		local cname `=country_name[r(min)]'
		local legend `"`legend' `leg_elem' "`cname'""'							// PEA country last and so on, so that PEA marker is on top
		local grcolor`groupcount': word `groupcount' of ${colorpalette}			// Palette defined in pea_figure_setup
		gen   mlabel = "{bf:" + code + "}" if code == "`country'"
		local msym`groupcount' "D"

		* Benchmark countries
		local b_count = 1
		foreach c of local benchmark_data {
			local groupcount = `groupcount' + 1	
			local leg_elem 	 = `leg_elem' - 1
			replace group    = `groupcount' if code == "`c'"
			qui sum count if code == "`c'"
			local cname `=country_name[r(min)]'
			local legend `"`legend' `leg_elem' "`cname'""'
			local b_count = `b_count' + 1
			local grcolor`groupcount': word `groupcount' of ${colorpalette}
			local msym`groupcount' "t"
		}
		// Scatter command (14b)
		qui levelsof group, local(group_num)
		foreach i of local group_num {
			local scatter_cmd`i' `"scatter mdpoor_i1 dep_poor1 if group == `i', mc("`grcolor`i''") msymbol("`msym`i''") ml(mlabel) msize(medlarge) mlabpos(9) || "'
			local scatter_cmd "`scatter_cmd`i'' `scatter_cmd' "					// PEA country comes last and marker is on top
		}
		
		drop if code == "`country'" & year ~= `lasty'							// Keep only last year for PEA country
		keep if code == "`country'" | code == b_in_list
		tempfile graph1
		su mdpoor_i1,d
		local mpmmax = r(max)
		gen x = 0 in 1
		gen y = 0 in 1
		replace x = `mpmmax' in 2
		replace y = `mpmmax' in 2
		
		twoway `scatter_cmd' || line x y, lpattern(-) lcolor(gray) ///
			xtitle("Poverty rate, %", size(medium)) ytitle("Multidimensional poverty measure, %", size(medium)) ///
			legend(order(`legend')) name(gr_mpm2, replace)
		
		putexcel set "`excelout2'", modify sheet("Figure14b", replace)
		graph export "`graph1'", replace as(png) name(gr_mpm2) wid(1500)
		putexcel A`u' = image("`graph1'")	
		putexcel A1 = ""
		putexcel A2 = "Figure 14b: Multidimensional poverty and poverty rates"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: Data is from the closest available survey within `within' years to `lasty'. Poverty rates refer to the international poverty line per day (`pppyear' PPP) line. See Table 6a for the weights of each MPM component."	
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"twoway `scatter_cmd' || line x y, lpattern(-) lcolor(gray), ytitle("Poverty rate, %", size(medium)) xtitle("Multidimensional poverty measure, %", size(medium)) legend(order(`legend'))"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
		putexcel save
		//Export data
		export excel code mdpoor_i1 dep_poor1 x y using "`excelout2'", sheet("Figure14b", modify) cell(O11) keepcellfmt firstrow(variables)	
		cap graph close	
		
	//Figure14c MPM and poverty addition by benchmark countries
		gen add_mpm = mdpoor_i1 - dep_poor1
		gen pea_country = code == "`country'"	
		graph bar dep_poor1 add_mpm, stack over(code, sort(pea_country mdpoor_i1)) ///
			legend(pos(6) order(1 "Monetary poverty" 2 "Additional multidimensional poverty") row(1) on) 	///
			ytitle("Multidimensional poverty rate (percent)") name(gr_mpm3, replace)	
			
		putexcel set "`excelout2'", modify sheet("Figure14c", replace)
		graph export "`graph1'", replace as(png) name(gr_mpm3) wid(1500)
		putexcel A`u' = image("`graph1'")	
		putexcel A1 = ""
		putexcel A2 = "Figure 14c: Monetary and multidimensional poverty rates"
		putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
		putexcel A4 = "Note: Data is from the closest available survey within `within' years to `lasty'. Figure shows monetary poor, and the additional poverty rates from other multidimensional rates. Monetary poverty rates refer to the international poverty line per day (`pppyear' PPP) line. See Table 6a for the weights of each MPM component."	
		
		putexcel O10 = "Data:"
		putexcel O6	= "Code:"
		putexcel O7 = `"graph bar dep_poor1 add_mpm, stack over(code, sort(pea_country mdpoor_i1)) legend(pos(6) order(1 "Monetary poverty" 2 "Additional multidimensional poverty") row(1) on) ytitle("Poverty rate (percent)")"'
		if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
		putexcel save
		//Export data
		export excel code mdpoor_i1 dep_poor1 x y using "`excelout2'", sheet("Figure14c", modify) cell(O11) keepcellfmt firstrow(variables)	
		cap graph close	
		
	} //qui
	if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"
end