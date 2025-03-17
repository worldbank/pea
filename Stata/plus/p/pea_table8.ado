*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 
*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Sandra Carolina Segovia Juarez <ssegoviajuarez@worldbank.org>
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

//Table 8. Inequality indicators

cap program drop pea_table8
program pea_table8, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Welfare(varname numeric) Year(varname numeric) MISSING excel(string) save(string) PPPyear(integer 2017)]
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')

	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}
	gen _all_ = 1
	la def _all_ 1 "All sample"
	la var _all_ "All sample"
	la val _all_ _all_
	local byind "_all_" //  `byind'
	
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
	
	if "`missing'"~="" { //show missing
		foreach var of local byind {
			su `var'
			local miss = r(max)
			replace `var' = `=`miss'+10' if `var'==.
			local varlbl : value label `var'
			la def `varlbl' `=`miss'+10' "Missing", add
		}
	}
	
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
		local flist `"`wvar' `welfare' `year' `byind'"'
		markout `touse' `flist' 
		
		foreach var of varlist `byind' {
			local lbl`var' : variable label `var'
			local label1 : value label `var'	
			//`lvl`var1'_`lv''
			levelsof `var', local(lvgr)
			foreach lv of local lvgr {
				local lvl`var'_`lv' : label `label1' `lv'
			}			
		}
		
		//reset to the floor
		if "`welfare'"~="" {
			replace `welfare' = ${floor_} if `welfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
		
		tempfile dataori datalbl
		save `dataori', replace
		des, replace clear
		save `datalbl', replace
		use `dataori', clear
	} //qui
	
	* Create a frame to store the results
	cap frame create temp_frame
	cap frame change temp_frame
	cap frame drop ineq_results	
	frame create ineq_results strL(var) float(group year obs pop) ///
							  float(mean median sd min max) ///
							  float(Gini Theil Kuznets Atkinson_1 Sen) ///
							  float(p10p50 p25p50 p75p25 p75p50 p90p10 p90p50 Bottom20share) ///
							  float(ge0 ge1 ge2) 
	
	use `dataori', clear
	* Get unique combinations of year
	levelsof `year', local(years)
	
	* Loop through each year
	foreach y in `years' {			
		foreach var of local byind {
			levelsof `var', local(groups)
			foreach grp of local groups {
				
				qui { 
					//Kuznets (Palma) ratio & Bottom20share
					//bottom20share: define quintile, su welfare [weight] --> r(r_sum) of q1/total
						_ebin `welfare' [w=`wvar'] if (`var' == `grp' & `year'==`y'), nquantiles(10) gen(qwlf)
							
							su `welfare' [w=`wvar'] if (`var' == `grp' & `year'==`y') 
							local totwelf =  r(sum)
							
							su `welfare' [w=`wvar'] if (`var' == `grp' & `year'==`y' & qwlf <= 2)
							local b20welf =  r(sum)
					
							su `welfare' [w=`wvar'] if (`var' == `grp' & `year'==`y' & qwlf <= 4) 
							local b40welf =  r(sum)
					
							su `welfare' [w=`wvar']  if (`var' == `grp' & `year'==`y' & qwlf == 10)
							local t10welf =  r(sum)
							
							local b20share = (`b20welf'/`totwelf')*100
							local palma = `t10welf'/`b40welf' 

							drop qwlf
				
					// Gini, Theil, Atkinson, Sen, GEs...
					ineqdeco `welfare' [w=`wvar'] if (`var' == `grp' & `year'==`y'), welfare
					* See <<help ineqdeco>> for definitions
				}
				
				// Post the results to the frame
				frame ineq_results {  
					frame post ineq_results ("`var'") (`grp') (`y') (`r(N)') (`r(sumw)')	///
						(`r(mean)') (`r(p50)') (`r(sd)') (`r(min)') (`r(max)') 	///
						(`r(gini)') (`r(ge1)') (`palma') (`r(a1)') (`r(wgini)')  ///
						(`r(p10p50)') (`r(p25p50)') (`r(p75p25)') (`r(p75p50)') (`r(p90p10)') (`r(p90p50)') ///
						(`b20share') (`r(ge0)') (`r(ge1)') (`r(ge2)') 
				}
			} //lvl each group
		}		
	} //end years

	* See results
	frame change ineq_results
	
	d, varlist
	local vars `r(varlist)'
	unab omit: var group year
	local choose:  list vars - omit
	noi di "`choose'"
	foreach var of local choose {
		rename `var' ind_`var'
	}

	reshape long ind_, i(`year' var group) j(indicator) string

	gen indicatorlbl=.
	replace indicatorlbl = 1 if indicator=="Gini"
	replace indicatorlbl = 2 if indicator=="Theil"
	replace indicatorlbl = 3 if indicator=="Kuznets"
	replace indicatorlbl = 4 if indicator=="Atkinson_1"
	replace indicatorlbl = 5 if indicator=="Sen"
	replace indicatorlbl = 6 if indicator=="p10p50"
	replace indicatorlbl = 7 if indicator=="p25p50"
	replace indicatorlbl = 8 if indicator=="p75p25"
	replace indicatorlbl = 9 if indicator=="p75p50"
	replace indicatorlbl = 10 if indicator=="p90p10"
	replace indicatorlbl = 11 if indicator=="p90p50"
	replace indicatorlbl = 12 if indicator=="Bottom20share"
	replace indicatorlbl = 13 if indicator=="ge0"
	replace indicatorlbl = 14 if indicator=="ge1"
	replace indicatorlbl = 15 if indicator=="ge2"
	
	la def indicatorlbl 1 "Gini index" 2 "Theil index" 3 "Palma (Kuznets) ratio" 4 "Atkinson index" 5 "Sen index" 6 "p10p50" 7 "p25p50" 8 "p75p25" 9 "p75p50" 10 "p90p10" 11 "p90p50" 12 "Bottom 20% share of incomes (%)" 13 "GE(0)" 14 "GE(1)" 15 "GE(2)" 
	
	//label var and group keeping original ordering 
	local i=1
	local j=1
	gen var_order = .
	gen group_order = .
	foreach var1 of local byind {
		replace var_order =`j' if var=="`var1'"
		la def var_order `j' "`lbl`var1''", add
		local j = `j'+1
		levelsof group if var=="`var1'", local(grplvl)
		foreach lv of local grplvl {
			replace group_order = `i' if var=="`var1'" & group==`lv'
			la def group_order `i' "`lvl`var1'_`lv''", add
			local i = `i' + 1
		}
	}
	
	la val var_order var_order
	la val group_order group_order
	
	la val indicatorlbl indicatorlbl
	drop if indicatorlbl==.	
	ren ind_ value
	order indicator indicatorlbl value
	replace value = value*100 if indicator=="Gini"

	collect clear
	qui collect: table (indicatorlbl) (`year'), stat(mean value) nototal nformat(%20.1f) missing // group_order indicatorlbl
	collect style header indicatorlbl `year', title(hide)
	
	collect title `"Table 8. Core inequality indicators"'
	collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
	collect notes 2: `"Note: The Gini index is a measure of inequality ranging from 0 (perfect equality) to 100 (perfect inequality). The Theil Index belongs to the Generalized Entropy (GE) class. The Palma (Kuznets) ratio measures the top 10 percent income share relative to the bottom 40 percent share. The Atkinson index is an inequality measure with a weighting parameter which measures aversion to inequality. Sen. The Watts index is the average log-point differences from the poverty line. Welfare ratios are presented for different percentiles; For example, p10/p50 refers to the ratio of consumption or income between those who are at the 10th percentile and those who are at the 50th percentile of the welfare distribution. The bottom 20% share of incomes indicates the share of total income or consumption held by the bottom 20% of the welfare distribution."'
	_pea_tbtformat
	_pea_tbt_export, filename(Table8) tbtname(Table8) excel("`excel'") dirpath("`dirpath'") excelout("`excelout'") shell
	
end 