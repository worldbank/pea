cap program drop _pea_pline_order
program _pea_pline_order, rclass
	version 16.0
	syntax [if] [in] [aw pw fw], [povlines(varlist numeric)]	
	tempname _x _varname _mean
	gen `_x' = _n
	gen `_varname' = ""
	gen `_mean' = .

	local i = 1
	foreach var of varlist `povlines' {
		quietly sum `var'
		if r(mean) < . {
			replace `_varname' = "`var'" in `i'
			replace `_mean' = r(mean) in `i'
			local lbl`var' : variable label `var'
			if "`lbl`var''"=="" {
				local lbl`var' "`var'"
				la var `var' "`var'"
			}
			local i = `i' + 1				
		}
	}
	local sorted_line
	local val_sorted_line
	sort `_mean'
	forv j=1(1)`=`i'-1' {
		local x = `_varname'[`j']
		local sorted_line `sorted_line' `x'
		local y = `_mean'[`j']		
		local y : display %4.2f `y'
		local val_sorted_line `val_sorted_line' `=trim("`y'")'
	}
	
	sort `_x'
	drop `_varname' `_mean' `_x'
	return local sorted_line "`sorted_line'"
	return local val_sorted_line "`val_sorted_line'"
	foreach var of local sorted_line {
		return local lbl`var' "`lbl`var''"
	}
end