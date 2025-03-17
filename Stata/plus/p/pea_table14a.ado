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

//Table 14a

cap program drop pea_table14a
program pea_table14a, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Welfare(varname numeric) Povlines(varname numeric) Year(varname numeric) CORE setting(string)  excel(string) save(string) age(varname numeric) male(varname numeric) hhhead(varname numeric) edu(varname numeric) urban(varname numeric) married(varname numeric) school(varname numeric) services(varlist numeric) assets(varlist numeric) hhsize(varname numeric) hhid(string) pid(string) industrycat4(varname numeric) lstatus(varname numeric) empstat(varname numeric) MISSING PPPyear(integer 2017)]
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	//house cleaning
	_pea_export_path, excel("`excel'")
	
	if "`missing'"~="" { //show missing
		foreach var of varlist `male' `hhhead' `edu' `industrycat4' `empstat' {
			su `var'
			local miss = r(max)
			replace `var' = `=`miss'+10' if `var'==.
			local varlbl : value label `var'
			la def `varlbl' `=`miss'+10' "Missing", add
		}
	}
	
	qui {
		//order the lines
		local lbl`povlines' : variable label `povlines'		
		su `povlines',d
		if `=r(sd)'==0 local lblline: var label `povlines'		
		
		//Weights
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		}
	
		//missing observation check
		marksample touse
		*local flist `"`wvar' `welfare' `povlines' `year' `hhid' `pid'"'
		local flist `"`wvar' `welfare' `povlines' `year'"'
		markout `touse' `flist' 
		
		if "`core'"~="" { //reset to the floor PPP lines
			replace `welfare' = ${floor_} if `welfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
		
		tempfile dataori datalbl
		save `dataori', replace
		des, replace clear
		save `datalbl', replace
		use `dataori', clear
	} //qui
	
	//check values	
	local tmp
	foreach var of local services {
		su `var' if `touse',d
		if r(N)>0 local tmp "`tmp' `var'"
	}
	local services `tmp'
	
	local tmp
	foreach var of local assets {
		su `var' if `touse',d
		if r(N)>0 local tmp "`tmp' `var'"
	}
	local assets `tmp'
	
	//FGT
	gen _fgt0_`welfare'_`povlines' = (`welfare' < `povlines') if `welfare'~=. & `touse'
	
	gen double _pop = `wvar' if `touse'
		
	gen _total = 1 if `touse'
	la def _total 1 "Total"
	la val _total _total
	
	//variable checks
	if "`age'"~="" {
		su `age' if `touse',d
		if r(N)>0 {
			gen age0t14 = 1 if `age'<=14
			gen age65p  = 1 if `age'>=65 & !missing(`age')
			gen age15t64 = 1 if `age'>=15 & `age'<=64
			gen age6t18 = 1 if `age'>=6 & `age'<=18
			
			bys `year' `hhid' (`pid'): egen age0t14sum = total(age0t14)
			bys `year' `hhid' (`pid'): egen age65psum = total(age65p)
			bys `year' `hhid' (`pid'): egen age15t64sum = total(age15t64)
			bys `year' `hhid' (`pid'): egen age6t18sum = total(age6t18)
			bys `year' `hhid' (`pid'): gen _hhx = _N
						
			egen depnum = rowtotal(age0t14sum age65psum), missing
			gen dep_ratio = (depnum/age15t64sum)*100
			gen age6t18_sh = (age6t18sum/_hhx)*100
			gen age65p_sh = (age65psum/_hhx)*100
			la var dep_ratio "Household dependency ratio"
			la var age6t18_sh "Share of children (age 6-18) in household (%)"
			la var age65p_sh "Share of elderly (age 65+) in household (%)"
			local agevars dep_ratio age6t18_sh age65p_sh
			local dep_ratio dep_ratio
			local age6t18_sh age6t18_sh
			local age65p_sh age65p_sh
			
			if "`school'"~="" {
				su `school',d
				if r(N)>0 {
					gen age6t18_sch = age6t18==1 & `school'==1
					bys `year' `hhid' (`pid'): egen age6t18schsum = total(age6t18_sch)
					gen age6t18_sch_ratio = (age6t18schsum/age6t18sum)*100
					local agevars "`agevars' age6t18_sch_ratio"
					la var age6t18_sch_ratio "Share of children age 6-18 attending school (%)"
					local age6t18_sch_ratio age6t18_sch_ratio
				}
			} //school	
			
			if "`hhhead'"~="" {
				gen age_head = `age' if `hhhead'==1
				la var age_head "Age of household head"
				local headvars age_head
				local age_head age_head
			}
		} //rn
	} //age
	
	if "`hhhead'"~="" {
		if "`male'"~="" {
			gen female_head = 100 if `hhhead'==1 & `male'==0
			replace female_head = 0 if `hhhead'==1 & `male'==1
			la var female_head "Household head is female (%)"
			local headvars "`headvars' female_head"	
			local female_head female_head
		}
		
		if "`married'"~="" {
			gen married_head = 100 if `hhhead'==1 & `married'==1
			replace married_head = 0 if `hhhead'==1 & `married'==0
			la var married_head "Household head is married (%)"
			local headvars "`headvars' married_head"
			local married_head married_head
		}
		
		if "`edu'"~="" {
			local edu_head
			clonevar edu_head = `edu'
			replace edu_head = . if `hhhead'~=1 
			*gen edu_head = `edu' if `hhhead'==1 
			la var edu_head "Household head's education"
			local lbledu_head "Household head's education"
			levelsof edu_head, local(edulvl)
			local label1 : value label edu_head	
			foreach lvl of local edulvl {
				gen edu_head`lvl' = 100*(edu_head==`lvl') if edu_head~=.
				local labelname1 : label `label1' `lvl'				
				la var edu_head`lvl' "`labelname1' (%)"
				local headvars "`headvars' edu_head`lvl'"
				local edu_head "`edu_head' edu_head`lvl'"
			}
			*local headvars "`headvars' edu_head"
		}
		
		if "`industrycat4'"~="" {
			local industry_head
			clonevar industry_head = `industrycat4'
			replace industry_head = . if `hhhead'~=1 			
			*gen industry_head = `industrycat4' if `hhhead'==1 
			la var industry_head "Household head's sector of employment"
			local lblindustry_head "Household head's sector of employment"
			
			levelsof industry_head, local(industrylvl)
			local label1 : value label industry_head	
			foreach lvl of local industrylvl {
				gen industry_head`lvl' = 100*(industry_head==`lvl') if industry_head~=.
				local labelname1 : label `label1' `lvl'				
				la var industry_head`lvl' "`labelname1'"
				local headvars "`headvars' industry_head`lvl'"
				local industry_head "`industry_head' industry_head`lvl'"
			}
			*local headvars "`headvars' industry_head"
		}
		
		if "`lstatus'"~="" {
			gen doesnotwork_head = 100*(`lstatus'==1) if `hhhead'==1 & `lstatus'~=.
			la var doesnotwork_head "Does not work (unemployed or out of labor force)"
			local headvars "`headvars' doesnotwork_head"
			local doesnotwork_head doesnotwork_head
		}
		
		if "`empstat'"~="" {
			local empstat_head
			clonevar empstat_head = `empstat'
			replace empstat_head = . if `hhhead'~=1 			
			*gen industry_head = `industrycat4' if `hhhead'==1 
			*la var industry_head "Household head's sector of employment"
			*local lblindustry_head "Household head's sector of employment"
			
			levelsof empstat_head, local(empstatlvl)
			local label1 : value label empstat_head	
			foreach lvl of local empstatlvl {
				gen empstat_head`lvl' = 100*(empstat_head==`lvl') if empstat_head~=.
				local labelname1 : label `label1' `lvl'				
				la var empstat_head`lvl' "`labelname1'"
				local headvars "`headvars' empstat_head`lvl'"
				local empstat_head "`empstat_head' empstat_head`lvl'"
			}			
			*local headvars "`headvars' industry_head"
		}
	}
	la var `urban' "Household lives in urban area (%)"
	di "`urban' `services' `assets'"
	for var `urban' `services' `assets': replace X = 100 if X==1
	
	local demographics `urban' `age_head' `female_head' `married_head' `edu_head' `age6t18_sch_ratio' `hhsize' `age6t18_sh' `age65p_sh' `dep_ratio'
	local headactivity `doesnotwork_head' `empstat_head'

	//bys `year' `hhid' (`pid'): egen double hhwgt = total(`wvar')
	//household can have more than one head, that is data problem, we dont fix this.
	//the indicators are defined at the household level, thus using weight.
	tempfile data1 data2 data3 datalbl
	save `data1', replace
	des, clear replace
	save `datalbl', replace
	clear
	save `data2', replace emptyok
	
	local byind _fgt0_`welfare'_`povlines'  _total
		
	foreach var of local byind {
		use `data1', clear
		
		groupfunction  [aw=`wvar'] if `touse', mean(`urban' `agevars' `headvars' `services' `assets') rawsum(_pop) by(`year' `var')
		ren `var' _bygroup
		gen _varname = "`var'"
		save `data3', replace
		foreach var in `urban' `agevars' `headvars' `services' `assets' {
			use `data3', clear
			keep `year' _bygroup _pop `var' _varname
			ren `var' value
			gen variable = "`var'"
			append using `data2'
			save `data2', replace
		}		
	}
	gen _bygroup2 = 1 if _bygroup==1 & _varname=="_fgt0_`welfare'_`povlines'"
	replace _bygroup2 = 2 if _bygroup==0 & _varname=="_fgt0_`welfare'_`povlines'"
	replace _bygroup2 = 3 if _bygroup==1 & _varname=="_total"
	la def _bygroup2 1 "Poor" 2 "Nonpoor" 3 "Total"
	la val _bygroup2 _bygroup2
	
	clonevar name = variable
	merge m:1 name using `datalbl', keepus(varlab)
	drop if _merge==2
	drop _merge
	
	//
	gen group1 = .
	foreach var of local demographics {
		replace group1 = 1 if name=="`var'"
	}
	foreach var of local services {
		replace group1 = 2 if name=="`var'"
	}
	foreach var of local assets {
		replace group1 = 3 if name=="`var'"
	}
	foreach var of local headactivity {
		replace group1 = 4 if name=="`var'"
	}
	foreach var of local industry_head {
		replace group1 = 5 if name=="`var'"		
	}

	la def group1 1 "Demographics" 2 "Access to services (%)" 3 "Asset ownership (%)" 4 "Employment status of household head (%)" 5 "Economic sector of household head (%)"
	la val group1 group1
	
	gen group2 = .
	foreach var of local edu_head {
		replace group2 = 1 if name=="`var'"
	}
	la def group2 1 "Household head's highest level of education" 
	la val group2 group2
	
	foreach var of local edu_head {
		replace varlab = "Household head's highest level of education: " + varlab if name=="`var'"
	}
	
	local i = 1
	gen order = .
	foreach var in `demographics' `services' `assets' `headactivity' `industry_head' {
		replace order = `i' if name=="`var'"
		local i = `i' + 1
	}
	if "`core'"=="" {
		local tabtitle "Table 14a. Profiles of the poor"
		local tbt Table14a
	}
	else {
		local tabtitle "Table A.4a. Poverty profiles"	
		local tbt TableA4a
	}
	collect clear
	qui collect: table (group1 order   varlab) (`year' _bygroup2), statistic(mean value) nototal nformat(%20.1f) missing	
	collect style header group1 order   varlab `year' _bygroup2, title(hide)
	collect title `"`tabtitle'"'
	*collect style header group2[.], level(hide)
	collect style header order, level(hide)
	collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."' 
	collect notes 2: `"Note: Poverty profiles are presented as shares of poor, nonpoor and total populations. The poor are defined using `lblline'. Household dependency ratio is the ratio of children (0-14) and elderly (65+) over working-age population (15-64). Improved drinking water sources include piped water on premises (piped household water connection located inside the user"s dwelling, plot or yard), and other improved drinking water sources (public taps or standpipes, tube wells or boreholes, protected dug wells, protected springs, and rainwater collection) (WHO/UNICEF Joint Monitoring Programme). Improved sanitation facilities are sanitation facilities likely to ensure hygienic separation of human excreta from human contact, including flush/pour flush (to piped sewer system, septic tank, pit latrine), ventilated improved pit latrine, pit latrine with slab, and composting toilet (WHO/UNICEF Joint Monitoring Programme)."' 
	
	collect style cell group1[]#cell_type[row-header], font(, bold)
	collect style cell varlab[]#cell_type[row-header], warn font(, nobold)
	_pea_tbtformat
	_pea_tbt_export, filename(`tbt') tbtname(`tbt') excel("`excel'") dirpath("`dirpath'") excelout("`excelout'") shell
	
end