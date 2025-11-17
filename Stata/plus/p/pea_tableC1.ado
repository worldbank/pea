*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 
*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Sandra Carolina Segovia Juarez <ssegoviajuarez@worldbank.org>; Henry Stemmler <hstemmler@worldbank.org>
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

//Table C.1. Key Poverty, Shared Prosperity and Labor Market Indicators

cap program drop pea_tableC1
program pea_tableC1, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) BENCHmark(string) Year(varname numeric) aggregate(string) ONELine(varname numeric) ONEWelfare(varname numeric) PPPyear(integer 2021) VULnerability(real 1.5) lstatus(varname numeric) empstat(varname numeric) industrycat4(varname numeric) age(varname numeric) male(varname numeric) setting(string) CORE LINESORTED FGTVARS using(string) excel(string) save(string)]	
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')

	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	
	//load data if defined
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}	
	if "`save'"=="" tempfile saveout
	
	//house cleaning
	_pea_export_path, excel("`excel'")
	
	if "`vulnerability'"=="" {
		local vulnerability = 1.5
		noi di in yellow "Default multiple of poverty line to define vulnerability is 1.5"
	}
	else {
		if `vulnerability' ~= 1.5 & `vulnerability' ~= 2 {
			display as error "Vulnerability multiple can only be 1.5 or 2"
			exit 198
		}
	}
	
	if "`aggregate'"~="" {
		local aggregate =lower("`aggregate'")
		if !inlist("`aggregate'", "groups", "benchmark") {
			display as error "aggregate() must be either 'groups' or 'benchmark'"
			exit 198
		}
	}
	else {
		//option when missing
	}
	
	if "`benchmark'"=="" local benchmark = upper("`benchmark'")
	
	if "`lstatus'"=="" {
		noi di in red "Not working variable must be defined in lstatus()"
		exit 1
	}
	if "`age'"=="" {
		noi di in red "Age variable must be defined in age()"
		exit 1
	}	
	
	//Use only one national poverty line-up
	if "`natpovlines'" ~= "" local natline = word("`natpovlines'", 1)

		
	//variable checks
	//check plines are not overlapped.
	//trigger some sub-tables
	qui {
		su `year', meanonly
		local ymax = r(max)
		levelsof `year', local(ylist)
		local atrisk0 2021		
		local atcheck : list ylist & atrisk0
		if "`atcheck'"=="" local yatrisk `ymax'
		else local yatrisk `atcheck'
		
		//order the lines
		if "`linesorted'"=="" {
			if "`ppppovlines'"~="" {
				_pea_pline_order, povlines(`ppppovlines')			
				local ppppovlines `=r(sorted_line)'
				foreach var of local ppppovlines {
					local lbl`var' `=r(lbl`var')'
				}
			}
			
		}
		else {
			foreach var of varlist `natline' `ppppovlines' {
				local lbl`var' : variable label `var'
			}
		}

		if "`oneline'"~="" {
			su `oneline'
			if `=r(sd)'==0 local lbloneline: display %9.2f `=r(mean)'				
			else local lbloneline `oneline'
			local lbloneline `=trim("`lbloneline'")'
		}
		
		//Weights
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		}
		
		// Check if empstat and/or industrycat4 are missing
		local lvarlist "`lstatus' `empstat' `industrycat4'"
		foreach var of local lvarlist {
			su `var', meanonly
			if (r(N) == 0) local noobs "`noobs' `var'"
		}
		local lvarlist: list lvarlist - noobs
	
		//missing observation check
		marksample touse
		local flist `"`wvar' `natwelfare' `natline' `pppwelfare' `ppppovlines' `year'"'
		markout `touse' `flist' 
		
		tempfile dataori datalbl data_fin
		save `dataori', replace
		des, replace clear
		save `datalbl', replace
		use `dataori', clear
	} //qui
	
	if "`fgtvars'"=="" { //only create when the fgt are not defined	
		if "`pppwelfare'"~="" { //reset to the floor
			replace `pppwelfare' = ${floor_} if `pppwelfare'< ${floor_}
			noi di in yellow "Welfare in `pppyear' PPP is adjusted to a floor of ${floor_}"
		}
		
		//FGT
		if "`natwelfare'"~="" & "`natline'"~="" _pea_gen_fgtvars if `touse', welf(`natwelfare') povlines(`natline')
		if "`pppwelfare'"~="" & "`ppppovlines'"~="" _pea_gen_fgtvars if `touse', welf(`pppwelfare') povlines(`ppppovlines') 
		
		gen double _pop = `wvar'
		
		//Gini, Prosperity Gap and vulnerability
		if "`natwelfare'"~="" & "`pppwelfare'"~="" local distwelf `natwelfare'
		if "`natwelfare'"=="" & "`pppwelfare'"~="" local distwelf `pppwelfare'
		clonevar _Gini_`distwelf' = `distwelf' if `touse'
		
		gen double _prosgap_`pppwelfare' = ${prosgline_}/`pppwelfare' if `touse'
		gen _pov_`onewelfare'_`oneline' = `onewelfare'< `oneline'  if `touse'
		gen _vulpov_`onewelfare'_`oneline' = `onewelfare'< `oneline'*`vulnerability' & `onewelfare' >= `oneline'  if `touse'	//	Only between poverty lines
	}
	else {
		
		if "`natwelfare'"~="" & "`pppwelfare'"~="" local distwelf `natwelfare'
		if "`natwelfare'"=="" & "`pppwelfare'"~="" local distwelf `pppwelfare'
		
		//Keep only first national poverty
		local count = 1
		foreach p of local natpovlines {
			if `count' ~= 1 {
				local _nnatline = word("`natpovlines'", `count')
				  drop _fgt0_`natwelfare'_`_nnatline'
				  di "_fgt0_`natwelfare'_`_nnatline'"
			}	
		local count = `count' + 1
		}		
	}
	tempfile data1 data1b data2 data3 data_lab atriskdata data_gmi1 data_gmi
	save `data1', replace
	
	//FGT - estimate points
	use `data1', clear
	groupfunction  [aw=`wvar'] if `touse', mean(_fgt* _prosgap_`pppwelfare' _vulpov_`onewelfare'_`oneline') gini(_Gini_`distwelf') rawsum(_pop) by(`year')
	drop _fgt1* _fgt2*
	save `data2', replace
	
	//MPM WB
	use `data1', clear
	_pea_mpm [aw=`wvar'], c(`country') year(`year') welfare(`pppwelfare') ppp(`pppyear')
	keep `year' mdpoor_i1
	replace mdpoor_i1 = mdpoor_i1*100
	ren mdpoor_i1 _mpmwb_`pppwelfare'
	merge 1:1 `year' using `data2'
	drop _merge
	save `data2', replace
	
	// Climate-hazard risk
	local cwd `"`c(pwd)'"'														// store current wd
	quietly capture cd "`persdir'pea/Scorecard_Summary_Vision/"
	if _rc~=0 {
		noi di in red "Scorecard_Summary_Vision folder does not exist."
	}
	quietly cd `"`cwd'"'

	cap import excel "`persdir'pea/Scorecard_Summary_Vision/EN_CLM_VULN.xlsx", firstrow clear
	if _rc==0 {
		qui destring Time_Period, gen(year)
		ren Geography_Code code
		keep if code=="`country'"
		if _N==0 {
			noi dis in y "Warning: no data for high risk of climate-related hazards or wrong country code"		
			local atriskdo = 0
		}
		else {
			ren Value value
			gen indicatorlbl = 51
			replace year = `yatrisk'
			keep year value indicatorlbl
			save `atriskdata', replace
			local atriskdo = 1		
		}
	} //rc excel
	else {
		noi dis as error "Unable to load the Scorecard EN_CLM_VULN.xlsx"
		error `=_rc'
	}	
	
	//Poverty 
	use `data2', clear
	erase `data2'
	gen double _npoor = _fgt0_`natwelfare'_`natline' *_pop
	su _npoor
	local xmin = r(min)
	local xmax = r(max)
	if `xmin' < 1000000 {
		local xscale 1000
		local xtxt "(thousands)"
	}
	else {
		local xscale 1000000
		local xtxt "(millions)"
	}
	replace _npoor = _npoor/`xscale'
	for var _fgt0* _vulpov* _Gini: replace X = X*100

	* Reshape
	order `year'
	xpose, varname clear promote
	ds 
	local vlist = r(varlist)
	local v0 _varname
	local vlist : list vlist - v0
	foreach var of local vlist {
		local tmp = `var'[1]
		ren `var' d`tmp'
	}
	drop in 1
	reshape long d, i(_varname) j(`year')
	ren d value
	split _varname, parse("_")
	drop _varname1
	
	//setup	indicator labels
	gen indicatorlbl = .
	if `atriskdo'==1 append using `atriskdata'
	replace indicatorlbl = 1 if _varname2=="fgt0" & _varname3=="natwelfare"
	replace indicatorlbl = 2 if _varname2=="npoor"
	local i = 3
	foreach var of local ppppovlines {
		replace indicatorlbl = `i' if _varname2=="fgt0" & _varname4=="`var'"
		local indlbl `indlbl' `i' "Poverty rate, `lbl`var'' (%)"
		local i = `i' + 1
	}
	replace indicatorlbl = 10 if _varname2=="mpmwb"
	replace indicatorlbl = 20 if _varname2=="Gini"
	replace indicatorlbl = 21 if _varname2=="prosgap"
	replace indicatorlbl = 30 if _varname2=="labor"
	replace indicatorlbl = 50 if _varname2=="vulpov"
	replace indicatorlbl = 51 if _varname2=="atrisk"
				
	drop if indicatorlbl==.		
	drop _varname*
	
	* Years for GMI benchmarking
	sum `year', meanonly
	local maxy `r(max)'
	save `data3', replace
	
	// Benchmark countries and regions	
	*Check if GMI data is already prepared, else download
	local nametodo = 0
	cap confirm file "`persdir'pea/GMI_extend_all_country.dta"
	if _rc==0 {
		cap use "`persdir'pea/GMI_extend_all_country.dta", clear	
		if _rc~=0 local nametodo = 1	
	}
	else local nametodo = 1
	if `nametodo'==1 {
		cap pea_dataupdate, datatype(GMI) update
		if _rc~=0 {
			noi dis "Unable to run pea_dataupdate, datatype(GMI) update"
			exit `=_rc'
		}
	}
	* Keep only relevant PPP
	keep if ppp == `pppyear'
	save `data_gmi1', replace
	
	* Save PEA country region and income group
	gen count = _n
	qui sum count if code == "`country'"
	local region_c `=region[r(min)]'
	local incgroup_current_c `=incgroup_current[r(min)]'		
	local country_name_c `=country_name[r(min)]'	
	
	* What is the correct poverty line? - For labor share in poor/nonpoor
	if "`incgroup_current_c'" == "Low-income countries" local inc = 1
	else if "`incgroup_current_c'" == "Lower-middle-income countries" local inc = 2
	else if "`incgroup_current_c'" == "Upper-middle-income countries" local inc = 3
	else "`incgroup_current_c'" == "High-income countries" local inc = 3			// Use UMIC if HIC
	local pea_pline : word `inc' of `ppppovlines'
	
	use `data1', clear
	qui levelsof `pea_pline', local(pline_use)	
	local pline_use = round(`pline_use' * 100)
	
	* What is the correct poverty line for vulnerability?
	*if "`onewelfare'" == "welfppp" {
	if "`onewelfare'" == "`pppwelfare'" {
		levelsof `oneline', local(pline_vul_low)
		local pline_vul_lo = round(`pline_vul_low' * 100)
		local pline_vul_up = floor(`pline_vul_lo'*`vulnerability')		
	} 
	else {
		noi di in red "Vulnerability to poverty for peers can only be calculated with pppwelfare() in onewelfare()."
	}
	
	//start merge/append GMI data for related countries
	clear 
	save `data_gmi', emptyok replace
	
	// GMI for peers
	// Option 1, benchmark countries
	if "`aggregate'" == "" {
		use `data_gmi1', clear
		gen keep = .
		foreach b of local benchmark  {
			replace keep = 1 if code == "`b'"
		}
		keep if keep == 1
		keep if year>=`=`maxy'-3' & year<=`=`maxy'+3'
		count
		if r(N) > 0 {
			gen diff = abs(year - `maxy')
			bys code: egen mindiff = min(diff)
			keep if diff == mindiff
			bys code: egen maxyear = max(year)								// If multiple years with same distance to circle year, use latest
			keep if year == maxyear
			* Generate country-survey information
			gen country_survey_year = country_name + " (" + welftype + " ," + survname + ")"
			qui levelsof country_survey_year, local(bench_types) clean separate(", ")
		}
		keep country_name code year fgt0_ipl fgt0_lmicpl fgt0_umicpl gini pg mdpoor_i1 _working_ind _misslfs_ind _empstat_ind_m _industry_ind_m _empstat_ind1 _industry_ind1 _industry_nonagr_ind poor`pline_use'_wrk nonpoor`pline_use'_wrk youth_wrk women_wrk
		rename country_name group
		save `data_gmi', replace emptyok
		
		// Scorecard for peers
		use `data_gmi1', clear
		bys code (year): keep if _n == _N	// Only have climate risk for one year, keep only one obs
		keep if atrisk ~= .
		gen keep = .
		foreach b of local benchmark  {
			replace keep = 1 if code == "`b'"
		}
		keep if keep == 1
		keep code country_name atrisk 
		rename country_name group
		merge 1:1 code using `data_gmi', nogen
		save `data_gmi', replace emptyok
				
		// Vulnerability for peers
		if "`onewelfare'" == "`pppwelfare'" { // only possible if ppp welfare		
			use "`persdir'pea/PIP_all_country.dta", clear
			keep if ppp == `pppyear'
			gen keep = .
			foreach b of local benchmark  {
				replace keep = 1 if code == "`b'"
			}
			keep if keep == 1
			keep if year>=`=`maxy'-3' & year<=`=`maxy'+3'
			qui sum
			if r(N) > 0 {
				gen diff = abs(year - `maxy')
				bys code: egen mindiff = min(diff)
				keep if diff == mindiff
				bys code: egen maxyear = max(year)								// If multiple years with same distance to circle year, use latest
				keep if year == maxyear
			}
			gen vulpov = headcount`pline_vul_up' - headcount`pline_vul_lo'
			keep vulpov code
			merge 1:1 code using `data_gmi', nogen
			drop code
			save `data_gmi', replace
		}
		count
		if r(N)==0 {
			noi dis "No data available for benchmark countries"
			error 2000
		}
	}
	// Option 2, aggregates of region and income groups
	else if "`aggregate'" == "groups" {
		foreach gp in incgroup_current region {
			use `data_gmi1', clear
			keep if `gp' == "``gp'_c'"											// Keep only PEA country specific region or income group
			keep if year>=`=`maxy'-3' & year<=`=`maxy'+3'
			gen diff = abs(year - `maxy')
			count
			if r(N)>0 {
				bys code: egen mindiff = min(diff)
				keep if diff == mindiff
				bys code: egen maxyear = max(year)								// If multiple years with same distance to circle year, use latest
				keep if year == maxyear
				* Generate country-survey information
				gen country_survey_year = country_name + " (" + welftype + " ," + survname + ")"
				qui levelsof country_survey_year, local(`gp'_names) clean separate(", ")
				collapse (mean) fgt0_ipl fgt0_lmicpl fgt0_umicpl gini pg mdpoor_i1 _working_ind _misslfs_ind _empstat_ind_m _industry_ind_m _empstat_ind1 _industry_ind1 _industry_nonagr_ind poor`pline_use'_wrk nonpoor`pline_use'_wrk youth_wrk women_wrk [aw=pop], by(`gp')
				gen group = `gp'
				drop `gp'
			}
			gen year = `maxy'			
			append using `data_gmi'
			save `data_gmi', replace emptyok
			
			// Scorecard for peers
			use `data_gmi1', clear
			bys code (year): keep if _n == _N	// Only have climate risk for one year, keep only one obs
			keep if atrisk ~= .
			keep if `gp' == "``gp'_c'"											// Keep only PEA country specific region or income group
			count
			if r(N)>0 {
				collapse (mean) atrisk [aw=pop_pip_vul], by(`gp')
			}
			gen group = `gp'
			drop `gp'
			keep group atrisk 
			merge 1:1 group using `data_gmi', nogen
			save `data_gmi', replace emptyok
			
			// Vulnerability for groups aggregate
			if "`onewelfare'" == "`pppwelfare'" {			
				use "`persdir'pea/PIP_all_country.dta", clear
				keep if ppp == `pppyear'
				merge 1:1 code year using `data_gmi1', keepusing(`gp')
				keep if `gp' == "``gp'_c'"											// Keep only PEA country specific region or income group
				keep if year>=`=`maxy'-3' & year<=`=`maxy'+3'
				gen diff = abs(year - `maxy')
				count
				if r(N)>0 {
					bys code: egen mindiff = min(diff)
					keep if diff == mindiff
					bys code: egen maxyear = max(year)								// If multiple years with same distance to circle year, use latest
					keep if year == maxyear
					gen vulpov = headcount`pline_vul_up' - headcount`pline_vul_lo'
					collapse (mean) vulpov [aw=pop], by(`gp')
				}
				gen group = `gp'				
				merge 1:1 group using `data_gmi', nogen
				save `data_gmi', replace emptyok
			}	
		}
		count
		if r(N)==0 {
			noi dis "No data available for benchmark countries"
			error 2000
		}
	}
	// Option 3, aggregates of benchmark
	else if "`aggregate'" == "benchmark" {
		use `data_gmi1', clear
		gen keep = .
		noi dis "`benchmark'"
		foreach b of local benchmark  {
			replace keep = 1 if code == "`b'"
		}
		keep if keep == 1
		keep if year>=`=`maxy'-3' & year<=`=`maxy'+3'
		count
		if r(N)>0 {
			gen diff = abs(year - `maxy')
			bys code: egen mindiff = min(diff)
			keep if diff == mindiff
			bys code: egen maxyear = max(year)								// If multiple years with same distance to circle year, use latest
			keep if year == maxyear
			gen country_survey_year = country_name + " (" + welftype + " ," + survname + ")"
			qui levelsof country_survey_year, local(bench_names) clean separate(", ")
			collapse (mean) fgt0_ipl fgt0_lmicpl fgt0_umicpl gini pg mdpoor_i1 _working_ind _misslfs_ind _empstat_ind_m _industry_ind_m _empstat_ind1 _industry_ind1 _industry_nonagr_ind poor`pline_use'_wrk nonpoor`pline_use'_wrk youth_wrk women_wrk [aw=pop]
		}
		gen group = "Peers"
		cap drop year
		gen year = `maxy'
		save `data_gmi', replace emptyok
		
		// Scorecard for peers aggregate
		use `data_gmi1', clear
		gen keep = .
		foreach b of local benchmark  {
			replace keep = 1 if code == "`b'"
		}
		keep if keep == 1
		bys code (year): keep if _n == _N	// Only have climate risk for one year, keep only one obs
		keep if atrisk ~= .
		count
		if r(N)>0 {
			collapse (mean) atrisk [aw=pop_pip_vul]
		}
		gen group = "Peers"
		merge 1:1 group using `data_gmi', nogen
		save `data_gmi', replace

		// Vulnerability for peers aggregate		
		if "`onewelfare'" == "`pppwelfare'" {	// only possible if ppp welfare
			use "`persdir'pea/PIP_all_country.dta", clear
			keep if ppp == `pppyear'
			gen keep = .
			foreach b of local benchmark  {
				replace keep = 1 if code == "`b'"
			}
			keep if keep == 1
			keep if year>=`=`maxy'-3' & year<=`=`maxy'+3'
			gen diff = abs(year - `maxy')
			count
			if r(N)>0 {
				bys code: egen mindiff = min(diff)
				keep if diff == mindiff
				bys code: egen maxyear = max(year)								// If multiple years with same distance to circle year, use latest
				keep if year == maxyear
				gen vulpov = headcount`pline_vul_up' - headcount`pline_vul_lo'
				collapse (mean) vulpov [aw=pop]
			}
			gen group = "Peers"
			merge 1:1 group using `data_gmi', nogen
			save `data_gmi', replace
		}
		count
		if r(N)==0 {
			noi dis "No data available for benchmark countries"
			error 2000
		}
	} //benchmark
	else {
		//other aggregate options should not reach
	}
	
	erase `data_gmi1'
	cap mi unset, asis
	
	* Reshape, manually otherwise SUPER slow
	local vars fgt0_ipl fgt0_lmicpl fgt0_umicpl gini pg mdpoor_i1 atrisk _working_ind _misslfs_ind _empstat_ind_m _industry_ind_m _empstat_ind1 _industry_ind1 _industry_nonagr_ind poor`pline_use'_wrk nonpoor`pline_use'_wrk youth_wrk women_wrk vulpov
	local n_var : word count `vars'
	gen row_id = _n
	expand `n_var'
	gen varname = ""
	gen value = .
	local i = 1
	foreach var of local vars {
		bys row_id: replace varname = "`var'" if _n == `i'
		capture confirm variable `var'
		if !_rc {
			bys row_id: replace value = `var' if _n == `i' 
			drop `var'
		}
		local i = `i' + 1
	}
	
	drop row_id
	gen 	indicatorlbl = .
	replace indicatorlbl = 3 if varname=="fgt0_ipl"
	replace indicatorlbl = 4 if varname=="fgt0_lmicpl"
	replace indicatorlbl = 5 if varname=="fgt0_umicpl"
	replace indicatorlbl = 10 if varname=="mdpoor_i1"
	replace indicatorlbl = 20 if varname=="gini"
	replace indicatorlbl = 21 if varname=="pg"
	replace indicatorlbl = 30 if varname=="_working_ind"
	replace indicatorlbl = 31 if varname=="_empstat_ind1"
	replace indicatorlbl = 32 if varname=="_industry_ind1"
	replace indicatorlbl = 33 if varname=="_industry_nonagr_ind"
	replace indicatorlbl = 40 if varname=="poor`pline_use'_wrk"
	replace indicatorlbl = 41 if varname=="nonpoor`pline_use'_wrk"
	replace indicatorlbl = 42 if varname=="youth_wrk"
	replace indicatorlbl = 43 if varname=="women_wrk"	
	replace indicatorlbl = 50 if varname=="vulpov"	
	replace indicatorlbl = 51 if varname=="atrisk"
	gen		indicatorlbl2 = .
	replace indicatorlbl2 = 91 if varname=="_misslfs_ind"
	replace indicatorlbl2 = 92 if varname=="_empstat_ind_m"
	replace indicatorlbl2 = 93 if varname=="_industry_ind_m"	
	drop varname
	save `data_gmi', replace				

	// Labor data	
	use `data1', clear
	qui sum `lstatus'															// Skip if no labor data
	local has_labor r(N)
	if `has_labor' ~= 0 {
		//Define groups
		gen w_age 			= `age' >= 15 & `age' <= 64 if `age' ~= .
		gen _All 			=  1 if w_age == 1
		gen _women			= `male' == 0 if `male' ~= . & w_age == 1
		gen _youth 			= `age' >= 15 & `age' <= 24 if `age' ~= . & w_age == 1
		gen _work			= `lstatus' ~= 1 if `lstatus' ~= . & w_age == 1
		gen _agriculture 	= `industrycat4' == 1 if `industrycat4' ~= . & w_age == 1
		gen _nonagriculture	= `industrycat4' ~= 1 if `industrycat4' ~= . & w_age == 1
		gen _paid			= `empstat' == 1 if `empstat' ~= . & w_age == 1
		gen _poor 			= _fgt0_`pppwelfare'_`pea_pline' == 1 if _fgt0_`pppwelfare'_`pea_pline' ~= . & w_age == 1 
		gen _nonpoor	 		= _fgt0_`pppwelfare'_`pea_pline' == 0 if _fgt0_`pppwelfare'_`pea_pline' ~= . & w_age == 1 
		gen _misslfs_ind	= `lstatus' == . if w_age == 1
		gen _empstat_ind_m	= `empstat' == . if w_age == 1 & _work == 1
		gen _industry_ind_m	= `industrycat4' == . if w_age == 1 & _work == 1
		
		save `data1b'
		clear 
		save `data_lab', emptyok
		//Generate averages
		foreach var in _All _women _youth _poor _nonpoor {
			use `data1b', clear
			collapse (mean) value = _work [aw=`wvar'] if `touse', by(`year' `var')
			gen varname = "`var'"
			keep if `var' == 1
			drop `var'
			append using `data_lab'
			save `data_lab', replace
		}
		foreach var2 in _paid _agriculture _nonagriculture {
			use `data1b', clear
			collapse (mean) value = `var2' [aw=`wvar'] if `touse', by(`year' _All)
			gen varname = "`var2'"
			keep if _All == 1
			drop _All
			append using `data_lab'
			save `data_lab', replace
		}
		use `data1b', clear
		collapse (mean) _misslfs_ind _empstat_ind_m _industry_ind_m [aw=`wvar'] if `touse', by(`year')
		rename (_misslfs_ind _empstat_ind_m _industry_ind_m) (value_misslfs_ind value_empstat_ind_m value_industry_ind_m)
		reshape long value, i(`year') j(varname, string)
		append using `data_lab'

		replace value = value*100
		//Label
		gen		indicatorlbl = .
		replace indicatorlbl = 30 if varname=="_All"
		replace indicatorlbl = 31 if varname=="_paid"
		replace indicatorlbl = 32 if varname=="_agriculture"
		replace indicatorlbl = 33 if varname=="_nonagriculture"
		replace indicatorlbl = 40 if varname=="_poor"
		replace indicatorlbl = 41 if varname=="_nonpoor"
		replace indicatorlbl = 42 if varname=="_youth"
		replace indicatorlbl = 43 if varname=="_women"
		gen		indicatorlbl2 = .
		replace indicatorlbl2 = 91 if varname=="_misslfs_ind"
		replace indicatorlbl2 = 92 if varname=="_empstat_ind_m"
		replace indicatorlbl2 = 93 if varname=="_industry_ind_m"
		drop varname				
		save `data_lab', replace
	}
 
	// Put all together
	use `data3', clear
	if `has_labor' ~= 0 append using `data_lab'
	gen group = "`country_name_c'"
	gen group_order = 1
	append using `data_gmi'
	
	//labels
	la def indicatorlbl 1 "National poverty rate (%)" 2 "Number of poor `xtxt', national line" `indlbl' 10 "Multidimensional poverty rate (%)" 20 "Gini index" 21 "Prosperity Gap" 50 "Poverty vulnerability (%)" 51 "Percentage of people at high risk from climate-related hazards (2021**, %)" 30 "Share of population (15-64) working (%)" 31 "    Of which, in paid work (%)" 32 "    Of which, in agriculture (%)" 33 "    Of which, in non-agriculture (%)"  40 "Share of poor working (%)" 41 "Share of non-poor working (%)" 42 "Share of youth (15-24) working (%)" 43 "Share of women working (%)", add
	la val indicatorlbl indicatorlbl

	//setup	headers
	gen 	headers = .
	replace headers = 1 	if indicatorlbl < 20
	replace headers = 20 if indicatorlbl >= 20 & indicatorlbl < 30
	replace headers = 30 if indicatorlbl >= 30 & indicatorlbl < 50
	replace headers = 50 if indicatorlbl >= 50
	la def headers 1 "Poverty" 20 "Shared Prosperity" 30 "Labor Market" 50 "Vulnerability and Shocks"
	la val headers headers	
	
	//Group order
	qui levelsof group, local(gval) 
	local i = 2
	foreach val of local gval {
		// Skip if PEA country
		if "`val'" ~= "`country_name_c'" { 
			replace group_order = `i' if group == "`val'"
			label define group_lbl `i' "`val'", add
			local i = `i' + 1
		}
	}
	label define group_lbl 1 "`country_name_c'", add
	label values group_order group_lbl
	
	// Main Table
	save `data_fin', replace 
	keep if indicatorlbl~= .
	// Year with asterisk
	if "`aggregate'" ~= "" {
		tostring `year', replace
		replace `year' = `year' + "*" if group_order ~= 1
	}
	if "`aggregate'" == "benchmark" local agg_note "Values for peer countries are aggregated using population weights. *Peer countries are included if a survey within 3 years of `maxy' is available, which are (in parantheses welfare type and survey acronym): `bench_names'."
	else if "`aggregate'" == "groups" local agg_note "Values for countries within the same region or income group as `country_name_c' are aggregated using population weights. *Region and income group countries are included if a survey within 3 years of `maxy' is available. For the region, these are (in parantheses welfare type and survey acronym): `region_names'. For the income group, these are: `incgroup_current_names'. Regional and income group poverty rates deviate from official World Bank published rates, as no line-up values are used."
	else if "`aggregate'" == "" local agg_note "Peer countries are included if a survey within 3 years of `maxy' is available. Welfare type and survey acronym are: `bench_types'"
	
	local mi_note "The row 'Share of obs. with missing LFS values' shows the share of observations (15-64) for which the labor force status (working, not working) is missing."
	
	// Table
	local tabtitle "Table C.1. Core poverty indicators"
	local tabname TableC.1
	
	collect clear	
	collect: table (headers indicatorlbl) (group_order `year'), statistic(mean value) nototal nformat(%20.1f) missing
	
	collect style header headers indicatorlbl group_order `year', title(hide)
	*collect style header subind[.], level(hide)
	collect title `"`tabtitle'"'
	collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
	collect notes 2: `"Note: Poverty rates reported for the international poverty lines (per person per day) are expressed in `pppyear' purchasing power parity dollars. These three poverty lines reflect the typical national poverty lines of low-income countries, lower-middle-income countries, and upper-middle-income countries, respectively. National poverty lines are expressed in local currency units (LCU). The prosperity gap is defined as the average factor by which incomes need to be multiplied to bring everyone to the prosperity standard of $${prosgline_}. Poverty vulnerability refers to the share of the population living just above the poverty line (`lbl`oneline'') —below 1.5 times its value—who remain at high risk of falling into poverty due to even small shocks or setbacks. For the share of poor/nonpoor working, the `lbl`pea_pline'' poverty line, typical for `incgroup_current_c', is used. Work includes paid and unpaid work. `agg_note' `mi_note' Values for climate-related hazard risks are for ca. 2021."'
	collect style cell headers[]#cell_type[row-header], font(, bold)
	collect style cell indicatorlbl[]#cell_type[row-header], warn font(, nobold)	
	_pea_tbtformat
	_pea_tbt_export, filename(TableC1) tbtname(`tabname') excel("`excel'") dirpath("`dirpath'") excelout("`excelout'") 
	
	// Missing Table
	use `data_fin', clear 
	keep if indicatorlbl2~= .
	*31 "Share of obs. with missing LFS values"
	la def indicatorlbl2 91 "Share of obs. with missing values on working (15-64)" 92 "Of those working: Share of obs. with missing values on employment type (15-64)" 93 "Of those working: Share of obs. with missing values on sector (15-64)", add
	label values indicatorlbl2 indicatorlbl2
	// Table
	local tabtitle "Table C.1.M. Missing values on labor indicators"
	local tabname TableC1.M
	
	collect clear	
	collect: table (indicatorlbl2) (group_order `year'), statistic(mean value) nototal nformat(%20.1f) missing
	
	collect style header indicatorlbl2 group_order `year', title(hide)
	*collect style header subind[.], level(hide)
	collect title `"`tabtitle'"'
	collect notes 2: `"Note: Table shows the share missing observations for working status, employment type and sector of employment. The share of missing values for employment type and sector of employment are computed only for those working. Sample is restricted to individuals between 15 and 64 years of age."'
	collect style cell indicatorlbl2[]#cell_type[row-header], warn font(, nobold)	
	_pea_tbtformat
	_pea_tbt_export, filename(TableC1) tbtname(`tabname') excel("`excel'") dirpath("`dirpath'") excelout("`excelout'") modify shell
end