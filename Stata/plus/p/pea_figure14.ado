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

//Fig 14. Multidimensional poverty: Multidimensional Poverty Measure (World Bank)

cap program drop pea_figure14
program pea_figure14, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) Welfare(varname numeric) Year(varname numeric) setting(string) excel(string) save(string) MISSING BENCHmark(string) within(integer 3) scheme(string) palette(string)]
	
  //Country
	if "`country'"=="" {
		noi dis as error "Please specify the country code of analysis"
		error 1
	}
	local country "`=upper("`country'")'"
	cap drop code
	gen code = "`country'"	
	
	if `within'>10 {
		noi dis as error "Surveys older than 10 years should not be used for comparisons. Please use a different value in within()"
		error 1
	}
	if "`within'"=="" local within 3
	local benchmark0 "`benchmark'"
	*local benchmark "`country' `benchmark'"
	
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
	
	// Figure colors
	local groups = 7																					// number of bars
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")						//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)
	
	
	  {
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
		local flist `"`wvar' `welfare' `povlines' `year'"'
		markout `touse' `flist' 
		
		tempfile dataori datalbl
		save `dataori', replace		
			
		_pea_mpm [aw=`wvar'], c(`country') year(`year') welfare(`welfare') setting(`setting')
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
				noi dis "Unable to run pea_dataupdate, datatype(MPM) update"
				exit `=_rc'
			}
		}
		
	
		use "`persdir'pea/WLD_GMI_MPM.dta", clear
		//drop current countries
		drop if code=="`country'"

		gen y_d = abs(`lasty' - year)												// year closest to PEA year
		bys code (year): egen min_d = min(y_d)
		keep if (y_d == min_d) & y_d < 3 & mdpoor_i1 ~= .
		bys code (year): keep if _n == _N 									// use latest year if there are 

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
		
		
		// Scatter preparation
		* PEA country
		local groupcount = 1
		local leg_elem = `b_data_count' + 3																	// Number of legend elements
		gen   group = `groupcount' if code == "`country'"
		qui sum count if code == "`country'"
		local cname `=country_name[r(min)]'
		local legend `"`legend' `leg_elem' "`cname'""'														// PEA country last and so on, so that PEA marker is on top
		local grcolor`groupcount': word `groupcount' of ${colorpalette}										// Palette defined in pea_figure_setup
		gen   mlabel = "{bf:" + code + "}" if code == "`country'"
		local msym`groupcount' "D"

		* Region
		local groupcount = `groupcount' + 1
		local leg_elem 	 = `leg_elem' - 1
		replace group 	 = `groupcount' if region  == "`region_name'" & group == .	 
		local legend `"`legend' `leg_elem' "`region_name'""'		
		local grcolor`groupcount': word `groupcount' of ${colorpalette}
		local msym`groupcount' "o"
		
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

		* Rest
		local groupcount = `groupcount' + 1
		local leg_elem 	 = `leg_elem' - 1
		replace group 	 = `groupcount' if group == .										
		local legend `"`legend' `leg_elem' "Other countries" "'	
		local lastcol: word count ${colorpalette}
		local grcolor`groupcount': word `lastcol' of ${colorpalette}								// Last color (grey in default)
		local msym`groupcount' "s" 
				
		// Scatter command
		qui levelsof group, local(group_num)
		foreach i of local group_num {
			local scatter_cmd`i' `"scatter mdpoor_i1 dep_poor1 if group == `i', mc("`grcolor`i''") msymbol("`msym`i''") ml(mlabel) msize(medlarge) mlabpos(9) || "'
			local scatter_cmd "`scatter_cmd`i'' `scatter_cmd' "						// PEA country comes last and marker is on top
		}
		//Figures
		local figname Figure14
		if "`excel'"=="" {
			local excelout2 "`dirpath'\\`figname'.xlsx"
			local act replace
		}
		else {
			local excelout2 "`excelout'"
			local act modify
		}
				
		local gr 1
		local u  = 5		
		putexcel set "`excelout2'", `act'
		
		//Prepare Notes
		local notes "Source: World Bank calculations using survey data accessed through GMD."
		local notes `"`notes'"'
		if "`nonotes'" ~= "" {
			local notes = ""
		}
		else if "`nonotes'" == "" {
			local notes `notes'
		}
		// Coloring of bars
		forval i = 1/7 {														// Number of bars
			local colors "`colors' bar(`i', color(${col`i'}))"		
		}
		
		//Figure14_1 MPM bar
		/*
		tempfile graph1
		
		graph bar dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw mdpoor_i1 if code=="`country'", over(year)  ///
			legend(order(1 "Monetary" 2 "Education attainment" 3 "Education enrollment" 4 "Electricity" 5 "Sanitation" 6 "Water" 7 "MPM") ///
			rows(2) size(small) position(6)) ///
			`colors'													 ///
			ytitle("Share of population, %") asyvars  name(gr_mpm1, replace) ///
			note(`notes')
		putexcel set "`excelout2'", modify sheet("Figure14_1", replace)
		graph export "`graph1'", replace as(png) name(gr_mpm1) wid(3000)
		putexcel A`u' = image("`graph1'")
			*/
		
		
		//Figure14_2 Venn
		
		//Figure14_3 Scatter many countries- update to the scatter style
		//Prepare Notes
		local notes "Source: World Bank calculations using survey data accessed through GMD."
		local notes `"`notes'" "Data is from the closest available survey within `within' years to `lasty'."'
		if "`nonotes'" ~= "" {
			local notes = ""
		}
		else if "`nonotes'" == "" {
			local notes `notes'
		}		
		drop if code == "`country'" & year ~= `lasty'							// Keep only last year for PEA country
		tempfile graph1
		su mdpoor_i1,d
		local mpmmax = r(max)
		gen x = 0 in 1
		gen y = 0 in 1
		replace x = `mpmmax' in 2
		replace y = `mpmmax' in 2
		twoway `scatter_cmd' || line x y, lpattern(-) lcolor(gray) ///
			ytitle("Poverty rate, %", size(medium)) xtitle("Multidimensional poverty measure, %", size(medium)) ///
			legend(order(`legend')) name(gr_mpm3, replace) ///
			note("`notes'")
		x
		putexcel set "`excelout2'", modify sheet("Figure14_3", replace)
		graph export "`graph1'", replace as(png) name(gr_mpm3) wid(3000)
		putexcel A`u' = image("`graph1'")
		
		putexcel save
		cap graph close	
	} //qui
	if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"
end