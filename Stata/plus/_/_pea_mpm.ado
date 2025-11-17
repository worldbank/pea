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

cap program drop _pea_mpm
program _pea_mpm, rclass
	version 16.0
	syntax [if] [in] [aw pw fw], [Country(string) Welfare(varname numeric) Year(varname numeric) SETting(string) PPPyear(integer 2021)]	
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	if `pppyear'==2017 global mpmpline 2.15
	if `pppyear'==2021 global mpmpline 3.00
	
	if "`setting'"=="GMD" {
		_pea_vars_set, setting(GMD)
		local vlist age male hhhead edu urban married school hhid pid hhsize industrycat4 empstat lstatus services assets
		foreach st of local vlist {
			local `st' "${pea_`st'}"
		}		
	}
	local country "`=upper("`country'")'"
	cap drop code
	gen code = "`country'"
	
	//trigger some sub-tables
	qui {		
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
		
		if "`welfare'"~="" {
			replace `welfare' = ${floor_} if `welfare'< ${floor_}
			noi di in yellow "Welfare in `pppyear' PPP is adjusted to a floor of ${floor_}"
		}
		
		tempfile dataori datalbl
		save `dataori', replace				
	} //qui
		
	****************************************************
	**Dimension 1: education (needs to define age groups)
	****************************************************
	**1a) Indicator: have no one with primary completion (completed 15+)
	//All adults
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
		
	use "`persdir'pea/UNESCO.dta", clear
	keep if countrycode=="`country'"	
	su year,d
	keep if year==`=r(max)'
	*qui dlw, country(Support) year(2005) type(GMDRAW) filename(UNESCO.dta) surveyid($surid) files clear nometa	
	
	if "`=off_pri_age[1]'"~="." {
		global lbage `=off_pri_age[1]'
		global ubage `=`=off_pri_age[1]'+8'
	}
	else error 1
	noi dis "Age: $lbage-$ubage"
	
	use `dataori', clear
	global eduage 15	
	local eduflag = 0
	cap gen educat5 = .
	cap gen educat7 = .
	
	cap su educat7
	if r(N)>0 {
		gen temp2 = 1 if age>=$eduage & age~=. & educat7>=3 & educat7~=.
		gen temp2c = 1 if age>=$eduage & age~=. & (educat7>=3 | educat7==.)
	}
	else { //educat5
		cap su educat5
		if r(N)>0 {
			gen temp2 = 1 if age>=$eduage & age~=. & educat5>=3 & educat5~=.
			gen temp2c = 1 if age>=$eduage & age~=. & (educat5>=3 | educat5==.)
		}
		else {	//educat4
			cap su educat4
			if r(N)>0 {
				gen temp2 = 1 if age>=$eduage & age~=. & educat4>=2 & educat4~=.
				gen temp2c = 1 if age>=$eduage & age~=. & (educat4>=2 | educat4==.)
			}
			else { //no education available	
				local eduflag = 1					
			}
		}
	}
	
	if `eduflag'==0 {			
		gen temp2a = 1 if age>=$eduage & age~=.
		bys `year' hhid: egen educ_com_size = sum(temp2a)
		bys `year' hhid: egen temp3 = sum(temp2)
		bys `year' hhid: egen temp3c = sum(temp2c)
		gen dep_educ_com = 0
		replace dep_educ_com = 1 if temp3==0
		gen dep_educ_com_lb = 0
		replace dep_educ_com_lb = 1 if temp3c==0
		ren temp3 educ_com_sum
		ren temp3c educ_com_sum_lb
		drop temp2 temp2a temp2c
	}
	else {
		gen dep_educ_com = .
		gen dep_educ_com_lb = .
		gen educ_com_sum = .
		gen educ_com_sum_lb = .
		gen educ_com_size = .			
	}
	
	gen educ_com_appl = 1
	replace educ_com_appl = 0 if (educ_com_size==0 | educ_com_size==.)
	gen temp2b = 1 if age>=$eduage & age~=. & educat4==. & educat5==. & educat7==.
	bys `year' hhid: egen educ_com_mis = sum(temp2b)
	drop temp2b
	gen educ_com_appl_miss = educ_com_appl == 1 & educ_com_mis>0 & educ_com_mis~=.
	
	la var dep_educ_com "Deprived if Households with NO adults $eduage+ with no primary completion"
	la var dep_educ_com_lb "Deprived if Households with NO adults $eduage+ with no or missing primary completion"
	la var educ_com_appl "School completion is applicable households, has $eduage or more individuals"
	la var educ_com_appl_miss "School completion is applicable households but missing completion"
	
	****************************************************
	**1b) Indicator: school-age children current not enroll in school
	gen tempx = 1 if age>=$lbage & age<=$ubage
	bys `year' hhid: egen nchildren = sum(tempx)

	cap su school
	if (_rc==0 & r(N)>0) {				
		gen temp2a = 1 if age>=$lbage & age<=$ubage
		bys `year' hhid: egen educ_enr_size = sum(temp2a)
		gen temp2 = 1 if age>=$lbage & age<=$ubage & school==0 //depr when school==0
		gen temp2c = 1 if age>=$lbage & age<=$ubage & (school==0 |school==.) //depr when school==0 or missing
		gen temp2b = 1 if age>=$lbage & age<=$ubage & school==.
		bys `year' hhid: egen temp4 = sum(temp2b)
		bys `year' hhid: egen temp3 = sum(temp2)
		bys `year' hhid: egen temp3c = sum(temp2c)
		
		gen dep_educ_enr = 0
		replace dep_educ_enr = 1 if temp3>0 & temp3~=.		
		gen dep_educ_enr_ub = 0
		replace dep_educ_enr_ub = 1 if temp3c>0 & temp3c~=.	
		
		ren temp3 educ_enr_sum
		ren temp3c educ_enr_sum_ub
		ren temp4 educ_enr_mis
		drop temp2 temp2a temp2b				
	}
	else { //not available
		gen dep_educ_enr = .
		gen dep_educ_enr_ub = .
		gen educ_enr_size = .
		gen educ_enr_sum = .
		gen educ_enr_sum_ub = .
		gen educ_enr_mis = .
	}
	
	gen educ_enr_appl = 1 
	replace educ_enr_appl = 0 if (educ_enr_size==0 | educ_enr_size==.)
	gen educ_enr_appl_miss = educ_enr_appl == 1 & educ_enr_mis>0 & educ_enr_mis~=.
	
	la var dep_educ_enr "Deprived if Households has at least one school-aged child not enrolling in school"
	la var dep_educ_enr_ub "Deprived if Households has at least one school-aged child no or missing enrollment in school"
	la var educ_enr_appl "School enrollment is applicable households, has $lbage-$ubage year old kids"
	la var educ_enr_appl_miss "School enrollment is applicable households but missing enrollment"

	****************************************************
	**Dimension 2: Access to infrastructure 
	****************************************************

	****************************************************
	//Indicator: Electricity
	cap des electricity
	if _rc==0 gen dep_infra_elec = electricity==0 if electricity~=.
	else gen dep_infra_elec = .
	la var dep_infra_elec "Deprived if HH has No access to electricity"
	
	****************************************************		
	//Indicator: Sanitation 			
	cap des imp_san_rec
	if _rc==0 gen dep_infra_imps = imp_san_rec==0 if imp_san_rec~=.		
	else      gen dep_infra_imps = .		
	la var dep_infra_imps "Deprived if HH has No access to improved sanitation"
	
	****************************************************		
	//Indicator: Water 			
	cap des imp_wat_rec
	if _rc==0 gen dep_infra_impw = imp_wat_rec==0 if imp_wat_rec~=.
	else      gen dep_infra_impw = . 
	la var dep_infra_impw "Deprived if HH has No access to improved drinking water"
	
	drop if `welfare'<0 // bottom censoring
	
	gen dep_poor1 = `welfare'< ${mpmpline} if `welfare'~=.
	la var dep_poor1 "Poor household at $${mpmpline}"
	
	//missing obs for some HHs	
	gen touse = dep_educ_com*dep_educ_enr*dep_infra_elec*dep_infra_impw*dep_infra_imps*dep_poor1~=.
	ta touse,m
	
	local indlist dep_educ_com dep_educ_enr dep_infra_elec dep_infra_impw dep_infra_imps dep_poor1
	
	//Indicator - deprived in all indicators
	gen dep_all_inds = dep_educ_com*dep_educ_enr*dep_infra_elec*dep_infra_impw*dep_infra_imps*dep_poor1
	
	//Dimensions and indicators setup	
	local edu		dep_educ_com dep_educ_enr
	local infra		dep_infra_elec dep_infra_imps dep_infra_impw
	local pov		dep_poor1
	local dims edu infra pov
	
	//deprived in all dimensions
	foreach dim of local dims {
		egen tmp_`dim' = rowtotal(``dim''), missing
		gen dim_`dim' =  (tmp_`dim'>=1) if tmp_`dim'~=.	
		drop tmp_`dim'
	}
	
	//Indicator - deprived in all dimensions
	egen c_all_dims = rowtotal(dim_edu dim_infra dim_pov), missing
	gen dep_1_dims = c_all_dims>=1 if c_all_dims~=.
	gen dep_2_dims = c_all_dims>=2 if c_all_dims~=.
	gen dep_3_dims = c_all_dims==3 if c_all_dims~=.
	
	//MPI - equal weight for each dimension, and indicators within each dimension	
	local pov `welfare'
	local ndim = "`=wordcount("`dims'")'"
	foreach dim of local dims {
		local nvar = "`=wordcount("``dim''")'"
		foreach var in ``dim'' {
			gen ww_`var' = 1/`nvar'
			gen w_`var' = 1/(`ndim'*`nvar')
		}
	}
	
	//Weight adjustment - Education - dep_educ_com dep_educ_enr
	*gen tmp_edu = dep_educ_com*dep_educ_enr
	// 1 0
	replace w_dep_educ_com = 1/3 if dep_educ_com~=. & dep_educ_enr==.
	replace w_dep_educ_enr = 0   if dep_educ_com~=. & dep_educ_enr==.
	replace touse = 1            if dep_educ_com~=. & dep_educ_enr==.
	// 0 1
	replace w_dep_educ_enr = 1/3 if dep_educ_com==. & dep_educ_enr~=.
	replace w_dep_educ_com = 0   if dep_educ_com==. & dep_educ_enr~=.
	replace touse = 1            if dep_educ_com==. & dep_educ_enr~=.
	
	//Weight adjustment - Infrastructure - dep_infra_elec dep_infra_imps dep_infra_impw
	//0 1 1
	replace w_dep_infra_elec  = 0                  if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw~=.
	replace w_dep_infra_imps  = (1/9) + 0.5*(1/9)  if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw~=.
	replace w_dep_infra_impw = (1/9) + 0.5*(1/9)  if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw~=.
	replace touse = 1                              if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw~=.
	
	//1 0 1
	replace w_dep_infra_elec  = (1/9) + 0.5*(1/9)  if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw~=.
	replace w_dep_infra_imps  = 0                  if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw~=.
	replace w_dep_infra_impw = (1/9) + 0.5*(1/9)  if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw~=.
	replace touse = 1                              if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw~=.
	
	//1 1 0
	replace w_dep_infra_elec  = (1/9) + 0.5*(1/9)  if dep_infra_elec~=. & dep_infra_imps~=. & dep_infra_impw==.
	replace w_dep_infra_imps  = (1/9) + 0.5*(1/9)  if dep_infra_elec~=. & dep_infra_imps~=. & dep_infra_impw==.
	replace w_dep_infra_impw = 0                  if dep_infra_elec~=. & dep_infra_imps~=. & dep_infra_impw==.
	replace touse = 1                              if dep_infra_elec~=. & dep_infra_imps~=. & dep_infra_impw==.
	
	//1 0 0
	replace w_dep_infra_elec  = (1/9) + 2*(1/9)    if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw==.
	replace w_dep_infra_imps  = 0                  if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw==.
	replace w_dep_infra_impw = 0                  if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw==.
	replace touse = 1                              if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw==.
	
	//0 0 1
	replace w_dep_infra_elec  = 0                  if dep_infra_elec==. & dep_infra_imps==. & dep_infra_impw~=.
	replace w_dep_infra_imps  = 0                  if dep_infra_elec==. & dep_infra_imps==. & dep_infra_impw~=.
	replace w_dep_infra_impw = (1/9) + 2*(1/9)    if dep_infra_elec==. & dep_infra_imps==. & dep_infra_impw~=.
	replace touse = 1                              if dep_infra_elec==. & dep_infra_imps==. & dep_infra_impw~=.
	
	//0 1 0
	replace w_dep_infra_elec  = 0                  if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw==.
	replace w_dep_infra_imps  = (1/9) + 2*(1/9)    if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw==.
	replace w_dep_infra_impw = 0                  if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw==.
	replace touse = 1                              if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw==.
	
	ta touse,m
	su w_*
	
	//matrix g_ij indicator
	//reverse dummy because it is already deprived
	foreach var of varlist dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw {
		replace `var' = 1 - `var'
	}
		
	local depr  dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw `welfare'
	local zline 1            1            1              1              1               $mpmpline
	
	tokenize `zline'
	local c = 1
	foreach ind of local depr {
		forv alpha=0(1)2 {
			gen g_i_`alpha'_`ind' = ((1- `ind'/``c'')^`alpha') * (`ind'<``c'')
			gen wg_i_`alpha'_`ind' = g_i_`alpha'_`ind'*w_`ind'
		}
		local c = `c' + 1
	}
	egen wci_0 = rowtotal(wg_i_0_*)
	egen wci_1 = rowtotal(wg_i_1_*)
	egen wci_2 = rowtotal(wg_i_2_*)
	
	//matrix dimension
	replace dim_edu = 1 - dim_edu
	replace dim_infra = 1 - dim_infra	
	local depr2 dim_edu dim_infra `welfare'
	local zline 1       1         $mpmpline
	tokenize `zline'
	local c = 1
	foreach ind of local depr2 {
		forv alpha=0(1)2 {
			gen g_d_`alpha'_`ind' = ((1- `ind'/``c'')^`alpha') * (`ind'<``c'')
			gen wg_d_`alpha'_`ind' = g_d_`alpha'_`ind'*(1/3)
		}
		local c = `c' + 1
	}
	egen wcd_0 = rowtotal(wg_d_0_*)
	egen wcd_1 = rowtotal(wg_d_1_*)
	egen wcd_2 = rowtotal(wg_d_2_*)

	//AF 2011 measure using indicator/dimensions (equal weight per dimension)
	gen mdpoor_i1 = (wci_0>=1/3) if wci_0~=. //Change the number of weighted deprivations
	gen mdpoor_i2 = (wci_0>=2/3) if wci_0~=.
	gen af_i_m0_1 = mdpoor_i1*wci_0 
	gen af_i_m0_2 = mdpoor_i2*wci_0 
	
	//AF 2011 measure using dimension only (union within dimension)
	gen mdpoor_d1 = (wcd_0>=1/3) if wcd_0~=. //Change the number of weighted deprivations
	gen mdpoor_d2 = (wcd_0>=2/3) if wcd_0~=.
	gen af_d_m0_1 = mdpoor_d1*wcd_0 
	gen af_d_m0_2 = mdpoor_d2*wcd_0

	//reverse for summary statistics
	foreach var of varlist dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw {
		replace `var' = 1 - `var'
	}
	replace dim_edu = 1 - dim_edu
	replace dim_infra = 1 - dim_infra
	
	//missing observations
	gen educ_com_underage = educ_com_size==0 //hh with underage individuals, therefore automatically count as deprived in education completion
	gen educ_enr_overage = educ_enr_size==0  //hh with overage individuals, noone belongs to the enrolling age cohorts, therefore automatically count as non-deprived in enrollment
	
	keep hhid pid code `year' `wvar' educ_com_* educ_enr_* dep_educ_com dep_educ_enr dep_infra_elec dep_infra_impw dep_infra_imps dep_poor1 `welfare' dep_all_inds *_all_dims dep_*_dims af_*  touse /* g_* ci */ wg_* wcd* wci* mdpoor* age urban male	
	
	//Add new Venn diagram indicators
	egen num_dep_educ     = rowtotal(dep_educ_com dep_educ_enr)
	egen num_dep_infra    = rowtotal(dep_infra_elec dep_infra_impw dep_infra_imps)

	cap drop venn_d
	g venn_d = .
	replace venn_d = 1 if dep_poor1 == 1 & num_dep_educ >= 1 & num_dep_infra >= 1 & mdpoor_i1 == 1            //Deprived in at least one indicator in each dimension
	replace venn_d = 2 if dep_poor1 == 1 & num_dep_educ == 0 & num_dep_infra >= 1 & mdpoor_i1 == 1            //Deprived in monetary dimension and at least one indicator in services and no indicator in education
	replace venn_d = 3 if dep_poor1 == 1 & num_dep_educ >= 1 & num_dep_infra == 0 & mdpoor_i1 == 1            //Deprived in monetary dimension and at least one indicator in education and no indicator in services
	replace venn_d = 4 if dep_poor1 == 0 & num_dep_educ >= 1 & num_dep_infra >= 1 & mdpoor_i1 == 1            //Deprived in at least one indicator in education and services and not in monetary
	replace venn_d = 5 if dep_poor1 == 1 & num_dep_educ == 0 & num_dep_infra == 0 & mdpoor_i1 == 1            //Deprived in monetary dimension only
	replace venn_d = 6 if dep_poor1 == 0 & num_dep_educ == 2 & num_dep_infra == 0 & mdpoor_i1 == 1            //Deprived in all education indicators only
	replace venn_d = 7 if dep_poor1 == 0 & num_dep_educ == 0 & num_dep_infra >= 1 & mdpoor_i1 == 1            //Deprived in all service indicators only
	replace venn_d = 8 if (dep_poor1 == 0 & num_dep_educ == 0 & num_dep_infra == 0) | mdpoor_i1 == 0            //Not deprived in any indicator or not multidimensional poor

	label define venn_d 1 "All" 2 "Monetary & Infrastructure" 3 "Monetary & Education" 4 "Education and Infrastructure" 5 "Monetary only" 6 "Education only" 7 "Infrastructure only" 8 "None", replace
	label val venn_d venn_d
	ta venn_d [aw = `wvar'],m
	forv i=1(1)8 {
		gen venn_d_`i'= venn_d==`i' if venn_d~=.
	}

	collapse (mean) dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw mdpoor_i1 venn_d_* [aw=`wvar'] if touse==1,by(code `year')
	*for var dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw mdpoor_i1 venn_d_*: replace X = X*100

end