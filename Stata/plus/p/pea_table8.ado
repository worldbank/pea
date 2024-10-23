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

//Table 8. Inequality indicators

*pea_table8 [aw=weight_p], welfare(welfare) year(year) byind(urban) missing

cap program drop pea_table8
program pea_table8, rclass
	version 17.0
	syntax [if] [in] [aw pw fw], [Welfare(varname numeric) Year(varname numeric) byind(varlist numeric) core setting(string) excel(string) save(string) missing]
	
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}
	
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
		
		tempfile dataori datalbl
		save `dataori', replace
		des, replace clear
		save `datalbl', replace
		use `dataori', clear
	} //qui
	
	
	* Create a frame to store the results
	* More intuitive name to current default frame
	cap frame drop this_survey
	frame rename default this_survey
	* Change to original frame
	frame change this_survey
	cap frame drop ineq_results
	frame create ineq_results float(group year obs pop) ///
							  float(mean median sd min max) ///
							  float(Gini Theil Atkinson_1 Atkinson_2 Sen) ///
							  float(p10p50 p25p50 p75p25 p75p50 p90p10 p90p50) ///
							  float(ge0 ge1 ge2) 
		  
	* Get unique combinations of year
	levelsof `year', local(years)
	* Loop through each year
	foreach y in `years' {			
		
		* Loop through groups within each year, including "All"
		levelsof `byind', local(groups)
		foreach grp in `groups' {
			
			qui: ineqdeco `welfare' [w=`wvar'] if (`byind' == `grp' & year == `y'), welfare
			local grp = `grp'		
			
			* Post the results to the frame
			frame ineq_results {  
				frame post ineq_results (`grp') (`y') (`r(N)') (`r(sumw)')	///
				(`r(mean)') (`r(p50)') (`r(sd)') (`r(min)') (`r(max)') 			///
				(`r(gini)') (`r(ge1)') (`r(a1)') (`r(a2)') (`r(wgini)') ///
				(`r(p10p50)') (`r(p25p50)') (`r(p75p25)') (`r(p75p50)') (`r(p90p10)')  (`r(p90p50)') ///
				(`r(ge0)') (`r(ge1)') (`r(ge2)')  
			} //end post frame
		} //end loop combinations
	} //end years

	* See results
	frame change ineq_results
		
	d, varlist
	local vars `r(varlist)'
	unab omit: group year
	local choose:  list vars - omit
	noi di "`choose'"
	foreach var of local choose {
		rename `var' ind_`var'
	}

	reshape long ind_, i(year group) j(indicator) string

	encode indicator, gen(indicatorlbl)
	order indicator indicatorlbl ind_*

	collect clear
	qui collect: table (group indicatorlbl) (`year'), stat(mean ind_) nototal nformat(%20.2f) missing
	collect style header group indicatorlbl year, title(hide)
	*collect style header subind[.], level(hide)
	*collect style cell, result halign(center)
	*collect title `"Table 3c. Subgroup poverty rates of household head"'
	*collect notes 1: `"Source: ABC"'
	*collect notes 2: `"Note: The global ..."'
	*collect style notes, font(, italic size(10))

	collect export "$output\\Table8.xlsx", sheet(Table8) modify 	
	shell start excel "$output\\Table8.xlsx"
				
	if "`excel'"=="" {
		collect export "$output\\Table8.xlsx", sheet(Table8) modify 	
		shell start excel "$output\\Table8.xlsx"
		}
		else {
		collect export "`excelout'", sheet(Table8, replace) modify 
	}

	
end 
	
	
	