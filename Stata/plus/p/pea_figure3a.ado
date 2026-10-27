 cap program drop pea_figure3a
program pea_figure3a, rclass
version 18.0

*==============================================================================
* Fig 3a. Growth Incidence Curve over time
*==============================================================================
* Disclaimers & credits 
	
	*! version 0.1.1  12Sep2014
	*! Copyright (C) World Bank 2017-2024 
	*! Minh Cong Nguyen <mnguyen3@worldbank.org>; Sandra Carolina Segovia Juarez 
	* <ssegoviajuarez@worldbank.org>; Henry Stemmler <hstemmler@worldbank.org>.
	*! Modifications by Daylan Alberto Salmeron Gomez; Maria Fernanda Gonzalez Icaza

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
*==============================================================================
* This program:
*   1. Validates the requested year spells;
*   2. Restricts the sample to the requested survey years;
*   3. Checks survey comparability, when comparability() is supplied;
*   4. Creates percentile-level mean welfare estimates;
*   5. Calculates annualized growth by percentile;
*   6. Produces one graph for the full sample and, optionally, for
*      each subgroup listed in by();
*   7. Exports graphs, underlying data, and graph code to Excel.

* A spell must contain exactly two years. Multiple spells must be
* separated by semicolons, for example: spells("2000 2004; 2004 2010")

* Required options:
*     welfare()    Welfare aggregate
*     spells()     One or more two-year spells
*     year()       Survey-year variable

* Optional grouping: by()         Numeric subgroup variables

*=============================================================================*/
//syntax [if] [in] [aw pw fw], [Welfare(varname numeric) spells(string) Year(varname numeric) comparability(varname numeric) setting(string) trim(string) YRange(string) excel(string) save(string) scheme(string) palette(string) ]
    syntax [if] [in] [aw pw fw],                       ///
        [                                                        ///
            Welfare(varname numeric)                             ///
            spells(string)                                       ///
            Year(varname numeric)                                ///
            BY(varlist numeric)                                  ///
            comparability(varname numeric)                       ///
            setting(string)                                      ///
            trim(string)                                         ///
            YRange(string)                                       ///
            excel(string)                                        ///
            save(string)                                         ///
            scheme(string)                                       ///
            palette(string)                                      ///
        ]
		
* Note: * setting() is retained for compatibility with existing calls but is
* not currently used by this program.	
		
*----------------------------------------------------------------
* Preserve user's data
*----------------------------------------------------------------
	preserve
	
*----------------------------------------------------------------
* Validate required options
* These options remain optional in syntax for compatibility with
* existing calls, but the program cannot run without them.
*----------------------------------------------------------------
    if "`welfare'" == "" {
        noisily display as error "welfare() is required"
        exit 198
    }

    if "`spells'" == "" {
        noisily display as error ///
            `"spells() is required; need at least two years; for example, spells("2000 2004")"'
        exit 198
    }

    if "`year'" == "" {
        noisily display as error "year() is required"
        exit 198
    }
	/* POTENTIALLY OBSOLETE CODE
	if "`nooutput'"~="" & "`excel'"~="" {
		noi dis as error "Cant have both nooutput and excel() options"
        exit 198
	} */
	
	/* Making sure save option is actually optional.
	if "`save'"=="" {
		tempfile saveout
		local save `saveout'
		* This creates a temporary filename when the user does not provide one, however, it is unclear whether this is dead code or not, seems not used afterwards.
	} */
	
*----------------------------------------------------------------
* Create sample indicator from user-supplied if/in qualifiers.
* Subsequent markout commands further restrict this sample by
* removing observations with missing values in required variables.
*----------------------------------------------------------------
marksample touse
	
*----------------------------------------------------------------
* Prepare the Excel export path
*----------------------------------------------------------------
_pea_export_path, excel("`excel'")
	
*----------------------------------------------------------------
* Parse and validate requested spells
*----------------------------------------------------------------
/* DELETE REDUNDANT BLOCK
* Convert the semicolon-delimited spell list into a list of all
* requested years. This list is used to restrict the input data.
    local requested_years = subinstr(`"`spells'"', ";", " ", .)
    local requested_years : list retokenize requested_years
    local requested_years : list uniq requested_years
    local requested_years : list sort requested_years */

    * Parse the individual semicolon-delimited spells.
    tokenize `"`spells'"', parse(";")
    local nspells = 0
    local token   = 1
    while `"``token''"' != "" {
        if `"``token''"' != ";" {
            local ++nspells
            local spell`nspells' `"``token''"'

     * Normalize internal spaces and order the two years.
     local spell`nspells' : list retokenize spell`nspells'
     local spell`nspells' : list sort spell`nspells'

     * Each spell must contain exactly two survey years.
      local nyears : word count `spell`nspells''

      if `nyears' != 2 {
                noisily display as error ///
                    `"Invalid spell: `spell`nspells''"'
                noisily display as error ///
                    "Each spell must contain exactly two years."
                restore
                exit 198
            }
            local start_year : word 1 of `spell`nspells''
            local end_year   : word 2 of `spell`nspells''

    * The annualized growth formula requires a positive time
            * interval between the starting and ending years.
            if `end_year' <= `start_year' {
                noisily display as error ///
    `"Invalid spell `start_year' `end_year': the ending year must be later than the starting year."'
                restore
                exit 198
            }
        }

        local ++token
    }

    if `nspells' == 0 {
        noisily display as error ///
            "At least one two-year spell must be specified."
        restore
        exit 198
    }

/* SIMPLER ORIGINAL OLD CODE 
	local x = subinstr("`spells'",";"," ",.)		
	local keepyears : list uniq x

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
	} */

*----------------------------------------------------------------
* Check spell comparability
* When comparability() is supplied, a spell is retained only when
* both of its years belong to at least one common comparability
* group.
*----------------------------------------------------------------
    local nvalid = 0
	    if "`comparability'" != "" {
        quietly levelsof `comparability' if `touse', ///
            local(comparability_groups)
        foreach group of local comparability_groups {
            quietly levelsof `year'                              ///
                if `touse' & `comparability' == `group',         ///
                local(comparable_years)
            local comparable_years : list sort comparable_years
            forvalues j = 1/`nspells' {
                local candidate_spell `"`spell`j''"'
                local spell_is_comparable : ///
                    list candidate_spell in comparable_years
                if `spell_is_comparable' {
                    local spell_valid`j' = 1
                }
            }
        }
        forvalues j = 1/`nspells' {
            if "`spell_valid`j''" == "1" {
                local ++nvalid
                local validspell`nvalid' `"`spell`j''"'
            }
            else {
                noisily display as text ///
                    `"Spell `spell`j'' excluded because its survey years are not comparable."'
            }
        }
    }
    else {
        * If no comparability variable is supplied, retain all
        * correctly specified spells.
        forvalues j = 1/`nspells' {
            local ++nvalid
            local validspell`nvalid' `"`spell`j''"'
        }
    }
    if `nvalid' == 0 {
        noisily display as error ///
            "No requested spell contains two comparable survey years."
        restore
        exit 2000
    }
	
* Create the list of years from valid spells
    * Spells excluded by the comparability check should not determine
    * the years retained in the working data.
   local valid_years
    forvalues j = 1/`nvalid' {
        local valid_years `valid_years' `validspell`j''
    }
    local valid_years : list uniq valid_years
    local valid_years : list sort valid_years	
	
	
/* OLDER VERSION 
	// Comparability
	local one = 1
	if "`comparability'" ~= "" {
		forv j=1(1)`=`a'-1' {
			local test
			local spell_c`j' = "`spell`j''"												// Save local
			qui levelsof `comparability', local(comp_years)								// Loop through all values of comparability
			foreach i of local comp_years {
				qui	levelsof year if `comparability' == `i', local(year_c)				// Create list of comparable years
				local year_c = "`year_c'" 
				local test_`i': list spell_c`j' in year_c								// Check if spell years are in list of comparable years
				local test "`test' `test_`i''"
			}
			local test_pos: list one in test												// Check if any spell has comparable years
			if (`test_pos' == 0) local spell`j' = ""										// If years not comparable, drop local
			if (`test_pos' == 1) local spell`j' = "`spell_c`j''"							// If years comparable, keep local			
		}
	}	// if
	*/
	
*----------------------------------------------------------------
* Validate percentile-trimming bounds
*----------------------------------------------------------------
    if "`trim'" == "" {
        local trim "3 97"
        noisily display as text ///
            "Default trimming below the 3rd and above the 97th percentile applied."
    }
    local ntrim : word count `trim'
    if `ntrim' != 2 {
        noisily display as error ///
            "trim() requires exactly two values, for example trim(5 95)."
        restore
        exit 198
    }
    local trim_low  : word 1 of `trim'
    local trim_high : word 2 of `trim'
    capture confirm number `trim_low'
    if _rc {
        noisily display as error ///
            "The lower trim() bound must be numeric."
        restore
        exit 198
    }
    capture confirm number `trim_high'
    if _rc {
        noisily display as error ///
            "The upper trim() bound must be numeric."
        restore
        exit 198
    }
    if `trim_low' < 1 | `trim_high' > 100 | ///
       `trim_low' >= `trim_high' {
        noisily display as error ///
            "trim() bounds must satisfy 1 <= lower < upper <= 100."
        restore
        exit 198
    }
		
/* OLD VERSION 	
	// Trimming
	if "`trim'" ~= "" {
		tokenize `trim'
		if missing("`2'") {
			noi dis as error "Trimming option needs 2 values, such as trim(5 95)"
			error 1
		}
	}
	else if "`trim'" == "" {
		local trim = "3 97"
		noi di in yellow "Default trimming below 3rd and above 97th percentile applied"
	} */
	
*----------------------------------------------------------------
* Configure graph scheme and colors
    * The number of requested colors is based on the valid spells,
*----------------------------------------------------------------
    pea_figure_setup,                            ///
        groups("`nvalid'")                       ///
        scheme("`scheme'")                       ///
        palette("`palette'")
		
/* OLD CODE
// Figure colors
	local _spells = subinstr("`spells'"," ","",.)														// Get number of spells
	local _spells = subinstr("`_spells'",";"," ",.)		
	local groups = `:word count `_spells''
	pea_figure_setup, groups("`groups'") scheme("`scheme'") palette("`palette'")						//	groups defines the number of colors chosen, so that there is contrast (e.g. in viridis) */
	
*----------------------------------------------------------------
* Prepare weights
* If no weight is supplied, assign equal analytical weights.
* Otherwise, preserve the weight type supplied by the user.
*----------------------------------------------------------------
    local wvar : word 2 of `exp'
    if "`wvar'" == "" {
        tempvar unit_weight
        generate double `unit_weight' = 1
        local wvar `unit_weight'
        local weight_expression "[aw=`unit_weight']"
    }
    else {
        local weight_expression "[`weight'`exp']"
    }
	
	/* OLD CODE: 	//variable checks
	//check plines are not overlapped.
	//trigger some sub-tables
	qui {		
		//Weights
		local wvar : word 2 of `exp'
		qui if "`wvar'"=="" {
			tempvar w
			gen `w' = 1
			local wvar `w'
		} */
		
*----------------------------------------------------------------
* Exclude observations missing any required analysis variable
*----------------------------------------------------------------
    local required_vars ///
        `wvar' `welfare' `year' `by' `comparability'
    markout `touse' `required_vars'
    quietly count if `touse'
    if r(N) == 0 {
        noisily display as error ///
            "No observations remain after applying the sample restrictions."
        restore
        exit 2000
    }
	
/* OLD CODE		
//missing observation check
		marksample touse
		local flist `"`wvar' `welfare' `by' `year'"'
		markout `touse' `flist' 
		
		tempfile dataori datalbl
		save `dataori', replace */

*----------------------------------------------------------------
* Check that all years from the valid spells are available
*----------------------------------------------------------------
    quietly levelsof `year' if `touse', local(available_years)
    local available_years : list sort available_years
    local unavailable_years : ///
        list valid_years - available_years
    if "`unavailable_years'" != "" {
        noisily display as error ///
            "The following requested years are unavailable: `unavailable_years'"
        noisily display as text ///
            "Available years: `available_years'"
        restore
        exit 198
    }
	
/* OLD CODE 	
		levelsof `year' if `touse', local(yrlist)
		local same : list keepyears in yrlist
		if `same'==0 {
			noi dis "There are different years requested, and some not available in the data."
			noi dis "Requested: `keepyears'. Available: `yrlist'"
		} */
*----------------------------------------------------------------
* Restrict the working dataset to years appearing in valid spells
*----------------------------------------------------------------
    tempvar keep_requested_year
    generate byte `keep_requested_year' = 0 if `touse'
    foreach yr of local valid_years {
        replace `keep_requested_year' = 1 ///
            if `touse' & `year' == `yr'
    }
    keep if `touse' & `keep_requested_year' == 1
    quietly count
    if r(N) == 0 {
        noisily display as error ///
            "No observations remain for the requested survey years."
        restore
        exit 2000
    }
    quietly levelsof `year', local(yrlist)	
	
/* OLD CODE		
		gen _keep =. if `touse'
		foreach yr of local keepyears {
			replace _keep=1 if `year'==`yr' & `touse'
		}
		keep if _keep==1 & `touse'
		drop _keep
		gen _all_ = 1 if `touse'
		la var _all_ "All sample"
		la def _all_ 1 "All sample"
		la val _all_ _all_
		local by "_all_ `by'"		
		save `dataori', replace
		levelsof `year' if `touse', local(yrlist) */
		
*----------------------------------------------------------------
* Create an internal full-sample grouping variable
* A temporary variable is used to avoid overwriting a variable
* named _all_ that may already exist.
*----------------------------------------------------------------
    tempvar all_sample
    generate byte `all_sample' = 1
    label variable `all_sample' "All sample"
    label define pea_all_sample 1 "All sample", replace
    label values `all_sample' pea_all_sample
    local groupvars `all_sample' `by'
		
*----------------------------------------------------------------
* Store the restricted source data and initialize results file
*----------------------------------------------------------------
    tempfile data_original results
    save `data_original', replace
    clear
    save `results', replace emptyok	
		
*----------------------------------------------------------------
* Calculate mean welfare by percentile, year, and group
*----------------------------------------------------------------
	foreach groupvar of local groupvars {
        use `data_original', clear
        quietly levelsof `groupvar', local(group_levels)
        local group_variable_label : variable label `groupvar'
        if `"`group_variable_label'"' == "" {
            local group_variable_label "`groupvar'"
        }	
        local group_value_label : value label `groupvar'
        foreach group_level of local group_levels {
            local group_label "`group_level'"
            if "`group_value_label'" != "" {
                local group_label : ///
                    label `group_value_label' `group_level'
            }
            if `"`group_label'"' == "" {
                local group_label "`group_level'"
            }
            foreach yr of local yrlist {
                use `data_original', clear
                tempvar welfare_quantile
                capture _ebin `welfare' `weight_expression'      ///
                    if `year' == `yr' &                          ///
                       `groupvar' == `group_level',               ///
                    nquantiles(100)                               ///
                    gen(`welfare_quantile')
                if _rc {
                    local rc = _rc
                    noisily display as error ///
                        `"Unable to create percentiles for `groupvar' == `group_level' in `yr'."'
                    restore
                    exit `rc'
                }
                collapse (mean) `welfare' `weight_expression'    ///
                    if `year' == `yr' &                          ///
                       `groupvar' == `group_level',               ///
                    by(`welfare_quantile')

                rename `welfare_quantile' percentile

                * Store a standardized year identifier so that the
                * code does not assume the user's variable is named
                * year.
                generate double pea_year = `yr'

                * Store standardized group identifiers and labels.
                generate str32 group_variable = "`groupvar'"
                generate double group_value = `group_level'

                generate str244 group_variable_label = ///
                    `"`group_variable_label'"'

                generate str244 group_value_label = ///
                    `"`group_label'"'

                append using `results'
                save `results', replace
            }
        }
    }
// IMPORTANT: _ebin.ado MUST BE CHECKED TO SEE IF IT SUPPORTS MORE THAN AW
			
		
/* OLD CODE UNCLEAR FOR WHAT
		clear
		tempfile data2
		save `data2', replace emptyok
		foreach byvar of local by {
			use `dataori', clear			
			levelsof `byvar', local(byvlist)
			local lbl`byvar' : variable label `byvar'				
			local label1 : value label `byvar'
			
			foreach lvl of local byvlist {				
				local lvl`byvar'_`lvl' : label `label1' `lvl'				
				foreach yr of local yrlist {
					use `dataori', clear
					tempvar qwlf
					cap _ebin `welfare' [aw=`wvar'] if `touse' & `year'==`yr' & `byvar'==`lvl', nquantiles(100) gen(`qwlf')
					if _rc!=0 {
						noi di in red "Error in creating percentile for `byvar'==`lvl'"						
						exit `=_rc'
					} 
					else {												
						collapse (mean) `welfare' [aw=`wvar'] if `touse' & `year'==`yr' & `byvar'==`lvl', by(`qwlf')
						ren `qwlf' percentile
						gen year = `yr'
						gen var = "`byvar'"
						gen var_lvl = `lvl'
						append using `data2'
						save `data2', replace
					}					
				}
			}	
		} */
*----------------------------------------------------------------
* Reshape percentile-level welfare estimates to wide format
*----------------------------------------------------------------
   use `results', clear
    quietly count
    if r(N) == 0 {
        noisily display as error ///
            "No percentile-level welfare estimates were generated."
        restore
        exit 2000
    }
    reshape wide `welfare',                                   ///
        i(                                                    ///
            group_variable                                    ///
            group_value                                       ///
            group_variable_label                              ///
            group_value_label                                 ///
            percentile                                        ///
        )                                                     ///
        j(pea_year)
/* old code 
use `data2', clear
		reshape wide `welfare', i(var var_lvl percentile) j(`year') */
		
*----------------------------------------------------------------
* Construct ordering variables for output and graph production
*----------------------------------------------------------------
    egen variable_order = group(group_variable), label
    egen group_order = group(                                 ///
        group_variable                                        ///
        group_value                                           ///
    )
    label variable variable_order "Grouping-variable order"
    label variable group_order    "Group order"

*----------------------------------------------------------------
* Assign readable group labels
*
* Preserve the spirit of the original implementation by combining
* the grouping-variable label and the value label. This avoids
* ambiguous graph titles such as "Male" or "Urban" when multiple
* by() variables are supplied.
*----------------------------------------------------------------

quietly levelsof group_order, local(group_order_list)

foreach group_id of local group_order_list {

    quietly levelsof group_variable_label                      ///
        if group_order == `group_id',                          ///
        local(current_var_label) clean

    quietly levelsof group_value_label                         ///
        if group_order == `group_id',                          ///
        local(current_group_label) clean

    * Full sample group
    if `"`current_var_label'"' == "All sample" {
        local final_label "All sample"
    }
    else {

        if `"`current_var_label'"' == "" {
            local current_var_label "Group"
        }

        if `"`current_group_label'"' == "" {
            local current_group_label "`group_id'"
        }

        local final_label ///
            `"`current_var_label' - `current_group_label'"'
    }

    label define pea_group_order ///
        `group_id' `"`final_label'"', ///
        modify
}
label values group_order pea_group_order
		
/* OLD CODE 
		local i=1
		local j=1
		gen var_order = .
		gen group_order = .
		foreach var1 of local by {
			replace var_order =`j' if var=="`var1'"
			la def var_order `j' "`lbl`var1''", add
			local j = `j'+1
			levelsof var_lvl if var=="`var1'", local(grplvl)
			foreach lv of local grplvl {
				replace group_order = `i' if var=="`var1'" & var_lvl==`lv'
				la def group_order `i' "`lvl`var1'_`lv''", add
				local i = `i' + 1
			}
		}
		la val var_order var_order
		la val group_order group_order
		drop var_lvl var		
		local vargic 
		local varlbl */
		
*----------------------------------------------------------------
* Calculate annualized growth for each valid spell.
* Growth incidence curves are computed using percentile-level mean
* welfare in the starting and ending year. The annualized growth
* formula assumes positive welfare values. 
*----------------------------------------------------------------
local vargic
local varlbl
forvalues j = 1/`nvalid' {
    local current_spell `"`validspell`j''"'
    local start_year : word 1 of `current_spell'
    local end_year   : word 2 of `current_spell'
    capture confirm variable `welfare'`start_year'
    if _rc {
        noi di as err ///
            "Welfare estimates are unavailable for `start_year'"
        restore
        exit 111
    }
    capture confirm variable `welfare'`end_year'
    if _rc {
        noi di as err ///
            "Welfare estimates are unavailable for `end_year'"
        restore
        exit 111
    }

    local gicvar gic_`start_year'_`end_year'

    gen double `gicvar' = ///
        ((`welfare'`end_year' / `welfare'`start_year') ///
        ^ (1/(`end_year' - `start_year')) - 1) * 100

    local varcount = `:word count `vargic'' + 1

    label variable `gicvar' ///
        "GIC Spell`varcount': `start_year'-`end_year'"

    local vargic `vargic' `gicvar'
    local varlbl `"`varlbl' `varcount' "`start_year'-`end_year'""'
}

if "`vargic'" == "" {
    noi di as err ///
        "No growth-incidence-curve variables could be generated."
    restore
    exit 2000
}
		
	/* OLD CODE 	
		forv j=1(1)`=`a'-1' {
			local spell`j' : list sort spell`j'
			tokenize "`spell`j''"
			if "`1'"~="" & "`2'"~="" {
				dis "Spell`j': `1'-`2'"		
				gen gic_`1'_`2' = ((`welfare'`2'/`welfare'`1')^(1/(`2'-`1'))-1)*100
				local vargic "`vargic' gic_`1'_`2'"
				local varcount = `:word count `vargic''	// added so that legend element fits if not all spells are comparable
				la var gic_`1'_`2' "GIC Spell`varcount': `1'-`2'"
				local varlbl `"`varlbl' `varcount' "`1'-`2'""'
			}
		} */
		
*----------------------------------------------------------------
* Apply percentile trimming
*----------------------------------------------------------------
    drop if percentile < `trim_low'
    drop if percentile > `trim_high'
    quietly count
    if r(N) == 0 {
        noisily display as error ///
            "No observations remain after applying trim(`trim')."
        restore
        exit 2000
    }
    sort variable_order group_order percentile
/* OLD CODE 
		tokenize "`trim'"
		drop if percentile < `1'
		drop if percentile > `2'
		sort var_order group_order percentile
		return local vargic = "`vargic'"
		return local varlbl = `"`varlbl'"' */

*----------------------------------------------------------------
* Determine the graph's y-axis range
* If yrange() is not supplied, calculate common labels across all
* generated GIC variables.
*----------------------------------------------------------------
    if "`yrange'" == "" {
        local range_initialized = 0
        foreach variable of local vargic {
            quietly summarize `variable', meanonly
            if r(N) > 0 {
                if !`range_initialized' {
                    local ymin_raw = r(min)
                    local ymax_raw = r(max)
                    local range_initialized = 1
                }
                else {
                    if r(min) < `ymin_raw' local ymin_raw = r(min)
                    if r(max) > `ymax_raw' local ymax_raw = r(max)
                }
            }
        }
        if !`range_initialized' {
            noisily display as error ///
                "All calculated growth-incidence-curve values are missing."
            restore
            exit 2000
        }
        local ymin = min(0, floor(`ymin_raw'))
        local ymax = max(0, ceil(`ymax_raw'))
    * nicelabels requires distinct lower and upper endpoints.
        if `ymin' == `ymax' {
            local ymin = `ymin' - 1
            local ymax = `ymax' + 1
        }
        nicelabels `ymin' `ymax', local(ylabels)
        local yrange_option `"ylabel(`ylabels')"'
    }
    else {
        local yrange_option `"ylabel(`yrange')"'
    }

 /* old code 
* Define Axis range
		if "`yrange'" == "" {
			local m = 1
			foreach var of local vargic {
				sum `var'													// min/max can come from different variables
				if (`m' == 1) local max = `r(max)'
				if (`m' == 1) local min = `r(min)'
				if (`r(max)' > `max') local max = `r(max)'
				if (`r(min)' < `min') local min = `r(min)'
				local m = `m' + 1
			}
			if `min' < 0 local ymin = floor(`min')
			else local ymin = 0
			if `max' > 0 local ymax = ceil(`max')
			else local ymax = 0
			nicelabels `ymin' `ymax', local(yla)
			local yrange "ylabel(`yla')"
		}
		else {
			local yrange "ylabel(`yrange')"
		} */

*----------------------------------------------------------------
* Prepare Excel output
*----------------------------------------------------------------
    local figure_name "Figure3a"
    local sheet_name  "Figure3a"
    if "`excel'" == "" {
        local excel_output `"`dirpath'\`figure_name'.xlsx"'
        capture erase `"`excel_output'"'
        putexcel set `"`excel_output'"', replace
    }
    else {
        local excel_output `"`excelout'"'
        putexcel set `"`excel_output'"', modify
    }
	
	/* OLD CODE 
* Figure preparation
		local figname Figure3a
		if "`excel'"=="" {
			local excelout2 "`dirpath'\\`figname'.xlsx"
			local act replace
			cap rm "`dirpath'\\`figname'.xlsx"
		}
		else {
			local excelout2 "`excelout'"
			local act modify
		}
				
		local gr 1
		local u  = 5 */
		
*----------------------------------------------------------------
* Replace the worksheet once before generating graphs
*----------------------------------------------------------------
    putexcel set `"`excel_output'"', ///
        modify sheet("`sheet_name'", replace)
	
*----------------------------------------------------------------
* Write figure title, source, note, and output headings
*----------------------------------------------------------------
    putexcel A1 = ""
    putexcel A2 = ///
        "Figure 3a: Growth Incidence Curves"
    putexcel A3 = ///
        "Source: World Bank calculations using survey data accessed through the GMD."
    putexcel A4 = ///
        "Note: Growth incidence curves display annualized household growth in per capita consumption or income by percentile of the welfare distribution between two periods. Growth incidence curves are shown only for years with comparable surveys. Percentiles below `trim_low' and above `trim_high' are excluded."
    if "`excel'" != "" {
        putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
    }
    putexcel O6  = "Code:"
    putexcel O10 = "Data:"
    putexcel N11 = "Variables:"	

*----------------------------------------------------------------
* Generate and export one graph for each group
*----------------------------------------------------------------
    quietly levelsof group_order, local(group_list)
    local graph_row = 5
    local code_row  = 7
    foreach group of local group_list {
        tempfile graph_file
        local graph_title : label pea_group_order `group'
        if `"`graph_title'"' == "" {
            local graph_title "Group `group'"
        }
        twoway                                                   ///
            (connected `vargic' percentile                       ///
                if group_order == `group',                       ///
                yline(                                           ///
                    0,                                           ///
                    lpattern(dash)                               ///
                    lcolor(black*0.6)                            ///
                )                                                ///
                lcolor(${colorpalette})                          ///
                mcolor(${colorpalette})                          ///
            ),                                                   ///
            legend(                                              ///
                on                                               ///
                order(`"`varlbl'"')                              ///
                rows(1)                                          ///
                position(6)                                      ///
            )                                                    ///
            `yrange_option'                                      ///
            title(`"`graph_title'"')                             ///
            xtitle("Percentile")                                 ///
            ytitle("Annualized growth, %")                       ///
            name(pea_figure3a_`group', replace)

        graph export `"`graph_file'"',                           ///
            replace                                              ///
            as(png)                                              ///
            name(pea_figure3a_`group')                           ///
            width(1500)

        * graph_row is incremented after every iteration so that each
        * exported graph is inserted in a different Excel location.
        putexcel A`graph_row' = image(`"`graph_file'"')

        putexcel O`code_row' = ///
            `"twoway (connected `vargic' percentile if group_order == `group', yline(0, lpattern(dash) lcolor(black*0.6)) lcolor(${colorpalette}) mcolor(${colorpalette})), legend(on order(`"`varlbl'"') rows(1) position(6)) `yrange_option' xtitle("Percentile") ytitle("Annualized growth, %")"'

        * Leave sufficient vertical space between graphs.
        local graph_row = `graph_row' + 25
        local code_row  = `code_row' + 1
    }

    graph close _all
    putexcel save

	
/* old code 
* Plot figure 
		putexcel set "`excelout2'", `act'
		levelsof group_order, local(grlist)
		foreach gr of local grlist {
			tempfile graph`gr'
			local lbltitle : label group_order `gr'	
			
		twoway (connected `vargic' percentile, yline(0, lp(-) lc(black*0.6)) lcolor(${colorpalette}) mcolor(${colorpalette})) if group_order==`gr', ///
		legend(on order(`"`varlbl'"') rows(1) position(6)) `yrange' ///
		xtitle(Percentile) ytitle("Annualized growth, %") name(ngraph`gr', replace) */

*----------------------------------------------------------------
* Export the underlying figure data
*----------------------------------------------------------------
    export excel * using `"`excel_output'"',                    ///
        sheet("`sheet_name'", modify)                           ///
        cell(O11)                                               ///
        keepcellfmt                                             ///
        firstrow(variables)                                     ///
        nolabel
*----------------------------------------------------------------
* Optionally save the underlying GIC dataset
*----------------------------------------------------------------
    if `"`save'"' != "" {
        save `"`save'"', replace
    }
	
/* OLD CODE
			putexcel set "`excelout2'", modify sheet(Figure3a, replace)
			graph export "`graph`gr''", replace as(png) name(ngraph`gr') wid(1500)
			putexcel A`u' = image("`graph`gr''")
			
			putexcel A1 = ""
			putexcel A2 = "Figure 3a: Growth Incidence Curves"
			putexcel A3 = "Source: World Bank calculations using survey data accessed through the GMD."
			putexcel A4 = "Note: Growth incidence curves display annualized household growth in per capita consumption or income by percentile of the welfare distribution between two periods. Growth incidence curves are only shown for years with comparable surveys. Percentiles are trimmed below `1' and above `2'."
			
			putexcel O10 = "Data:"
			putexcel O6	= "Code:"
			putexcel N11 = "Labels:"
			putexcel N12 = "Variables:"
			putexcel O7 = `"twoway (connected `vargic' percentile, yline(0, lp(-) lc(black*0.6)) lcolor(${colorpalette}) mcolor(${colorpalette})) if group_order==`gr', legend(on order(`"`varlbl'"') rows(1) position(6)) `yrange' xtitle(Percentile) ytitle("Annualized growth, %")"'
			if "`excel'"~="" putexcel I1 = hyperlink("#Contents!A1", "Back to Contents")
			putexcel save					
		}		
		cap graph close	
	} 
	
	export excel * using "`excelout2'", sheet("Figure3a", modify) cell(O11) keepcellfmt firstrow(varlabels)	
	export excel * using "`excelout2'", sheet("Figure3a", modify) cell(O12) keepcellfmt firstrow(variables)	nolabel
		
	if "`excel'"=="" shell start excel "`dirpath'\\`figname'.xlsx"	*/
	shell explorer "%TEMP%"
	shell start "" "`excelout'"
	restore
end
*==============================================================================
