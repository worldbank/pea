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

//Table 13a. Decomposition of poverty changes: Huppi-Ravallion decomposition (urban/rural)				

cap program drop pea_table13a
program pea_table13a, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) spells(string) Year(varname numeric) urban(varname numeric) CORE LINESORTED setting(string) NOOUTPUT excel(string) save(string) MISSING GRAPH PPPyear(integer 2021)]
	
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')

	//load data if defined
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}
	if "`urban'"=="" {
		noi di in red "Sector/urban variable must be define in urban()"
		exit 1
	}
	if "`save'"=="" {
		tempfile saveout
		local save `saveout'
	}
	if "`nooutput'"~="" & "`excel'"~="" {
		noi dis as error "Cant have both nooutput and excel() options"
		error 1
	}
	if "`spells'"=="" {
		noi dis as error "Need at least two years, i.e. 2000 2004"
		error 1
	}
	//house cleaning
	_pea_export_path, excel("`excel'")
	
	local x = subinstr("`spells'",";"," ",.)		
	local keepyears : list uniq x
	qui {	
		//order the lines
		if "`linesorted'"=="" {
			if "`ppppovlines'"~="" {
				_pea_pline_order, povlines(`ppppovlines')				
				local ppppovlines `=r(sorted_line)'
				foreach var of local ppppovlines {
					local lbl`var' `=r(lbl`var')'
				}
			}
			
			if "`natpovlines'"~="" {
				_pea_pline_order, povlines(`natpovlines')				
				local natpovlines `=r(sorted_line)'
				foreach var of local natpovlines {
					local lbl`var' `=r(lbl`var')'
				}
			}
		}
		else {
			foreach var of varlist `natpovlines' `ppppovlines' {
				local lbl`var' : variable label `var'
			}
		}
		
		//Weights
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		}
	
		//missing observation check
		marksample touse
		local flist `"`wvar' `welfare' `urban' `year'"'
		markout `touse' `flist' 
		
		if "`pppwelfare'"~="" { //reset to the floor
			replace `pppwelfare' = ${floor_} if `pppwelfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
		
		tempfile dataori datalbl
		
		// Check if any years don't have urban
		foreach y of local keepyears {
			sum `urban' if `year' == `y'
			if `r(N)' == 0 {
			noi disp in red "No values for `urban' for year `y'. Please select other years, or a different sector variable."
				exit
			}
		}
		
		// Check year list			
		levelsof `year' if `touse', local(yrlist)
		local same : list yrlist === keepyears
		if `same'==0 {
			noi dis "There are different years requested, and some not available in the data."
			noi dis "Requested: `keepyears'. Available: `yrlist'"
		}
		
		gen _keep =. if `touse'
		foreach yr of local keepyears {
			replace _keep=1 if `year'==`yr' & `touse'
		}
		keep if _keep==1 & `touse'
		drop _keep
		save `dataori', replace
		
		// Number of areas
		qui levelsof `urban', local(indlev)
		local indnum = `: word count `indlev''
		
		// Prepare frames for output saving
		local totdecomp = `indnum' + 3 														// Sectors + Total + Population + Interaction 
		forval i = 1/`totdecomp' {
			local values "`values' value`i'"
		}
		
		// Prepare spells		
		tokenize "`spells'", parse(";")	
		local i = 1
		local a = 1
		while "``i''" != "" {
			if "``i''"~=";" {
				local spell`a' "``i''"		
				dis "`spell`a''"
				local a = `a' + 1
			}	
			local i = `i' + 1
		}
		
		cap frame create temp_frame
		cap frame change temp_frame
		cap frame drop decomp_results2	
		frame create decomp_results2 strL(decomp spell povline) float(`values')
							  		
		forv j=1(1)`=`a'-1' {
			local spell`j' : list sort spell`j'
			tokenize "`spell`j''"
			if "`1'"~="" & "`2'"~="" {
				dis "Spell`j': `1'-`2'"	
				tempfile data_y2
				use `dataori' if `year'==`2', clear
				save `data_y2', replace
				foreach var of local ppppovlines {
					//Huppi-Ravallion decomposition
					use `dataori' if `year'==`1', clear					
					sedecomposition using `data_y2' [aw=`wvar'], sector(`urban') pline1(`var') pline2(`var') var1(`pppwelfare') var2(`pppwelfare') hc
				
					mat a = r(b_sec)
					mat b = r(b_tot)					
					local rnames : rowfullnames a
					local rlbl
					local x = 4
					foreach rn of local rnames {
						local rlbl `"`rlbl' `x' "`rn'""'
						local x = `x' + 1
					}					
					local value1 = b[1,1]
					local value2 = b[3,1]
					local value3 = b[4,1]

					forval i = 1/`indnum' {
						local j = `i' + 3						// Name of value has to start at 4
						local value`j' = a[`i',2]
					}		
										
					local categ					
					// Get correct number values
					forval i = 1/`totdecomp' {
						local categ "`categ' (`value`i'')"
					}
					* Post the results to the frame
					frame decomp_results2 {  
						frame post decomp_results2 ("Huppi-Ravallion") ("`1'-`2'") ("`var'") `categ'
					}
				}
				foreach var of local natpovlines {
					//Huppi-Ravallion decomposition
					use `dataori' if `year'==`1', clear					
					sedecomposition using `data_y2' [aw=`wvar'], sector(`urban') pline1(`var') pline2(`var') var1(`natwelfare') var2(`natwelfare') hc
				
					mat a = r(b_sec)
					mat b = r(b_tot)					
					local rnames : rowfullnames a
					local rlbl
					local x = 4
					foreach rn of local rnames {
						local rlbl `"`rlbl' `x' "`rn'""'
						local x = `x' + 1
					}					
					local value1 = b[1,1]
					local value2 = b[3,1]
					local value3 = b[4,1]

					forval i = 1/`indnum' {
						local j = `i' + 3						// Name of value has to start at 4
						local value`j' = a[`i',2]
					}		
										
					local categ					
					// Get correct number values
					forval i = 1/`totdecomp' {
						local categ "`categ' (`value`i'')"
					}
					* Post the results to the frame
					frame decomp_results2 {  
						frame post decomp_results2 ("Huppi-Ravallion") ("`1'-`2'") ("`var'") `categ'
					}
				}	
			} //1 2
		} //j
		
		* See results
		frame change decomp_results2	
		reshape long value, i(decomp spell povline) j(subind)
		la def subind 1 "Total change" 2 "Population shift" 3 "Interaction" `rlbl'		
		la val subind subind
		replace value = . if value==-9999
		gen indicatorlbl = .
		local i = 1
		if "`ppppovlines'"~="" {
			foreach var of local ppppovlines {
				replace indicatorlbl = `i' if povline=="`var'"
				la def indicatorlbl `i' "`lbl`var''", add
				local i = `i' + 1
			}
		}
		
		if "`natpovlines'"~="" {
			foreach var of local natpovlines {
				replace indicatorlbl = `i' if povline=="`var'"
				la def indicatorlbl `i' "`lbl`var''", add
				local i = `i' + 1
			}
		}
		la val indicatorlbl indicatorlbl
		drop if indicatorlbl==.
		
		if "`nooutput'"~="" {
			save `save', replace
		}
		else {			
			collect clear
			qui collect: table ( indicatorlbl subind) ( spell) if decomp=="Huppi-Ravallion", statistic(mean value) nototal nformat(%20.1f) missing
			collect style header indicatorlbl subind spell, title(hide)
			*collect style header value[.], level(hide)
			collect title `"Table 13a. Decomposition of poverty changes: Huppi-Ravallion decomposition (urban/rural)"'
			collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
			collect notes 2: `"Note: The Huppi-Ravallion decomposition shows how progress in poverty changes can be attributed to different groups, following Huppi and Ravallion (1991). The intra-sectoral component displays how the incidence of poverty in rural and urban areas has changed, assuming the relative population size in each of these has remained constant. Population shift refers to the contribution of changes in population shares, assuming poverty incidence in each group has remained constant. The interaction between the two indicates whether there is a correlation between changes in poverty incidence and population movements."'
			collect style cell indicatorlbl[]#cell_type[row-header], font(, bold)
			collect style cell subind[]#cell_type[row-header], warn font(, nobold)
			_pea_tbtformat
			_pea_tbt_export, filename(Table13a) tbtname(Table13a) excel("`excel'") dirpath("`dirpath'") excelout("`excelout'") shell				
		}
	} //qui
end