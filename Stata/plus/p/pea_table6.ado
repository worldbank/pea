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

//Table 6. Multidimensional poverty: Multidimensional Poverty Measure (World Bank)

cap program drop pea_table6
program pea_table6, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Country(string) Welfare(varname numeric) Year(varname numeric) setting(string) excel(string) save(string) MISSING BENCHmark(string) ALL LAST3 PPPyear(integer 2017)]
	
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
	
	if "`all'"~="" & "`last3'"~="" {
		noi dis as error "Either all or within3, not both options"
		error 1
	}
	if "`all'"=="" & "`last3'"=="" local last3 last3
	local benchmark0 "`benchmark'"
	local benchmark "`country' `benchmark'"
	
	//house cleaning
	_pea_export_path, excel("`excel'")
	 
	qui {
		//Keep only the latest data
		su `year',d
		local ymax = r(max)
		keep if `year'==`ymax'
		
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
			
		_pea_mpm [aw=`wvar'], c(`country') year(`year') welfare(`welfare') setting(`setting') pppyear(`pppyear')
		save `dataori', replace			
	} //qui
	
	//benchmark
	clear
	*tempfile mpmben
	*save `mpmben', replace emptyok
	
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	
	local nametodo = 0
	cap confirm file "`persdir'pea/PIP_list_name.dta"
	if _rc==0 {
		cap use "`persdir'pea/PIP_list_name.dta", clear	
		if _rc~=0 local nametodo = 1	
	}
	else local nametodo = 1
	if `nametodo'==1 {
		cap pea_dataupdate, datatype(LIST) update
		if _rc~=0 {
			noi dis "Unable to run pea_dataupdate, datatype(LIST) update"
			exit `=_rc'
		}
	}
		
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
	
	foreach cc of local benchmark {
		local cc "`=upper("`cc'")'"
		use "`persdir'pea/WLD_GMI_MPM.dta" if code=="`cc' & ppp==`pppyear'", clear
		if "`all'"~="" {
			if _N>0 {				
				ren dep_infra_impw2 dep_infra_impw
				keep code year dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw mdpoor_i1 survname welftype
				append using `dataori'
				save `dataori', replace
			}
		}
		
		if "`last3'"~="" {
			gsort -year
			gen x = _n
			keep if x<=3
			if _N>0 {				
				ren dep_infra_impw2 dep_infra_impw
				keep code year dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw mdpoor_i1 survname welftype	
				append using `dataori'
				save `dataori', replace
			}
		} //last3		
	} //benchmark
	
	use `dataori', clear
	merge m:1 code using "`persdir'pea/PIP_list_name.dta", keep(1 3) keepusing(country_name)
	replace country_name = code if country_name == ""

	for var dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw mdpoor_i1: replace X = X*100
	
	la var mdpoor_i1 "Multidimensional Poverty Measure headcount (%)"
	la var dep_poor1 "Daily income less than $${mpmpline} per person"
	la var dep_educ_com "No adult has completed primary education"
	la var dep_educ_enr "At least one school-aged child is not enrolled in school"
	la var dep_infra_elec "No access to electricity"
	la var dep_infra_imps "No access to limited-standard sanitation"
	la var dep_infra_impw "No access to limited-standard drinking water"
	local i=2
	gen order = .
	replace order = 1 if code=="`country'"
	foreach cc of local benchmark0 {
		replace order = `i' if code=="`cc'"
		local i = `i'+1
	}
	
		//6a
		collect clear
		qui collect: table (order country_name) (year), stat(mean mdpoor_i1) nototal nformat(%20.1f) missing
		collect style header order country_name year, title(hide)
		collect style header order, level(hide)		
		collect title `"Table 6a. Multidimensional poverty: Multidimensional Poverty Measure (World Bank) (%)"'
		collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Indicator database"'
		collect notes 2: `"Note: The World Bank Multidimensional Poverty Measure (MPM) is a weighted aggregate of six components (weights in parantheses): income (1/3), education (1/6), school-enrolment (1/6), electricity (1/9), sanitation (1/9), drinking water (1/9) with `pppyear' PPP."'
		_pea_tbtformat
		_pea_tbt_export, filename(Table6) tbtname(Table6a) excel("`excel'") dirpath("`dirpath'") excelout("`excelout'")	
		
		//6b
		collect clear
		qui collect: table () (year) if code=="`country'", stat(mean dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw ) nototal nformat(%20.1f) missing	
		collect style header year, title(hide)
		
		collect title `"Table 6b. Multidimensional poverty: Multidimensional poverty components (%) (World Bank)"'
		collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Indicator database"'
		collect notes 2: `"Note: The table shows deprivation rates of the six components of the World Bank Multidimensional Poverty Measure (MPM) with `pppyear' PPP. See Table 6a for weights of each component. Limited-standard drinking water refers to water from an improved source within collection time of 30 minutes for a roundtrip including queuing. Limited-standard sanitation refers to the use of improved facilities which are not shared with other households (WHO/UNICEF Joint Monitoring Programme)."'
		_pea_tbtformat		
		_pea_tbt_export, filename(Table6) tbtname(Table6b) excel("`excel'") dirpath("`dirpath'") excelout("`excelout'")	shell
end