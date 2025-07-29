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

//Table 5. Key labor market outcomes by population group

cap program drop pea_table5
program pea_table5, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [Welfare(varname numeric) Year(varname numeric) Povlines(varname numeric) CORE setting(string) excel(string) save(string) age(varname numeric) male(varname numeric) edu(varname numeric) urban(varname numeric) industrycat4(varname numeric) lstatus(varname numeric) empstat(varname numeric) MISSING]
	
	//house cleaning
	_pea_export_path, excel("`excel'")
	
	if "`lstatus'"=="" {
		noi di in red "Not working variable must be defined in lstatus()"
		exit 1
	}
	if "`age'"=="" {
		noi di in red "Age variable must be defined in age()"
		exit 1
	}	
	
	// Check if empstat and/or industrycat4 are missing
	local lvarlist "`lstatus' `empstat' `industrycat4'"
	foreach var of local lvarlist {
		qui su `var'
		if (r(N) == 0) local noobs "`noobs' `var'"
	}
	local lvarlist: list lvarlist - noobs

	//Keep only the latest data
	qui su `year',d
	local ymax = r(max)
	keep if `year'==`ymax'
	
	qui {
		//order the lines
		local lbl`povlines' : variable label `povlines'		
		local lblline: var label `povlines'		

		//Weights
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		}
	
		//missing observation check
		marksample touse
		local flist `"`wvar' `welfare' `povlines'"'
		markout `touse' `flist' 
		
		if "`core'"~="" { //reset to the floor PPP lines
			replace `welfare' = ${floor_} if `welfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
	}	
			
	//variable checks
	// Age
	gen agecatind 		= 1 if `age'>=15 & `age'<=24
	replace agecatind 	= 2 if `age'>=25 & `age'<=54
	replace agecatind 	= 3 if `age'>=55 & `age'<=64
	qui sum agecatind
	la def agecatind 1 "Youth (15-24)" 2 "Prime (25-54)" 3 "Older (55-64)"
	label values agecatind agecatind

	// Quntiles
	cap _ebin `welfare' [aw=`wvar'] if `touse', nquantiles(5) gen(__quintile)
	label define qn 1 "Q1 (poorest 20%)" 2 "Q2" 3 "Q3" 4 "Q4" 5 "Q5 (richest 20%)" 
	label values __quintile qn
	
	//Working age population
	keep if `age' >= 15 & `age' <= 64	
	
	//FGT
	gen _fgt0 = (`welfare' < `povlines') if `welfare'~=. & `touse'
	la def _fgt0 0 "Nonpoor" 1 "Poor" 
	label values _fgt0 _fgt0
	
	// Missing
	if "`missing'"~="" { //show missing
		foreach var of varlist `male' `urban' `edu' __quintile agecatind _fgt0 {
			qui su `var'
			if r(N)>0 {
				local miss = r(max)
				replace `var' = `=`miss'+1' if `var'==.
				local varlbl : value label `var'
				la def `varlbl' `=`miss'+1' "Missing", add
			}	
		}
		
		foreach var of varlist `lvarlist' {
			gen `var'mi = `var' == .
			if ("`var'" ~= "`lstatus'") replace `var'mi = . if `lstatus' ~= 0
			qui su `var'
			local miss = r(max)
			local varlbl : value label `var'
			la def `varlbl' `=`miss'+1' "Missing", modify
		}
	}
	
	qui {
		// Generate variables for each group
		local j = 1
		foreach var in `lvarlist' {	
			qui levelsof `var', local(lab`var')
			local vlab`var': value label `var'
			foreach i of local lab`var' {
				local labl`j': label `vlab`var'' `i'
				gen lgroups`j' = `var' == `i' if `var' ~= .
				local vars`var' "`vars`var'' lgroups`j'"
				local j = `j' + 1
			}
			if "`missing'"~="" { 													//show missing
				gen lgroups`j' = `var'mi == 1 if `var'mi ~= .
				local n : word count `lab`var''
				local l : word `n' of `lab`var''
				local labl`j': label `vlab`var'' `=`l'+1'							// last element
				local vars`var' "`vars`var'' lgroups`j'"
				local j = `j' + 1	
			}
		}
		gen _All = 1
		label define tot 1 "Total"
		label values _All tot
		// Generate statistics
		tempfile data1 data2 datalbl
		save `data1', replace
		des, clear replace
		save `datalbl', replace
		use `data1', clear
		clear
		save `data2', replace emptyok
		foreach var in `lvarlist' {
			local o = 0
			use `data1', clear
			su `var'
			if r(N)>0 {
				foreach row in _All `urban' __quintile `male' agecatind `edu' _fgt0 {
					use `data1', clear
					su `row'
					if r(N)>0 {
						groupfunction  [aw=`wvar'] if `touse', mean(`vars`var'') by(`row')
						gen overlbl = "`var'"
						gen categ 	= "`row'"
						decode `row', gen(group)
						egen gvar = group(`row')
						replace gvar = gvar + `o'	// Unique number for each subgroup, in correct order
						levelsof gvar, local(gnum)
						local gn : word count `gnum'
						drop `row'
						local o = `o' + `gn'
						append using `data2'
						save `data2', replace
					}
				}
			}
		}
	} // qui
	use `data2', clear

	reshape long lgroups, i(overlbl group gvar categ) j(ind)
	keep if lgroups ~= .
	replace lgroups = lgroups * 100
	
	// Labeling
	qui levelsof gvar, local(numvals)
	foreach val of local numvals {
		qui levelsof group if gvar == `val', local(strval) clean		// Use string values as value labels (correct order)
		label define labelname `val' `"`strval'"', add
	}
	label values gvar labelname
	
	qui levelsof ind, local(ind)
	foreach i of local ind {
		label define ind `i' "`labl`i''", modify
	}	
	label values ind ind
	gen 	overgroup = 1 if overlbl == "`lstatus'"
	replace overgroup = 2 if overlbl == "`empstat'"
	replace overgroup = 3 if overlbl == "`industrycat4'"
	label define overgroup	1 "Labor force status as share of working-age population (age 15-64)"	///
							2 "Employment status, as share of working-age population (age 15-64)"	///
							3 "Sector of activity, as share of working-age population (age 15-64)"
	label values overgroup overgroup
	gen 	categn = 0 if categ == "_All"
	replace	categn = 1 if categ == "`urban'"
	replace categn = 2 if categ == "__quintile"
	replace categn = 3 if categ == "`male'"
	replace categn = 4 if categ == "agecatind"
	replace categn = 5 if categ == "`edu'"
	replace categn = 6 if categ == "_fgt0"
	lab define categn 1 "By area" 2 "By welfare quintile" 3 "By sex" 4 "By age group" 5 "By education level" 6 "By poverty status"
	lab values categn categn
	
	drop overlbl group categ
	//Table
	if "`core'"=="" {
		local tabtitle "Table 5. Key labor market indicators by population group (`ymax')"
		local tbt Table5
	}
	else {
		local tabtitle "Table C.2. Key labor market indicators by population group (`ymax')"
		local tbt TableC.2
	}
	if "`missing'"~="" local note_m "Missing values for the labor market indicators are presented separately, therefore totals for each indicator may exceed 100%."
	
	collect clear
	qui collect: table (categn gvar) (overgroup ind), stat(mean lgroups) nototal nformat(%20.1f) missing
	collect style header categn gvar overgroup ind, title(hide)	
	collect style cell categn[]#cell_type[row-header], font(, bold)
	collect style cell gvar[]#cell_type[row-header], font(, nobold)
	collect style cell gvar[1]#cell_type[row-header], font(, bold)
	collect style header categn[0], level(hide)
	collect title `"`tabtitle'"'
	collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
	collect notes 2: `"Note: The table presents labor market indicators by population subgroups. Labor market indicators are calculated for individuals in the age group of 15-64. Employment status and sector indicators (if available) are calculated for the subpopulation of those that are working. Population shares are calculated for observations with non-missing values only. `note_m' Education level refers to the highest level attended, complete or incomplete. The poor are defined using `lblline'."'
	_pea_tbtformat
	_pea_tbt_export, filename(`tbt') tbtname(`tbt') excel("`excel'") dirpath("`dirpath'") excelout("`excelout'") shell
	
end	