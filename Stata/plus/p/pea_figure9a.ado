*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 
*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Henry Stemmler <hstemmler@worldbank.org>; Sandra Carolina Segovia Juarez <ssegoviajuarez@worldbank.org>
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

//Figure 9a. Inequality by year lines

cap program drop pea_figure9a
program pea_figure9a, rclass
	version 18.0
	syntax [if] [in] [aw pw fw], [ONEWelfare(varname numeric) Year(varname numeric) comparability(string) NOOUTPUT NOEQUALSPACING YRange(string) ineqind(string) excel(string) save(string) BAR MISSING scheme(string) palette(string) PPPyear(integer 2021)]
	//Check PPPyear
	_pea_ppp_check, ppp(`pppyear')
	
	local persdir : sysdir PERSONAL	
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all		
	
	//house cleaning	
	if "`comparability'"=="" {
		noi di in red "Warning: Comparability option not specified for Figure 9a. Non-comparable spells may be shown."	// Not a strict condition
	}
	else if "`comparability'"~="" {
		qui ta `year'
		local nyear = r(r)
		qui ta `comparability'
		local ncomp = r(r)
		if `ncomp' > `nyear' {
			noi dis as error "Inconsistency between number of years and number of comparable data points."
			error 1
		}
	}	
	if "`using'"~="" {
		cap use "`using'", clear
		if _rc~=0 {
			noi di in red "Unable to open the data"
			exit `=_rc'
		}
	}
	_pea_export_path, excel("`excel'")
	
	// If no indicator specified, all are used
	if ("`ineqind'" == "") local ineqind "Gini Theil Palma Top20"
		
	// Warning messages and invalid values
	local allowed_ind "Gini Theil Palma Top20"
	local check_ineq: list ineqind in allowed_ind 
	if 	`check_ineq' ~= 1 {		
		noi dis as error `"Inequality indicators may not include entries other than "Gini", "Theil", "Palma", "Top20"."'
		error 1
 	}	
	
	//Number of groups (for colors)
	local groups = `:word count `ineqind''

	// Figure colors
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")	//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis)

	//Weights
	local wvar : word 2 of `exp'
	qui if "`wvar'"=="" {
		tempvar w
		gen `w' = 1
		local wvar `w'
	}
	
	if "`onewelfare'"~="" { //reset to the floor
		replace `onewelfare' = ${floor_} if `onewelfare'< ${floor_}
		noi dis "Replace the bottom/floor ${floor_} for `pppyear' PPP"
	}
		
	//missing observation check
	marksample touse
	local flist `"`wvar' `onewelfare' `year'"'
	markout `touse' `flist' 
	
	tempfile dataori datacomp
	save `dataori', replace

	//store comparability
	if "`comparability'"~="" {
		bys  `year': keep if _n == 1
		keep `year' `comparability'
		save `datacomp'
	}	
	
	use `dataori', clear	
	
	//Prepare inequality indicators
	* Create a frame to store the results
	cap frame create temp_frame
	cap frame change temp_frame
	cap frame drop ineq_results	
	frame create ineq_results float(year) ///
							  float(Gini Theil Palma Top20)
	
	use `dataori', clear
	* Get unique combinations of year
	levelsof `year', local(years)
	* Loop through each year
	foreach y in `years' {			
			qui { 
				//Kuznets (Palma) ratio & Top 20 Share
				//bottom20share: define quintile, su welfare [weight] --> r(r_sum) of q1/total
					_ebin `onewelfare' [w=`wvar'] if (`year'==`y'), nquantiles(10) gen(qwlf)
					
						su `onewelfare' [w=`wvar'] if (`year'==`y') 
						local totwelf =  r(sum)
							
						su `onewelfare' [w=`wvar'] if (`year'==`y' & qwlf <= 4) 
						local b40welf =  r(sum)
				
						su `onewelfare' [w=`wvar']  if (`year'==`y' & qwlf >= 8)
						local t20welf =  r(sum)
							
						su `onewelfare' [w=`wvar']  if (`year'==`y' & qwlf == 10)
						local t10welf =  r(sum)			
							
						local palma = `t10welf'/`b40welf'
						local t20share = (`t20welf'/`totwelf')*100

						drop qwlf
				
					// Gini, Theil, Atkinson, Sen, GEs...
					ineqdeco `onewelfare' [w=`wvar'] if (`year'==`y'), welfare
					* See <<help ineqdeco>> for definitions
				}
				
				// Post the results to the frame
				frame ineq_results {  
					frame post ineq_results (`y') 				///
						(`=`r(gini)'*100') (`=`r(ge1)'*100') (`palma') (`t20share')
				}
	} //end years

	* See results
	frame change ineq_results
	
	d, varlist
	local vars `r(varlist)'
	unab omit: year
	local choose:  list vars - omit
	noi di "`choose'"
	foreach var of local choose {
		rename `var' ind_`var'
	}

	reshape long ind_, i(`year') j(indicator) string

	gen indicatorlbl=.
	replace indicatorlbl = 1 if indicator=="Gini"
	replace indicatorlbl = 2 if indicator=="Theil"
	replace indicatorlbl = 3 if indicator=="Top20"
	replace indicatorlbl = 4 if indicator=="Palma"
	replace ind_ = ind_ * 10 if indicator == "Palma"	// Need to add *10 to Palma ratio for axis range

	la def indicatorlbl 1 "Gini index" 2 "Theil index" 3 "Top 20% share of incomes (%)" 4 "Palma (Kuznets) ratio (*10)"		// Need to add *10 to Palma ratio
	la val indicatorlbl indicatorlbl

	*Keep only those that are specified
	gen keep = .
	foreach k of local ineqind {
		replace keep = 1 if indicator=="`k'"		
	}
	keep if keep == 1
	drop keep
	

	//Axis range
	if "`yrange'" == "" {
		local ymin = 0
		qui sum ind_
		nicelabels `ymin' `r(max)', local(yla)
		local yrange "ylabel(`yla')"
	}
	else {
		local yrange "ylabel(`yrange')"
	}

	// Add comparability variable
	if "`comparability'"~="" {
		merge m:1 `year' using `datacomp', nogen
	}
	
	//Prepare year variable without gaps if specified
	if "`noequalspacing'"=="" {																	// Year spacing option
		egen year_nogap = group(`year'), label(year_nogap)										// Generate year variable without gaps
		local year year_nogap
	}	
	qui levelsof `year'		 , local(yearval)	
	sort `year'

	if "`comparability'"~="" {
		qui levelsof `comparability', local(compval)
		local compgroups = `:word count `compval''
	}
	else local compgroups = 1
	// Put together graph components
	qui levelsof indicatorlbl, local(ind)
	local j = 1
	foreach i of local ind {
		
		local label_`i': label(indicatorlbl) `i'
		local legend`i' `"`j' "`label_`i''""'						
		local legend "`legend' `legend`i''"	
		local allindicators "`allindicators' `label_`i''"
	
		local scatter_cmd`i' = `"scatter ind_ `year' if indicatorlbl==`i', mcolor("${col`j'}") lcolor("${col`j'}") || "'	// Colors defined in pea_figure_setup
		local scatter_cmd "`scatter_cmd' `scatter_cmd`i''"
		// Connect years (only if comparable if option is specified)
		
		if "`comparability'"~="" {												// If comparability specified, only comparable years are connected
			foreach co of local compval {
				local line_cmd`i'`co' = `"line ind_ `year' if indicatorlbl==`i' & `comparability'==`co', mcolor("${col`j'}") lcolor("${col`j'}") || "'
				local line_cmd "`line_cmd' `line_cmd`i'`co''"
			}
				local note_c "Non-connected dots indicate that survey-years are not comparable."
			}
			
		else if "`comparability'"=="" {
			local line_cmd`i'= `"line ind_ `year' if indicatorlbl==`i', mcolor("${col`j'}") lcolor("${col`j'}") || "' 					
			local line_cmd "`line_cmd' `line_cmd`i''"
		}
		
		local bcolors "`bcolors' bar(`j', color(${col`j'}))"		
		local j = `j' + 1
	}

	if "`excel'"=="" {
		local excelout2 "`dirpath'\\Figure9a.xlsx"
		local act replace
		cap rm "`dirpath'\\Figure9a.xlsx"
	}
	else {
		local excelout2 "`excelout'"
		local act modify
	}

	//Figure		
	local gr = 1
	local u  = 5
	putexcel set "`excelout2'", `act'
	//change all legend to bottom, and maybe 2 rows
	//add comparability
	tempfile graph`gr'
	if "`bar'" == "" {
		twoway `scatter_cmd' `line_cmd'								///	
			  , legend(order("`legend'") pos(6) row(1)) 			///
			  ytitle("Inequality indicators", axis(1))				///
			  xtitle("")											///
			  xlabel(`yearval', valuelabel)							///
			  `yrange'												///
			  name(ngraph`gr', replace)	
	}		  
	else if "`bar'" ~= "" {
		graph bar ind_, over(indicatorlbl) over(`year') `bcolors'	///
				ytitle("Inequality indicators") asyvars				///
				`yrange' name(ngraph`gr', replace)								
	}
	putexcel set "`excelout2'", modify sheet(Figure9a, replace)	  
	graph export "`graph`gr''", replace as(png) name(ngraph`gr') wid(1500)		
	putexcel A`u' = image("`graph`gr''")
	
	putexcel A1 = ""
	putexcel A2 = "Figure 9a: Inequality indices over time"
	putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
	putexcel A4 = "Note: The figure shows `allindicators' over time. The Palma (Kuznets) ratio measures the top 10 percent income share relative to the bottom 40 percent share. Its values have been multiplied by 10 to display them on the same scale as the other inequality indicators. A Palma ratio of 2 appears as 20 on this graph. The Gini index is a measure of inequality ranging from 0 (perfect equality) to 100 (perfect inequality). The Theil Index measures the distance of the welfare distribution from perfect equality. The top 20% share of incomes indicates the share of total income or consumption held by the top 20% of the welfare distribution. `note_c'"
	
	putexcel O10 = "Data:"
	putexcel O6	= "Code:"
	if "`bar'" == "" putexcel O7 = `"twoway `scatter_cmd' `line_cmd', legend(order("`legend'") pos(6) row(1)) ytitle("Inequality indicators", axis(1)) xtitle("") xlabel(`yearval', valuelabel) `yrange'"'
	else if "`bar'" ~= "" putexcel O7 = `"graph bar ind_, over(indicatorlbl) over(year) `bcolors' ytitle("Inequality indicators") `yrange' asyvars"'
	if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
	putexcel save							
	cap graph close	
	//Export data
	export excel * using "`excelout2'" , sheet("Figure9a", modify) cell(O11) keepcellfmt firstrow(variables) nolabel
	if "`excel'"=="" shell start excel "`dirpath'\\Figure9a.xlsx"

end	
