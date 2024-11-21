*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 

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
	syntax [if] [in] [aw pw fw], [Country(string) Welfare(varname numeric) Year(varname numeric) setting(string) excel(string) save(string) MISSING BENCHmark(string) last(integer 5)]
	
	//Country
	if "`country'"=="" {
		noi dis as error "Please specify the country code of analysis"
		error 1
	}
	local country "`=upper("`country'")'"
	cap drop code
	gen code = "`country'"	
	
	if `last'>10 {
		noi dis as error "Data range is too big, please choose an number less than or equal 10"
		error 1
	}
	if "`last'"=="" local last 5
	local benchmark0 "`benchmark'"
	local benchmark "`country' `benchmark'"
	
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
	
	qui {
		//Keep only the latest data
		su `year',d
		local ymax = r(max)
		*keep if `year'==`ymax'
		
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
		
		gsort -year
		gen x = _n
		keep if x<=`last'
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
		
		//Figure14_1 MPM bar
		tempfile graph1
		graph bar dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw mdpoor_i1 if code=="`country'", over(year)  ///
			legend(order(1 "Monetary" 2 "Education attainment" 3 "Education enrollment" 4 "Electricity" 5 "Sanitation" 6 "Water" 7 "MPM") ///
			rows(2) size(small) position(6)) ///	
			ytitle("Share of population, %") asyvars  name(gr_mpm1, replace)
			
		putexcel set "`excelout2'", modify sheet("Figure14_1", replace)
		graph export "`graph1'", replace as(png) name(gr_mpm1) wid(3000)
		putexcel A`u' = image("`graph1'")
		
		//Figure14_2 Venn
		
		//Figure14_3 Scatter many countries- update to the scatter style
		tempfile graph1
		su mdpoor_i1,d
		local mpmmax = r(max)
		gen x = 0 in 1
		gen y = 0 in 1
		replace x = `mpmmax' in 2
		replace y = `mpmmax' in 2
		scatter mdpoor_i1 dep_poor1 || line x y, lpattern(-) lcolor(gray) ///
			ytitle("Poverty rate, %", size(medium)) xtitle("Multidimensional poverty measure, %", size(medium)) ///
			legend(off) name(gr_mpm3, replace)
		
		putexcel set "`excelout2'", modify sheet("Figure14_3", replace)
		graph export "`graph1'", replace as(png) name(gr_mpm3) wid(3000)
		putexcel A`u' = image("`graph1'")
		
		putexcel save
		cap graph close	
	} //qui
	if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"
end