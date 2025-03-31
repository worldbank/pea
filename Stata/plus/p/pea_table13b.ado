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

//Table 13b. Decomposition of poverty changes: Huppi-Ravallion decomposition (sectoral)			

cap program drop pea_table13b
program pea_table13b, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [NATWelfare(varname numeric) NATPovlines(varlist numeric) PPPWelfare(varname numeric) PPPPovlines(varlist numeric) spells(string) Year(varname numeric) industrycat4(varname numeric) hhhead(varname numeric) hhid(string) CORE LINESORTED setting(string) NOOUTPUT excel(string) save(string) MISSING GRAPH PPPyear(integer 2017)]
	
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
	if "`industrycat4'"=="" {
		noi di in red "Sector variable must be defined in industrycat4()"
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
		noi dis as error "Need at least two years in spells(), i.e. 2000 2004"
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
		// sector by household head
		gen head_sec = `industrycat4' if `hhhead'==1
		bys `year' `hhid': egen head_secall = max(head_sec) 
		replace `industrycat4' = head_secall
		
		//missing observation check
		marksample touse
		local flist `"`wvar' `welfare' `industrycat4' `year'"'
		markout `touse' `flist' 
		
		if "`pppwelfare'"~="" { //reset to the floor
			replace `pppwelfare' = ${floor_} if `pppwelfare'< ${floor_}
			noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
		}
		
		tempfile dataori datalbl
		save `dataori', replace
		
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
		
		// Create ag - non-ag sector  
		gen sector_nonag = `industrycat4' ~= 1 if `industrycat4' ~= .			// Only works if sector = 1 is agriculture
		label define nonag 0 "Agriculture" 1 "Non-agriculture"
		label values sector_nonag nonag
		label var 	sector_nonag "Non-agriculture sector"
		save `dataori', replace
		
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
		frame create decomp_results2 strL(decomp spell povline) float(value1 value2 value3 value4 value5)
							  		
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
					sedecomposition using `data_y2' [aw=`wvar'], sector(sector_nonag) pline1(`var') pline2(`var') var1(`pppwelfare') var2(`pppwelfare') hc
					mat a = r(b_sec)
					mat b = r(b_tot)					
					local rnames : rowfullnames a
					local rlbl
					local x = 2
					foreach rn of local rnames {
						local rlbl `"`rlbl' `x' "`rn'""'
						local x = `x' + 1
					}					
					local value1 = b[1,1]
					local value2 = a[1,2]
					local value3 = a[2,2]
					local value4 = b[3,1]
					local value5 = b[4,1]
					
					* Post the results to the frame
					frame decomp_results2 {  
						frame post decomp_results2 ("Huppi-Ravallion") ("`1'-`2'") ("`var'") (`value1') (`value2') (`value3') (`value4') (`value5')
					}
				}
				foreach var of local natpovlines {
					//Huppi-Ravallion decomposition
					use `dataori' if `year'==`1', clear					
					sedecomposition using `data_y2' [aw=`wvar'], sector(sector_nonag) pline1(`var') pline2(`var') var1(`natwelfare') var2(`natwelfare') hc
					mat a = r(b_sec)
					mat b = r(b_tot)
					local rnames : rowfullnames a
					local rlbl
					local x = 2
					foreach rn of local rnames {
						local rlbl `"`rlbl' `x' "`rn'""'
						local x = `x' + 1
					}
					local value1 = b[1,1]
					local value2 = a[1,2]
					local value3 = a[2,2]
					local value4 = b[3,1]
					local value5 = b[4,1]
					
					* Post the results to the frame
					frame decomp_results2 {  
						frame post decomp_results2 ("Huppi-Ravallion") ("`1'-`2'") ("`var'") (`value1') (`value2') (`value3') (`value4') (`value5')
					}
				}	
			} //1 2
		} //j
		
		* See results
		frame change decomp_results2	
		
		reshape long value, i(decomp spell povline) j(subind)
		la def subind 1 "Total change in p.p." `rlbl' 4 "Population shift" 5 "Interaction"
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
			collect title `"Table 13b. Decomposition of poverty changes: Huppi-Ravallion decomposition (sectoral)"'
			collect notes 1: `"Source: World Bank calculations using survey data accessed through the Global Monitoring Database."'
			collect notes 2: `"Note: The Huppi-Ravallion decomposition shows how progress in poverty changes can be attributed to different groups, following Huppi and Ravallion (1991). The total change displayed in this table may differ from the total change displayed in Table 13a, due to missing values for the economic sector. Every household member is assigned the sector of employment of the household head. The intra-sectoral component displays how the incidence of poverty in the agricultural and non-agricultural sectors has changed, assuming the relative population size in each of these has remained constant. Population shift refers to the contribution of changes in population shares, assuming poverty incidence in each group has remained constant. The interaction between the two indicates whether there is a correlation between changes in poverty incidence and population movements."'
			collect style cell indicatorlbl[]#cell_type[row-header], font(, bold)
			collect style cell subind[]#cell_type[row-header], warn font(, nobold)
			_pea_tbtformat
			_pea_tbt_export, filename(Table13b) tbtname(Table13b) excel("`excel'") dirpath("`dirpath'") excelout("`excelout'") shell				
		}
	} //qui
end